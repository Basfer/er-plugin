unit uMetadataExtractor;

interface

uses
  Classes, Generics.Collections, uDataModel;

type
  TMetadataExtractor = class
  private
    FConnection: Pointer; // OCI connection handle
    FDatabaseName: string;
    FCurrentSchema: string;
    
    function ExecuteQuery(const ASQL: string): TObjectList<TDictionary<string, string>>;
    function GetStringValue(ADict: TDictionary<string, string>; const AKey: string): string;
    function GetIntValue(ADict: TDictionary<string, string>; const AKey: string): Integer;
    function GetBoolValue(ADict: TDictionary<string, string>; const AKey: string): Boolean;
    
    procedure ExtractTablesForSchema(const ASchemaName: string; AModel: TERModel);
    procedure ExtractColumns(ATable: TTableObject);
    procedure ExtractConstraints(ATable: TTableObject);
    procedure ExtractForeignKeys(AModel: TERModel);
    procedure ExtractComments(ATable: TTableObject);
    procedure ExtractTableStatistics(ATable: TTableObject);
    
    function ResolveSynonym(const ASynonymName: string; out AOwner: string; out ATableName: string): Boolean;
    function GetViewBaseTables(const AViewName: string): TStringList;
    
  public
    constructor Create(AConnection: Pointer; const ADatabaseName: string; const ACurrentSchema: string);
    destructor Destroy; override;
    
    // Main extraction methods
    function ExtractWholeDatabase: TERModel;
    function ExtractSchema(const ASchemaName: string): TERModel;
    function ExtractTables(const ATableNames: TStrings): TERModel;
    function ExtractTablesWithRelations(const ATableNames: TStrings): TERModel;
    
    property DatabaseName: string read FDatabaseName;
    property CurrentSchema: string read FCurrentSchema;
  end;

implementation

uses
  SysUtils, Variants, uConstants;

{ TMetadataExtractor }

constructor TMetadataExtractor.Create(AConnection: Pointer; const ADatabaseName: string; const ACurrentSchema: string);
begin
  inherited Create;
  FConnection := AConnection;
  FDatabaseName := ADatabaseName;
  FCurrentSchema := ACurrentSchema;
end;

destructor TMetadataExtractor.Destroy;
begin
  inherited Destroy;
end;

function TMetadataExtractor.ExecuteQuery(const ASQL: string): TObjectList<TDictionary<string, string>>;
begin
  // Placeholder - in real implementation, this would execute SQL via OCI
  // and return results as a list of dictionaries (row -> column name -> value)
  Result := TObjectList<TDictionary<string, string>>.Create(True);
  
  // TODO: Implement actual Oracle query execution using OCI
  // This is a stub for the interface definition
end;

function TMetadataExtractor.GetStringValue(ADict: TDictionary<string, string>; const AKey: string): string;
begin
  if ADict.TryGetValue(AKey, Result) then
    Exit;
  Result := '';
end;

function TMetadataExtractor.GetIntValue(ADict: TDictionary<string, string>; const AKey: string): Integer;
var
  S: string;
begin
  if ADict.TryGetValue(AKey, S) then
    Result := StrToIntDef(S, 0)
  else
    Result := 0;
end;

function TMetadataExtractor.GetBoolValue(ADict: TDictionary<string, string>; const AKey: string): Boolean;
var
  S: string;
begin
  if ADict.TryGetValue(AKey, S) then
    Result := SameText(S, 'Y') or SameText(S, '1') or SameText(S, 'TRUE')
  else
    Result := False;
end;

procedure TMetadataExtractor.ExtractTablesForSchema(const ASchemaName: string; AModel: TERModel);
var
  QueryResults: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
  TableObj: TTableObject;
  ObjectType: string;
