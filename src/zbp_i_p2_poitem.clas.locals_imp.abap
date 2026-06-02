CLASS lhc_ZI_P2_POITEM DEFINITION INHERITING FROM cl_abap_behavior_handler.
  puBLIC SECTION.
            TYPES: BEGIN OF ty_key,
             ebeln       TYPE ebeln,
             ebelp type ebelp,
             is_draft TYPE abp_behv_flag,
           END OF ty_key.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_p2_poitem RESULT result.
    METHODS UploadCSV FOR MODIFY
      IMPORTING keys FOR ACTION zi_p2_poitem~uploadcsv RESULT result.
    METHODS calcStockAmountDeep FOR MODIFY
      IMPORTING keys FOR ACTION ZI_P2_POITEM~calcStockAmountDeep RESULT result.

*    METHODS UploadCSV FOR MODIFY
*      IMPORTING keys FOR ACTION zi_p2_poitem~UploadCSV.
**       RESULT result.

ENDCLASS.

CLASS lhc_ZI_P2_POITEM IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

*  METHOD UploadCSV.
*
*  "1) Get uploaded content from action parameter
*  DATA lv_file_content TYPE xstring.
*  lv_file_content = VALUE #( keys[ 1 ]-%param-_streamproperties-StreamProperty OPTIONAL ).
*
*  IF lv_file_content IS INITIAL.
*    APPEND VALUE #(
*      %msg = new_message_with_text(
*               severity = if_abap_behv_message=>severity-error
*               text     = 'No CSV received. Please select a CSV file.'
*             )
*    ) TO reported-zi_p2_poitem.
*    RETURN.
*  ENDIF.
*
*  "2) Convert xstring -> string (internal proven pattern)
*  DATA lv_text TYPE string.
*
*lv_text = xco_cp=>xstring( lv_file_content )->as_string( xco_cp_character=>code_page->utf_8 )->value.
*
**  lv_text = xco_cp=>string( lv_file_content )->value.
**  DATA lo_conv TYPE REF TO cl_abap_conv_in_ce.
**
**  lo_conv = cl_abap_conv_in_ce=>create( input = lv_file_content ).
**  lo_conv->read( IMPORTING data = lv_text ).
*  "3) Split into rows
*  DATA lt_rows TYPE STANDARD TABLE OF string.
**  lv_text = VALUE #( keys[ 1 ]-%param-_streamproperties-StreamProperty OPTIONAL ).
*  SPLIT lv_text AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_rows.
*  "4) Prepare data for create/update
*  TYPES: BEGIN OF ty_key,
*           ebeln TYPE ebeln,
*           ebelp TYPE ebelp,
*         END OF ty_key.
*
*  DATA lt_keys TYPE STANDARD TABLE OF ty_key WITH EMPTY KEY.
*  DATA lt_create TYPE TABLE FOR CREATE ZI_P2_POITEM.
*  DATA lt_update TYPE TABLE FOR UPDATE ZI_P2_POITEM.
*
*  DATA lv_rowno TYPE i VALUE 0.
*
*  LOOP AT lt_rows INTO DATA(lv_row).
*    lv_rowno += 1.
*
*    IF lv_row IS INITIAL.
*      CONTINUE.
*    ENDIF.
*
*    "Skip header if present
*    IF lv_rowno = 1 AND ( lv_row CP 'PO*' OR lv_row CP 'EBELN*' ).
*      CONTINUE.
*    ENDIF.
*
*    DATA: lv_po   TYPE string,
*          lv_item TYPE string,
*          lv_amt  TYPE string,
*          lv_ref  TYPE string.
*
*    SPLIT lv_row AT ',' INTO lv_po lv_item lv_amt lv_ref.
*    DATA:
*    lv_err TYPE abap_boolean VALUE abap_false,
*    lv_errmsg TYPE char256 VALUE ''.
*
*    DATA lv_ebeln TYPE ebeln.
*    DATA lv_ebelp TYPE ebelp.
*    DATA lv_amount TYPE wrbtr.
*
*    "Validate keys
*    IF lv_po IS INITIAL OR lv_item IS INITIAL.
*      lv_err = abap_true.
*      lv_errmsg = 'PO/Item is mandatory'.
*    ELSE.
*      lv_ebeln = |{ lv_po ALPHA = IN }|.
*      lv_ebelp = |{ lv_item ALPHA = IN }|.
*    ENDIF.
*
*    "Validate amount numeric (optional)
*    IF lv_err = abap_false AND lv_amt IS NOT INITIAL.
*      TRY.
*          lv_amount = CONV wrbtr( lv_amt ).
*        CATCH cx_sy_conversion_no_number.
*          lv_err = abap_true.
*          lv_errmsg = 'Amount is not numeric'.
*      ENDTRY.
*    ENDIF.
*
*    APPEND VALUE #( ebeln = lv_ebeln ebelp = lv_ebelp ) TO lt_keys.
*
*    "Temporarily store as create; we'll split into create/update after existence check
*    APPEND VALUE #(
*      Po = lv_ebeln
*      Item = lv_ebelp
*      Amount = lv_amount
*      Reference = lv_ref
*
*      Error = lv_err
*      ErrorMsg = lv_errmsg
*    ) TO lt_create.
*
*  ENDLOOP.
*
*  IF lt_create IS INITIAL.
*    APPEND VALUE #(
*      %msg = new_message_with_text(
*               severity = if_abap_behv_message=>severity-error
*               text     = 'No rows found in CSV.'
*             )
*    ) TO reported-zi_p2_poitem.
*    RETURN.
*  ENDIF.
*
*  "5) Existence check in persistence (POC-friendly)
*  SORT lt_keys BY ebeln ebelp.
*  DELETE ADJACENT DUPLICATES FROM lt_keys COMPARING ebeln ebelp.
*
*  DATA lt_existing TYPE SORTED TABLE OF ty_key WITH UNIQUE KEY ebeln ebelp.
*
*  SELECT ebeln, ebelp
*    FROM zp2_t_poitem
*    FOR ALL ENTRIES IN @lt_keys
*    WHERE ebeln = @lt_keys-ebeln
*      AND ebelp = @lt_keys-ebelp
*    INTO TABLE @lt_existing.
*
*  "6) Build UPDATE list for existing keys; keep CREATE for new keys
*  DATA lt_create_final TYPE TABLE FOR CREATE ZI_P2_POITEM.
*  DATA lt_update_final TYPE TABLE FOR UPDATE ZI_P2_POITEM.
*
*  LOOP AT lt_create INTO DATA(ls_any).
*    READ TABLE lt_existing WITH KEY ebeln = ls_any-Po ebelp = ls_any-Item TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0 and ls_any-Error = abap_false.
*      APPEND VALUE #(
*        Po = ls_any-Po
*        Item = ls_any-Item
*        Amount = ls_any-Amount
*        Reference = ls_any-Reference
*        Error = ls_any-Error
*        ErrorMsg = ls_any-ErrorMsg
*        %control-Amount = if_abap_behv=>mk-on
*        %control-Reference = if_abap_behv=>mk-on
*        %control-Error = if_abap_behv=>mk-on
*        %control-ErrorMsg = if_abap_behv=>mk-on
*      ) TO lt_update_final.
*    ELSEif ls_any-Error = abap_false..
*      APPEND ls_any TO lt_create_final.
*    ENDIF.
*  ENDLOOP.
*
*  "7) Execute EML
*  IF lt_create_final IS NOT INITIAL.
**    MODIFY ENTITIES OF ZI_P2_POITEM IN LOCAL MODE
**      ENTITY zi_p2_poitem
**      CREATE FROM lt_create_final
**      FAILED   DATA(lt_failed_c)
**      REPORTED DATA(lt_reported_c).
*
*
*MODIFY ENTITIES OF ZI_P2_POITEM IN LOCAL MODE
*  ENTITY zi_p2_poitem
*  CREATE AUTO FILL CID
*  WITH lt_create_final
*  FAILED   DATA(lt_failed_c)
*  REPORTED DATA(lt_reported_c)
*  MAPPED   DATA(lt_mapped_c).
*
*  ENDIF.
*
*  IF lt_update_final IS NOT INITIAL.
*    MODIFY ENTITIES OF ZI_P2_POITEM IN LOCAL MODE
*      ENTITY zi_p2_poitem
*      UPDATE FROM lt_update_final
*      FAILED   DATA(lt_failed_u)
*      REPORTED DATA(lt_reported_u).
*  ENDIF.
*
*  "8) Summary message
*  DATA(lv_err_cnt) = REDUCE i( INIT x = 0 FOR r IN lt_create NEXT x = x + COND i( WHEN r-Error = abap_true THEN 1 ELSE 0 ) ).
*
*  APPEND VALUE #(
*    %msg = new_message_with_text(
*             severity = COND #( WHEN lv_err_cnt > 0 THEN if_abap_behv_message=>severity-warning
*                                ELSE if_abap_behv_message=>severity-success )
*             text = |CSV done. Total { lines( lt_create ) }, Errors { lv_err_cnt }. See ErrorMessage column.|
*           )
*  ) TO reported-zi_p2_poitem.
*
*ENDMETHOD.


