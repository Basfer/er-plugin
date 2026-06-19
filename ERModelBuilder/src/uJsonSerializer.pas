unit uJsonSerializer;

interface

uses
  Classes, Generics.Collections, uDataModel;

type
  TJsonSerializer = class
  private
    function EscapeString(const AStr: string): string;
    function FormatValue(const AValue: string; AIsString: Boolean): string;
    
    procedure WriteTable(ATable: TTableObject; AIndent: Integer; AWriter: TStringWriter);
    procedure WriteForeignKey(AFKey: TForeignKey; AIndent: Integer; AWriter: TStringWriter);
    procedure WriteColumn(ACol: TColumn; AIndent: Integer; AWriter: TStringWriter);
    procedure WriteCheckConstraint(AConstr: TCheckConstraint; AIndent: Integer; AWriter: TStringWriter);
    
  public
    function Serialize(AModel: TERModel): string;
    function Deserialize(const AJson: string): TERModel;
    
    function SaveToFile(AModel: TERModel; const AFileName: string): Boolean;
    function LoadFromFile(const AFileName: string): TERModel;
  end;

implementation

uses
  SysUtils, DateUtils;

{ TJsonSerializer }

function TJsonSerializer.EscapeString(const AStr: string): string;
var
  i: Integer;
  C: Char;
begin
  Result := '';
  for i := 1 to Length(AStr) do
  begin
    C := AStr[i];
    case C of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #12: Result := Result + '\f';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
      #9: Result := Result + '\t';
    else
      if Ord(C) < 32 then
        Result := Result + '\u' + IntToHex(Ord(C), 4)
      else
        Result := Result + C;
    end;
  end;
end;

function TJsonSerializer.FormatValue(const AValue: string; AIsString: Boolean): string;
begin
  if AIsString then
    Result := '"' + EscapeString(AValue) + '"'
  else
    Result := AValue;
end;

procedure TJsonSerializer.WriteColumn(ACol: TColumn; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '{');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '"tableName": "' + EscapeString(ACol.TableName) + '",');
  AWriter.WriteLine(IndentStr + '"columnName": "' + EscapeString(ACol.ColumnName) + '",');
  AWriter.WriteLine(IndentStr + '"dataType": "' + EscapeString(ACol.DataType) + '",');
  AWriter.WriteLine(IndentStr + '"dataLength": ' + IntToStr(ACol.DataLength) + ',');
  AWriter.WriteLine(IndentStr + '"dataPrecision": ' + IntToStr(ACol.DataPrecision) + ',');
  AWriter.WriteLine(IndentStr + '"dataScale": ' + IntToStr(ACol.DataScale) + ',');
  AWriter.WriteLine(IndentStr + '"nullable": ' + IfThen(ACol.Nullable, 'true', 'false') + ',');
  AWriter.WriteLine(IndentStr + '"isPrimaryKey": ' + IfThen(ACol.IsPrimaryKey, 'true', 'false') + ',');
  AWriter.WriteLine(IndentStr + '"isForeignKey": ' + IfThen(ACol.IsForeignKey, 'true', 'false') + ',');
  AWriter.WriteLine(IndentStr + '"position": ' + IntToStr(ACol.Position) + ',');
  AWriter.WriteLine(IndentStr + '"defaultValue": "' + EscapeString(ACol.DefaultValue) + '",');
  AWriter.WriteLine(IndentStr + '"comments": "' + EscapeString(ACol.Comments) + '"');
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '}');
end;

