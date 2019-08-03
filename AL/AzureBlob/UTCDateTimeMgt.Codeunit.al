codeunit 60200 "UTC DateTime Management"
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
        DateVariant := UTCDate;
        if not TypeHelper.Evaluate(DateVariant, DateTimeText, 'R', '') then exit;
        UTCDate := DateVariant;
    end;

}