CLASS lhc_PmtAdvheader DEFINITION INHERITING FROM cl_abap_behavior_handler.

PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR pmtadvheader RESULT result.

    METHODS createPMTADVCData FOR MODIFY
      IMPORTING keys FOR ACTION pmtadvheader~createPMTADVCData RESULT result.

    METHODS getCID RETURNING VALUE(cid) TYPE abp_behv_cid.

    METHODS generate_deductions
    IMPORTING VALUE(grn) TYPE I_MaterialDocumentHeader_2-MaterialDocument
              VALUE(year) TYPE I_MaterialDocumentHeader_2-MaterialDocumentYear
              VALUE(InvTaxAbleAmt) TYPE ZR_PmtAdvMtSumm-InvTaxableAmt
              VALUE(InspectionLot) TYPE I_InspectionLot-InspectionLot.

    METHODS earlynumbering_pmtHeader FOR NUMBERING
      IMPORTING entities FOR CREATE pmtadvheader.

*    METHODS earlynumbering_pmtamtbdsumm FOR NUMBERING
*      IMPORTING entities FOR CREATE pmtadvheader\_PmtAmtBDSumm.

*    METHODS earlynumbering_pmtamtdeduct FOR NUMBERING
*      IMPORTING entities FOR CREATE pmtadvheader\_PmtAmtDeduct.

    CLASS-DATA lt_deductions TYPE TABLE OF zr_pmtadvdeduct.

ENDCLASS.

CLASS lhc_PmtAdvheader IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD createpmtadvcdata.

    READ TABLE keys INTO DATA(ls_key) INDEX 1.
    DATA(grn) = ls_key-%param-grn.
    DATA(year) = ls_key-%param-MDYear.
    DATA: lt_bardana TYPE TABLE OF zr_pmtadvbdsumm,
          wa_bardana TYPE zr_pmtadvbdsumm.


*    Header

    SELECT SINGLE FROM I_MaterialDocumentHeader_2 AS a
    INNER JOIN I_MaterialDocumentItem_2 AS c ON c~MaterialDocument = a~MaterialDocument AND c~MaterialDocumentYear = a~MaterialDocumentYear
    LEFT JOIN I_Supplier AS d ON d~Supplier = c~Supplier
    LEFT JOIN I_InspectionLot AS b ON b~MaterialDocument = a~MaterialDocument AND b~MaterialDocumentYear = a~MaterialDocumentYear
    LEFT JOIN I_PurchaseOrderItemAPI01 AS e ON e~PurchaseOrder = c~PurchaseOrder AND e~PurchaseOrderItem = c~PurchaseOrderItem
    LEFT JOIN I_PurchaseContractAPI01 AS f ON f~PurchaseContract = e~PurchaseContract
    FIELDS a~MaterialDocument, b~InspectionLot,d~BusinessPartnerName1, d~BusinessPartnerName2, f~CreationDate, f~PurchaseContract, a~PostingDate
    WHERE a~MaterialDocumentYear = @year AND a~MaterialDocument = @grn AND c~Material IN ( '000000001000000051' )
    INTO @DATA(wa_mtHead).

    SELECT SINGLE FROM c_supplierinvoiceitemdex AS a
    FIELDS a~SupplierInvoice, a~PostingDate
    WHERE a~PrmtHbReferenceDocument = @grn
    INTO @DATA(wa_invHeader).


*    Material Summary
    SELECT SINGLE FROM I_MaterialDocumentItem_2 AS a
    INNER JOIN I_ProductDescription_2 AS b ON b~Product = a~Material
    LEFT JOIN I_PurchaseOrderItemAPI01 AS c ON c~PurchaseOrder = a~PurchaseOrder AND c~PurchaseOrderItem = a~PurchaseOrderItem
    FIELDS b~ProductDescription, c~NetPriceAmount, a~QuantityInDeliveryQtyUnit, a~DeliveryQuantityUnit, c~PurchaseOrder
     WHERE a~MaterialDocument = @grn AND a~MaterialDocumentYear = @year AND c~Material IN ( '000000001000000051' )
    INTO @DATA(wa_mtsummItem1).

    SELECT SINGLE FROM I_MaterialDocumentItem_2 AS a
    FIELDS SUM( a~QuantityInEntryUnit ) AS QuantityInDeliveryQtyUnit
    WHERE a~MaterialDocument = @grn AND a~MaterialDocumentYear = @year AND a~GoodsMovementType = '501'
    INTO @DATA(rcvgbags_mtsumm).

    SELECT SINGLE FROM I_MaterialDocumentItem_2 AS a
    FIELDS SUM( a~QuantityInEntryUnit ) AS QuantityInDeliveryQtyUnit
    WHERE a~MaterialDocument = @grn AND a~MaterialDocumentYear = @year AND a~GoodsMovementType = '101' AND a~Material IN ( '000000001000000051' )
    INTO @DATA(rcvgnt_mtsumm).