*
  METHOD UploadCSV.

    "------------------------------------------------------------
    "1) Get uploaded content from action parameter (XSTRING)
    "------------------------------------------------------------
    DATA lv_file_content TYPE xstring.
    lv_file_content = VALUE #( keys[ 1 ]-%param-_streamproperties-StreamProperty OPTIONAL ).

    IF lv_file_content IS INITIAL.
      APPEND VALUE #(
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'No CSV received. Please select a CSV file.'
               )
      ) TO reported-zi_p2_poitem.
      RETURN.
    ENDIF.

    "------------------------------------------------------------
    "2) Convert XSTRING -> STRING (UTF-8) using released XCO API
    "   (prevents hex-dump string like 504F2C...)
    "------------------------------------------------------------
    DATA lv_text TYPE string.
    lv_text = xco_cp=>xstring( lv_file_content )->as_string( xco_cp_character=>code_page->utf_8 )->value.
    "------------------------------------------------------------
    "3) Split into rows
    "------------------------------------------------------------
    DATA lt_rows TYPE STANDARD TABLE OF string.
    SPLIT lv_text AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_rows.

    "Prepare tables
    TYPES: BEGIN OF ty_key,
             ebeln TYPE ebeln,
             ebelp TYPE ebelp,
           END OF ty_key.

    DATA lt_keys   TYPE STANDARD TABLE OF ty_key WITH EMPTY KEY.
    DATA lt_create TYPE TABLE FOR CREATE ZI_P2_POITEM.
    DATA lt_upload_res TYPE STANDARD TABLE OF z_upload_res WITH EMPTY KEY.

    DATA lv_rowno TYPE i VALUE 0.

    "------------------------------------------------------------
    "4) Parse each row, validate, and build create payload
    "   CSV columns expected: PO,ITEM,AMOUNT,CURRENCY,REFERENCE
    "------------------------------------------------------------
    LOOP AT lt_rows INTO DATA(lv_row).
      lv_rowno += 1.

      IF lv_row IS INITIAL.
        CONTINUE.
      ENDIF.

      "Skip header row if present
      IF lv_rowno = 1 AND ( lv_row CP 'PO*' OR lv_row CP 'EBELN*' ).
        CONTINUE.
      ENDIF.

      DATA: lv_po   TYPE string,
            lv_item TYPE string,
            lv_amt  TYPE string,
            lv_curr TYPE string,
            lv_ref  TYPE string.

      "✅ FIX: split 5 columns
      SPLIT lv_row AT ',' INTO lv_po lv_item lv_amt lv_curr lv_ref.

      DATA: lv_err    TYPE abap_boolean VALUE abap_false,
            lv_errmsg TYPE char256      VALUE ''.

      DATA: lv_ebeln  TYPE ebeln,
            lv_ebelp  TYPE ebelp,
            lv_amount TYPE wrbtr.

      CLEAR: lv_ebeln, lv_ebelp, lv_amount.

      "---- Key validation (mandatory)
      IF lv_po IS INITIAL OR lv_item IS INITIAL.
        lv_err    = abap_true.
        lv_errmsg = 'PO/Item is mandatory'.

        "Cannot store without keys -> report and skip
        APPEND VALUE #(
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Row { lv_rowno }: { lv_errmsg }|
                 )
        ) TO reported-zi_p2_poitem.
        CONTINUE.
      ENDIF.

      "Normalize keys (leading zeros)
      lv_ebeln = |{ lv_po   ALPHA = IN }|.
      lv_ebelp = |{ lv_item ALPHA = IN }|.

      "---- Amount validation
      IF lv_amt IS NOT INITIAL.
        TRY.
            lv_amount = CONV wrbtr( lv_amt ).
          CATCH cx_sy_conversion_no_number.
            lv_err    = abap_true.
            lv_errmsg = |Amount is not numeric: { lv_amt }|.
            CLEAR lv_amount.
        ENDTRY.
      ENDIF.

      "---- Build row message with row number
      DATA: lv_row_msg TYPE char256.
      lv_row_msg = COND #( WHEN lv_err = abap_true
                           THEN |Row { lv_rowno }: { lv_errmsg }|
                           ELSE '' ).

      "Show message strip per invalid row (warning)
      IF lv_err = abap_true.
        APPEND VALUE #(
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-warning
                   text     = |{ lv_row_msg } (PO={ lv_ebeln }, Item={ lv_ebelp })|
                 )
        ) TO reported-zi_p2_poitem.
      ENDIF.

      "Collect keys for existence check
      APPEND VALUE #( ebeln = lv_ebeln ebelp = lv_ebelp ) TO lt_keys.

      "Store EVERY row (valid or invalid) so it appears in list report
      APPEND VALUE #(
        Po        = lv_ebeln
        Item      = lv_ebelp
        Amount    = lv_amount
        Reference = lv_ref

        Currency = lv_curr
        Error     = lv_err
        ErrorMsg  = lv_row_msg

        %control-Amount    = if_abap_behv=>mk-on
        %control-Reference = if_abap_behv=>mk-on
        %control-Currency     = if_abap_behv=>mk-on
        %control-Error     = if_abap_behv=>mk-on
        %control-ErrorMsg  = if_abap_behv=>mk-on
      ) TO lt_create.

      APPEND VALUE z_upload_res(
  ebeln     = lv_ebeln
  ebelp     = lv_ebelp
  amount    = lv_amount
  currency  = lv_curr
  reference = lv_ref
  error     = lv_err
  error_msg = lv_row_msg
) TO lt_upload_res.

    ENDLOOP.

    IF lt_create IS INITIAL.
      APPEND VALUE #(
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'No rows found in CSV.'
               )
      ) TO reported-zi_p2_poitem.
      RETURN.
    ENDIF.

    "------------------------------------------------------------
    "5) Existence check (for UPSERT behavior)
    "------------------------------------------------------------
    SORT lt_keys BY ebeln ebelp.
    DELETE ADJACENT DUPLICATES FROM lt_keys COMPARING ebeln ebelp.

    DATA lt_existing TYPE SORTED TABLE OF ty_key WITH UNIQUE KEY ebeln ebelp.

    SELECT ebeln, ebelp
      FROM zp2_t_poitem
      FOR ALL ENTRIES IN @lt_keys
      WHERE ebeln = @lt_keys-ebeln
        AND ebelp = @lt_keys-ebelp
      INTO TABLE @lt_existing.

    "Split into create/update
    DATA lt_create_final TYPE TABLE FOR CREATE ZI_P2_POITEM.
    DATA lt_update_final TYPE TABLE FOR UPDATE ZI_P2_POITEM.

    LOOP AT lt_create INTO DATA(ls_any).
      READ TABLE lt_existing WITH KEY ebeln = ls_any-Po ebelp = ls_any-Item TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        "UPDATE existing (include errors too)
        APPEND VALUE #(
          Po        = ls_any-Po
          Item      = ls_any-Item
          Amount    = ls_any-Amount
          Reference = ls_any-Reference
          Currency = ls_any-Currency
          Error     = ls_any-Error
          ErrorMsg  = ls_any-ErrorMsg
          %control-Amount    = if_abap_behv=>mk-on
          %control-Reference = if_abap_behv=>mk-on
          %control-Currency     = if_abap_behv=>mk-on
          %control-Error     = if_abap_behv=>mk-on
          %control-ErrorMsg  = if_abap_behv=>mk-on
        ) TO lt_update_final.
      ELSE.
        "CREATE new
        APPEND ls_any TO lt_create_final.
      ENDIF.
    ENDLOOP.

    "------------------------------------------------------------
    "6) Execute EML (use AUTO FILL CID to avoid MISSING_CID dump)
    "------------------------------------------------------------
    IF lt_create_final IS NOT INITIAL.
      "Avoid duplicate creates inside one request
      SORT lt_create_final BY Po Item.
      DELETE ADJACENT DUPLICATES FROM lt_create_final COMPARING Po Item.

