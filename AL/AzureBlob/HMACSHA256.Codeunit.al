codeunit 60201 "Azure Blob HMACSHA256 Mgt."
{
    procedure GetTextToHash(Verb: Text; ContentType: Text; CanonicalizedHeaders: Text; CanonicalizedResource: Text; ContentLength: Text) TextToHash: Text
    begin
        Initialize();
        exit(
            Verb + NewLine +  //HTTP Verb
            NewLine +  //Content-Encoding
            NewLine +  //Content-Language
            ContentLength + NewLine +  //Content-Length (include value when zero)
            NewLine +  //Content-MD5
            ContentType + NewLine +  //Content-Type
            NewLine +  //Date
            NewLine +  //If-Modified-Since
            NewLine +  //If-Match
            NewLine +  //If-None-Match
            NewLine +  //If-Unmodified-Since
            NewLine +  //Range
            CanonicalizedHeaders + NewLine +  //CanonicalizedHeaders
            CanonicalizedResource);
    end;

    procedure GetAuthorization(AccountName: Text; HashKey: Text; TextToHash: Text) Authorization: Text;
    begin
        Initialize();
        Authorization := 'SharedKey ' + AccountName + ':' + GenerateKeyedHash(TextToHash, HashKey);
    end;

    local procedure GenerateKeyedHash(TextToHash: Text; HashKey: Text) KeyedHash: Text
    var
        EncryptionMgt: Codeunit "Encryption Management";
        HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
    begin
        KeyedHash := EncryptionMgt.GenerateBase64KeyedHashAsBase64String(TextToHash, HashKey, HashAlgorithmType::HMACSHA256)
    end;

    local procedure Initialize()
    begin
        NewLine[1] := 10;
    end;

    var
        NewLine: Text[1];

}