begin
  // Query to get all tables, views, and synonyms in the schema
  // For MVP, we'll focus on tables first
  QueryResults := ExecuteQuery(
    'SELECT OWNER, TABLE_NAME, ''TABLE'' as OBJECT_TYPE ' +
    'FROM ALL_TABLES WHERE OWNER = :schema ' +
    'UNION ALL ' +
    'SELECT OWNER, VIEW_NAME, ''VIEW'' as OBJECT_TYPE ' +
    'FROM ALL_VIEWS WHERE OWNER = :schema ' +
    'UNION ALL ' +
    'SELECT TABLE_OWNER, TABLE_NAME, ''SYNONYM'' as OBJECT_TYPE ' +
    'FROM ALL_SYNONYMS WHERE OWNER = :schema'
  );
  
  try
    for Row in QueryResults do
    begin
      TableObj := TTableObject.Create;
      TableObj.Owner := GetStringValue(Row, 'OWNER');
      TableObj.ObjectName := GetStringValue(Row, 'TABLE_NAME');
      TableObj.ObjectType := GetStringValue(Row, 'OBJECT_TYPE');
      
      // For synonyms, resolve to actual table
      if SameText(TableObj.ObjectType, OBJ_TYPE_SYNONYM) then
      begin
        if ResolveSynonym(TableObj.ObjectName, TableObj.Owner, TableObj.OriginalName) then
          TableObj.ObjectName := TableObj.OriginalName;
      end;
      
      AModel.AddTable(TableObj);
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractColumns(ATable: TTableObject);
var
  QueryResults: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
  Col: TColumn;
begin
  QueryResults := ExecuteQuery(
    'SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, ' +
    'NULLABLE, DATA_DEFAULT, COLUMN_ID ' +
    'FROM ALL_TAB_COLUMNS ' +
    'WHERE OWNER = :owner AND TABLE_NAME = :table_name ' +
    'ORDER BY COLUMN_ID'
  );
  
  try
    for Row in QueryResults do
    begin
      Col := TColumn.Create;
      Col.TableName := ATable.ObjectName;
      Col.ColumnName := GetStringValue(Row, 'COLUMN_NAME');
      Col.DataType := GetStringValue(Row, 'DATA_TYPE');
      Col.DataLength := GetIntValue(Row, 'DATA_LENGTH');
      Col.DataPrecision := GetIntValue(Row, 'DATA_PRECISION');
      Col.DataScale := GetIntValue(Row, 'DATA_SCALE');
      Col.Nullable := GetBoolValue(Row, 'NULLABLE');
      Col.DefaultValue := GetStringValue(Row, 'DATA_DEFAULT');
      Col.Position := GetIntValue(Row, 'COLUMN_ID');
      
      ATable.Columns.Add(Col);
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractConstraints(ATable: TTableObject);
var
  QueryResults: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
  ConstraintType: string;
  FK: TForeignKey;
  UK: TForeignKey;
  CheckConstr: TCheckConstraint;
begin
  // Get all constraints for the table
  QueryResults := ExecuteQuery(
    'SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, SEARCH_CONDITION, STATUS ' +
    'FROM ALL_CONSTRAINTS ' +
    'WHERE OWNER = :owner AND TABLE_NAME = :table_name'
  );
  
  try
    for Row in QueryResults do
    begin
      ConstraintType := GetStringValue(Row, 'CONSTRAINT_TYPE');
      
      if ConstraintType = CONSTRAINT_PK then
      begin
        // Primary Key
        FK := TForeignKey.Create;
        FK.ConstraintName := GetStringValue(Row, 'CONSTRAINT_NAME');
        FK.PKTableName := ATable.ObjectName;
        FK.FKTableName := ATable.ObjectName;
        ATable.PrimaryKey := FK;
        
        // Get PK columns
        // TODO: Query ALL_CONS_COLUMNS for PK columns
      end
      else if ConstraintType = CONSTRAINT_FK then
      begin
        // Foreign Key - will be processed separately
      end
      else if ConstraintType = CONSTRAINT_UNIQUE then
      begin
        // Unique constraint
        UK := TForeignKey.Create;
        UK.ConstraintName := GetStringValue(Row, 'CONSTRAINT_NAME');
        UK.PKTableName := ATable.ObjectName;
        UK.FKTableName := ATable.ObjectName;
        ATable.UniqueConstraints.Add(UK);
      end
      else if ConstraintType = CONSTRAINT_CHECK then
      begin
        // Check constraint
        CheckConstr := TCheckConstraint.Create;
        CheckConstr.ConstraintName := GetStringValue(Row, 'CONSTRAINT_NAME');
        CheckConstr.TableName := ATable.ObjectName;
        CheckConstr.SearchCondition := GetStringValue(Row, 'SEARCH_CONDITION');
        CheckConstr.Enabled := SameText(GetStringValue(Row, 'STATUS'), 'ENABLED');
        ATable.CheckConstraints.Add(CheckConstr);
      end;
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractForeignKeys(AModel: TERModel);
var
  QueryResults: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
  FK: TForeignKey;
  PKTable, FKTable: TTableObject;
