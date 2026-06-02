@EndUserText.label: 'Deep Parameter Root'
define root abstract entity ZA_PRODUCT_ROOT
{
    dummy: abap.char(1); 
    _product : composition [0..*] of ZA_PRODUCT_TABLE;
}
