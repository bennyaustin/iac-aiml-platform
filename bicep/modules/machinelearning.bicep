// Parameters
@description('Location where resources will be deployed. Defaults to resource group location')
param location string = resourceGroup().location

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string

@description('Azure Machine Learning resource name')
param aml_name string

@description('AML Key Vault resource reference')
param amlkeyvault_ref object

@description('AML Storage resource reference')
param amlstorage_ref object

// Variables
var suffix = uniqueString(resourceGroup().id)
var aml_uniquename = '${aml_name}-${suffix}'

resource aml 'Microsoft.MachineLearningServices/workspaces@2023-10-01' = {
  name: aml_uniquename
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  identity: {type: 'SystemAssigned'}

  properties: {
    description: aml_uniquename
    friendlyName: aml_name
    keyVault: amlkeyvault_ref.id
    storageAccount: amlstorage_ref.id
}
}