*    Bardana Summary
    SELECT FROM I_MaterialDocumentItem_2 AS a
    JOIN I_productdescription_2 AS b ON b~Product = a~Material
    JOIN I_Product AS c ON c~Product = a~Material
    FIELDS a~Material, a~QuantityInEntryUnit, b~ProductDescription, c~NetWeight, c~WeightUnit
    WHERE a~MaterialDocument = @grn AND a~MaterialDocumentYear = @year AND a~GoodsMovementType = '501'
    INTO TABLE @DATA(bdsumm).

    DATA(sno) = 1.
    LOOP AT bdsumm INTO DATA(wa_bdsumm).
      CLEAR wa_bardana.
      wa_bardana-ItemNo = sno.
      wa_bardana-Material = wa_bdsumm-ProductDescription.
      wa_bardana-ReceivedBags = wa_bdsumm-QuantityInEntryUnit.
      wa_bardana-BDUnitWeight = wa_bdsumm-NetWeight.
      wa_bardana-BDUnitWeightUOM = wa_bdsumm-WeightUnit.
      wa_bardana-BDNetWeight = ( wa_bardana-ReceivedBags * ( wa_bardana-BDUnitWeight / 1000000 ) ).
      wa_bardana-WeightPerBag = ( wa_bardana-BDUnitWeight / 1000 ) - ( ( rcvgnt_mtsumm * 1000 ) / rcvgbags_mtsumm ).
      wa_bardana-MSNetWeight = ( wa_bardana-WeightPerBag * wa_bardana-ReceivedBags ) / 1000.
      APPEND wa_bardana TO lt_bardana.
      sno += 1.
    ENDLOOP.