begin
  // Get all foreign keys between tables in the model
  QueryResults := ExecuteQuery(
    'SELECT FC.CONSTRAINT_NAME, FC.TABLE_NAME as FK_TABLE, ' +
    'PC.TABLE_NAME as PK_TABLE, FC.R_OWNER, FC.DELETE_RULE, FC.UPDATE_RULE ' +
    'FROM ALL_CONSTRAINTS FC ' +
    'JOIN ALL_CONSTRAINTS PC ON FC.R_CONSTRAINT_NAME = PC.CONSTRAINT_NAME ' +
    'AND FC.R_OWNER = PC.OWNER ' +
    'WHERE FC.CONSTRAINT_TYPE = ''R'''
    // Add filters for specific tables if needed
  );
  
  try
    for Row in QueryResults do
    begin
      FKTable := AModel.GetTable(GetStringValue(Row, 'FK_TABLE'));
      PKTable := AModel.GetTable(GetStringValue(Row, 'PK_TABLE'));
      
      if Assigned(FKTable) and Assigned(PKTable) then
      begin
        FK := TForeignKey.Create;
        FK.ConstraintName := GetStringValue(Row, 'CONSTRAINT_NAME');
        FK.FKTableName := FKTable.ObjectName;
        FK.PKTableName := PKTable.ObjectName;
        FK.DeleteRule := GetStringValue(Row, 'DELETE_RULE');
        FK.UpdateRule := GetStringValue(Row, 'UPDATE_RULE');
        
        // Get FK columns
        // TODO: Query ALL_CONS_COLUMNS for FK columns
        
        FKTable.ForeignKeys.Add(FK);
        AModel.AllForeignKeys.Add(FK);
      end;
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractComments(ATable: TTableObject);
var
  QueryResults: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
  Col: TColumn;
begin
  // Get table comment
  QueryResults := ExecuteQuery(
    'SELECT COMMENTS FROM ALL_TAB_COMMENTS ' +
    'WHERE OWNER = :owner AND TABLE_NAME = :table_name'
  );
  
  try
    if QueryResults.Count > 0 then
    begin
      Row := QueryResults[0];
      ATable.Comments := GetStringValue(Row, 'COMMENTS');
    end;
  finally
    QueryResults.Free;
  end;
  
  // Get column comments
  QueryResults := ExecuteQuery(
    'SELECT COLUMN_NAME, COMMENTS FROM ALL_COL_COMMENTS ' +
    'WHERE OWNER = :owner AND TABLE_NAME = :table_name'
  );
  
  try
    for Row in QueryResults do
    begin
      for Col in ATable.Columns do
      begin
        if SameText(Col.ColumnName, GetStringValue(Row, 'COLUMN_NAME')) then
        begin
          Col.Comments := GetStringValue(Row, 'COMMENTS');
          Break;
        end;
      end;
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractTableStatistics(ATable: TTableObject);
var
  QueryResults: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
