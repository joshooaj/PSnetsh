function GetNSHUrlAcl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $cmdResults
    )
    
    process {
        $emitUrlAcl = {
            param($urlacl)
            if ($null -ne $urlacl) {
                $users = $urlacl.Users.Keys | Select-Object
                foreach ($user in $users) {
                    $urlacl.Users.$user = [pscustomobject]$urlacl.Users.$user
                }
                if ($null -ne $urlacl.Users) {
                    $urlacl.Users = [pscustomobject]$urlacl.Users
                }
                $urlacl
            }
        }
        $pattern = '^\s*(?<key>\w+(\s\w+)?)\s*:\s(?<value>[^\s]+(\s[^\s]+)*)\s*$'
        foreach ($row in $cmdResults) {
            if ($row -like '*Error:*') {
                Write-Error $row
                continue
            } elseif ($row -notmatch $pattern) {
                continue
            }
            
            $key, $value = $Matches.key, $Matches.value
            switch ($key) {
                'Reserved URL' {
                    $emitUrlAcl.Invoke($urlacl)
                    Write-Verbose "Processing urlacl reservation for $value"                
                    $urlacl = [pscustomobject]@{
                        Url   = $value
                        Users = @{}
                    }
                }

                'User' {
                    $currentUser = $value
                    $urlacl.Users.$currentUser = [ordered]@{}
                }

                Default {
                    $urlacl.Users.$currentUser.$key = $value
                }
            }
        }
        $emitUrlAcl.Invoke($urlacl)
    }
}