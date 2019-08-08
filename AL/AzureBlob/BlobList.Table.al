table 60200 "Azure Blob List"
{
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; Name; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Name';
        }
        field(2; "Last Modified"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Modified';
        }
        field(3; "E-Tag"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'E-Tag';
        }
        field(4; "Content Length"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Content Length';
        }
        field(5; "Content Type"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Content Type';
        }
        field(6; "Blob Type"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Blob Type';
        }
        field(7; "Lease Status"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Lease Status';
        }
        field(8; "Lease State"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Lease State';
        }
    }

    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }

    var
        RecordNotTemporaryErr: Label 'Table %1 can only be used as a temporary storage!';

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    procedure ReadBlobList(AccountName: Text; AccountContainer: Text; AccountPrivateKey: Text)
    var
        ListAzureBlob: Codeunit "List Azure Blob";
        NextMarker: Text;
        Xml: XmlDocument;
    begin
        if not IsTemporary() then
            error(RecordNotTemporaryErr, TableCaption);
        DeleteAll();
        Xml := ListAzureBlob.ListBlob(AccountName, AccountContainer, AccountPrivateKey, NextMarker);
        NextMarker := ReadXml(Xml);
        while NextMarker <> '' do begin
            Xml := ListAzureBlob.ListBlob(AccountName, AccountContainer, AccountPrivateKey, NextMarker);
            NextMarker := ReadXml(Xml);
        end;
    end;

    procedure ReadXml(Xml: XmlDocument) NextMarker: Text
    var
        NodeMgt: Codeunit "Azure Blob Node Mgt.";
        RecRef: RecordRef;
        BlobNodeList: XmlNodeList;
        BlobNode: XmlNode;
        BlobPropertiesNode: XmlNode;
    begin
        if not IsTemporary() then
            error(RecordNotTemporaryErr, TableCaption);
        if not Xml.SelectNodes(NodeMgt.GetNodeXPath('Blob'), BlobNodeList) then exit('');
        RecRef.GetTable(Rec);
        foreach BlobNode in BlobNodeList do begin
            RecRef.Init();
            NodeMgt.SetFieldValue(RecRef, FieldNo(Name), BlobNode, 'Name');
            if BlobNode.SelectSingleNode(NodeMgt.GetChildNodeXPath('Properties'), BlobPropertiesNode) then begin
                NodeMgt.SetFieldValue(RecRef, FieldNo("Last Modified"), BlobPropertiesNode, 'Last-Modified');
                NodeMgt.SetFieldValue(RecRef, FieldNo("E-Tag"), BlobPropertiesNode, 'Etag');
                NodeMgt.SetFieldValue(RecRef, FieldNo("Content Length"), BlobPropertiesNode, 'Content-Length');
                NodeMgt.SetFieldValue(RecRef, FieldNo("Content Type"), BlobPropertiesNode, 'Content-Type');
                NodeMgt.SetFieldValue(RecRef, FieldNo("Blob Type"), BlobPropertiesNode, 'BlobType');
                NodeMgt.SetFieldValue(RecRef, FieldNo("Lease Status"), BlobPropertiesNode, 'LeaseStatus');
                NodeMgt.SetFieldValue(RecRef, FieldNo("Lease State"), BlobPropertiesNode, 'LeaseState');
            end;
            RecRef.Insert();
        end;
        if Xml.SelectSingleNode(NodeMgt.GetNodeXPath('Marker'), BlobNode) then
            NextMarker := BlobNode.AsXmlElement().InnerText();
    end;

    procedure WriteToJObject(ContainerUrl: Text; var JObject: JsonObject)
    var
        JArray: JsonArray;
        BlobObject: JsonObject;
    begin
        if FindSet() then
            repeat
                Clear(BlobObject);
                BlobObject.Add('Path', ContainerUrl + Name);
                BlobObject.Add('Name', Name);
                BlobObject.Add('Size', "Content Length");
                BlobObject.Add('Date', DT2Date("Last Modified"));
                BlobObject.Add('Time', DT2Time("Last Modified"));
                JArray.Add(BlobObject);
            until Next() = 0;
        JObject.Add('List', JArray);
    end;
}