@EndUserText.label: 'Deep Parameter for Products'
define abstract entity ZA_PRODUCT_TABLE
{
  ebeln             : ebeln;
  ebelp             : ebelp;
  isActiveEntity: abap_boolean;
  
  _root: association to parent ZA_PRODUCT_ROOT;
}
