[CmdletBinding()] 
param(
    [Parameter(Mandatory=$true)]
    [string]$CertData,
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$certPath = "Cert:\CurrentUser\My";
$CertData > C:\certs\rootCert.cer;
$file = ( Get-ChildItem -Path C:\certs\rootCert.cer );
$file | Import-Certificate -CertStoreLocation $certPath;
if($null -eq $clientCert) {
    New-SelfSignedCertificate -Type Custom -DnsName ContosoClient -KeySpec Signature `
        -Subject "CN=VPN Client" -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 -KeyLength 2048 `
        -CertStoreLocation $certPath `
        -Signer $rootCert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2");
}
$rootCert = (Get-ChildItem -Path $certPath) | Where-Object { $_.Subject -eq "CN=VPN CA" };
$clientCert = (Get-ChildItem -Path $certPath) | Where-Object { $_.Subject -eq "CN=VPN Client" };
$mypwd = ConvertTo-SecureString -String $Password -Force -AsPlainText;
Export-PfxCertificate -Cert $clientCert -FilePath c:\certs\clientCert.pfx -Password $mypwd;