pageextension 50001 "Inc. Doc. Attach Factbox Ext" extends "Incoming Doc. Attach. FactBox"
{
    layout
    {

    }

    actions
    {
        addfirst(processing)
        {
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log';
                Image = Log;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category5;
                ToolTip = 'View the status and any errors related to the attachment.';

                trigger OnAction()
                var
                    ActivityLog: Record "Activity Log";
                    IncomingDocAttachment: Record "Incoming Document Attachment";
                begin
                    if IncomingDocAttachment.Get("Incoming Document Entry No.", "Line No.") then
                        ActivityLog.ShowEntries(IncomingDocAttachment);
                end;
            }
        }
    }
}
