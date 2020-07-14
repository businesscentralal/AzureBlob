codeunit 60206 "Download Blob"
{
    procedure DownloadDemoBlob(Url: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
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
        TempBlob.CreateOutStream(OutStr);
        WebResponse.Content.ReadAs(InStr);
        CopyStream(OutStr, InStr);
    end;

    local procedure CreateResponseStream(var InStr: Instream)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.CreateInStream(InStr);
    end;
}