*    Deductions
    CLEAR lt_deductions.
    generate_deductions( grn = grn year = year InspectionLot = wa_mtHead-InspectionLot invtaxableamt = ( wa_mtsummItem1-NetPriceAmount * wa_mtsummItem1-QuantityInDeliveryQtyUnit ) ).


    DATA(cid) = getCID( ).
    MODIFY ENTITIES OF zr_pmtadvheader IN LOCAL MODE
      ENTITY pmtadvheader
          CREATE FIELDS ( GRNDate GRNNumber InspectionLot SupplierName BargainNumber BargainDate InvoiceNumber InvoiceDate PONumber )
          WITH VALUE #(
            ( %cid = cid
              GRNDate = wa_mtHead-PostingDate
              GRNNumber = wa_mtHead-MaterialDocument
              InspectionLot = wa_mtHead-InspectionLot
              SupplierName = wa_mtHead-BusinessPartnerName1 && ' ' && wa_mtHead-BusinessPartnerName2
              BargainNumber = wa_mtHead-PurchaseContract
              BargainDate = wa_mtHead-CreationDate
              InvoiceNumber = wa_invHeader-SupplierInvoice
              InvoiceDate = wa_invHeader-PostingDate
              PONumber = wa_mtsummItem1-PurchaseOrder
               )
          )
      CREATE BY \_PmtAdvMtSumm
      FIELDS ( Material Rcvdbags Invwt Shortwt Rcvdnt Invrate Invtaxableamt )
      WITH VALUE #(
        ( %cid_ref = cid
          PaymentAdviseNumber = space
          %target = VALUE #(
            ( %cid = cid && '1'
              Material = wa_mtsummItem1-ProductDescription
              Rcvdbags = rcvgbags_mtsumm
              Invwt = wa_mtsummItem1-QuantityInDeliveryQtyUnit
              Shortwt = ( wa_mtsummItem1-QuantityInDeliveryQtyUnit - rcvgnt_mtsumm )
              Rcvdnt = rcvgnt_mtsumm
              Invrate = wa_mtsummItem1-NetPriceAmount
              Invtaxableamt = ( wa_mtsummItem1-NetPriceAmount * wa_mtsummItem1-QuantityInDeliveryQtyUnit ) )
          ) )
      )
      CREATE BY \_PmtAmtBDSumm
      FIELDS ( ItemNo Material ReceivedBags BDUnitWeight BDUnitWeightUOM BDNetWeight WeightPerBag MSNetWeight )
      WITH VALUE #(
        ( %cid_ref = cid
          PaymentAdviseNumber = space
          %target = VALUE #( FOR ws_bardana IN lt_bardana INDEX INTO i (
                         %cid =  |{ cid }{ i WIDTH = 3 ALIGN = RIGHT PAD = '0' }|
                            ItemNo = ws_bardana-ItemNo
                            Material = ws_bardana-Material
                            ReceivedBags = ws_bardana-ReceivedBags
                            BDUnitWeight = ws_bardana-BDUnitWeight
                            BDUnitWeightUOM = ws_bardana-BDUnitWeightUOM
                            BDNetWeight = ws_bardana-BDNetWeight
                            WeightPerBag = ws_bardana-WeightPerBag
                            MSNetWeight = ws_bardana-MSNetWeight
                            ) )
         )
      )
      CREATE BY \_PmtAmtDeduct
      FIELDS ( ItemNo Particulars ConditionNumber Actual DeductionAmount )
      WITH VALUE #(
        ( %cid_ref = cid
          PaymentAdviseNumber = space
          %target = VALUE #( FOR ws_deduction IN lt_deductions INDEX INTO i (
                         %cid =  |{ cid }DE{ i WIDTH = 3 ALIGN = RIGHT PAD = '0' }|
                            ItemNo = ws_deduction-ItemNo
                            Particulars = ws_deduction-Particulars
                            ConditionNumber = ws_deduction-ConditionNumber
                            Actual = ws_deduction-Actual
                            DeductionAmount = ws_deduction-DeductionAmount
                         ) )
         )
      )
      MAPPED mapped
      FAILED failed
      REPORTED reported.

    CLEAR lt_deductions.

    LOOP AT mapped-pmtadvheader ASSIGNING FIELD-SYMBOL(<mapped_entry>).
      APPEND VALUE #( %cid = ls_key-%cid
                       %param = VALUE #(
                            %key = <mapped_entry>-%key
                        ) ) TO result.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD generate_deductions.
    DATA wa_deduction TYPE zr_pmtadvdeduct.
    CLEAR lt_deductions.


*    OIL CONTENT
    SELECT SINGLE FROM I_InspectionLot AS a
    LEFT JOIN I_InspectionCharacteristic AS b ON b~InspectionLot = a~InspectionLot
    LEFT JOIN I_InspectionResultValue AS c ON c~InspectionLot = a~InspectionLot AND c~InspectionCharacteristic = b~InspectionCharacteristic
                                              AND c~InspPlanOperationInternalID = b~InspPlanOperationInternalID
    FIELDS b~InspSpecUpperLimit, c~InspectionResultMeasuredValue
    WHERE a~InspectionLot = @InspectionLot AND b~InspSpecUpperLimit IS NOT INITIAL
    INTO @DATA(wa_oilcontent).

    wa_deduction-ItemNo = 1.
    wa_deduction-Particulars = 'OIL CONTENT'.
    wa_deduction-ConditionNumber = wa_oilcontent-InspSpecUpperLimit.
    wa_deduction-Actual = wa_oilcontent-InspectionResultMeasuredValue.
    APPEND wa_deduction TO lt_deductions.


