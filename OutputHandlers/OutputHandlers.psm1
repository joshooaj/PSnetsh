$parsers = Get-ChildItem -Path $PSScriptRoot\*.ps1
foreach ($parser in $parsers) {
    . $parser.FullName
}

Export-ModuleMember -Function $parsers.BaseName