codeunit 60202 "List Azure Blob"
{
    procedure ListBlob(AccountName: Text; AccountContainer: Text; AccountPrivateKey: Text; Marker: Text) Xml: XmlDocument
    var
        HMACSHA256Mgt: Codeunit "HMACSHA256 Management";
        WebRequest: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        WebContent: HttpContent;
        WebHeaders: HttpHeaders;
        WebClient: HttpClient;
        InStr: InStream;
        CanonicalizedHeaders: Text;
        CanonicalizedResource: Text;
        Authorization: Text;
        ResponseXml: Text;
    begin
        Initialize(AccountName);

        CanonicalizedHeaders := 'x-ms-date:' + UTCDateTimeText + NewLine + 'x-ms-version:2015-02-21';
        CanonicalizedResource := StrSubstNo('/%1/%2', AccountName, AccountContainer) + NewLine + 'comp:list' + NewLine + 'marker:' + Marker + NewLine + 'restype:container';
        Authorization := HMACSHA256Mgt.GetAuthorization(AccountName, AccountPrivateKey, HMACSHA256Mgt.GetTextToHash('GET', '', CanonicalizedHeaders, CanonicalizedResource, ''));

        WebRequest.SetRequestUri(StorageAccountUrl + AccountContainer + StrSubstNo('?restype=container&comp=list&marker=%1', Marker));
        WebRequest.Method('GET');
        WebRequest.GetHeaders(WebHeaders);
        WebHeaders.Add('Authorization', Authorization);
        WebHeaders.Add('x-ms-date', UTCDateTimeText);
        WebHeaders.Add('x-ms-version', '2015-02-21');
        WebClient.Send(WebRequest, WebResponse);
        if not WebResponse.IsSuccessStatusCode then
            error(FailedToGetBlobErr + WebResponse.ReasonPhrase);
        WebContent := WebResponse.Content;
        CreateResponseStream(InStr);
        WebContent.ReadAs(ResponseXml);
        XmlDocument.ReadFrom(ResponseXml, Xml);
    end;

    local procedure CreateResponseStream(var InStr: Instream)
    var
        TempBlob: Record TempBlob;
    begin
        TempBlob.Blob.CreateInStream(InStr);
    end;

    local procedure Initialize(AccountName: Text)
    var
        UTCDateTimeMgt: Codeunit "UTC DateTime Management";
    begin
        NewLine[1] := 10;
        UTCDateTimeText := UTCDateTimeMgt.GetUTCDateTimeText();
        StorageAccountUrl := 'https://' + AccountName + '.blob.core.windows.net/';
    end;

    var
        FailedToGetBlobErr: Label 'Failed to download a blob: ';
        UrlIncorrectErr: Label 'Url incorrect.';
        UTCDateTimeText: Text;
        StorageAccountUrl: Text;
        NewLine: Text[1];
}