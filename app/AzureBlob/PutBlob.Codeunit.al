codeunit 60204 "Put Azure Blob"
{
    procedure PutBlob(VAR TempBlob: Codeunit "Temp Blob"; AccountName: Text; AccountContainer: Text; AccountAccessKey: Text; FileName: Text) BlobUrl: Text
    var
        HMACSHA256Mgt: Codeunit "Azure Blob HMACSHA256 Mgt.";
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
        if not TempBlob.HasValue() then exit('');

        Initialize(AccountName);

        FileName := FileMgt.GetSafeFileName(FileName);
        BlobUrl := AccountContainer + '/' + FileName;

        CanonicalizedHeaders := 'x-ms-blob-content-disposition:attachment; filename="' + FileName + '"' + NewLine + 'x-ms-blob-type:BlockBlob' + NewLine + 'x-ms-date:' + UTCDateTimeText + NewLine + 'x-ms-version:2015-02-21';
        CanonicalizedResource := StrSubstNo('/%1/%2', AccountName, BlobUrl);
        Authorization := HMACSHA256Mgt.GetAuthorization(AccountName, AccountAccessKey, HMACSHA256Mgt.GetTextToHash('PUT', FileMgt.GetFileNameMimeType(FileName), CanonicalizedHeaders, CanonicalizedResource, Format(TempBlob.Length, 0, 9)));

        WebRequest.SetRequestUri(StorageAccountUrl + BlobUrl);
        WebRequest.Method('PUT');
        TempBlob.CreateInStream(InStr);
        WebContent.WriteFrom(InStr);
        WebContent.GetHeaders(WebHeaders);
        WebHeaders.Clear();
        WebHeaders.Add('Content-Type', FileMgt.GetFileNameMimeType(FileName));
        WebHeaders.Add('Content-Length', Format(TempBlob.Length, 0, 9));
        WebRequest.Content := WebContent;
        WebRequest.GetHeaders(WebHeaders);
        WebHeaders.Add('Authorization', Authorization);
        WebHeaders.Add('x-ms-blob-content-disposition', 'attachment; filename="' + FileName + '"');
        WebHeaders.Add('x-ms-blob-type', 'BlockBlob');
        WebHeaders.Add('x-ms-date', UTCDateTimeText);
        WebHeaders.Add('x-ms-version', '2015-02-21');
        WebClient.Send(WebRequest, WebResponse);
        if not WebResponse.IsSuccessStatusCode then
            error(FailedToGetBlobErr + WebResponse.ReasonPhrase);
        exit(StorageAccountUrl + BlobUrl);
    end;

    local procedure Initialize(AccountName: Text)
    var
        UTCDateTimeMgt: Codeunit "Azure Blob UTC DateTime Mgt.";
    begin
        NewLine[1] := 10;
        UTCDateTimeText := UTCDateTimeMgt.GetUTCDateTimeText();
        StorageAccountUrl := 'https://' + AccountName + '.blob.core.windows.net/';
    end;

    var
        FailedToGetBlobErr: Label 'Failed to upload to blob: ';
        UTCDateTimeText: Text;
        StorageAccountUrl: Text;
        NewLine: Text[1];
}