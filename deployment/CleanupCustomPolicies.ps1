#region "Helper Functions"

#function for making clear and distinct titles
function Write-Title([string]$Title) {
    Write-Host "`n`n============================================================="
    Write-Host $Title
    Write-Host "=============================================================`n`n"
}
#endregion


# Connecting to the b2c tenant and removing the custom policies already uploaded to the b2c tenant
Write-Title "Cleaning up the custom policies from the b2c tenant"

$B2cTenantDomain = Read-Host "What is your B2C tenants domain (e.g. mytenant.onmicrosoft.com)?"
Import-Module AzureADPreview
Connect-AzureAD -Tenant $B2cTenantDomain

Remove-AzureADMSTrustFrameworkPolicy -Id B2C_1A_PasswordReset
Remove-AzureADMSTrustFrameworkPolicy -Id B2C_1A_ProfileEdit
Remove-AzureADMSTrustFrameworkPolicy -Id B2C_1A_signup_signin
Remove-AzureADMSTrustFrameworkPolicy -Id B2C_1A_TrustFrameworkBase
Remove-AzureADMSTrustFrameworkPolicy -Id B2C_1A_TrustFrameworkExtensions
Remove-AzureADMSTrustFrameworkPolicy -Id B2C_1A_TrustFrameworkLocalization


# Cleaning up the keysets from the b2c tenant
Write-Title "Cleaning up the keysets from the b2c tenant"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $access_token)

$response = Invoke-RestMethod 'https://graph.microsoft.com/beta/trustFramework/keySets/B2C_1A_TokenSigningKeyContainer' -Method 'DELETE' -Headers $headers
$response | ConvertTo-Json

$response = Invoke-RestMethod 'https://graph.microsoft.com/beta/trustFramework/keySets/B2C_1A_TokenEncryptionKeyContainer' -Method 'DELETE' -Headers $headers
$response | ConvertTo-Json