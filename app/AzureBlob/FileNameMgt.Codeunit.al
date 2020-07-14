codeunit 60207 "Azure Blob File Name Mgt."
{
    procedure GetRandomFileName(TempBlob: Codeunit "Temp Blob"; FileExtension: Text) RandomFileName: Text
    var
        EncryptionMgt: Codeunit "Cryptography Management";
        StringConversionMgt: Codeunit StringConversionManagement;
        InStr: InStream;
        HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
    begin
        TempBlob.CreateInStream(InStr);
        RandomFileName := LowerCase(Format(StringConversionMgt.RemoveNonAlphaNumericCharacters(CreateGuid())) + EncryptionMgt.GenerateHash(InStr, HashAlgorithmType::HMACMD5)) + '.' + FileExtension;
    end;
}