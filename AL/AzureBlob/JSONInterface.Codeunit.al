codeunit 60209 "Azure Blob JSON Interface"
{
    TableNo = TempBlob;

    trigger OnRun()
    var
        Tempblob: Record TempBlob;
        BlobList: Record "Azure Blob List" temporary;
        GetBlob: Codeunit "Get Azure Blob";
        PutBlob: Codeunit "Put Azure Blob";
        DeleteBlob: Codeunit "Delete Azure Blob";
        JObject: JsonObject;
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        ContainerUrl: Text;
        BlobUrl: Text;
        FileName: Text;
    begin
        ReadJSON(Rec, JObject);
        ReadConfiguration(JObject, AccountName, AccountContainer, AccountPrivateKey);
        case GetJSONValue(JObject, 'Method') of
            'GetBlob':
                begin
                    BlobUrl := GetJSONValue(JObject, 'Url');
                    Clear(JObject);
                    JObject.Add('Content-Length', GetBlob.GetBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, BlobUrl));
                    JObject.Add('Content', TempBlob.ToBase64String());
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            'PutBlob':
                begin
                    FileName := GetJSONValue(JObject, 'FileName');
                    Tempblob.FromBase64String(GetJSONValue(JObject, 'Content'));
                    Clear(JObject);
                    JObject.Add('Url', PutBlob.PutBlob(Tempblob, AccountName, AccountContainer, AccountPrivateKey, FileName));
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            'DeleteBlob':
                begin
                    BlobUrl := GetJSONValue(JObject, 'Url');
                    Clear(JObject);
                    DeleteBlob.DeleteBlob(AccountName, AccountContainer, AccountPrivateKey, BlobUrl);
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            'ListBlob':
                begin
                    BlobList.ReadBlobList(AccountName, AccountContainer, AccountPrivateKey);
                    Clear(JObject);
                    BlobList.WriteToJObject('https://' + AccountName + '.blob.core.windows.net/' + AccountContainer + '/', JObject);
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            else
                Init();
        end;
    end;

    local procedure ReadJSON(TempBlob: Record Tempblob; var JObject: JsonObject)
    begin
        JObject.ReadFrom(TempBlob.ReadAsTextWithCRLFLineSeparator());
    end;

    local procedure GetJSONValue(JObject: JsonObject; JPath: Text): Text;
    var
        JToken: JsonToken;
    begin
        if JObject.Get(JPath, JToken) then
            exit(JToken.AsValue().AsText());
    end;

    local procedure ReadConfiguration(JObject: JsonObject; var AccountName: Text; var AccountContainer: Text; var AccountPrivateKey: Text)
    begin
        AccountName := GetJSONValue(JObject, 'Name');
        AccountContainer := GetJSONValue(JObject, 'Container');
        AccountPrivateKey := GetJSONValue(JObject, 'PrivateKey')
    end;

    local procedure WriteJSON(JObject: JsonObject; var TempBlob: Record Tempblob)
    var
        JSON: Text;
    begin
        JObject.WriteTo(JSON);
        TempBlob.WriteAsText(JSON, TextEncoding::UTF8);
    end;

}