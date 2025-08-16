@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Material Summary'
define view entity ZR_PMTADVMTSUMM
  as select from zpmtadvmtsumm
association to parent ZR_PMTADVHEADER as _PMTADVHEADER on $projection.PaymentAdviseNumber = _PMTADVHEADER.PaymentAdviseNumber
{
  key pmtadvno as PaymentAdviseNumber,
  material as Material,
  @Semantics.quantity.unitOfMeasure: 'Bagsuom'
  invbags as Invbags,
  @Semantics.quantity.unitOfMeasure: 'Bagsuom'
  rcvdbags as Rcvdbags,
  @Semantics.quantity.unitOfMeasure: 'Wtuom'
  invwt as Invwt,
  @Semantics.quantity.unitOfMeasure: 'Wtuom'
  rcvdwt as Rcvdwt,
  @Semantics.quantity.unitOfMeasure: 'Wtuom'
  shortwt as Shortwt,
  @Semantics.quantity.unitOfMeasure: 'Wtuom'
  msnetwt as Msnetwt,
  @Semantics.amount.currencyCode: 'Currency'
  invrate as Invrate,
  @Semantics.amount.currencyCode: 'Currency'
  invtaxableamt as Invtaxableamt,
  @Semantics.quantity.unitOfMeasure: 'Wtuom'
  rcvdgr as Rcvdgr,
  @Semantics.quantity.unitOfMeasure: 'Wtuom'
  rcvdtr as Rcvdtr,
  @Semantics.quantity.unitOfMeasure: 'Wtuom'
  rcvdnt as Rcvdnt,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
  currency as Currency,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_UnitOfMeasureStdVH', 
    entity.element: 'UnitOfMeasure', 
    useForValidation: true
  } ]
  bagsuom as Bagsuom,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_UnitOfMeasureStdVH', 
    entity.element: 'UnitOfMeasure', 
    useForValidation: true
  } ]
  wtuom as Wtuom,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  last_changed_by as LastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  last_changed_at as LastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  _PMTADVHEADER
  
}