procedure TJsonSerializer.WriteForeignKey(AFKey: TForeignKey; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
  i: Integer;
  Col: TForeignKeyColumn;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '{');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '"constraintName": "' + EscapeString(AFKey.ConstraintName) + '",');
  AWriter.WriteLine(IndentStr + '"pkTableName": "' + EscapeString(AFKey.PKTableName) + '",');
  AWriter.WriteLine(IndentStr + '"fkTableName": "' + EscapeString(AFKey.FKTableName) + '",');
  AWriter.WriteLine(IndentStr + '"deleteRule": "' + EscapeString(AFKey.DeleteRule) + '",');
  AWriter.WriteLine(IndentStr + '"updateRule": "' + EscapeString(AFKey.UpdateRule) + '",');
  AWriter.WriteLine(IndentStr + '"columns": [');
  
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  for i := 0 to AFKey.Columns.Count - 1 do
  begin
    Col := AFKey.Columns[i];
    if i > 0 then
      AWriter.Write(',');
    AWriter.WriteLine;
    AWriter.WriteLine(IndentStr + '{');
    Inc(AIndent, 2);
    IndentStr := StringOfChar(' ', AIndent);
    AWriter.WriteLine(IndentStr + '"pkColumn": "' + EscapeString(Col.PKColumn) + '",');
    AWriter.WriteLine(IndentStr + '"fkColumn": "' + EscapeString(Col.FKColumn) + '",');
    AWriter.WriteLine(IndentStr + '"position": ' + IntToStr(Col.Position));
    Dec(AIndent, 2);
    IndentStr := StringOfChar(' ', AIndent);
    AWriter.Write(IndentStr + '}');
  end;
  AWriter.WriteLine;
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + ']');
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '}');
end;

procedure TJsonSerializer.WriteCheckConstraint(AConstr: TCheckConstraint; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '{');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '"constraintName": "' + EscapeString(AConstr.ConstraintName) + '",');
  AWriter.WriteLine(IndentStr + '"tableName": "' + EscapeString(AConstr.TableName) + '",');
  AWriter.WriteLine(IndentStr + '"searchCondition": "' + EscapeString(AConstr.SearchCondition) + '",');
  AWriter.WriteLine(IndentStr + '"enabled": ' + IfThen(AConstr.Enabled, 'true', 'false'));
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '}');
end;

procedure TJsonSerializer.WriteTable(ATable: TTableObject; AIndent: Integer; AWriter: TStringWriter);
var
  IndentStr: string;
  Col: TColumn;
  FK: TForeignKey;
  CheckConstr: TCheckConstraint;
  i: Integer;
begin
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '{');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  
  AWriter.WriteLine(IndentStr + '"objectName": "' + EscapeString(ATable.ObjectName) + '",');
  AWriter.WriteLine(IndentStr + '"originalName": "' + EscapeString(ATable.OriginalName) + '",');
  AWriter.WriteLine(IndentStr + '"objectType": "' + EscapeString(ATable.ObjectType) + '",');
  AWriter.WriteLine(IndentStr + '"owner": "' + EscapeString(ATable.Owner) + '",');
  AWriter.WriteLine(IndentStr + '"comments": "' + EscapeString(ATable.Comments) + '",');
  AWriter.WriteLine(IndentStr + '"numRows": ' + IntToStr(ATable.NumRows) + ',');
  AWriter.WriteLine(IndentStr + '"lastAnalyzed": "' + DateTimeToStr(ATable.LastAnalyzed) + '",');
  AWriter.WriteLine(IndentStr + '"left": ' + IntToStr(ATable.Left) + ',');
  AWriter.WriteLine(IndentStr + '"top": ' + IntToStr(ATable.Top) + ',');
  AWriter.WriteLine(IndentStr + '"width": ' + IntToStr(ATable.Width) + ',');
  AWriter.WriteLine(IndentStr + '"height": ' + IntToStr(ATable.Height) + ',');
  AWriter.WriteLine(IndentStr + '"selected": ' + IfThen(ATable.Selected, 'true', 'false') + ',');
  
  // Columns
  AWriter.WriteLine(IndentStr + '"columns": [');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  for i := 0 to ATable.Columns.Count - 1 do
  begin
    Col := ATable.Columns[i];
    if i > 0 then
      AWriter.Write(',');
    AWriter.WriteLine;
    WriteColumn(Col, AIndent, AWriter);
  end;
  AWriter.WriteLine;
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '],');
  
  // Primary Key
  AWriter.WriteLine(IndentStr + '"primaryKey": ');
  if Assigned(ATable.PrimaryKey) then
    WriteForeignKey(ATable.PrimaryKey, AIndent, AWriter)
  else
    AWriter.WriteLine(IndentStr + 'null,');
  
  // Foreign Keys
  AWriter.WriteLine(IndentStr + '"foreignKeys": [');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  for i := 0 to ATable.ForeignKeys.Count - 1 do
  begin
    FK := ATable.ForeignKeys[i];
    if i > 0 then
      AWriter.Write(',');
    AWriter.WriteLine;
    WriteForeignKey(FK, AIndent, AWriter);
  end;
  AWriter.WriteLine;
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '],');
  
  // Unique Constraints
  AWriter.WriteLine(IndentStr + '"uniqueConstraints": [');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  for i := 0 to ATable.UniqueConstraints.Count - 1 do
  begin
    FK := ATable.UniqueConstraints[i];
    if i > 0 then
      AWriter.Write(',');
    AWriter.WriteLine;
    WriteForeignKey(FK, AIndent, AWriter);
  end;
  AWriter.WriteLine;
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '],');
  
  // Check Constraints
  AWriter.WriteLine(IndentStr + '"checkConstraints": [');
  Inc(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  for i := 0 to ATable.CheckConstraints.Count - 1 do
  begin
    CheckConstr := ATable.CheckConstraints[i];
    if i > 0 then
      AWriter.Write(',');
    AWriter.WriteLine;
    WriteCheckConstraint(CheckConstr, AIndent, AWriter);
  end;
  AWriter.WriteLine;
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + ']');
  
  Dec(AIndent, 2);
  IndentStr := StringOfChar(' ', AIndent);
  AWriter.WriteLine(IndentStr + '}');
