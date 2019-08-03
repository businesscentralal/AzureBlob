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
    procedure VerifyBlobDownload();
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
        AccountPrivateKey := AzureBlobLibrary.GetAccountPrivateKey();

        // [When] Exercise:      
        ContentLength := GetAzureBlob.GetBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, AzureBlobLibrary.GetBlobDownloadUrl());

        // [Then] Verify: 
        ExpectedValue := 25638;
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
        asserterror ContentLength := GetAzureBlob.GetBlob(TempBlob, AccountName, AccountContainer, AccountPrivateKey, AzureBlobLibrary.GetBlobDownloadUrl());

        // [Then] Verify: 
        ExpectedValue := 'Failed to download a blob: Server failed to authenticate the request. Make sure the value of Authorization header is formed correctly including the signature.';
        ActualValue := GetLastErrorText();
        IfErrorTxt := 'Failed to verify the authentication error';
        AssertThat.AreEqual(ExpectedValue, ActualValue, IfErrorTxt);
    end;

    var
        AzureBlobLibrary: Codeunit "Azure blob Test Library";
        AssertThat: Codeunit Assert;
        RandomLibrary: Codeunit "Library - Random";
        ExpectedValue: Variant;
        ActualValue: Variant;
        IfErrorTxt: Text;
}