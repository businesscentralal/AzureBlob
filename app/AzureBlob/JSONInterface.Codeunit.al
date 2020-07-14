codeunit 60209 "Azure Blob JSON Interface"
{
    TableNo = "Name/Value Buffer";

    trigger OnRun()
    var
        Tempblob: Codeunit "Temp Blob";
        BlobList: Record "Azure Blob List" temporary;
        GetBlob: Codeunit "Get Azure Blob";
        PutBlob: Codeunit "Put Azure Blob";
        DeleteBlob: Codeunit "Delete Azure Blob";
        Base64: Codeunit "Base64 Convert";
        JObject: JsonObject;
        InStr: InStream;
        OutStr: OutStream;
        AccountName: Text;
        AccountContainer: Text;
        AccountAccessKey: Text;
        ContainerUrl: Text;
        BlobUrl: Text;
        FileName: Text;
    begin
        ReadJSON(Rec, JObject);
        ReadConfiguration(JObject, AccountName, AccountContainer, AccountAccessKey);
        case GetJSONValue(JObject, 'Method') of
            'GetBlob':
                begin
                    BlobUrl := GetJSONValue(JObject, 'Url');
                    Clear(JObject);
                    JObject.Add('Content-Length', GetBlob.GetBlob(TempBlob, AccountName, AccountContainer, AccountAccessKey, BlobUrl));
                    Tempblob.CreateInStream(InStr);
                    JObject.Add('Content', Base64.ToBase64(InStr));
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            'PutBlob':
                begin
                    FileName := GetJSONValue(JObject, 'FileName');
                    Tempblob.CreateOutStream(OutStr);
                    Base64.FromBase64(GetJSONValue(JObject, 'Content'), OutStr);
                    Clear(JObject);
                    JObject.Add('Url', PutBlob.PutBlob(Tempblob, AccountName, AccountContainer, AccountAccessKey, FileName));
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            'DeleteBlob':
                begin
                    BlobUrl := GetJSONValue(JObject, 'Url');
                    Clear(JObject);
                    DeleteBlob.DeleteBlob(AccountName, AccountContainer, AccountAccessKey, BlobUrl);
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            'ListBlob':
                begin
                    BlobList.ReadBlobList(AccountName, AccountContainer, AccountAccessKey);
                    Clear(JObject);
                    BlobList.WriteToJObject('https://' + AccountName + '.blob.core.windows.net/' + AccountContainer + '/', JObject);
                    JObject.Add('Success', true);
                    WriteJSON(JObject, Rec);
                end;
            else
                Init();
        end;
    end;

    local procedure ReadJSON(var Buffer: Record "Name/Value Buffer"; var JObject: JsonObject)
    begin
        JObject.ReadFrom(Buffer.GetValue());
    end;

    local procedure GetJSONValue(JObject: JsonObject; JPath: Text): Text;
    var
        JToken: JsonToken;
    begin
        if JObject.Get(JPath, JToken) then
            exit(JToken.AsValue().AsText());
    end;

    local procedure ReadConfiguration(JObject: JsonObject; var AccountName: Text; var AccountContainer: Text; var AccountAccessKey: Text)
    begin
        AccountName := GetJSONValue(JObject, 'Name');
        AccountContainer := GetJSONValue(JObject, 'Container');
        AccountAccessKey := GetJSONValue(JObject, 'AccessKey')
    end;

    local procedure WriteJSON(JObject: JsonObject; var Buffer: Record "Name/Value Buffer")
    var
        JSON: Text;
    begin
        JObject.WriteTo(JSON);
        Buffer.SetValue(JSON);
    end;

}