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

    procedure GetDemoBlobDownloadUrl(): Text
    begin
        exit('https://365links.blob.core.windows.net/azureblobtest/ANNA_20190215_0003-thumb.jpg?sp=r&st=2019-08-03T19:40:45Z&se=2019-08-04T03:40:45Z&spr=https&sv=2018-03-28&sig=Js8jbOpjHx%2BMn91IsSol368vAB5sVGhLjbyQ42C85ek%3D&sr=b');
    end;
}