*      MODIFY ENTITIES OF ZI_P2_POITEM IN LOCAL MODE
*        ENTITY zi_p2_poitem
*        CREATE AUTO FILL CID
*        wITH lt_create_final
*        FAILED   DATA(lt_failed_c)
*        REPORTED DATA(lt_reported_c)
*        MAPPED   DATA(lt_mapped_c).

         "Create entries into DOA table using lt_create
      MODIFY ENTITIES OF ZI_P2_POITEM IN LOCAL MODE
        ENTITY zi_p2_poitem
*                     CREATE  AUTO FILL CID WITH
            CREATE FROM
                      VALUE #(  FOR lwa_insert IN lt_create (
                                                          %CID = | { lwa_insert-Po }{ lwa_insert-Item } |
                                                          %key = lwa_insert-%key
                                                           Po        = lwa_insert-Po
          Item      = lwa_insert-Item
          Amount    = lwa_insert-Amount
          Reference = lwa_insert-Reference
          Currency = lwa_insert-Currency
          Error     = lwa_insert-Error
          ErrorMsg  = lwa_insert-ErrorMsg
          %control-Po    = if_abap_behv=>mk-on
          %control-Item = if_abap_behv=>mk-on
          %control-Amount    = if_abap_behv=>mk-on
          %control-Reference = if_abap_behv=>mk-on
          %control-Currency     = if_abap_behv=>mk-on
          %control-Error     = if_abap_behv=>mk-on
          %control-ErrorMsg  = if_abap_behv=>mk-on
                                                            ) )

                     MAPPED DATA(lt_mapped_status)
                     REPORTED DATA(lt_reported_status)
                     FAILED DATA(lt_failed_status).

        READ ENTITIES OF ZI_P2_POITEM IN LOCAL MODE
        ENTITY zi_p2_poitem
        ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).


        if lt_mapped_status is not inITIAL.
