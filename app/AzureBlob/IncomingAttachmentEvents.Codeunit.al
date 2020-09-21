codeunit 50000 "O4N Inc. Doc. Attach. Events"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnAttachBinaryFile', '', false, false)]
    local procedure OnAttachBinaryFile(var sender: Record "Incoming Document Attachment")
    var
        PutBlob: Codeunit "Put Azure Blob";
        TempBlob: Codeunit "Temp Blob";
        FileNameMgt: Codeunit "Azure Blob File Name Mgt.";
        FileName: Text;
        BlobUrl: Text;
    begin
        // Content is already populated in the Sender.
        TempBlob.FromRecord(sender, sender.FieldNo(Content));
        FileName := FileNameMgt.GetRandomFileName(TempBlob, sender."File Extension");
        BlobUrl := PutBlob.PutBlob(TempBlob, 'bcazureblob', 'azureblobdemo', 'FMBt0KwY/RDJL6QT9MGjh5ODLCXjSV2UtGwYsjukAVVeRXMEfvgvUiN+PCJRcFqKDON4VSGTRv/00PSA2AxSiw==', FileName);
        sender.O4NWriteURLasContent(BlobUrl);
        sender."O4N Content is URL" := true;
        sender.Modify();
        Message('Attachment stored in Azure Blob');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnGetBinaryContent', '', false, false)]
    local procedure OnGetBinaryContent(var sender: Record "Incoming Document Attachment"; var TempBlob: Codeunit "Temp Blob")
    var
        ActivityLog: Record "Activity Log";
        GetBlob: Codeunit "Get Azure Blob";
        BlobUrl: Text;
    begin
        if not sender."O4N Content is URL" then exit;
        ActivityLog.LogActivity(sender, ActivityLog.Status::Success, 'Download Blob', '', '');
        BlobUrl := sender.O4NGetURLfromContent();
        if GetBlob.GetBlob(TempBlob, 'bcazureblob', 'azureblobdemo', 'FMBt0KwY/RDJL6QT9MGjh5ODLCXjSV2UtGwYsjukAVVeRXMEfvgvUiN+PCJRcFqKDON4VSGTRv/00PSA2AxSiw==', BlobUrl) > 0 then
            Message('Downloaded content from Azure Blob');
    end;
}