pageextension 50000 "Inc. Doc. Attachments Ext" extends "Incoming Document Attachments"
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
                begin
                    ActivityLog.ShowEntries(Rec);
                end;
            }
        }
    }
}
