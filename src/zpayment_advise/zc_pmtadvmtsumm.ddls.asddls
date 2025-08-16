@Metadata.allowExtensions: true
@EndUserText.label: 'Material Summary'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define  view entity ZC_PMTADVMTSUMM
  as projection on ZR_PMTADVMTSUMM
{
  key PaymentAdviseNumber,
  Material,
  Invbags,
  Rcvdbags,
  Invwt,
  Rcvdwt,
  Shortwt,
  Msnetwt,
  Invrate,
  Invtaxableamt,
  Rcvdgr,
  Rcvdtr,
  Rcvdnt,
  @Semantics.currencyCode: true
  Currency,
  @Semantics.unitOfMeasure: true
  Bagsuom,
  @Semantics.unitOfMeasure: true
  Wtuom,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  LocalLastChangedAt,
  _PMTADVHEADER: redirected to parent ZC_PMTADVHEADER
  
}
