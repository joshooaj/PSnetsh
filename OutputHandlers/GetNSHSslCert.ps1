function GetNSHSslCert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $cmdResults
    )
    
    process {
        $emitSslCert = {
            param($sslcert, $extendedProperties)
            if ($null -ne $sslcert -and $sslcert.Keys.Count -gt 1) {
                $sslcert.ExtendedProperties = $extendedProperties
                [pscustomobject]$sslcert
            }
        }

        $pattern = '^\s*(?<key>.+)\s+:\s(?<value>.*)$'
        foreach ($line in $cmdResults) {
            if ($line -notmatch $pattern) { continue }
            $key, $value = $Matches.key.Trim(), $Matches.value.Trim()
            switch ($key) {
                'IP:port' {
                    $emitSslCert.Invoke($sslcert, $extendedProperties)
                    Write-Verbose "Processing sslcert binding for IP:port $value"
                    $extendedProperties = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
                    $dictionary = [ordered]@{}
                    $sslcert = $dictionary
                }

                'PropertyId' {
                    $dictionary = [ordered]@{}
                    $extendedProperties.Add($dictionary)
                }
            }
            $dictionary[$key] = $value
        }
        $emitSslCert.Invoke($sslcert, $extendedProperties)
    }
}