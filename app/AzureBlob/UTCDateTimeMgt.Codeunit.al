codeunit 60200 "Azure Blob UTC DateTime Mgt."
{
    trigger OnRun()
    begin

    end;


    procedure GetUTCDateTimeText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.GetCurrUTCDateTimeAsText());
    end;

    procedure ParseUTCDateTimeText(DateTimeText: Text) UTCDate: DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        DateVariant: Variant;
    begin
        DateVariant := CurrentDateTime();
        if not TypeHelper.Evaluate(DateVariant, DateTimeText, 'R', '') then exit;
        UTCDate := DateVariant;
    end;

}