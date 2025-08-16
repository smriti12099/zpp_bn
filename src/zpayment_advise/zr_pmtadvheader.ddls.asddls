@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Payment Advise Header CDS'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_PMTADVHEADER as select from zpmtadvheader as _PmtAdvHeader
composition [0..*] of ZR_PMTADVBDSUMM as _PmtAmtBDSumm 
composition [0..*] of ZR_PMTADVDEDUCT as _PmtAmtDeduct
composition [0..1] of ZR_PMTADVMTSUMM as _PmtAdvMtSumm 

{
    key pmtadvno as PaymentAdviseNumber,
    grnno as GRNNumber,
    grndate as GRNDate,
    duedate as DueDate,
    inspectionlot as InspectionLot,
    brokername as BrokerName,
    suppliername as SupplierName,
    bargainno as BargainNumber,
    bargaindate as BargainDate,
    place as Place,
    ponumber as PONumber,
    invoiceno as InvoiceNumber,
    vehicleno as VehicleNumber,
    invoicedate as InvoiceDate,

    @Semantics.user.createdBy: true
    created_by as CreatedBy,
    @Semantics.systemDateTime.createdAt: true
    created_at as CreatedAt,
    @Semantics.user.localInstanceLastChangedBy: true
    last_changed_by as LastChangedBy,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    local_last_changed_at as LocalLastChangedAt,
    @Semantics.systemDateTime.lastChangedAt: true
    last_changed_at as LastChangedAt,
    _PmtAmtBDSumm,
    _PmtAmtDeduct,
    _PmtAdvMtSumm

    
}
