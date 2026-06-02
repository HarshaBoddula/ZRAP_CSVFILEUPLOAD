@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'POC - PO Item Root'
//@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_P2_POITEM as select from zp2_t_poitem
{
    key ebeln as Po,
    key ebelp as Item,
    amount as Amount,
    currency as Currency,
    reference as Reference,
    error as Error,
    error_msg as ErrorMsg,
    local_created_by as LocalCreatedBy,
    local_created_at as LocalCreatedAt,
    local_last_changed_by as LocalLastChangedBy,
    local_last_changed_at as LocalLastChangedAt,
    last_changed_at as LastChangedAt
}
