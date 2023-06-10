
// Parameters
@description('Location where resources will be deployed. Defaults to resource group location')
param location string = resourceGroup().location

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string

// @description('Mult-service Cogntive Service resource name')
// param cogsvc_name string

@description('Form Recognizer resource name')
param formrecognizer_name string

@allowed(['F0','S0'])
@description('Form Recognizer SKU name')
param formrecognizer_sku string ='S0'

@description('Storage account name for custom cognitive services model')
param custom_model_storage_name string

@description('Datalake SKU. Allowed values are Premium_LRS, Premium_ZRS, Standard_GRS, Standard_GZRS, Standard_LRS,Standard_RAGRS, Standard_RAGZRS, Standard_ZRS')
@allowed([
'Premium_LRS'
'Premium_ZRS'
'Standard_GRS'
'Standard_GZRS'
'Standard_LRS'
'Standard_RAGRS'
'Standard_RAGZRS'
'Standard_ZRS'
])
param custom_model_storage_sku string ='Standard_LRS'

@description('Flag to indicate whether to enable integration of data platform resources with either an existing Purview resource')
param enable_purview bool

@description('Resource reference of an existing Purview Account. Specify a resource name if create_purview=true')
param purview_resource object

@minLength(2)
@maxLength(60)
@description('Cognitive Search resource name.Service name must only contain lowercase letters, digits or dashes, cannot use dash as the first two or last one characters, cannot contain consecutive dashes, and is limited between 2 and 60 characters in length.')
param cogsearch_name string

@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
@description('Cognitive Search SKU name')
param cogsearch_sku string ='standard'

@description('Cognitive Search peplicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier).')
@minValue(1)
@maxValue(12)
param cogsearch_replicaCount int = 1

@description('Cognitive Search partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units.')
@allowed([
  1
  2
  3
  4
  6
  12
])
param cogsearch_partitionCount int = 1

@description('Applicable only for Cognitive Search SKUs set to standard3. You can set this property to enable a single, high density partition that allows up to 1000 indexes, which is much higher than the maximum indexes allowed for any other SKU.')
@allowed([
  'default'
  'highDensity'
])
param cogsearch_hostingMode string = 'default'

// Variables
var suffix = uniqueString(resourceGroup().id)
// var cogsvc_uniquename = '${cogsvc_name}-${suffix}'
var formrecognizer_uniquename = '${formrecognizer_name}-${suffix}'
var custom_model_storage_uniquename = substring('${custom_model_storage_name}${suffix}',0,24)
var cogsearch_uniquename = '${cogsearch_name}-${suffix}'

// Commented out - Since multi-service cognitive service reuires to accept terms of responsible AI manually from the Azure portal
// //Multi-service Cognitive
// resource cogsvc 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
//   name: cogsvc_uniquename
//   location: location
//   tags: {
//     CostCentre: cost_centre_tag
//     Owner: owner_tag
//     SME: sme_tag
//   }
//   sku: { name: sku}
//   kind: 'CognitiveServices'
//   identity: { type: 'SystemAssigned'}
//   properties:{
//     apiProperties:{
//       statisticsEnabled: false
//     }
//   }
// }

//Blob Storage for Custom Models
resource custom_model_storage 'Microsoft.Storage/storageAccounts@2022-09-01' ={
  name: custom_model_storage_uniquename
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  sku: { name: custom_model_storage_sku}
  kind: 'StorageV2'
  identity: { type: 'SystemAssigned'}
  properties:{
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    isHnsEnabled: false // non-hierarchical storage
    minimumTlsVersion: 'TLS1_2'
  }

}

//Set CORS for Form Recognizer Studio to access Storage
resource enable_CORS_custom_model_storage 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' ={
  name: 'default'
  parent: custom_model_storage
  properties:{
    cors: {
      corsRules: [
        {
          allowedOrigins: ['https://fott-2-1.azurewebsites.net']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          allowedMethods: ['DELETE','GET','HEAD','MERGE','OPTIONS','PATCH','POST','PUT']
          maxAgeInSeconds: 200  
        }
        {
          allowedOrigins: ['*']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          allowedMethods: ['DELETE','GET','HEAD','MERGE','OPTIONS','PATCH','POST','PUT']
          maxAgeInSeconds: 200  
        }
      ]
    }
  }

}

//Form Recognizer
resource formrecognizer 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: formrecognizer_uniquename
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  sku: { name: formrecognizer_sku}
  kind: 'FormRecognizer'
  identity: { type: 'SystemAssigned'}
  properties:{
    apiProperties:{
      statisticsEnabled: false
    }
  }
}

//Cognitive Search

resource cogsearch 'Microsoft.Search/searchServices@2022-09-01'={
 name: cogsearch_uniquename
 location: location
 tags: {
  CostCentre: cost_centre_tag
  Owner: owner_tag
  SME: sme_tag
 } 
 sku: { name: cogsearch_sku}
 identity: { type: 'SystemAssigned'}
 properties:{
  replicaCount: cogsearch_replicaCount
  partitionCount: cogsearch_partitionCount
  hostingMode: cogsearch_hostingMode
 }

}

// Role Assignment
@description('This is the built-in Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

@description('This is the built-in Reader role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

@description('This is the built-in Storage Blob Reader role. See https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#storage-blob-data-reader')
resource sbdr 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

@description('This is the built-in Storage Blob Contributor role. See https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor')
resource sbdc 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// Grant Form Recognizer contributor role to Storage
resource grant_formrecognizer_role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id,formrecognizer.name,contributorRoleDefinition.id)
  scope: custom_model_storage
  properties:{
    principalType: 'ServicePrincipal'
    principalId: formrecognizer.identity.principalId
    roleDefinitionId: contributorRoleDefinition.id
  }
}

// Grant Purview reader role to Storage
resource grant_purview_sbdc_role 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enable_purview) {
  name: guid(resourceGroup().id,purview_resource.resourceGroupName,sbdc.id)
  scope: custom_model_storage
  properties:{
    principalType: 'ServicePrincipal'
    principalId: purview_resource.identity.principalId
    roleDefinitionId: sbdc.id
  }
}

// Grant Cognitive Search to Storage Blob Data Reader role 
resource grant_sbdr_role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id,cogsearch.name,sbdr.id)
  scope: custom_model_storage
  properties:{
    principalType: 'ServicePrincipal'
    principalId: cogsearch.identity.principalId
    roleDefinitionId: sbdr.id
  }
}

// Grant Cognitive Search to Storage Blob Contributor Reader role 
resource grant_sbdc_role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id,cogsearch.name,sbdc.id)
  scope: custom_model_storage
  properties:{
    principalType: 'ServicePrincipal'
    principalId: cogsearch.identity.principalId
    roleDefinitionId: sbdc.id
  }
}
