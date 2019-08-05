codeunit 60299 "Azure Blob Test"
{
    Subtype = Test;

    [Test]
    procedure VerifyUTCDateParse();
    var
        UTCDateTimeMgt: Codeunit "UTC DateTime Management";
        ExampleDateTime: DateTime;
        ExampleDateTimeText: Text;
    begin
        // [Scenario] Verify UTC Date Parse        
        // [Given] Setup: 
        ExampleDateTimeText := UTCDateTimeMgt.GetUTCDateTimeText();

        // [When] Exercise: 
        ExampleDateTime := UTCDateTimeMgt.ParseUTCDateTimeText(ExampleDateTimeText);

        // [Then] Verify: 
        ExpectedValue := CurrentDateTime();
        ActualValue := ExampleDateTime;
        IfErrorTxt := 'Failed to parse the date time text ' + ExampleDateTimeText;
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure VerifyTextToHash();
    var
        HMACSHA256Mgt: Codeunit "HMACSHA256 Management";
        TextToHash: Text;
        CanonicalizedHeaders: Text;
        CanonicalizedResource: Text;
        NewLine: Text[1];
    begin
        // [Scenario] Verify HMACSHA256 hashing        
        // [Given] Setup: 
        NewLine[1] := 10;
        CanonicalizedHeaders := 'x-ms-date:Fri, 26 Jun 2015 23:39:12 GMT' + NewLine + 'x-ms-version:2015-02-21';
        CanonicalizedResource := '/myaccount/mycontainer' + NewLine + 'restype:container' + NewLine + 'timeout:30';

        // [When] Exercise: 
        TextToHash := HMACSHA256Mgt.GetTextToHash('PUT', '', CanonicalizedHeaders, CanonicalizedResource, '');

        // [Then] Verify: 
        ExpectedValue := 'PUT' + PadStr('', 12, NewLine) + 'x-ms-date:Fri, 26 Jun 2015 23:39:12 GMT' + NewLine + 'x-ms-version:2015-02-21' + NewLine + '/myaccount/mycontainer' + NewLine + 'restype:container' + NewLine + 'timeout:30';
        ActualValue := TextToHash;
        IfErrorTxt := 'Failed to verify the text to hash';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure VerifyHMACSHA256();
    var
        HMACSHA256Mgt: Codeunit "HMACSHA256 Management";
        AccountPrivateKey: Text;
        TextToHash: Text;
        CanonicalizedHeaders: Text;
        CanonicalizedResource: Text;
        Authorization: Text;
        NewLine: Text[1];
    begin
        // [Scenario] Verify HMACSHA256 hashing        
        // [Given] Setup: 
        NewLine[1] := 10;
        CanonicalizedHeaders := 'x-ms-date:Fri, 26 Jun 2015 23:39:12 GMT' + NewLine + 'x-ms-version:2015-02-21';
        CanonicalizedResource := '/myaccount/mycontainer' + NewLine + 'restype:container' + NewLine + 'timeout:30';
        TextToHash := HMACSHA256Mgt.GetTextToHash('PUT', '', CanonicalizedHeaders, CanonicalizedResource, '');
        AccountPrivateKey := 'gcHIfdErQ+k3J8VhB5QSxxl9WzHrrdLc9qVqJ/Fl8RGAhIK2bqCCoGEcVqHvFyFRVOA1YwRygl/BLXKME3T/ag==';

        // [When] Exercise:         
        Authorization := HMACSHA256Mgt.GetAuthorization('myaccount', AccountPrivateKey, TextToHash);

        // [Then] Verify: 
        ExpectedValue := 'SharedKey myaccount:1a6okLAhbXIYLeEed+zlDbHWB48zDbwr7UYz5OgRO8o=';
        ActualValue := Authorization;
        IfErrorTxt := 'Failed to verify the authorization';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure VerifyBlobUpload();
    var
        TempBlob: Record TempBlob;
        DownloadBlob: Codeunit "Download Blob";
        PutAzureBlob: Codeunit "Put Azure Blob";
        FileNameMgt: Codeunit "File Name Management";
        WebRequestHelper: Codeunit "Web Request Helper";
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        FileName: Text;
        BlobUrl: Text;
    begin
        // [Scenario] Upload Image to container

        // [Given] Setup: 
        DownloadBlob.DownloadDemoBlob(AzureBlobLibrary.GetDemoBlobDownloadUrl(), TempBlob);
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();
        FileName := 'Test-' + FileNameMgt.GetRandomFileName(TempBlob, '.jpg');

        // [When] Exercise:      
        BlobUrl := PutAzureBlob.PutBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, FileName);

        // [Then] Verify: 
        ExpectedValue := true;
        ActualValue := WebRequestHelper.IsValidUri(BlobUrl);
        IfErrorTxt := 'Failed to upload jpg image';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure VerifyBlobUpdate();
    var
        TempBlob: Record TempBlob;
        DownloadBlob: Codeunit "Download Blob";
        PutAzureBlob: Codeunit "Put Azure Blob";
        FileNameMgt: Codeunit "File Name Management";
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        FileName: Text;
        BlobUrl1: Text;
        BlobUrl2: Text;
    begin
        // [Scenario] Update already uploaded Image in container

        // [Given] Setup: 
        DownloadBlob.DownloadDemoBlob(AzureBlobLibrary.GetDemoBlobDownloadUrl(), TempBlob);
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();
        FileName := 'Test-' + FileNameMgt.GetRandomFileName(TempBlob, '.jpg');

        // [When] Exercise:      
        BlobUrl1 := PutAzureBlob.PutBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, FileName);
        BlobUrl2 := PutAzureBlob.PutBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, FileName);

        // [Then] Verify: 
        ExpectedValue := BlobUrl1;
        ActualValue := BlobUrl2;
        IfErrorTxt := 'Failed to update blob';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure VerifyBlobDownload();
    var
        TempBlob: Record TempBlob;
        DownloadBlob: Codeunit "Download Blob";
        PutAzureBlob: Codeunit "Put Azure Blob";
        GetAzureBlob: Codeunit "Get Azure Blob";
        FileNameMgt: Codeunit "File Name Management";
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        FileName: Text;
        BlobUrl: Text;
        ContentLength: Integer;
    begin
        // [Scenario] Download Image from // https://365links.blob.core.windows.net/azureblobtest/ANNA_20190215_0003-thumb.jpg

        // [Given] Setup:
        DownloadBlob.DownloadDemoBlob(AzureBlobLibrary.GetDemoBlobDownloadUrl(), TempBlob);
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();
        FileName := 'Test-' + FileNameMgt.GetRandomFileName(TempBlob, '.jpg');

        // [When] Exercise:
        BlobUrl := PutAzureBlob.PutBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, FileName);
        ContentLength := GetAzureBlob.GetBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, BlobUrl);

        // [Then] Verify: 
        ExpectedValue := 114074;
        ActualValue := ContentLength;
        IfErrorTxt := 'Failed to download jpg image';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    [Test]
    procedure VerifyBlobDownloadAuthenticationError();
    var
        TempBlob: Record TempBlob;
        GetAzureBlob: Codeunit "Get Azure Blob";
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        ContentLength: Integer;
    begin
        // [Scenario] Download Image from // https://365links.blob.core.windows.net/azureblobtest/ANNA_20190215_0003-thumb.jpg

        // [Given] Setup: 
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := 'gcHIfdErQ+k3J8VhB5QSxxl9WzHrrdLc9qVqJ/Fl8RGAhIK2bqCCoGEcVqHvFyFRVOA1YwRygl/BLXKME3T/ag==';

        // [When] Exercise:      
        asserterror ContentLength := GetAzureBlob.GetBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, AzureBlobLibrary.GetDemoBlobDownloadUrl());

        // [Then] Verify: 
        ExpectedValue := 'Failed to download a blob: Server failed to authenticate the request. Make sure the value of Authorization header is formed correctly including the signature.';
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'Failed to verify the authentication error';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;


    [Test]
    procedure VerifyBlobDelete();
    var
        TempBlob: Record TempBlob;
        DownloadBlob: Codeunit "Download Blob";
        PutAzureBlob: Codeunit "Put Azure Blob";
        DeleteAzureBlob: Codeunit "Delete Azure Blob";
        FileNameMgt: Codeunit "File Name Management";
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        FileName: Text;
        BlobUrl: Text;
    begin
        // [Scenario] Delete uploaded Image in container

        // [Given] Setup: 
        DownloadBlob.DownloadDemoBlob(AzureBlobLibrary.GetDemoBlobDownloadUrl(), TempBlob);
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();
        FileName := 'Test-' + FileNameMgt.GetRandomFileName(TempBlob, '.jpg');

        // [When] Exercise:      
        BlobUrl := PutAzureBlob.PutBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, FileName);
        DeleteAzureBlob.DeleteBlob(AccountName, AccountContainer, AccountPrivateKey, BlobUrl);
    end;

    [Test]
    procedure VerifyReadBlobListXml()
    var
        BlobList: Record "Azure Blob List" temporary;
        Xml: XmlDocument;
        NextMarker: Text;
    begin
        // [Scenario] Import Demo Xml file into the Blob List table

        // [Given] Setup: 
        XmlDocument.ReadFrom(AzureBlobLibrary.GetDemoBlobList(), Xml);

        // [When] Exercise:
        NextMarker := BlobList.ReadXml(Xml);

        // [Then] Verify NextMarker: 
        ExpectedValue := 'string-value';
        ActualValue := NextMarker;
        IfErrorTxt := 'Failed to verify NextMarker';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [Then] Verify Record Created:
        AssertThat.RecordCount(BlobList, 1);

        // [Then] Verify Record Values:Fri, 26 Jun 2015 23:39:12 GMT
        BlobList.FindFirst();
        AssertThat.AreEqual('blob-name', BlobList.Name, 'Failed to verify Blob List field value');
        AssertThat.AreEqual(CreateDateTime(DMY2Date(26, 06, 2015), 233912T), BlobList."Last Modified", 'Failed to verify Blob List field value');
        AssertThat.AreEqual('blob-content-type', BlobList."Content Type", 'Failed to verify Blob List field value');
        AssertThat.AreEqual(1234, BlobList."Content Length", 'Failed to verify Blob List field value');
        AssertThat.AreEqual('etag', BlobList."E-Tag", 'Failed to verify Blob List field value');
        AssertThat.AreEqual('available | leased | expired | breaking | broken', BlobList."Lease State", 'Failed to verify Blob List field value');
        AssertThat.AreEqual('locked|unlocked', BlobList."Lease Status", 'Failed to verify Blob List field value');
    end;

    [Test]
    procedure VerifyListBlob();
    var
        TempBlob: Record TempBlob;
        BlobList: Record "Azure Blob List" temporary;
        DownloadBlob: Codeunit "Download Blob";
        PutAzureBlob: Codeunit "Put Azure Blob";
        FileNameMgt: Codeunit "File Name Management";
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        FileName: Text;
        BlobUrl: Text;
    begin
        // [Scenario] Get Blob List from Azure

        // [Given] Setup: 
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();
        DownloadBlob.DownloadDemoBlob(AzureBlobLibrary.GetDemoBlobDownloadUrl(), TempBlob);
        FileName := 'Test-' + FileNameMgt.GetRandomFileName(TempBlob, '.jpg');

        // [When] Exercise: 
        BlobUrl := PutAzureBlob.PutBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, FileName);
        BlobList.ReadBlobList(AccountName, AccountContainer, AccountPrivateKey);

        // [Then] Verify Record Created:
        BlobList.SetRange(Name, FileName);
        AssertThat.RecordCount(BlobList, 1);
    end;

    [Test]
    procedure VerifyJSONInterface()
    var
        Tempblob: Record TempBlob;
        DownloadBlob: Codeunit "Download Blob";
        JSONInterface: Codeunit "Azure Blob JSON Interface";
        FileNameMgt: Codeunit "File Name Management";
        JArray: JsonArray;
        JObject: JsonObject;
        JToken: JsonToken;
        JSON: Text;
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        FileName: Text;
        BlobUrl: Text;
        ContentLength: Integer;
    begin
        // [Scenario] Verify methods in Json Interface

        // [Given] Setup: 
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();
        DownloadBlob.DownloadDemoBlob(AzureBlobLibrary.GetDemoBlobDownloadUrl(), TempBlob);
        FileName := 'Test-' + FileNameMgt.GetRandomFileName(TempBlob, '.jpg');
        ContentLength := Tempblob.Blob.Length;

        // [When] Exercise: Put Blob
        SetConfiguration(AccountName, AccountContainer, AccountPrivateKey, JObject);
        JObject.Add('Method', 'PutBlob');
        JObject.Add('FileName', FileName);
        JObject.Add('Content', Tempblob.ToBase64String());
        JObject.WriteTo(JSON);
        Tempblob.WriteAsText(JSON, TextEncoding::UTF8);
        JSONInterface.Run(Tempblob);
        JObject.ReadFrom(Tempblob.ReadAsTextWithCRLFLineSeparator());
        JObject.Get('Url', JToken);
        BlobUrl := JToken.AsValue().AsText();

        // [Then] Verify BlobUrl
        ExpectedValue := 'https://' + AccountName + '.blob.core.windows.net/' + AccountContainer + '/' + FileName;
        ActualValue := BlobUrl;
        IfErrorTxt := 'Failed to verify the Put blob Method';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [When] Exercise: Get Blob
        SetConfiguration(AccountName, AccountContainer, AccountPrivateKey, JObject);
        JObject.Add('Method', 'GetBlob');
        JObject.Add('Url', BlobUrl);
        JObject.WriteTo(JSON);
        Tempblob.WriteAsText(JSON, TextEncoding::UTF8);
        JSONInterface.Run(Tempblob);
        JObject.ReadFrom(Tempblob.ReadAsTextWithCRLFLineSeparator());
        JObject.Get('Content', JToken);
        Tempblob.Init();
        Tempblob.FromBase64String(JToken.AsValue().AsText());
        JObject.Get('Content-Length', JToken);

        // [Then] Verify Content Length
        ExpectedValue := 114074;
        ActualValue := JToken.AsValue().AsInteger();
        IfErrorTxt := 'Failed to verify the Get blob Method';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [Then] Verify Blob Length
        ExpectedValue := ContentLength;
        ActualValue := Tempblob.Blob.Length;
        IfErrorTxt := 'Failed to verify the Get blob Method';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [When] Exercise: List Blob
        SetConfiguration(AccountName, AccountContainer, AccountPrivateKey, JObject);
        JObject.Add('Method', 'ListBlob');
        JObject.WriteTo(JSON);
        Tempblob.WriteAsText(JSON, TextEncoding::UTF8);
        JSONInterface.Run(Tempblob);
        JObject.ReadFrom(Tempblob.ReadAsTextWithCRLFLineSeparator());
        JObject.Get('List', JToken);
        JArray := JToken.AsArray();
        JArray.SelectToken(StrSubstNo('$[?(@.%1 == ''%2'')]', 'Name', FileName), JToken);
        JObject := JToken.AsObject();

        // [Then] Verify File Name
        JObject.Get('Name', JToken);
        ExpectedValue := FileName;
        ActualValue := JToken.AsValue().AsText();
        IfErrorTxt := 'Failed to verify the List blob Method';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [Then] Verify File Path
        JObject.Get('Path', JToken);
        ExpectedValue := 'https://' + AccountName + '.blob.core.windows.net/' + AccountContainer + '/' + FileName;
        ActualValue := JToken.AsValue().AsText();
        IfErrorTxt := 'Failed to verify the List blob Method';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [Then] Verify File Size
        JObject.Get('Size', JToken);
        ExpectedValue := 114074;
        ActualValue := JToken.AsValue().AsInteger();
        IfErrorTxt := 'Failed to verify the List blob Method';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [Then] Verify File Date
        JObject.Get('Date', JToken);
        ExpectedValue := 0D;
        ActualValue := JToken.AsValue().AsDate();
        IfErrorTxt := 'Failed to verify the List blob Method';
        AssertThat.AreNotEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [Then] Verify File Date
        JObject.Get('Time', JToken);
        ExpectedValue := 0T;
        ActualValue := JToken.AsValue().AsTime();
        IfErrorTxt := 'Failed to verify the List blob Method';
        AssertThat.AreNotEqual(ExpectedValue, ActualValue, IfErrorTxt);

        // [When] Exercise: Delete Blob
        SetConfiguration(AccountName, AccountContainer, AccountPrivateKey, JObject);
        JObject.Add('Method', 'DeleteBlob');
        JObject.Add('Url', BlobUrl);
        JObject.WriteTo(JSON);
        Tempblob.WriteAsText(JSON, TextEncoding::UTF8);
        JSONInterface.Run(Tempblob);
        JObject.ReadFrom(Tempblob.ReadAsTextWithCRLFLineSeparator());
        JObject.Get('Success', JToken);

        // [Then] Verify Not in Blob List
        SetConfiguration(AccountName, AccountContainer, AccountPrivateKey, JObject);
        JObject.Add('Method', 'ListBlob');
        JObject.WriteTo(JSON);
        Tempblob.WriteAsText(JSON, TextEncoding::UTF8);
        JSONInterface.Run(Tempblob);
        JObject.ReadFrom(Tempblob.ReadAsTextWithCRLFLineSeparator());
        JObject.Get('List', JToken);
        JArray := JToken.AsArray();
        asserterror JArray.SelectToken(StrSubstNo('$[?(@.%1 == ''%2'')]', 'Name', FileName), JToken);

    end;

    [Test]
    procedure DeleteAllTestBlobs();
    var
        BlobList: Record "Azure Blob List" temporary;
        DeleteAzureBlob: Codeunit "Delete Azure Blob";
        AccountName: Text;
        AccountContainer: Text;
        AccountPrivateKey: Text;
        ContainerUrl: Text;
    begin
        // [Scenario] Get Blob List from Azure

        // [Given] Setup: 
        AccountName := AzureBlobLibrary.GetAccountName();
        AccountContainer := AzureBlobLibrary.GetAccountContainer();
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();
        ContainerUrl := 'https://' + AccountName + '.blob.core.windows.net/' + AccountContainer + '/';

        // [When] Exercise: 
        BlobList.ReadBlobList(AccountName, AccountContainer, AccountPrivateKey);
        BlobList.SetFilter(Name, 'Test-*');
        if BlobList.FindSet() then
            repeat
                DeleteAzureBlob.DeleteBlob(AccountName, AccountContainer, AccountPrivateKey, ContainerUrl + BlobList.Name);
            until BlobList.Next() = 0;

    end;

    local procedure SetConfiguration(AccountName: Text; AccountContainer: Text; AccountPrivateKey: Text; var JObject: JsonObject)
    begin
        Clear(JObject);
        JObject.Add('Name', AccountName);
        JObject.Add('Container', AccountContainer);
        JObject.Add('PrivateKey', AccountPrivateKey);
    end;

    var
        AzureBlobLibrary: Codeunit "Azure blob Test Library";
        AssertThat: Codeunit Assert;
        ExpectedValue: Variant;
        ActualValue: Variant;
        IfErrorTxt: Text;
}