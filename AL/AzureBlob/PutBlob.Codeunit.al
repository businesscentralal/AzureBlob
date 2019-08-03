codeunit 60204 "Put Azure Blob"
{
    procedure PutBlob(VAR TempBlob: Record Tempblob temporary; AccountName: Text; AccountContainer: Text; AccountPrivateKey: Text; FileName: Text) BlobUrl: Text
    var
        HMACSHA256Mgt: Codeunit "HMACSHA256 Management";
        StringConvertionMgt: Codeunit StringConversionManagement;
        FileMgt: Codeunit "File Management";
        WebRequest: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        WebContent: HttpContent;
        WebHeaders: HttpHeaders;
        WebClient: HttpClient;
        InStr: InStream;
        CanonicalizedHeaders: Text;
        CanonicalizedResource: Text;
        Authorization: Text;
    begin
        Initialize(AccountName);
        BlobUrl := AccountContainer + '/' + GetRandomFileName(TempBlob, FileName);
        FileName := StringConvertionMgt.RemoveNonAlphaNumericCharacters(FileMgt.GetFileNameWithoutExtension(FileName)) + '.' + StringConvertionMgt.RemoveNonAlphaNumericCharacters(FileMgt.GetExtension(FileName));

        CanonicalizedHeaders := 'x-ms-blob-content-disposition:attachment; filename="' + FileName + '"' + NewLine + 'x-ms-blob-type:BlockBlob' + NewLine + 'x-ms-date:' + UTCDateTimeText + NewLine + 'x-ms-version:2015-02-21';
        CanonicalizedResource := StrSubstNo('/%1/%2', AccountName, BlobUrl);
        Authorization := HMACSHA256Mgt.GetAuthorization(AccountName, AccountPrivateKey, HMACSHA256Mgt.GetTextToHash('PUT', FileMgt.GetFileNameMimeType(FileName), CanonicalizedHeaders, CanonicalizedResource, Format(TempBlob.Blob.Length)));

        WebRequest.SetRequestUri(ContainerUrl + BlobUrl);
        WebRequest.Method('PUT');
        TempBlob.Blob.CreateInStream(InStr);
        WebRequest.Content.ReadAs(InStr);
        WebRequest.GetHeaders(WebHeaders);
        WebHeaders.Add('Authorization', Authorization);
        WebHeaders.Add('x-ms-blob-content-disposition', 'attachment; filename="' + FileName + '"');
        WebHeaders.Add('x-ms-blob-type', 'BlockBlob');
        WebHeaders.Add('x-ms-date', UTCDateTimeText);
        WebHeaders.Add('x-ms-version', '2015-02-21');
        WebClient.Send(WebRequest, WebResponse);
        if not WebResponse.IsSuccessStatusCode then
            error(FailedToGetBlobErr + WebResponse.ReasonPhrase);
        exit(ContainerUrl + BlobUrl);
    end;

    local procedure Initialize(AccountName: Text)
    var
        UTCDateTimeMgt: Codeunit "UTC DateTime Management";
    begin
        NewLine[1] := 10;
        UTCDateTimeText := UTCDateTimeMgt.GetUTCDateTimeText();
        ContainerUrl := 'https://' + AccountName + '.blob.core.windows.net/';
    end;

    local procedure GetRandomFileName(TempBlob: Record TempBlob; FileName: Text) RandomFileName: Text
    var
        EncryptionMgt: Codeunit "Encryption Management";
        FileMgt: Codeunit "File Management";
        InStr: InStream;
        HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
    begin
        TempBlob.Blob.CreateInStream(InStr);
        RandomFileName := Format(CreateGuid()).Replace('{-}', '') + EncryptionMgt.GenerateHashFromStream(InStr, HashAlgorithmType::HMACMD5) + '.' + FileMgt.GetExtension(FileName);
    end;

    var
        FailedToGetBlobErr: Label 'Failed to upload to blob: ';
        UrlIncorrectErr: Label 'Url incorrect.';
        UTCDateTimeText: Text;
        ContainerUrl: Text;
        NewLine: Text[1];
}