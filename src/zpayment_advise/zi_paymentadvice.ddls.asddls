@EndUserText.label: 'Payment Advice Creation Params'
define abstract entity ZI_PAYMENTADVICE
{
  @EndUserText.label: 'GRN'
  @Consumption.valueHelpDefinition: [{ entity:{ name: 'I_MaterialDocumentHeader_2', element: 'MaterialDocument' },
  additionalBinding: [{ element: 'MaterialDocumentYear',localElement: 'MDYear' }] }]
  GRN     : mblnr;
  @EndUserText.label: 'Year'
  MDYear:mjahr;
    
}
