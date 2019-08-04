codeunit 60206 "Download Blob"
{
    procedure DownloadDemoBlob(Url: Text; var TempBlob: Record Tempblob): Boolean
    var
        WebResponse: HttpResponseMessage;
        WebClient: HttpClient;
        OutStr: OutStream;
        InStr: InStream;
    begin
        WebClient.Get(url, WebResponse);
        if not WebResponse.IsSuccessStatusCode then
            error(WebResponse.ReasonPhrase);
        CreateResponseStream(InStr);
        TempBlob.Blob.CreateOutStream(OutStr);
        WebResponse.Content.ReadAs(InStr);
        CopyStream(OutStr, InStr);
    end;

    local procedure CreateResponseStream(var InStr: Instream)
    var
        TempBlob: Record TempBlob;
    begin
        TempBlob.Blob.CreateInStream(InStr);
    end;
}