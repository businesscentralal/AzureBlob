codeunit 60298 "Azure blob Test Library"
{
    procedure GetAccountName(): Text
    begin
        exit('bcazureblob');
    end;

    procedure GetAccountContainer(): Text
    begin
        exit('azureblobtest');
    end;

    procedure GetAccountAccessKey(): Text
    begin
        exit(GetSecretValue());
    end;

    procedure GetDemoBlobDownloadUrl(): Text
    begin
        exit('https://bcazureblob.blob.core.windows.net/azureblobdemo/ANNA_20190215_0003-thumb.jpg');
    end;

    procedure GetDemoBlobList(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>  ' +
            '<EnumerationResults ServiceEndpoint="http://myaccount.blob.core.windows.net/"  ContainerName="mycontainer">  ' +
            '  <Prefix>string-value</Prefix>  ' +
            '  <Marker>string-value</Marker>  ' +
            '  <MaxResults>int-value</MaxResults>  ' +
            '  <Delimiter>string-value</Delimiter>  ' +
            '  <Blobs>  ' +
            '    <Blob>  ' +
            '      <Name>blob-name</Name>    ' +
            '      <Deleted>true</Deleted>' +
            '      <Snapshot>date-time-value</Snapshot>' +
            '      <Properties> ' +
            '        <Creation-Time>date-time-value</Creation-Time>' +
            '        <Last-Modified>Fri, 26 Jun 2015 23:39:12 GMT</Last-Modified>  ' +
            '        <Etag>etag</Etag>  ' +
            '        <Content-Length>1234</Content-Length>  ' +
            '        <Content-Type>blob-content-type</Content-Type>  ' +
            '        <Content-Encoding />  ' +
            '        <Content-Language />  ' +
            '        <Content-MD5 />  ' +
            '        <Cache-Control />  ' +
            '        <x-ms-blob-sequence-number>sequence-number</x-ms-blob-sequence-number>  ' +
            '        <BlobType>BlockBlob|PageBlob|AppendBlob</BlobType>  ' +
            '        <AccessTier>tier</AccessTier>  ' +
            '        <LeaseStatus>locked|unlocked</LeaseStatus>  ' +
            '        <LeaseState>available | leased | expired | breaking | broken</LeaseState>  ' +
            '        <LeaseDuration>infinite | fixed</LeaseDuration>  ' +
            '        <CopyId>id</CopyId>  ' +
            '        <CopyStatus>pending | success | aborted | failed </CopyStatus>  ' +
            '        <CopySource>source url</CopySource>  ' +
            '        <CopyProgress>bytes copied/bytes total</CopyProgress>  ' +
            '        <CopyCompletionTime>datetime</CopyCompletionTime>  ' +
            '        <CopyStatusDescription>error string</CopyStatusDescription>  ' +
            '        <ServerEncrypted>true</ServerEncrypted> ' +
            '        <IncrementalCopy>true</IncrementalCopy>' +
            '        <AccessTierInferred>true</AccessTierInferred>' +
            '        <AccessTierChangeTime>datetime</AccessTierChangeTime>' +
            '        <DeletedTime>datetime</DeletedTime>' +
            '        <RemainingRetentionDays>no-of-days</RemainingRetentionDays>' +
            '      </Properties>  ' +
            '      <Metadata>     ' +
            '        <Name>value</Name>  ' +
            '      </Metadata>  ' +
            '    </Blob>  ' +
            '    <BlobPrefix>  ' +
            '      <Name>blob-prefix</Name>  ' +
            '    </BlobPrefix>  ' +
            '  </Blobs>  ' +
            '  <NextMarker />  ' +
            '</EnumerationResults>        ');
    end;

    procedure StoreSecretValue(SecretValue: Text)
    begin
        Buffer.InsertRec(0, 0, 0, SecretValue, '');
    end;

    local procedure GetSecretValue() SecretValue: Text
    begin
        if not Buffer.FindFirst() then exit('');
        SecretValue := Buffer.GetValue();
    end;

    var
        Buffer: Record "Data Exch. Field";

}