page 50000 "Azure Blob List"
{
    ApplicationArea = All;
    Caption = 'Azure Blob List';
    PageType = ListPlus;
    SourceTable = "Azure Blob List";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Lists;
    SaveValues = true;
    DataCaptionExpression = '';

    layout
    {
        area(content)
        {
            group(Container)
            {
                Caption = 'Container';
                field(AccountNameField; AccountName)
                {
                    ShowMandatory = true;
                    Caption = 'Account Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Account Name in the Azure Storage Account.';
                }
                field(ContainerNameField; ContainerName)
                {
                    ShowMandatory = true;
                    Caption = 'Container Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Container Name in the Azure Storage Account.';
                }
                field(AccessKey; AccessKey)
                {
                    ShowMandatory = true;
                    Caption = 'Access Key';
                    ExtendedDatatype = Masked;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Access Key in the Azure Storage Account.';
                }

            }
            repeater(General)
            {
                Editable = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Name field';
                }
                field("Last Modified"; Rec."Last Modified")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Last Modified field';
                }
                field("E-Tag"; Rec."E-Tag")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the E-Tag field';
                }
                field("Content Length"; Rec."Content Length")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Content Length field';
                }
                field("Content Type"; Rec."Content Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Content Type field';
                }
                field("Blob Type"; Rec."Blob Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Blob Type field';
                }
                field("Lease Status"; Rec."Lease Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Lease Status field';
                }
                field("Lease State"; Rec."Lease State")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Lease State field';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetList)
            {
                Caption = 'Get List';
                ApplicationArea = All;
                ToolTip = 'Download the blob list from azure storage.';
                Image = EntriesList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Page;
                trigger OnAction()
                begin
                    if not IsSetupOK() then
                        Error(ContainerErr);
                    Rec.DeleteAll();
                    Rec.ReadBlobList(AccountName, ContainerName, AccessKey);
                    CurrPage.Update(false);
                end;
            }
            action(Download)
            {
                Caption = 'Download File';
                ApplicationArea = All;
                ToolTip = 'Download the selected blob from azure storage.';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    GetBlob: Codeunit "Get Azure Blob";
                    FileMgt: Codeunit "File Management";
                begin
                    Rec.TestField(Name);
                    if GetBlob.GetBlob(TempBlob, AccountName, ContainerName, AccessKey, 'https://' + AccountName + '.blob.core.windows.net/' + ContainerName + '/' + Rec.Name) > 0 then
                        FileMgt.BLOBExport(TempBlob, Rec.Name, true)
                    else
                        Error(UnableToDownloadErr);
                end;
            }
            action(Upload)
            {
                Caption = 'Upload File';
                ApplicationArea = All;
                ToolTip = 'Upload the selected blob from azure storage.';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    PutBlob: Codeunit "Put Azure Blob";
                    FileMgt: Codeunit "File Management";
                    FileName: Text;
                begin
                    FileName := FileMgt.BLOBImport(TempBlob, '');
                    if TempBlob.HasValue() then
                        if PutBlob.PutBlob(TempBlob, AccountName, ContainerName, AccessKey, FileName) = '' then
                            Error(UnableToUploadErr)
                        else begin
                            Rec.DeleteAll();
                            Rec.ReadBlobList(AccountName, ContainerName, AccessKey);
                            if Rec.Get(FileName) then;
                            CurrPage.Update(false);
                        end;
                end;
            }
            action(Delete)
            {
                Caption = 'Delete File';
                ApplicationArea = All;
                ToolTip = 'Delete the selected blob from azure storage.';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                trigger OnAction()
                var
                    DeleteBlob: Codeunit "Delete Azure Blob";
                begin
                    DeleteBlob.DeleteBlob(AccountName, ContainerName, AccessKey, 'https://' + AccountName + '.blob.core.windows.net/' + ContainerName + '/' + Rec.Name);
                    Rec.Delete();
                    CurrPage.Update(false);
                end;
            }
        }

    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            Rec.Insert();
    end;

    local procedure IsSetupOK(): Boolean
    begin
        exit((AccountName <> '') and (ContainerName <> '') and (AccessKey <> ''));
    end;

    var
        ContainerErr: Label 'Access to the container has not been completed.';
        UnableToDownloadErr: Label 'Unable to download file from azure storage.';
        UnableToUploadErr: Label 'Unable to upload file to azure storage.';
        AccountName: Text;
        ContainerName: Text;
        AccessKey: Text;
}