*
*        result = CORRESPONDING #( lt_mapped_status-zi_p2_poitem MAPPING %cid = %cid
*                                                            %param = value #( ebeln =  ) )
*          loop at lt_mapped_status aSSIGNING fIELD-SYMBOL(<fs_map>).
*
*          endLOOP.
*            appeND vaLUE #( )
        endIF.
          ENDIF.

    IF lt_update_final IS NOT INITIAL.
      MODIFY ENTITIES OF ZI_P2_POITEM IN LOCAL MODE
        ENTITY zi_p2_poitem
        UPDATE FROM lt_update_final
        FAILED   DATA(lt_failed_u)
        REPORTED DATA(lt_reported_u).
    ENDIF.

    "------------------------------------------------------------
    "7) Summary message
    "------------------------------------------------------------
    DATA(lv_err_cnt) = REDUCE i(
      INIT x = 0
      FOR r IN lt_create
      NEXT x = x + COND i( WHEN r-Error = abap_true THEN 1 ELSE 0 )
    ).

    APPEND VALUE #(
      %msg = new_message_with_text(
               severity = COND #( WHEN lv_err_cnt > 0
                                  THEN if_abap_behv_message=>severity-warning
                                  ELSE if_abap_behv_message=>severity-success )
               text = |CSV done. Total { lines( lt_create ) }, Errors { lv_err_cnt }. Check ErrorMsg column.|
             )
    ) TO reported-zi_p2_poitem.

    result = VALUE #( FOR res IN lt_upload_res
                  ( %param = res ) ).
