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

@description('Flag to indicate whether to enable integration of data platform resources with either an existing Purview resource')
param enable_purview bool =true

@description('Resource Group Name of an existing Purview Account. Required if create_purview=true')
param purview_rg_name string = 'rg-datagovernance'

@description('Resource Name of an existing Purview Account. Required if create_purview=true')
param purview_resource_name string = 'ba-purview01-6spfx5oytiivq'

@description('Resource Name of an existing Storage Account for Azure Machine Learning')
param aiml_storage_name string = 'bacustmodelstorage01q575'

@description('Timestamp that will be appendedto the deployment name')
param deployment_suffix string = utcNow()


// Variables
var keyvault_deployment_name = 'keyvault_deployment_${deployment_suffix}'
var cogsvc_deployment_name = 'cogsvc_deployment_${deployment_suffix}'
var aml_deployment_name = 'aml_deployment_${deployment_suffix}'

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

//Get Storage reference
resource aiml_storage_ref 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: aiml_storage_name
  scope: aiml_rg
}


//Get existing Purview reference
resource purview_rg_ref 'Microsoft.Resources/resourceGroups@2022-09-01' existing = if (enable_purview) {
  name: purview_rg_name
  scope: subscription()
}

resource purview_ref 'Microsoft.Purview/accounts@2021-07-01' existing = if (enable_purview) {
  name: purview_resource_name
  scope: purview_rg_ref
}

// Deploy Cognitive Services
module cogsvc './modules/cognitive.bicep' = {
 name: cogsvc_deployment_name
 scope: aiml_rg
 params:{
   formrecognizer_name: 'ba-formrecognizer01'
   custom_model_storage_name: 'bacustmodelstorage01'
   custom_model_storage_sku: 'Standard_LRS'
   location: rglocation
   cost_centre_tag: cost_centre_tag
   owner_tag: owner_tag
   sme_tag: sme_tag
   formrecognizer_sku: 'S0'
   enable_purview: enable_purview
   purview_resource: purview_ref
   cogsearch_name: 'ba-cogsearch01'
   cogsearch_hostingMode: 'default'
   cogsearch_partitionCount: 1
   cogsearch_replicaCount: 1
   cogsearch_sku: 'standard'
   azureopenai_name: 'ba-aoai02'
   azureopenai_sku: 'S0'
 }
}

//Deploy Azure Machine Learning Workspace
module aml './modules/machinelearning.bicep' ={
  name: aml_deployment_name
  scope: aiml_rg
  params:{
    location: rglocation
    cost_centre_tag: cost_centre_tag
    owner_tag: owner_tag
    sme_tag: sme_tag
    aml_name: 'ba-aml01'
    amlkeyvault_ref: kv_ref
    amlstorage_ref: aiml_storage_ref
}
}