end;

function TJsonSerializer.Serialize(AModel: TERModel): string;
var
  Writer: TStringWriter;
  Table: TTableObject;
  FK: TForeignKey;
  i: Integer;
begin
  Writer := TStringWriter.Create;
  try
    Writer.WriteLine('{');
    Writer.WriteLine('  "version": "1.0",');
    Writer.WriteLine('  "databaseName": "' + EscapeString(AModel.DatabaseName) + '",');
    Writer.WriteLine('  "schemaName": "' + EscapeString(AModel.SchemaName) + '",');
    Writer.WriteLine('  "created": "' + DateTimeToStr(AModel.Created) + '",');
    Writer.WriteLine('  "modified": "' + DateTimeToStr(AModel.Modified) + '",');
    Writer.WriteLine('  "canvasWidth": ' + IntToStr(AModel.CanvasWidth) + ',');
    Writer.WriteLine('  "canvasHeight": ' + IntToStr(AModel.CanvasHeight) + ',');
    
    // Tables
    Writer.WriteLine('  "tables": [');
    for i := 0 to AModel.Tables.Count - 1 do
    begin
      Table := AModel.Tables[i];
      if i > 0 then
        Writer.Write(',');
      Writer.WriteLine;
      WriteTable(Table, 4, Writer);
    end;
    Writer.WriteLine;
    Writer.WriteLine('  ],');
    
    // All Foreign Keys
    Writer.WriteLine('  "allForeignKeys": [');
    for i := 0 to AModel.AllForeignKeys.Count - 1 do
    begin
      FK := AModel.AllForeignKeys[i];
      if i > 0 then
        Writer.Write(',');
      Writer.WriteLine;
      WriteForeignKey(FK, 4, Writer);
    end;
    Writer.WriteLine;
    Writer.WriteLine('  ]');
    
    Writer.WriteLine('}');
    
    Result := Writer.ToString;
  finally
    Writer.Free;
  end;
end;

function TJsonSerializer.Deserialize(const AJson: string): TERModel;
begin
  // TODO: Implement JSON deserialization
  // This would require a JSON parser or manual parsing
  Result := nil;
  raise Exception.Create('JSON deserialization not yet implemented');
end;

function TJsonSerializer.SaveToFile(AModel: TERModel; const AFileName: string): Boolean;
var
  JsonContent: string;
  FileStream: TStringStream;
begin
  Result := False;
  try
    JsonContent := Serialize(AModel);
    FileStream := TStringStream.Create(JsonContent, TEncoding.UTF8);
    try
      FileStream.SaveToFile(AFileName);
      Result := True;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // Log error or show message
      Result := False;
    end;
  end;
end;

function TJsonSerializer.LoadFromFile(const AFileName: string): TERModel;
var
  FileStream: TStringStream;
  JsonContent: string;
begin
  Result := nil;
  if not FileExists(AFileName) then
    Exit;
  
  FileStream := TStringStream.Create;
  try
    FileStream.LoadFromFile(AFileName);
    JsonContent := FileStream.ReadString(TEncoding.UTF8);
    Result := Deserialize(JsonContent);
  finally
    FileStream.Free;
  end;
end;

end.
