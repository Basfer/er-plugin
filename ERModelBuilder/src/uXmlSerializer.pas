unit uXmlSerializer;

interface

uses
  Classes, Generics.Collections, uDataModel;

type
  TXmlSerializer = class
  private
    function EscapeXml(const AStr: string): string;
    
    procedure WriteTable(ATable: TTableObject; AIndent: Integer; AWriter: TStringWriter);
    procedure WriteForeignKey(AFKey: TForeignKey; AIndent: Integer; AWriter: TStringWriter);
    procedure WriteColumn(ACol: TColumn; AIndent: Integer; AWriter: TStringWriter);
    procedure WriteCheckConstraint(AConstr: TCheckConstraint; AIndent: Integer; AWriter: TStringWriter);
    
  public
    function Serialize(AModel: TERModel): string;
    function Deserialize(const AXml: string): TERModel;
    
    function SaveToFile(AModel: TERModel; const AFileName: string): Boolean;
    function LoadFromFile(const AFileName: string): TERModel;
  end;

implementation

uses
  SysUtils, DateUtils;

{ TXmlSerializer }

function TXmlSerializer.EscapeXml(const AStr: string): string;
var
  i: Integer;
  C: Char;
begin
  Result := '';
  for i := 1 to Length(AStr) do
  begin
    C := AStr[i];
    case C of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
      '''': Result := Result + '&apos;';
    else
      if Ord(C) < 32 then
        // Skip control characters or replace with space
        Result := Result + ' '
      else
        Result := Result + C;
    end;
  end;
end;

procedure TXmlSerializer.WriteColumn(ACol: TColumn; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '<column>');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '<tableName>' + EscapeXml(ACol.TableName) + '</tableName>');
  AWriter.WriteLine(IndentStr + '<columnName>' + EscapeXml(ACol.ColumnName) + '</columnName>');
  AWriter.WriteLine(IndentStr + '<dataType>' + EscapeXml(ACol.DataType) + '</dataType>');
  AWriter.WriteLine(IndentStr + '<dataLength>' + IntToStr(ACol.DataLength) + '</dataLength>');
  AWriter.WriteLine(IndentStr + '<dataPrecision>' + IntToStr(ACol.DataPrecision) + '</dataPrecision>');
  AWriter.WriteLine(IndentStr + '<dataScale>' + IntToStr(ACol.DataScale) + '</dataScale>');
  AWriter.WriteLine(IndentStr + '<nullable>' + IfThen(ACol.Nullable, 'true', 'false') + '</nullable>');
  AWriter.WriteLine(IndentStr + '<isPrimaryKey>' + IfThen(ACol.IsPrimaryKey, 'true', 'false') + '</isPrimaryKey>');
  AWriter.WriteLine(IndentStr + '<isForeignKey>' + IfThen(ACol.IsForeignKey, 'true', 'false') + '</isForeignKey>');
  AWriter.WriteLine(IndentStr + '<position>' + IntToStr(ACol.Position) + '</position>');
  AWriter.WriteLine(IndentStr + '<defaultValue>' + EscapeXml(ACol.DefaultValue) + '</defaultValue>');
  AWriter.WriteLine(IndentStr + '<comments>' + EscapeXml(ACol.Comments) + '</comments>');
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '</column>');
end;

procedure TXmlSerializer.WriteForeignKey(AFKey: TForeignKey; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
  Col: TForeignKeyColumn;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '<foreignKey>');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '<constraintName>' + EscapeXml(AFKey.ConstraintName) + '</constraintName>');
  AWriter.WriteLine(IndentStr + '<pkTableName>' + EscapeXml(AFKey.PKTableName) + '</pkTableName>');
  AWriter.WriteLine(IndentStr + '<fkTableName>' + EscapeXml(AFKey.FKTableName) + '</fkTableName>');
  AWriter.WriteLine(IndentStr + '<deleteRule>' + EscapeXml(AFKey.DeleteRule) + '</deleteRule>');
  AWriter.WriteLine(IndentStr + '<updateRule>' + EscapeXml(AFKey.UpdateRule) + '</updateRule>');
  
  // Columns
  AWriter.WriteLine(IndentStr + '<columns>');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  for Col in AFKey.Columns do
  begin
    AWriter.WriteLine(IndentStr + '<column>');
    Inc(AIndent, 2);
    IndentStr := StringOfChar(' ', AIndent);
    AWriter.WriteLine(IndentStr + '<pkColumn>' + EscapeXml(Col.PKColumn) + '</pkColumn>');
    AWriter.WriteLine(IndentStr + '<fkColumn>' + EscapeXml(Col.FKColumn) + '</fkColumn>');
    AWriter.WriteLine(IndentStr + '<position>' + IntToStr(Col.Position) + '</position>');
    Dec(AIndent, 2);
    IndentStr := StringOfChar(' ', AIndent);
    AWriter.WriteLine(IndentStr + '</column>');
  end;
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '</columns>');
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '</foreignKey>');
end;

procedure TXmlSerializer.WriteCheckConstraint(AConstr: TCheckConstraint; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '<checkConstraint>');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '<constraintName>' + EscapeXml(AConstr.ConstraintName) + '</constraintName>');
  AWriter.WriteLine(IndentStr + '<tableName>' + EscapeXml(AConstr.TableName) + '</tableName>');
  AWriter.WriteLine(IndentStr + '<searchCondition>' + EscapeXml(AConstr.SearchCondition) + '</searchCondition>');
  AWriter.WriteLine(IndentStr + '<enabled>' + IfThen(AConstr.Enabled, 'true', 'false') + '</enabled>');
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '</checkConstraint>');
end;

procedure TXmlSerializer.WriteTable(ATable: TTableObject; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
  Col: TColumn;
  FK: TForeignKey;
  CheckConstr: TCheckConstraint;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '<table>');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '<objectName>' + EscapeXml(ATable.ObjectName) + '</objectName>');
  AWriter.WriteLine(IndentStr + '<originalName>' + EscapeXml(ATable.OriginalName) + '</originalName>');
  AWriter.WriteLine(IndentStr + '<objectType>' + EscapeXml(ATable.ObjectType) + '</objectType>');
  AWriter.WriteLine(IndentStr + '<owner>' + EscapeXml(ATable.Owner) + '</owner>');
  AWriter.WriteLine(IndentStr + '<comments>' + EscapeXml(ATable.Comments) + '</comments>');
  AWriter.WriteLine(IndentStr + '<numRows>' + IntToStr(ATable.NumRows) + '</numRows>');
  AWriter.WriteLine(IndentStr + '<lastAnalyzed>' + DateTimeToStr(ATable.LastAnalyzed) + '</lastAnalyzed>');
  AWriter.WriteLine(IndentStr + '<left>' + IntToStr(ATable.Left) + '</left>');
  AWriter.WriteLine(IndentStr + '<top>' + IntToStr(ATable.Top) + '</top>');
  AWriter.WriteLine(IndentStr + '<width>' + IntToStr(ATable.Width) + '</width>');
  AWriter.WriteLine(IndentStr + '<height>' + IntToStr(ATable.Height) + '</height>');
  AWriter.WriteLine(IndentStr + '<selected>' + IfThen(ATable.Selected, 'true', 'false') + '</selected>');
  
  // Columns
  AWriter.WriteLine(IndentStr + '<columns>');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  for Col in ATable.Columns do
    WriteColumn(Col, AIndent, AWriter);
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '</columns>');
  
  // Primary Key
  AWriter.WriteLine(IndentStr + '<primaryKey>');
  if Assigned(ATable.PrimaryKey) then
    WriteForeignKey(ATable.PrimaryKey, AIndent + 2, AWriter);
  AWriter.WriteLine(IndentStr + '</primaryKey>');
  
  // Foreign Keys
  AWriter.WriteLine(IndentStr + '<foreignKeys>');
  for FK in ATable.ForeignKeys do
    WriteForeignKey(FK, AIndent + 2, AWriter);
  AWriter.WriteLine(IndentStr + '</foreignKeys>');
  
  // Unique Constraints
  AWriter.WriteLine(IndentStr + '<uniqueConstraints>');
  for FK in ATable.UniqueConstraints do
    WriteForeignKey(FK, AIndent + 2, AWriter);
  AWriter.WriteLine(IndentStr + '</uniqueConstraints>');
  
  // Check Constraints
  AWriter.WriteLine(IndentStr + '<checkConstraints>');
  for CheckConstr in ATable.CheckConstraints do
    WriteCheckConstraint(CheckConstr, AIndent + 2, AWriter);
  AWriter.WriteLine(IndentStr + '</checkConstraints>');
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '</table>');
end;

function TXmlSerializer.Serialize(AModel: TERModel): string;
var
  Writer: TStringWriter;
  Table: TTableObject;
  FK: TForeignKey;
begin
  Writer := TStringWriter.Create;
  try
    Writer.WriteLine('<?xml version="1.0" encoding="UTF-8"?>');
    Writer.WriteLine('<erModel version="1.0">');
    
    // Header info
    Writer.WriteLine('  <header>');
    Writer.WriteLine('    <databaseName>' + EscapeXml(AModel.DatabaseName) + '</databaseName>');
    Writer.WriteLine('    <schemaName>' + EscapeXml(AModel.SchemaName) + '</schemaName>');
    Writer.WriteLine('    <created>' + DateTimeToStr(AModel.Created) + '</created>');
    Writer.WriteLine('    <modified>' + DateTimeToStr(AModel.Modified) + '</modified>');
    Writer.WriteLine('    <canvasWidth>' + IntToStr(AModel.CanvasWidth) + '</canvasWidth>');
    Writer.WriteLine('    <canvasHeight>' + IntToStr(AModel.CanvasHeight) + '</canvasHeight>');
    Writer.WriteLine('  </header>');
    
    // Tables
    Writer.WriteLine('  <tables>');
    for Table in AModel.Tables do
      WriteTable(Table, 4, Writer);
    Writer.WriteLine('  </tables>');
    
    // All Foreign Keys
    Writer.WriteLine('  <allForeignKeys>');
    for FK in AModel.AllForeignKeys do
      WriteForeignKey(FK, 4, Writer);
    Writer.WriteLine('  </allForeignKeys>');
    
    Writer.WriteLine('</erModel>');
    
    Result := Writer.ToString;
  finally
    Writer.Free;
  end;
end;

function TXmlSerializer.Deserialize(const AXml: string): TERModel;
begin
  // TODO: Implement XML deserialization using XML parser
  Result := nil;
  raise Exception.Create('XML deserialization not yet implemented');
end;

function TXmlSerializer.SaveToFile(AModel: TERModel; const AFileName: string): Boolean;
var
  XmlContent: string;
  FileStream: TStringStream;
begin
  Result := False;
  try
    XmlContent := Serialize(AModel);
    FileStream := TStringStream.Create(XmlContent, TEncoding.UTF8);
    try
      FileStream.SaveToFile(AFileName);
      Result := True;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

function TXmlSerializer.LoadFromFile(const AFileName: string): TERModel;
var
  FileStream: TStringStream;
  XmlContent: string;
begin
  Result := nil;
  if not FileExists(AFileName) then
    Exit;
  
  FileStream := TStringStream.Create;
  try
    FileStream.LoadFromFile(AFileName);
    XmlContent := FileStream.ReadString(TEncoding.UTF8);
    Result := Deserialize(XmlContent);
  finally
    FileStream.Free;
  end;
end;

end.
