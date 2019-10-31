# Script to provision a RancherOS machine

# function to base64 the credentials
function get-base64auth() {
    # This $cred variable should be defined in Azure Devops
    $Cred = '<credentials>'
    $Base64 = [System.Text.Encoding]::UTF8.GetBytes($Cred)
    $Base64Credentials = [Convert]::ToBase64String($Base64)
    $ApiCredentials = "Basic $Base64Credentials" 
    return $ApiCredentials
}

# Getting authentication from the API
function get-apiauthentication {
    param(
        [Parameter(Mandatory = $true)] [string] $AuthHeader
    )

    $Endpoint = '<URL>'    
    $Header = @{
        'Authorization' = $AuthHeader
    }

    $Token = Invoke-RestMethod -Method Get -Uri $Endpoint -Headers $Header
    $Token = $Token.auth_token 
    $AuthHeaderToken = @{
        'X-Auth-Token' = $Token
    }

    return $AuthHeaderToken
}

# Check the standard API call to verify if the API works
function get-apicheck {
    param(
        [Parameter(Mandatory = $true)] $AuthHeader
    )

    $Endpoint = '<URL>'  

    Invoke-RestMethod -Method Get -Uri $Endpoint -Headers $AuthHeader
}

# Open the YAML cloud-config file and make this a string
function open-cloudconfigyaml {
    $YamlLocation = '<Location>'
    $Document = Get-Content $YamlLocation | Out-String
    return $Document
}

function request-rancheros_vm {
    param(
        [Parameter(Mandatory = $true)] $AuthHeader,
        [Parameter(Mandatory = $true)] [string] $CloudConfig
    )
    # Variables that should be gained from AzureDevops
    # So these are placeholders to test the script
    $VmName = '<NAME>'
    $DatacenterLocation = '<NAME>'
    $VLAN = '<VLAN>'
    $VmEnvironment = '<ENVIRONMENT>'
    $BusinessCrit = '<BUSINESS>'

    #define the Endpoint
    $Endpoint = '<URL>'

    # Find and modify the JSON for the api call, convert this to string
    $JSONLocation = '<LOCATION>'
    $Payload = Get-Content $JSONLocation | ConvertFrom-Json

    # Change the JSON variables. This could be improved
    $Payload.vm_name = $VmName
    $Payload.location = $DatacenterLocation
    $Payload.vlan = $VLAN
    $Payload.cloud_config = $CloudConfig

    #change the value in the "tags" JSON object
    $Payload.tags.environment = $VmEnvironment
    $Payload.tags.business_critical = $BusinessCrit

    $Payload = $Payload | ConvertTo-Json
    
    # Send the provisioning request to the API
    $RequestNo = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $AuthHeader -Body $Payload -ContentType 'application/json'
    $RequestNo = $RequestNo.id
    
    # the RequestNo can be used to track the VM provisioning, for some reason this is not returned every time a call is made(TBD what to do)
    return $RequestNo
}

# the main sequence to enact
function main { 
    Write-host 'Creating the base64 authentication'
    $ApiCredentials = get-base64auth

    Write-host 'Getting authorisation'
    $Token = get-apiauthentication -AuthHeader $ApiCredentials
    Write-Host 'Authorisation gained'

    Write-Host 'Check if the API is available'
    get-apicheck -AuthHeader $Token

    Write-Host 'Finding and converting the cloud-config'
    $CloudConfig = open-cloudconfigyaml

    # to provision the RancherOS VM based on the variables from Azure Devops
    # Also gain a requestnumber which can be used to track the provisioning status against the API
    Write-Host 'Provision the RancherOS VM via the API'
    $RequestNo = request-rancheros_vm -AuthHeader $Token -CloudConfig $CloudConfig
    Write-Host $RequestNo
    #Add a function here to check the request and respond with the result.
}


main
