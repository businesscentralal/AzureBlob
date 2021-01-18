codeunit 60205 "Delete Azure Blob"
{
    procedure DeleteBlob(AccountName: Text; AccountContainer: Text; AccountAccessKey: Text; BlobUrl: Text)
    var
        HMACSHA256Mgt: Codeunit "Azure Blob HMACSHA256 Mgt.";
        TypeHelper: Codeunit "Type Helper";
        WebRequest: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        WebContent: HttpContent;
        WebHeaders: HttpHeaders;
        WebClient: HttpClient;
        OutStr: OutStream;
        InStr: InStream;
        CanonicalizedHeaders: Text;
        CanonicalizedResource: Text;
        Authorization: Text;
    begin
        Initialize(AccountName);
        if StrPos(BlobUrl, StorageAccountUrl) <> 1 then error(FailedToDeleteBlobErr + UrlIncorrectErr);
        BlobUrl := CopyStr(BlobUrl, StrLen(StorageAccountUrl) + 1);
        BlobUrl := TypeHelper.UriEscapeDataString(BlobUrl).Replace('%2F', '/').Replace('%3A', ':');

        CanonicalizedHeaders := 'x-ms-date:' + UTCDateTimeText + NewLine + 'x-ms-version:2015-02-21';
        CanonicalizedResource := StrSubstNo('/%1/%2', AccountName, BlobUrl);
        Authorization := HMACSHA256Mgt.GetAuthorization(AccountName, AccountAccessKey, HMACSHA256Mgt.GetTextToHash('DELETE', '', CanonicalizedHeaders, CanonicalizedResource, ''));

        WebRequest.SetRequestUri(StorageAccountUrl + BlobUrl);
        WebRequest.Method('DELETE');
        WebRequest.GetHeaders(WebHeaders);
        WebHeaders.Add('Authorization', Authorization);
        WebHeaders.Add('x-ms-date', UTCDateTimeText);
        WebHeaders.Add('x-ms-version', '2015-02-21');
        WebClient.Send(WebRequest, WebResponse);
        if not WebResponse.IsSuccessStatusCode then
            error(FailedToDeleteBlobErr + WebResponse.ReasonPhrase);
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
        FailedToDeleteBlobErr: Label 'Failed to delete a blob: ';
        UrlIncorrectErr: Label 'Url incorrect.';
        UTCDateTimeText: Text;
        StorageAccountUrl: Text;
        NewLine: Text[1];
}