*     MOISTURE
    SELECT SINGLE FROM I_InspectionLot AS a
    LEFT JOIN I_InspectionCharacteristic AS b ON b~InspectionLot = a~InspectionLot
    LEFT JOIN I_InspectionResultValue AS c ON c~InspectionLot = a~InspectionLot AND c~InspectionCharacteristic = b~InspectionCharacteristic
                                            AND c~InspPlanOperationInternalID = b~InspPlanOperationInternalID
    FIELDS b~InspSpecLowerLimit, c~InspectionResultMeasuredValue
    WHERE a~InspectionLot = @InspectionLot AND b~InspSpecUpperLimit IS NOT INITIAL
    INTO @DATA(wa_moisture).

    CLEAR wa_deduction.
    wa_deduction-ItemNo = 2.
    wa_deduction-Particulars = 'MOISTURE'.
    wa_deduction-ConditionNumber = wa_moisture-InspSpecLowerLimit.
    wa_deduction-Actual = wa_moisture-InspectionResultMeasuredValue.
    APPEND wa_deduction TO lt_deductions.


*      FREE FATTY ACID (AS OLEIC)
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 3.
    wa_deduction-Particulars = 'FREE FATTY ACID (AS OLEIC)'.
    wa_deduction-ConditionNumber = wa_moisture-InspSpecLowerLimit.
    wa_deduction-Actual = wa_moisture-InspectionResultMeasuredValue.
    APPEND wa_deduction TO lt_deductions.


*    FOREIGN MATTER
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 4.
    wa_deduction-Particulars = 'FOREIGN MATTER'.
    wa_deduction-ConditionNumber = wa_moisture-InspSpecLowerLimit.
    wa_deduction-Actual = wa_moisture-InspectionResultMeasuredValue.
    APPEND wa_deduction TO lt_deductions.


*    BRDNAJT500GM
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 5.
    wa_deduction-Particulars = 'BRDNAJT500GM'.
    APPEND wa_deduction TO lt_deductions.


*    BRDNAJT900GM
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 6.
    wa_deduction-Particulars = 'BRDNAJT900GM'.
    APPEND wa_deduction TO lt_deductions.


*   BRDNAPP150GM
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 7.
    wa_deduction-Particulars = 'BRDNAPP150GM'.
    APPEND wa_deduction TO lt_deductions.


*   BRDNAJTMS1KG
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 8.
    wa_deduction-Particulars = 'BRDNAJTMS1KG'.
    APPEND wa_deduction TO lt_deductions.


*   SHORTAGE
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 9.
    wa_deduction-Particulars = 'SHORTAGE'.
    APPEND wa_deduction TO lt_deductions.


*   RATE DIFF IN RS PMT
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 10.
    wa_deduction-Particulars = 'RATE DIFF IN RS PMT'.
    APPEND wa_deduction TO lt_deductions.


*   OTHER ADJUSTMENTS
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 11.
    wa_deduction-Particulars = 'OTHER ADJUSTMENTS'.
    APPEND wa_deduction TO lt_deductions.


*   REMARKS
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 12.
    wa_deduction-Particulars = 'REMARKS'.
    APPEND wa_deduction TO lt_deductions.


*   TOTAL DEDUCTION
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 13.
    wa_deduction-Particulars = 'TOTAL DEDUCTION'.
    APPEND wa_deduction TO lt_deductions.


*   TAXABLE PAYABLE AMOUNT
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 14.
    wa_deduction-Particulars = 'TAXABLE PAYABLE AMOUNT'.
    wa_deduction-DeductionAmount = InvTaxAbleAmt.
    APPEND wa_deduction TO lt_deductions.


*   GST
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 15.
    wa_deduction-Particulars = 'GST'.
    APPEND wa_deduction TO lt_deductions.


*   TDS
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 16.
    wa_deduction-Particulars = 'TDS'.
    APPEND wa_deduction TO lt_deductions.


