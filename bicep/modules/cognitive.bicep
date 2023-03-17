
// Parameters
@description('Location where resources will be deployed. Defaults to resource group location')
param location string = resourceGroup().location

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string

@description('Mult-service Cogntive Service resource name')
param cogsvc_name string

@description('Form Recognizer resource name')
param formrecognizer_name string

@allowed(['F0','S0'])
param sku string


// Variables
var suffix = uniqueString(resourceGroup().id)
var cogsvc_uniquename = '${cogsvc_name}-${suffix}'
var formrecognizer_uniquename = '${formrecognizer_name}-${suffix}'

// Commented out - Since multi-service cognitive service reuires to accept terms of responsible AI manually from the Azure portal
// //Mult-service Cognitive
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

//Form Recognizer
resource formrecognizer 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: formrecognizer_uniquename
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  sku: { name: sku}
  kind: 'FormRecognizer'
  identity: { type: 'SystemAssigned'}
  properties:{
    apiProperties:{
      statisticsEnabled: false
    }
  }
}
