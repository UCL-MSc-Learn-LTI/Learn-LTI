# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

[CmdletBinding()]
param (
    [string]$ResourceGroupName = "AdOnly4-MSLearnLti",
    [string]$AppName = "AdOnly4-MS-Learn-Lti-Tool-App",
    [switch]$UseActiveAzureAccount,
    [string]$SubscriptionNameOrId = "550c8aca-87a0-4da2-8e2e-10aca7b2e187",
    [string]$LocationName = "uksouth"
)

process {
    #region "Helper Functions"
    #function for making clear and distinct titles
    function Write-Title([string]$Title) {
        Write-Host "`n`n============================================================="
        Write-Host $Title
        Write-Host "=============================================================`n`n"
    }

    #function for making coloured outputs
    function Write-Color($Color, [string]$Text) {
        Write-Host $Text -ForegroundColor $Color
    }

    #function for writing errors
    function Write-Error([string]$Text) {
        Write-Host "`n`n=============================================================`n" -ForegroundColor "red" -BackgroundColor "black" -NoNewline
        Write-Host "Error!`n$Text" -ForegroundColor "red" -BackgroundColor "black" -NoNewline
        Write-Host "`n=============================================================" -ForegroundColor "red" -BackgroundColor "black"
    }
    #endregion

    #region "exception handling classes"
    class InvalidAzureSubscriptionException: System.Exception{
        $Emessage
        InvalidAzureSubscriptionException([string]$msg){
            $this.Emessage=$msg
        }
    }
    
    class InvalidAzureRegionException: System.Exception{
        $Emessage
        InvalidAzureRegionException([string]$msg){
            $this.Emessage=$msg
        }
    }
    #endregion
    
    try {

        #region Show Learn LTI Banner
        Write-Host ''
        Write-Host ' _      ______          _____  _   _            _   _______ _____ '
        Write-Host '| |    |  ____|   /\   |  __ \| \ | |          | | |__   __|_   _|'
        Write-Host '| |    | |__     /  \  | |__) |  \| |  ______  | |    | |    | |  '
        Write-Host '| |    |  __|   / /\ \ |  _  /| . ` | |______| | |    | |    | |  '
        Write-Host '| |____| |____ / ____ \| | \ \| |\  |          | |____| |   _| |_ '
        Write-Host '|______|______/_/    \_\_|  \_\_| \_|          |______|_|  |_____|'
        Write-Host ''
        Write-Host ''
        #endregion

        #region Setup Logging
        . .\Write-Log.ps1
        $ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
        $ExecutionStartTime = $(get-date -f dd-MM-yyyy-HH-mm-ss)
        $LogRoot = Join-Path $ScriptPath "Log"

        $LogFile = Join-Path $LogRoot "Log-$ExecutionStartTime.log"
        Set-LogFile -Path $LogFile
        
        $TranscriptFile = Join-Path $LogRoot "Transcript-$ExecutionStartTime.log"
        Start-Transcript -Path $TranscriptFile;
        #endregion
    
        $azureVersion = (az version 2>&1 | ConvertFrom-Json)."azure-cli"
        if ($azureVersion -lt 2.37){
            throw "Please upgrade to the minimum supported version of cli (2.37)"
        }
        
        #region "getting the setup mode for b2c vs ad"
        $b2cOrAD = "none"
        while($b2cOrAD -ne "b2c" -and $b2cOrAD -ne "ad") {
            $b2cOrAD = Read-Host "Would you like to set this up with Azure Business to Consumer or Azure Active Directory? B2C is reccomended as it can support multi-tenant authentication. (b2c/ad) "
        }
        #endregion

        #formatting a unique identifier to ensure we create a new keyvault for each run
        $uniqueIdentifier = [Int64]((Get-Date).ToString('yyyyMMddhhmmss')) #get the current second as being the unique identifier

        

        #region Login to Azure CLI        
        Write-Title 'STEP #1 - Logging into Azure'

        function Test-LtiActiveAzAccount {
            $account = az account show | ConvertFrom-Json
            if(!$account) {
                throw "Error while trying to get Active Account Info."
            }            
        }

        function Connect-LtiAzAccount {
            $loginOp = az login | ConvertFrom-Json
            if(!$loginOp) {
                throw "Encountered an Error while trying to Login."
            }
        }

        if ($UseActiveAzureAccount) { 
            Write-Log -Message "Using Active Azure Account"
            Test-LtiActiveAzAccount
        }
        else { 
            Write-Log -Message "Logging in to Azure"
            Connect-LtiAzAccount
        }

        Write-Log -Message "Successfully logged in to Azure."
        #endregion

        #region Choose Active Subcription 
        Write-Title 'STEP #2 - Choose Subscription'

        function Get-LtiSubscriptionList {
            $AzAccountList = ((az account list --all --output json) | ConvertFrom-Json)
            if(!$AzAccountList) {
                throw "Encountered an Error while trying to fetch Subscription List."
            }
            Write-Output $AzAccountList
        }

        function Set-LtiActiveSubscription {
            param (
                [string]$NameOrId,
                $List
            )
            
            $subscription = ($List | Where-Object { ($_.name -ieq $NameOrId) -or ($_.id -ieq $NameOrId) })
            if(!$subscription) {
                throw [InvalidAzureSubscriptionException] "Invalid Subscription Name/ID Entered."
            }
            az account set --subscription $NameOrId
            #Intentionally not catching an exception here since the set subscription commands behavior (output) is different from others
            
            Write-Output $subscription
        }

        Write-Log -Message "Fetching List of Subscriptions in Users Account"
        $SubscriptionList = Get-LtiSubscriptionList
        Write-Log -Message "List of Subscriptions:-`n$($SubscriptionList | ConvertTo-Json -Compress)"    

        $SubscriptionCount = ($SubscriptionList | Measure-Object).Count
        Write-Log -Message "Count of Subscriptions: $SubscriptionCount"
        if ($SubscriptionCount -eq 0) {
            throw "Please create at least ONE Subscription in your Azure Account"
        }
        elseif ($SubscriptionNameOrId) {
            Write-Log -Message "Using User provided Subscription Name/ID: $SubscriptionNameOrId"            
        }
        elseif ($SubscriptionCount -eq 1) {
            $SubscriptionNameOrId = $SubscriptionList[0].id;
            Write-Log -Message "Defaulting to Subscription ID: $SubscriptionNameOrId"
        }
        else {
            $SubscriptionListOutput = $SubscriptionList | Select-Object @{ l="Subscription Name"; e={ $_.name } }, "id", "isDefault"
            Write-Host ($SubscriptionListOutput | Out-String)
            $SubscriptionNameOrId = Read-Host 'Enter the Name or ID of the Subscription from Above List'
            #trimming the input for empty spaces, if any
            $SubscriptionNameOrId = $SubscriptionNameOrId.Trim()
            Write-Log -Message "User Entered Subscription Name/ID: $SubscriptionNameOrId"
        }

        $subscriptionId = ""
        #defensive programming so script doesn't halt and require a cleanup if subscription is mistyped
        while(1){
            try{
                $ActiveSubscription = Set-LtiActiveSubscription -NameOrId $SubscriptionNameOrId -List $SubscriptionList
                $subscriptionId = $ActiveSubscription.id
                break
            }
            catch [InvalidAzureSubscriptionException]{
                Write-Error $Error[0]
                $SubscriptionNameOrId = Read-Host 'Enter the Name or ID of the Subscription from Above List'
                #trimming the input for empty spaces, if any
                $SubscriptionNameOrId = $SubscriptionNameOrId.Trim()
                Write-Log -Message "User Entered Subscription Name/ID: $SubscriptionNameOrId"
            }
        }
        $UserEmailAddress = $ActiveSubscription.user.name
        Write-Host "Email that will be allowed to access platforms page:" $UserEmailAddress
        $choice = Read-Host "Want to add more users/email(y/n):"
        $choice = $choice.Trim()
        if($choice -eq "y"){
            $extramail = Read-Host "Enter user's email or 'n' to exit:"
            While($extramail -ne 'n'){
                $UserEmailAddress = $UserEmailAddress + ";" + $extramail
                $extramail = Read-Host "Enter user's email or 'n' to exit:"
            }
            Write-Host "Updated list of emails that will be allowed to access platforms page:" $UserEmailAddress
        }



        #endregion


        #region "B2C STEP 0: Calling B2CDeployment to set up the b2c script and retrieving the returned values to be used later on"
        $REACT_APP_EDNA_B2C_CLIENT_ID = 'NA'
        $REACT_APP_EDNA_AUTH_CLIENT_ID = 'Placeholder' # either replaced below by returned value of b2c script if b2cOrAD = "b2c", or at end of step 4 to AAD_Client_ID's ($appinfo.appId) value if b2cOrAD = "ad" so it is ready for its usage when updating .env.development and .env.deploy
        $b2c_secret = 'NA'
        $REACT_APP_EDNA_B2C_TENANT = 'NA'
        $B2C_ObjectID = 'NA'
        $b2c_tenant_name_full = 'NA'
        if($b2cOrAD -eq "b2c"){
            Write-Title "B2C Step #0: Running the B2C Setup Script"
            
            # passing in the ExecutionStartTime to continue the log file
            # passing in the tenantId of the AD tenant as the b2c setup must be linked with the AD tenant for the chosen subscription
            $results = (& ".\B2CDeployment.ps1" $ExecutionStartTime $ActiveSubscription.tenantId) 
            if($results[-1] -eq -1){
                throw "B2CDeployment.ps1 failed"
            }
            Write-Log -Message "Returned from the B2C setup script, continuing with LTI deployment"

            # TODO - indexing from -1 etc. because it seems to return meaningless values before the final 3 which we actually want; need to work out why and perhaps fix if it is deemed an issue
            $AD_Tenant_Name_full = $results[-6] # tenant name of the AD server
            $b2c_tenant_name_full = $results[-5] #b2c tenant name
            $REACT_APP_EDNA_B2C_CLIENT_ID = $results[-4] #webclient ID
            $REACT_APP_EDNA_AUTH_CLIENT_ID = $results[-4] #webclient ID
            $b2c_secret = $results[-3] #webclient secret
            $REACT_APP_EDNA_B2C_TENANT = $results[-2] #b2c tenant name
            $B2C_ObjectID = $results[-1] # b2c webapp id that needs the SPA uri

            Write-Log -Message "Returned the follow values from the b2c setup script-
            `nAD_Tenant_Name_full: $AD_Tenant_Name_full
            `nb2c_tenant_name_full: $b2c_tenant_name_full
            `nREACT_APP_EDNA_B2C_CLIENT_ID: $REACT_APP_EDNA_B2C_CLIENT_ID
            `nREACT_APP_EDNA_AUTH_CLIENT_ID: $REACT_APP_EDNA_AUTH_CLIENT_ID
            `nb2c_secret: $b2c_secret
            `nREACT_APP_EDNA_B2C_TENANT: $REACT_APP_EDNA_B2C_TENANT
            `nB2C_ObjectID: $B2C_ObjectID"


            #update b2c deploy template 
            $policy_name = "b2c_1a_signin" 
            
            #Updating function apps's settings
           
            #$B2C_APP_CLIENT_ID_IDENTIFIER = "0cd1d1d6-a7aa-41e2-b569-1ca211147973" # TODO remove hardcode 
            #$AD_APP_CLIENT_ID_IDENTIFIER = "cb508fc8-6a5f-49b1-b688-dac065ba59e4" # TODO remove hardcode
            $OPENID_B2C_CONFIG_URL_IDENTIFIER = "https://${REACT_APP_EDNA_B2C_TENANT}.b2clogin.com/${b2c_tenant_name_full}/${policy_name}/v2.0/.well-known/openid-configuration"
            $OPENID_AD_CONFIG_URL_IDENTIFIER = "https://login.microsoft.com/${AD_Tenant_Name_full}/v2.0/.well-known/openid-configuration"

            ((Get-Content -path ".\azuredeploy.json" -Raw) -replace '"<AZURE_B2C_SECRET_STRING>"', $b2c_secret) |  Set-Content -path (".\azuredeploy.json")
            

            (Get-Content -path ".\azuredeployB2CTemplate.json" -Raw) `
            -replace '<B2C_APP_CLIENT_ID_IDENTIFIER>', ($REACT_APP_EDNA_B2C_CLIENT_ID) `
            -replace '<IDENTIFIER_DATETIME>', ("'"+$uniqueIdentifier+"'") `
            -replace '<OPENID_B2C_CONFIG_URL_IDENTIFIER>', ($OPENID_B2C_CONFIG_URL_IDENTIFIER) `
            -replace '<AZURE_B2C_SECRET_STRING>', ($b2c_secret) `
            -replace '<OPENID_AD_CONFIG_URL_IDENTIFIER>', ($OPENID_AD_CONFIG_URL_IDENTIFIER) | Set-Content -path (".\azuredeploy.json")
        
        
            # log back in to the azure account now we've returned from B2C Script
            Write-Log -Message "Logging back in to Azure Account for tenant $AD_Tenant_Name_full and subscription $SubscriptionNameOrId after returning frmo B2C Script"
            az login --tenant $AD_Tenant_Name_full #logging back into the azure account for the AD tenant
            az account set --subscription $SubscriptionNameOrId #setting the active subscription back to the stored value
        }
        #else its AD load the AD azuredeploy template
        else{
            $AD_Tenant_Name_full = az rest --method get --url https://graph.microsoft.com/v1.0/domains --query 'value[?isDefault].id' -o tsv
            $OPENID_AD_CONFIG_URL_IDENTIFIER = "https://login.microsoft.com/${AD_Tenant_Name_full}/v2.0/.well-known/openid-configuration"
            ((Get-Content -path ".\azuredeployADTemplate.json" -Raw) -replace '<IDENTIFIER_DATETIME>', ("'"+$uniqueIdentifier+"'")) `
            -replace '<OPENID_AD_CONFIG_URL_IDENTIFIER>', ($OPENID_AD_CONFIG_URL_IDENTIFIER) |  Set-Content -path (".\azuredeploy.json")
        }

        

        #endregion


        #region Choose Region for Deployment
        Write-Title "STEP #3 - Choose Location`n(Please refer to the Documentation / ReadMe on Github for the List of Supported Locations)"

        Write-Log -Message "Fetching List of Locations"
        $LocationList = ((az account list-locations) | ConvertFrom-Json)
        Write-Log -Message "List of Locations:-`n$($locationList | ConvertTo-Json -Compress)"

        #defensive programming so script doesn't halt and require a cleanup if region is mistyped
        while(1){
            try{
                if(!$LocationName) {
                    $LocationNames = az account list-locations --output table --query "[].{Name:name}"
                    Write-Host "$($LocationNames[2..$LocationNames.Length] | Sort-Object | Out-String)`n"
                    $LocationName = Read-Host 'Enter Location From Above List for Resource Provisioning'
                    #trimming the input for empty spaces, if any
                    $LocationName = $LocationName.Trim()
                }
                Write-Log -Message "User Provided Location Name: $LocationName"
        
                $ValidLocation = $LocationList | Where-Object { $_.name -ieq $LocationName }
                if(!$ValidLocation) {
                    throw [InvalidAzureRegionException] "Invalid Location Name Entered."
                }
                break
            }
            catch [InvalidAzureRegionException]{
                Write-Error $Error[0]

                $LocationName = Read-Host 'Enter Location From Above List for Resource Provisioning'
                #trimming the input for empty spaces, if any
                $LocationName = $LocationName.Trim()
            }
        }
        #endregion
        

        #region Create New App Registration in AzureAD
        Write-Title 'STEP #4 - Registering Azure Active Directory App'
    
        Write-Log -Message "Creating AAD App with Name: $AppName"
        $appinfo=$(az ad app create --display-name $AppName) | ConvertFrom-Json;
        if(!$appinfo) {
            throw "Encountered an Error while creating AAD App"
        }
        $identifierURI = "api://$($appinfo.appId)";
        Write-Log -Message "Updating Identifier URI's in AAD App to: [ api://$($appinfo.appId) ]"
        $appUpdateOp = az ad app update --id $appinfo.appId --identifier-uris $identifierURI;
        #Intentionally not catching an exception here since the app update commands behavior (output) is different from others
    
        Write-Log -Message "Updating App so as to add MS Graph -> User Profile -> Read Permissions to the AAD App"
        $GraphAPIId = '00000003-0000-0000-c000-000000000000'
        $GraphAPIPermissionId = 'e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope'
        $appPermissionAddOp = az ad app permission add --id $appinfo.appId --api $GraphAPIId --api-permissions $GraphAPIPermissionId
        #Intentionally not catching an exception here
    
        Write-Host 'App Created Successfully'
        #endregion
        #region Create New Resource Group in above Region
        Write-Title 'STEP #5 - Creating Resource Group'
    
        Write-Log -Message "Creating Resource Group with Name: $ResourceGroupName at Location: $LocationName"
        $resourceGroupCreationOp = az group create -l $LocationName -n $ResourceGroupName
        if(!$resourceGroupCreationOp) {
            $ex = @(
                "Error while creating Resource Group with Name : [ $ResourceGroupName ] at Location: [ $LocationName ]."
                "One Reason could be that a Resource Group with same name but different location already exists in your Subscription."
                "Delete the other Resource Group and run this script again."
            ) -join ' '
            throw $ex
        }
    
        Write-Host 'Resource Group Created Successfully'


        # if this is being run in AD mode then update the placeholder for REACT_APP_EDNA_AUTH_CLIENT_ID to the ADD_CLIENT_ID
        if($b2cOrAD -eq "ad"){
            $REACT_APP_EDNA_AUTH_CLIENT_ID = $appinfo.appId # if 'ad' then set to AAD_CLIENT_ID's vaue
        }
        #endregion

        #region Provision Resources inside Resource Group on Azure using ARM template
        Write-Title 'STEP #6 - Creating Resources in Azure'
    
        $userObjectId = az ad signed-in-user show --query id # requires 2.37 or higher
        $templateFileName = "azuredeploy.json"
        $deploymentName = "Deployment-$ExecutionStartTime"
        Write-Log -Message "Deploying ARM Template to Azure inside ResourceGroup: $ResourceGroupName with DeploymentName: $deploymentName, TemplateFile: $templateFileName, AppClientId: $($appinfo.appId), IdentifiedURI: $($appinfo.identifierUris)"
        $deploymentOutput = (az deployment group create --resource-group $ResourceGroupName --name $deploymentName --template-file $templateFileName --parameters appRegistrationClientId=$($appinfo.appId) appRegistrationApiURI=$($identifierURI) userEmailAddress=$($UserEmailAddress) userObjectId=$($userObjectId)) | ConvertFrom-Json;
        if(!$deploymentOutput) {
            throw "Encountered an Error while deploying to Azure"
        }
        Write-Host 'Resource Creation in Azure Completed Successfully'
        
        Write-Title 'Step #7 - Updating KeyVault with LTI 1.3 Key'

        function Update-LtiFunctionAppSettings([string]$ResourceGroupName, [string]$FunctionAppName, [hashtable]$AppSettings) {
            Write-Log -Message "Updating App Settings for Function App [ $FunctionAppName ]: -"
            foreach ($it in $AppSettings.GetEnumerator()) {
                Write-Log -Message "`t[ $($it.Name) ] = [ $($it.Value) ]"
                az functionapp config appsettings set --resource-group $ResourceGroupName --name $FunctionAppName --settings "$($it.Name)=$($it.Value)"
            }
        }
    
        #Creating EdnaLiteDevKey in keyVault and Updating the Config Entry EdnaLiteDevKey in the Function Config
        $keyCreationOp = (az keyvault key create --vault-name $deploymentOutput.properties.outputs.KeyVaultName.value --name EdnaLiteDevKey --protection software) | ConvertFrom-Json;
        if(!$keyCreationOp) {
            throw "Encountered an Error while creating Key in keyVault"
        }
        $KeyVaultLink = $keyCreationOp.key.kid
        $EdnaKeyString = @{ "EdnaKeyString"="$KeyVaultLink" }
        $ConnectUpdateOp = Update-LtiFunctionAppSettings $ResourceGroupName $deploymentOutput.properties.outputs.ConnectFunctionName.value $EdnaKeyString
        $PlatformsUpdateOp = Update-LtiFunctionAppSettings $ResourceGroupName $deploymentOutput.properties.outputs.PlatformsFunctionName.value $EdnaKeyString
        $UsersUpdateOp = Update-LtiFunctionAppSettings $ResourceGroupName $deploymentOutput.properties.outputs.UsersFunctionName.value $EdnaKeyString

        Write-Host 'Key Creation in KeyVault Completed Successfully'

        Write-Title 'Step #8 - Enabling Static Website Container'

        #Creating a Container in Static Website
        $containerEnableOp = az storage blob service-properties update --account-name $deploymentOutput.properties.outputs.StaticWebSiteName.value --static-website --404-document index.html --index-document index.html --only-show-errors
        if(!$containerEnableOp) {
            throw "Encountered an Error while creating Container to host Static Website"
        }
        Write-Host 'Static Website Container Enabled Successfully'

        Write-Title 'STEP #9 - Updating AAD App'
    
        $AppRedirectUrl = $deploymentOutput.properties.outputs.webClientURL.value
        Write-Log -Message "Updating App with ID: $($appinfo.appId) to Redirect URL: $AppRedirectUrl and also enabling Implicit Flow"
        #$appUpdateRedirectUrlOp = az ad app update --id $appinfo.appId --reply-urls $AppRedirectUrl --oauth2-allow-implicit-flow true

        #Azure CLI doesn't offer the ability to create SPA redirect uris, must use patch instead 
        $graphUrl = "https://graph.microsoft.com/v1.0/applications/$($appinfo.id)"
        $body = '{\"spa\":{\"redirectUris\":[\"' + $AppRedirectUrl + '\"]}}'
        Write-Log -Message "Pointing to  $graphUrl and using body $body"
        az rest --method PATCH --uri $graphUrl --headers 'Content-Type=application/json' --body $body
        #Intentionally not catching an exception here since the app update commands behavior (output) is different from others


        # adding the user_impersonation scope to the app, required for client side auth
        $appApiInfo = $appinfo.api
        $appScopeGUID = [guid]::NewGuid()
        $UserImpersonationScope = "{
                `"adminConsentDescription`": `"Allow the application to access $AppName on behalf of the signed-in user.`",
                `"adminConsentDisplayName`": `"Access $AppName`",
                `"id`": `"$appScopeGUID`",
                `"isEnabled`": true,
                `"type`": `"User`",
                `"userConsentDescription`": null,
                `"userConsentDisplayName`": null,
                `"value`": `"user_impersonation`"
        }" | ConvertFrom-Json
        $appApiInfo.oauth2PermissionScopes += $UserImpersonationScope
        ConvertTo-Json -InputObject $appApiInfo | Out-File -FilePath "userImpersonationScope.json"
        az ad app update --id $appinfo.appId --set api=@userImpersonationScope.json --only-show-errors

        # granting user_impersonation to the web app
        # az ad app permission grant --id $WebClientID --api $appinfo.appId --scope "user_impersonation" --only-show-errors > $null
        # az ad app permission add --id $WebClientID --api $appinfo.appId --api-permissions "$appScopeGUID=Scope" --only-show-errors

        Remove-Item userImpersonationScope.json
        


        #endregion



    
        Write-Host 'App Update Completed Successfully'
        #endregion

        #region Build and Publish Function Apps
        . .\Install-Backend.ps1
        Write-Title "STEP #10 - Installing the backend"
    
        $BackendParams = @{
            SourceRoot="../backend";
            ResourceGroupName=$ResourceGroupName;
            LearnContentFunctionAppName=$deploymentOutput.properties.outputs.LearnContentFunctionName.value;
            LinksFunctionAppName=$deploymentOutput.properties.outputs.LinksFunctionName.value;
            AssignmentsFunctionAppName=$deploymentOutput.properties.outputs.AssignmentsFunctionName.value;
            ConnectFunctionAppName=$deploymentOutput.properties.outputs.ConnectFunctionName.value;
            PlatformsFunctionAppName=$deploymentOutput.properties.outputs.PlatformsFunctionName.value;
            UsersFunctionAppName=$deploymentOutput.properties.outputs.UsersFunctionName.value;
        }
        Install-Backend @BackendParams
        #endregion

        #region Build and Publish Client Artifacts

        . .\Install-Client.ps1
        Write-Title "STEP #11.A - Updating client's .env.production file"

        $ClientUpdateConfigParams = @{
            ConfigPath="../client/.env.production";
            AppId=$appinfo.appId;
            LearnContentFunctionAppName=$deploymentOutput.properties.outputs.LearnContentFunctionName.value;
            LinksFunctionAppName=$deploymentOutput.properties.outputs.LinksFunctionName.value;
            AssignmentsFunctionAppName=$deploymentOutput.properties.outputs.AssignmentsFunctionName.value;
            PlatformsFunctionAppName=$deploymentOutput.properties.outputs.PlatformsFunctionName.value;
            UsersFunctionAppName=$deploymentOutput.properties.outputs.UsersFunctionName.value;
            StaticWebsiteUrl=$deploymentOutput.properties.outputs.webClientURL.value;
            b2cClientID=$REACT_APP_EDNA_B2C_CLIENT_ID; #defaulted to 'NA' if AD
            b2cTenantName=$REACT_APP_EDNA_B2C_TENANT; #defaulted to 'NA' if AD
            authClientID=$REACT_APP_EDNA_AUTH_CLIENT_ID #defaulted to $appinfo.appId if AD
        }
        Update-ClientConfig @ClientUpdateConfigParams

        Write-Title "STEP #11.B - Updating .env.development file"

        $DevelopmentUpdateConfigParams = @{
            ConfigPath="../client/.env.development";
            b2cClientID=$REACT_APP_EDNA_B2C_CLIENT_ID; #defaulted to 'NA' if AD
            b2cTenantName=$REACT_APP_EDNA_B2C_TENANT; #defaulted to 'NA' if AD
            authClientID=$REACT_APP_EDNA_AUTH_CLIENT_ID #defaulted to $appinfo.appId if AD
        }
        Update-DevelopmentConfig @DevelopmentUpdateConfigParams

        Write-Title 'STEP #12 - Installing the client'  
        $ClientInstallParams = @{
            SourceRoot="../client";
            StaticWebsiteStorageAccount=$deploymentOutput.properties.outputs.StaticWebSiteName.value
        }
        Install-Client @ClientInstallParams
        #endregion

        if ($b2cOrAD -eq "b2c"){ #Set the SPA uri link on the B2C as well
            Write-Title 'STEP #13 (B2C Only) - Updating the B2C WebApp redirect URI'
            az login --tenant "$REACT_APP_EDNA_B2C_TENANT.onmicrosoft.com" --allow-no-subscriptions --only-show-errors > $null
            $graphUrl = "https://graph.microsoft.com/v1.0/applications/$B2C_ObjectID"
            az rest --method PATCH --uri $graphUrl --headers 'Content-Type=application/json' --body $body
        }


        Write-Title "TOOL REGISTRATION URL (Please Copy, Required for Next Steps) -> $($deploymentOutput.properties.outputs.webClientURL.value)platform"

        #region "Creating URL so users can more easily investigate their logs for the platform page if issues arise"
        $ConfigPath = "../client/.env.production"
        $text = Get-Content $ConfigPath
        $configValues = $text | ConvertFrom-StringData

        $platformUniqueValue = $configValues.REACT_APP_EDNA_PLATFORM_SERVICE_URL #getting the platform service url
        $platformUniqueValue = $platformUniqueValue.Substring(($platformUniqueValue.IndexOf("platforms-")),$platformUniqueValue.Length-$platformUniqueValue.IndexOf("platforms-")) # trimming to the start of the uniqueIdentifier for the platform page
        $platformUniqueValue = $platformUniqueValue.Substring(0,$platformUniqueValue.IndexOf(".")) # trimming to the end of the uniqueIdentifier for the platform page

        # make sure we have the id of the subscription

        Write-Title "PLATFORM PAGE AZURE URL (Please Copy, useful for debugging logs if something goes wrong)" = "https://portal.azure.com/#@$AD_Tenant_Name_full/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Insights/components/$platformUniqueValue/overview"

        #endregion


        Write-Title '======== Successfully Deployed Resources to Azure ==========='

        Write-Log -Message "Deployment Complete"
    }
    catch {
        $Message = 'Error occurred while executing the Script. Please report the bug on Github (along with Error Message & Logs)'
        Write-Log -Message $Message -ErrorRecord $_
        throw $_
    }
    finally {
        Stop-Transcript
        $exit = Read-Host 'Press any Key to Exit'
    }
}
