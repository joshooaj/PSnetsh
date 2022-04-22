#Requires -RunAsAdministrator
BeforeAll {
    $moduleManifest = "$PSScriptRoot\..\PSnetsh\PSnetsh.psd1"
    Write-Host "Importing $moduleManifest"
    Import-Module $moduleManifest -Force
}

Context "Get-NSHSslCert" {
    BeforeAll {
        # Get/create self-signed cert for testing
        $script:cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq 'CN=PSnetshTest' | Select-Object -First 1
        if ($null -eq $cert) {
            $script:cert = New-SelfSignedCertificate -Subject 'CN=PSnetshTest' -CertStoreLocation Cert:\LocalMachine\My -ErrorAction Stop
            Write-Host "Successfully added self-signed certificate Cert:\LocalMachine\My\$($cert.Thumbprint)" -ForegroundColor Green
        }

        # Ensure at least one specific sslcert binding is present
        $script:testEntry = '0.0.0.0:8443'
        $script:appId = [guid]'a2dd14ed-f800-473f-86d2-275e15a03156'
        $params = 'http', 'show', 'sslcert', "ipport=$testEntry"
        $null = & netsh $params
        if (!$?) {
            $params = 'http', 'add', 'sslcert', "ipport=$testEntry", "certhash=$($cert.Thumbprint)", "appid=$appId"
            $result = & netsh $params
            if ($?) {
                Write-Host "Successfully added sslcert binding for ipport=$testEntry" -ForegroundColor Green
            } else {
                throw [string]::Join([environment]::NewLine, $result)
            }
        }
    }

    It "Returns at least one SslCert binding" {
        (Get-NSHSslCert).Count | Should -BeGreaterThan 0
    }

    It "Returns a specific SslCert" {
        Get-NSHSslCert -IPPort $testEntry | Should -Not -BeNullOrEmpty
    }

    It "SslCert binding has the expected properties" {
        $sslcert = Get-NSHSslCert -IPPort $testEntry
        $sslcert.'Certificate Hash' | Should -Be $cert.Thumbprint
        $sslcert.'Application ID' | Should -Be "{$appId}"
    }
}
