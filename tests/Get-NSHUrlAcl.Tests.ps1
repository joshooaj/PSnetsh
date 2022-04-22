#Requires -RunAsAdministrator
BeforeAll {
    $moduleManifest = "$PSScriptRoot\..\PSnetsh\PSnetsh.psd1"
    Write-Host "Importing $moduleManifest"
    Import-Module $moduleManifest -Force
}

Context "Get-NSHUrlAcl" {
    BeforeAll {
        $script:testUrl = 'https://+:8443/PSnetshFakeUrl/'
        $result = & netsh http show urlacl url=$testUrl
        if ($null -eq ($result | Select-String -SimpleMatch $testUrl)) {
            $result = & netsh http add urlacl url=$testUrl user="NT AUTHORITY\NetworkService"
            if (!$?) {
                throw [string]::Join([environment]::NewLine, $result)
            }
        }
    }
    
    It "Returns at least one urlacl" {
        (Get-NSHUrlAcl).Count | Should -BeGreaterThan 0
    }

    It "Returns a specific urlacl" {
        Get-NSHUrlAcl -Url $testUrl | Should -Not -BeNullOrEmpty
    }
}
