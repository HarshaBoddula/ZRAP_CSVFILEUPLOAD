@EndUserText.label: 'Abs. Entity For Attachment'
define root abstract entity Z_FILE_STREAM
{
  @Semantics.largeObject.mimeType: 'MimeType'
  @Semantics.largeObject.fileName: 'FileName'
  @Semantics.largeObject.contentDispositionPreference: #INLINE
  @EndUserText.label: 'Select CSV File'
  StreamProperty : abap.string;
  
  @UI.hidden: true
  MimeType : abap.char(128);
  
  @UI.hidden: true
  FileName : abap.char(128);   
}
