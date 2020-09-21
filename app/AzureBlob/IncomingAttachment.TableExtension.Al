tableextension 50000 "Incoming Doc Attachment Ext" extends "Incoming Document Attachment"
{
    fields
    {
        field(50000; "O4N Content is URL"; boolean)
        {
            Caption = 'Content is URL';
            DataClassification = CustomerContent;
        }
    }

    procedure O4NWriteURLasContent(URL: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec.Content);
        Rec.Content.CreateOutStream(OutStr);
        OutStr.WriteText(URL);
    end;

    procedure O4NGetURLfromContent() URL: Text
    var
        InStr: InStream;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InStr);
        InStr.ReadText(URL);
    end;

}