begin
  QueryResults := ExecuteQuery(
    'SELECT NUM_ROWS, LAST_ANALYZED FROM ALL_TABLES ' +
    'WHERE OWNER = :owner AND TABLE_NAME = :table_name'
  );
  
  try
    if QueryResults.Count > 0 then
    begin
      Row := QueryResults[0];
      ATable.NumRows := GetIntValue(Row, 'NUM_ROWS');
      // Parse LAST_ANALYZED date
    end;
  finally
    QueryResults.Free;
  end;
end;

function TMetadataExtractor.ResolveSynonym(const ASynonymName: string; out AOwner: string; out ATableName: string): Boolean;
var
  QueryResults: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
begin
  Result := False;
  AOwner := '';
  ATableName := '';
  
  QueryResults := ExecuteQuery(
    'SELECT TABLE_OWNER, TABLE_NAME, DB_LINK FROM ALL_SYNONYMS ' +
    'WHERE SYNONYM_NAME = :synonym_name'
  );
  
  try
    if QueryResults.Count > 0 then
    begin
      Row := QueryResults[0];
      AOwner := GetStringValue(Row, 'TABLE_OWNER');
      ATableName := GetStringValue(Row, 'TABLE_NAME');
      Result := True;
    end;
  finally
    QueryResults.Free;
  end;
end;

function TMetadataExtractor.GetViewBaseTables(const AViewName: string): TStringList;
begin
  Result := TStringList.Create;
  // TODO: Parse view definition from ALL_VIEWS.TEXT to find base tables
  // This requires SQL parsing which can be complex
  // For MVP, we might skip this or use a simpler approach
end;

function TMetadataExtractor.ExtractWholeDatabase: TERModel;
var
  SchemaQuery: TObjectList<TDictionary<string, string>>;
  Row: TDictionary<string, string>;
  SchemaName: string;
begin
  Result := TERModel.Create;
  Result.DatabaseName := FDatabaseName;
  
  // Get all schemas
  SchemaQuery := ExecuteQuery(
    'SELECT DISTINCT OWNER FROM ALL_TABLES ORDER BY OWNER'
  );
  
  try
    for Row in SchemaQuery do
    begin
      SchemaName := GetStringValue(Row, 'OWNER');
      ExtractTablesForSchema(SchemaName, Result);
    end;
  finally
    SchemaQuery.Free;
  end;
  
  // Extract detailed information for all tables
  // ... (columns, constraints, etc.)
end;

function TMetadataExtractor.ExtractSchema(const ASchemaName: string): TERModel;
begin
  Result := TERModel.Create;
  Result.SchemaName := ASchemaName;
  Result.DatabaseName := FDatabaseName;
  
  ExtractTablesForSchema(ASchemaName, Result);
  
  // Extract columns for each table
  // Extract constraints
  // Extract foreign keys
  // Extract comments
end;

function TMetadataExtractor.ExtractTables(const ATableNames: TStrings): TERModel;
var
  i: Integer;
  TableName: string;
  TableObj: TTableObject;
begin
  Result := TERModel.Create;
  Result.DatabaseName := FDatabaseName;
  
  for i := 0 to ATableNames.Count - 1 do
  begin
    TableName := ATableNames[i];
    // Create table object and extract metadata
    // TODO: Implement
  end;
end;

function TMetadataExtractor.ExtractTablesWithRelations(const ATableNames: TStrings): TERModel;
var
  Visited: TDictionary<string, Boolean>;
  i: Integer;
begin
  Result := TERModel.Create;
  Result.DatabaseName := FDatabaseName;
  
  Visited := TDictionary<string, Boolean>.Create;
  try
    // First add the selected tables
    for i := 0 to ATableNames.Count - 1 do
    begin
      // Add table to model
      // Then recursively add related tables
      Result.AddRelatedTablesRecursively(ATableNames[i], Visited);
    end;
  finally
    Visited.Free;
  end;
end;

end.
