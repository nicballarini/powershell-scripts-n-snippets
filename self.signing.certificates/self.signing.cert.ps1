#generate a new cert, dnsname should be your FQDN
$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -dnsname "$env:computername.$env:userdnsdomain" -Type CodeSigningCert
$cert

#set a secure password to be applied to the cert
$secPassword = ConvertTo-SecureString -String 'passw0rd!' -Force -AsPlainText

#define the certpath and export the pfx file, if it needs to be shared.
$certPath = "Cert:\LocalMachine\My\$($cert.Thumbprint)"
Export-PfxCertificate -Cert $certPath -FilePath C:\selfcert.pfx -Password $secPassword -Force

pause

## import the pfx cert with password
Import-PfxCertificate -Password $secPassword -FilePath C:\selfcert.pfx -CertStoreLocation 'Cert:\LocalMachine\Root'

pause

# run the next 4 lines to resign the script(s) you define.

$certArray = Get-ChildItem -path:"Cert:\LocalMachine\My" 
$certPath = "Cert:\LocalMachine\My\$($certArray[-1].Thumbprint)"

$myCert = Get-ChildItem -Path:$certPath
$myCert.EnhancedKeyUsageList

pause
# have to run separately from above section

set-location -path $Env:USERPROFILE\Documents
get-location
$scriptPath = @('.\automate_ze_robots.ps1')
$scriptPath | foreach {Set-AuthenticodeSignature -Certificate:$myCert -FilePath $_ }

#optional, you'll see from the line above that the signing is valid, 
# but it's nice to be able to check a given file
Get-AuthenticodeSignature -FilePath $scriptPath