endmETHOD.


  METHOD calcStockAmountDeep.
    DATA amount TYPE i.
    DATA lt_productuuid TYPE STANDARD TABLE OF ty_key.

    "get product keys
    LOOP AT keys INTO DATA(key).
      LOOP AT key-%param-_product INTO DATA(product).
        APPEND VALUE #( ebeln = product-ebeln
                        ebelp = product-ebelp
                        is_draft = SWITCH #( product-isActiveEntity
                                              WHEN abap_true THEN if_abap_behv=>mk-off
                                                             ELSE if_abap_behv=>mk-on ) ) TO lt_productuuid.
      ENDLOOP.
    ENDLOOP.

    READ ENTITIES OF zi_p2_poitem IN LOCAL MODE
      ENTITY zi_p2_poitem
      FIELDS ( Amount )
      WITH VALUE #( FOR data IN lt_productuuid (
          %tky = VALUE #( Po = data-ebeln
                          Item = data-ebelp
                          %is_draft = data-is_draft ) ) )
      RESULT DATA(stock_t).

    " calculate stock amount
    LOOP AT stock_t INTO DATA(stock).
      amount = amount + stock-Amount.
    ENDLOOP.

    " return result
    result = VALUE #( FOR key1 IN keys (
                       %cid = key1-%cid
                       %param =  VALUE #( amount = amount )
                     ) ).

  ENDMETHOD.

ENDCLASS.
