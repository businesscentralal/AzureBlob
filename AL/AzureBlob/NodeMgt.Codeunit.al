codeunit 60208 "Azure Blob Node Mgt."
{
    procedure SetFieldValue(var RecRef: RecordRef; FldNo: Integer; XmlSearchNode: XmlNode; NodeName: Text): Boolean
    var
        TempBlob: Record TempBlob;
        FldRef: FieldRef;
    begin
        FldRef := RecRef.Field(FldNo);
        case UpperCase(Format(FldRef.Type)) of
            'BLOB':
                begin
                    TempBlob.WriteAsText(FindNodeTextValue(XmlSearchNode, NodeName), TextEncoding::Windows);
                    FldRef.Value(TempBlob.Blob);
                end;
            'TEXT', 'CODE':
                FldRef.Value(CopyStr(FindNodeTextValue(XmlSearchNode, NodeName), 1, FldRef.Length));
            'DECIMAL', 'INTEGER':
                FldRef.Value(FindNodeDecimalValue(XmlSearchNode, NodeName));
            'DATETIME':
                FldRef.Value(FindNodeDateTimeValue(XmlSearchNode, NodeName));
            'DATE':
                FldRef.Value(FindNodeDateValue(XmlSearchNode, NodeName));
            'GUID':
                FldRef.Value(FindNodeGuidValue(XmlSearchNode, NodeName));
            else
                error(UnsupportedDataTypeErr, Format(FldRef.Type));
        end;

    end;

    procedure FindNodeTextValue(XmlSearchNode: XmlNode; NodeName: Text) NodeValue: Text
    var
        FoundNode: XmlNode;
    begin
        if not XmlSearchNode.SelectSingleNode(GetChildNodeXPath(NodeName), FoundNode) then exit('');
        NodeValue := FoundNode.AsXmlElement().InnerText();
    end;

    procedure FindNodeDecimalValue(XmlSearchNode: XmlNode; NodeName: Text) NodeValue: Decimal
    begin
        if not Evaluate(NodeValue, FindNodeTextValue(XmlSearchNode, NodeName), 9) then exit(0);
    end;

    procedure FindNodeDateTimeValue(XmlSearchNode: XmlNode; NodeName: Text) NodeValue: DateTime
    begin
        if not Evaluate(NodeValue, FindNodeTextValue(XmlSearchNode, NodeName), 9) then exit(0DT);
    end;

    procedure FindNodeDateValue(XmlSearchNode: XmlNode; NodeName: Text) NodeValue: Date
    begin
        exit(DT2Date(FindNodeDateTimeValue(XmlSearchNode, NodeName)));
    end;

    procedure FindNodeGuidValue(XmlSearchNode: XmlNode; NodeName: Text) NodeValue: Guid
    begin
        if not evaluate(NodeValue, FindNodeTextValue(XmlSearchNode, NodeName)) then
            clear(NodeValue);
    end;

    procedure FindAttributeTextValue(XmlSearchNode: XmlNode; AttributeName: Text) AttributeValue: Text
    var
        XmlSearchAttribute: XmlAttribute;
    begin
        foreach XmlSearchAttribute in XmlSearchNode.AsXmlElement().Attributes() do
            if XmlSearchAttribute.LocalName() = AttributeName then exit(XmlSearchAttribute.Value());
    end;

    procedure FindAttributeDecimalValue(XmlSearchNode: XmlNode; AttributeName: Text) AttributeValue: Decimal
    begin
        if not Evaluate(AttributeValue, FindAttributeTextValue(XmlSearchNode, AttributeName), 9) then exit(0);
    end;

    procedure FindAttributeDateTimeValue(XmlSearchNode: XmlNode; AttributeName: Text) AttributeValue: DateTime
    begin
        if not Evaluate(AttributeValue, FindAttributeTextValue(XmlSearchNode, AttributeName), 9) then exit(0DT);
    end;

    procedure GetNodeXPath(NodeName: Text): Text
    begin
        exit(StrSubstNo('//*[local-name()="%1"]', NodeName))
    end;

    procedure GetChildNodeXPath(NodeName: Text): Text
    begin
        exit(StrSubstNo('./*[local-name()="%1"]', NodeName))
    end;

    var
        UnsupportedDataTypeErr: Label 'Unsupported data type: %1';
}