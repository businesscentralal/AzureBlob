codeunit 60298 "Azure blob Test Library"
{
    procedure GetAccountName(): Text
    begin
        exit('365links');
    end;

    procedure GetAccountContainer(): Text
    begin
        exit('azureblobtest');
    end;

    procedure GetAccountPrivateKey(): Text
    begin
        // Your current Access Key
        exit('BwAOOF89WF4yHlM0HtINL/V8n+eEPrjD3+69bX3k0UC4pRq3RejMAuW7WgMwRQbSufvqCkQxi6dg2Lrql2mG9w==');
    end;

    procedure GetBlobDownloadUrl(): Text
    begin
        exit('https://365links.blob.core.windows.net/azureblobtest/ANNA_20190215_0003-thumb.jpg');
    end;
}