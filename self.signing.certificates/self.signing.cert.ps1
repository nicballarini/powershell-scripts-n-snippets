function checkCert {
    param
    (
        [String] $certLocation,
        [String] $certFriendlyName,
        [String] $certType
    )
    Write-host "Checking for Cert" -ForegroundColor Yellow
    $theCert = (Get-ChildItem -path $certLocation | where-object {$_.Subject -eq "CN=$env:computername.$env:userdnsdomain" -and $_.FriendlyName -eq $certFriendlyName})
    return $theCert.Thumbprint
}

function makeCert {
    param
    (
        [String] $pass,
        [String] $certLocation,
        [String] $certType,
        [String] $certFriendlyName
    )
    write-host "Creating cert" -ForegroundColor Yellow
    #generate a new cert, dnsname should be your FQDN
    $cert = New-SelfSignedCertificate -CertStoreLocation $certLocation -dnsname "$env:computername.$env:userdnsdomain" -Type CodeSigningCert -FriendlyName $certFriendlyName
    write-host $cert.Thumbprint -ForegroundColor Red
    $password = ConvertTo-SecureString -String $pass -Force -AsPlainText

    #define the certpath and export the pfx file, if it needs to be shared.
    $certPath = "$certLocation$($cert.Thumbprint)"
    $certExport = Export-PfxCertificate -Cert $certPath -FilePath C:\selfcert.pfx -Password $password -Force
    write-host "Cert created" -ForegroundColor Green
    return $cert.Thumbprint
    
}

function importCert {
    param
    (
        [String] $pass,
        [String] $certLocation
    )
    ## import the pfx cert with password
    write-host "Importing cert" -ForegroundColor Yellow
    $password = ConvertTo-SecureString -String $pass -Force -AsPlainText

    $certImport = Import-PfxCertificate -Password $password -FilePath C:\selfcert.pfx -CertStoreLocation $certRestoreLocation
    write-host "Cert imported" -ForegroundColor Green
}

function certSigning {
    param
    (
        [String] $cert
    )
    $myCert = Get-ChildItem -Path:$cert

    $scriptWorkingDir = set-location -path $Env:USERPROFILE\Documents\ps.files\
    $scriptPath = (get-childitem -path . -recurse -filter "*.ps1" | Resolve-Path -Relative)
    $scriptPath | foreach {Set-AuthenticodeSignature -Certificate:$myCert -FilePath $_ }

    #used to check signed status of a script
    #Get-AuthenticodeSignature -FilePath $scriptPath
}

function main {
    param
    (
        [int] $i
    )
    $certLocation = "Cert:\\LocalMachine\My\"
    $certRestoreLocation = "Cert:\\LocalMachine\Root\"
    $certFriendlyName = "MyCodeSigningCert"
    $certType = "CodeSigningCert"
    $password = "passw0rd!"
    $certTP = checkCert -certLocation $certLocation -certType $certType -certFriendlyName $certFriendlyName
    if ($certTP)
    {
        write-host "Cert found"  -ForegroundColor Green
    }
    else
    {
        write-host "No matching code signing cert. Creating new cert" -ForegroundColor Yellow
        $certTP = makeCert -pass $password -certLocation $certLocation -certType $certType -certFriendlyName $certFriendlyName
        importCert -pass $password -certLocation $certRestoreLocation -certType $certType -certFriendlyName $certFriendlyName
    }
    if ($i = 1) {
        write-host "Signing files"
        certSigning -cert "$certLocation$certTP"
    }
}


main -i 1

