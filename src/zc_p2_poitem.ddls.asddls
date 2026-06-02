@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'POC - PO Item (Consumption)'
//@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_P2_POITEM
  provider contract transactional_query as projection on ZI_P2_POITEM
{
    key Po,
    key Item,
    Amount,
    Currency,
    Reference,
    Error,
    ErrorMsg,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt
}
