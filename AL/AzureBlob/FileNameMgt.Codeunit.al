codeunit 60207 "Azure Blob File Name Mgt."
{
    procedure GetRandomFileName(TempBlob: Record TempBlob; FileExtension: Text) RandomFileName: Text
    var
        EncryptionMgt: Codeunit "Encryption Management";
        StringConversionMgt: Codeunit StringConversionManagement;
        InStr: InStream;
        HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
    begin
        TempBlob.Blob.CreateInStream(InStr);
        RandomFileName := LowerCase(Format(StringConversionMgt.RemoveNonAlphaNumericCharacters(CreateGuid())) + EncryptionMgt.GenerateHashFromStream(InStr, HashAlgorithmType::HMACMD5)) + '.' + FileExtension;
    end;
}