*   TOTAL
    CLEAR wa_deduction.
    wa_deduction-ItemNo = 17.
    wa_deduction-Particulars = 'TOTAL PAYABLE'.
    wa_deduction-DeductionAmount = InvTaxAbleAmt.
    APPEND wa_deduction TO lt_deductions.
  ENDMETHOD.

  METHOD earlynumbering_pmtHeader.

    DATA: nr_number     TYPE cl_numberrange_runtime=>nr_number.
    DATA nextnumber TYPE zpmtadvheader-pmtadvno.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<gate_entry_header>).

        DATA Lnm TYPE zpmtadvheader-pmtadvno.

        SELECT FROM zr_pmtadvheader
        FIELDS PaymentAdviseNumber
        ORDER BY PaymentAdviseNumber DESCENDING
        INTO TABLE @DATA(LastNo)
        UP TO 1 ROWS .

        LOOP AT LastNo INTO DATA(NextNum).
             Lnm = NextNum-PaymentAdviseNumber.
        ENDLOOP.

        IF sy-subrc = 0.
          nextnumber = CONV zpmtadvheader-pmtadvno( |{ Lnm + 1 }| ).
        ELSE.
          nextnumber = '1000000001'.
        ENDIF.


        SHIFT nextnumber LEFT DELETING LEADING '0'.
    ENDLOOP.

    "assign Gate Entry no.
    APPEND CORRESPONDING #( <gate_entry_header> ) TO mapped-pmtadvheader ASSIGNING FIELD-SYMBOL(<mapped_gate_entry_header>).
    IF <gate_entry_header>-PaymentAdviseNumber IS INITIAL.
"      max_item_id += 10.
      <mapped_gate_entry_header>-PaymentAdviseNumber =  nextnumber.
    ENDIF.
  ENDMETHOD.


*  METHOD earlynumbering_pmtamtbdsumm.
*    READ ENTITIES OF zr_pmtadvheader IN LOCAL MODE
*      ENTITY pmtadvheader BY \_PmtAmtBDSumm
*        FIELDS ( ItemNo )
*          WITH CORRESPONDING #( entities )
*          RESULT DATA(entry_lines)
*        FAILED failed.
*
*
*    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entry_header>).
*      " get highest item from lines
*      DATA(max_item_id) = REDUCE #( INIT max = CONV posnr( '000000' )
*                                    FOR entry_line IN entry_lines USING KEY entity WHERE ( PaymentAdviseNumber = <entry_header>-PaymentAdviseNumber )
*                                    NEXT max = COND posnr( WHEN entry_line-ItemNo > max
*                                                           THEN entry_line-ItemNo
*                                                           ELSE max )
*                                  ).
*    ENDLOOP.
*
*    "assign Item No.
*    LOOP AT <entry_header>-%target ASSIGNING FIELD-SYMBOL(<entry_line>).
*      APPEND CORRESPONDING #( <entry_line> ) TO mapped-pmtadvbdsumm ASSIGNING FIELD-SYMBOL(<mapped_entry_line>).
*      IF <entry_line>-ItemNo IS INITIAL.
*        max_item_id += 10.
*        <mapped_entry_line>-ItemNo = max_item_id.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.

*  METHOD earlynumbering_pmtamtdeduct.
*    READ ENTITIES OF zr_pmtadvheader IN LOCAL MODE
*      ENTITY pmtadvheader BY \_PmtAmtDeduct
*        FIELDS ( ItemNo )
*          WITH CORRESPONDING #( entities )
*          RESULT DATA(entry_lines)
*        FAILED failed.
*
*
*    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entry_header>).
*      " get highest item from lines
*      DATA(max_item_id) = REDUCE #( INIT max = CONV posnr( '000000' )
*                                    FOR entry_line IN entry_lines USING KEY entity WHERE ( PaymentAdviseNumber = <entry_header>-PaymentAdviseNumber )
*                                    NEXT max = COND posnr( WHEN entry_line-ItemNo > max
*                                                           THEN entry_line-ItemNo
*                                                           ELSE max )
*                                  ).
*    ENDLOOP.
*
*    "assign Item No.
*    LOOP AT <entry_header>-%target ASSIGNING FIELD-SYMBOL(<entry_line>).
*      APPEND CORRESPONDING #( <entry_line> ) TO mapped-pmtadvdeduct ASSIGNING FIELD-SYMBOL(<mapped_entry_line>).
*      IF <entry_line>-ItemNo IS INITIAL.
*        max_item_id += 10.
*        <mapped_entry_line>-ItemNo = max_item_id.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.

    METHOD getCID.
            TRY.
                cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
            CATCH cx_uuid_error.
                ASSERT 1 = 0.
            ENDTRY.
  ENDMETHOD.



ENDCLASS.
