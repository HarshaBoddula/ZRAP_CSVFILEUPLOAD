@EndUserText.label: 'Upload Result'
@Metadata.allowExtensions: true
define abstract entity Z_UPLOAD_RES
{
  ebeln             : ebeln;
  ebelp             : ebelp;
  @Semantics.amount.currencyCode: 'currency'
  amount                : wrbtr;
  currency              : waers;
  reference             : abap.char(50);
  error                 : abap_boolean;
  error_msg             : char256;
}
