$projectRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($projectRoot)) {
    $projectRoot = (Get-Location).Path
}
Write-Host "`$projectRoot = $projectRoot"

Write-Host "Importing output handlers"
Import-Module -Name $projectRoot\OutputHandlers\OutputHandlers.psm1 -Force -Global

$commands = Get-ChildItem $projectRoot\CommandDefinitions\*.json | Foreach-Object {
    Write-Host "Importing command configuration from $($_.FullName)"
    Import-CommandConfiguration -file $_.FullName
}
foreach ($command in $commands) {
    Write-Host "Retrieving help information for '$($command.OriginalName) $($command.OriginalCommandElements)'"
    $command.Description = [string]::join("`n", (& $command.OriginalName $command.OriginalCommandElements /?)).Trim()
}

Write-Host "Building Crescendo configuration file"
$configuration = [PSCustomObject]@{
    '$Schema' = "https://aka.ms/PowerShell/Crescendo/Schemas/2021-11"
     Commands = @($commands)
}
$configuration | ConvertTo-Json -Depth 10 | Out-File $projectRoot\netsh.Crescendo.json
$configurationFile = Resolve-Path $projectRoot\netsh.Crescendo.json | Select-Object -ExpandProperty Path
try {
    $moduleRoot = Join-Path $projectRoot PSnetsh
    Write-Host "Exporting Crescendo module to $moduleRoot"
    $null = New-Item -Path $moduleRoot -ItemType Directory -Force
    Get-ChildItem $moduleRoot | Remove-Item -Recurse
    Push-Location $moduleRoot
    Export-CrescendoModule -ConfigurationFile $configurationFile -ModuleName "PSnetsh" -ErrorAction Stop
    Write-Host "Module available at $(Join-Path $moduleRoot 'PSnetsh.psd1')"
} finally {
    Pop-Location
}

$command = 'Invoke-Pester -OutputFormat NUnitXml -OutputFile testResults.xml'
Start-Process -FilePath 'pwsh' -Verb RunAs -ArgumentList '-wd', $projectRoot, '-nop', '-nol', '-Command', $command -Wait
if (Test-Path $projectRoot\testResults.xml) {
    $xml = [xml](Get-Content $projectRoot\testResults.xml)
    $passed = $true
    foreach ($case in $xml.SelectNodes("//test-case[@success='False']")) {
        $passed = $false
        $message = 'Test case "{0}" failed: {1}' -f $case.Attributes['name'].Value, $case.failure.message
        Write-Error $message
    }
    if ($passed) {
        Write-Host "All Pester tests passed" -ForegroundColor Green
    }
}
