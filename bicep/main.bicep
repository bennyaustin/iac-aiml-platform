// Scope
targetScope = 'subscription'

// Parameters
@description('Resource group where AI/ML platform will be deployed. Resource group will be created if it doesnt exist')
param aimlrg string= 'rg-aiml'

@description('Resource group location')
param rglocation string = 'australiaeast'

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string = 'Mars'

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string = 'mars@contoso.com'

@description('Subject Matter EXpert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string ='venus@contoso.com'

@description('Timestamp that will be appendedto the deployment name')
param deployment_suffix string = utcNow()


// Variables
var keyvault_deployment_name = 'keyvault_deployment_${deployment_suffix}'
var cogsvc_deployment_name = 'cogsvc_deployment_${deployment_suffix}'


// Create data platform resource group
resource aiml_rg  'Microsoft.Resources/resourceGroups@2022-09-01' = {
 name: aimlrg 
 location: rglocation
 tags: {
        CostCentre: cost_centre_tag
        Owner: owner_tag
        SME: sme_tag
  }
}


// Deploy Key Vault with default access policies using module
module kv './modules/keyvault.bicep' = {
  name: keyvault_deployment_name
  scope: aiml_rg
  params:{
     location: aiml_rg.location
     keyvault_name: 'ba-kv02'
     cost_centre_tag: cost_centre_tag
     owner_tag: owner_tag
     sme_tag: sme_tag
  }
}

resource kv_ref 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kv.outputs.keyvault_name
  scope: aiml_rg
}

// Deploy Cognitive Services
module cogsvc './modules/cognitive.bicep' = {
 name: cogsvc_deployment_name
 scope: aiml_rg
 params:{
   cogsvc_name: 'ba-cogsvc01'
   formrecognizer_name: 'ba-formrecognizer01'
   location: rglocation
   cost_centre_tag: cost_centre_tag
   owner_tag: owner_tag
   sme_tag: sme_tag
   sku: 'S0'
 }
}
