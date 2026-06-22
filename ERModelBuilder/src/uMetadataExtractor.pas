unit uMetadataExtractor;

interface

uses
  Classes, Generics.Collections, uDataModel, uOCIManager;

type
  TMetadataExtractor = class
  private
    FOCIManager: TOCIManager;
    FDatabaseName: string;
    FCurrentSchema: string;
    
    function ExecuteQuery(const ASQL: string): TOCIQueryResult;
    function GetStringValue(AResult: TOCIQueryResult; const AKey: string): string;
    function GetIntValue(AResult: TOCIQueryResult; const AKey: string): Integer;
    function GetBoolValue(AResult: TOCIQueryResult; const AKey: string): Boolean;
    
    procedure ExtractTablesForSchema(const ASchemaName: string; AModel: TERModel);
    procedure ExtractColumns(ATable: TTableObject);
    procedure ExtractConstraints(ATable: TTableObject);
    procedure ExtractForeignKeys(AModel: TERModel);
    procedure ExtractComments(ATable: TTableObject);
    procedure ExtractTableStatistics(ATable: TTableObject);
    procedure ExtractPKColumns(ATable: TTableObject; const AConstraintName: string);
    procedure ExtractFKColumns(AFK: TForeignKey; const AConstraintName: string);
    procedure ExtractUniqueColumns(AUK: TForeignKey; const AConstraintName: string);
    
    function ResolveSynonym(const ASynonymName: string; out AOwner: string; out ATableName: string): Boolean;
    function GetViewBaseTables(const AViewName: string): TStringList;
    
  public
    constructor Create(AOCIManager: TOCIManager; const ADatabaseName: string; const ACurrentSchema: string);
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

constructor TMetadataExtractor.Create(AOCIManager: TOCIManager; const ADatabaseName: string; const ACurrentSchema: string);
begin
  inherited Create;
  FOCIManager := AOCIManager;
  FDatabaseName := ADatabaseName;
  FCurrentSchema := ACurrentSchema;
end;

destructor TMetadataExtractor.Destroy;
begin
  inherited Destroy;
end;

function TMetadataExtractor.ExecuteQuery(const ASQL: string): TOCIQueryResult;
begin
  Result := FOCIManager.ExecuteQuery(ASQL);
end;

function TMetadataExtractor.GetStringValue(AResult: TOCIQueryResult; const AKey: string): string;
begin
  if Assigned(AResult) then
    Result := AResult.GetColumnValueByName(AKey)
  else
    Result := '';
end;

function TMetadataExtractor.GetIntValue(AResult: TOCIQueryResult; const AKey: string): Integer;
var
  S: string;
begin
  S := GetStringValue(AResult, AKey);
  Result := StrToIntDef(S, 0);
end;

function TMetadataExtractor.GetBoolValue(AResult: TOCIQueryResult; const AKey: string): Boolean;
var
  S: string;
begin
  S := GetStringValue(AResult, AKey);
  Result := SameText(S, 'Y') or SameText(S, '1') or SameText(S, 'TRUE');
end;

procedure TMetadataExtractor.ExtractTablesForSchema(const ASchemaName: string; AModel: TERModel);
var
  QueryResults: TOCIQueryResult;
  TableObj: TTableObject;
  ObjectType: string;
begin
  // Query to get all tables, views, and synonyms in the schema
  // For MVP, we'll focus on tables first
  QueryResults := ExecuteQuery(
    'SELECT OWNER, TABLE_NAME, ''TABLE'' as OBJECT_TYPE ' +
    'FROM ALL_TABLES WHERE OWNER = ''' + ASchemaName + ''' ' +
    'UNION ALL ' +
    'SELECT OWNER, VIEW_NAME, ''VIEW'' as OBJECT_TYPE ' +
    'FROM ALL_VIEWS WHERE OWNER = ''' + ASchemaName + ''' ' +
    'UNION ALL ' +
    'SELECT TABLE_OWNER, TABLE_NAME, ''SYNONYM'' as OBJECT_TYPE ' +
    'FROM ALL_SYNONYMS WHERE OWNER = ''' + ASchemaName + ''''
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      TableObj := TTableObject.Create;
      TableObj.Owner := GetStringValue(QueryResults, 'OWNER');
      TableObj.ObjectName := GetStringValue(QueryResults, 'TABLE_NAME');
      TableObj.ObjectType := GetStringValue(QueryResults, 'OBJECT_TYPE');
      
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
  QueryResults: TOCIQueryResult;
  Col: TColumn;
begin
  QueryResults := ExecuteQuery(
    'SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, ' +
    'NULLABLE, DATA_DEFAULT, COLUMN_ID ' +
    'FROM ALL_TAB_COLUMNS ' +
    'WHERE OWNER = ''' + ATable.Owner + ''' AND TABLE_NAME = ''' + ATable.ObjectName + ''' ' +
    'ORDER BY COLUMN_ID'
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      Col := TColumn.Create;
      Col.TableName := ATable.ObjectName;
      Col.ColumnName := GetStringValue(QueryResults, 'COLUMN_NAME');
      Col.DataType := GetStringValue(QueryResults, 'DATA_TYPE');
      Col.DataLength := GetIntValue(QueryResults, 'DATA_LENGTH');
      Col.DataPrecision := GetIntValue(QueryResults, 'DATA_PRECISION');
      Col.DataScale := GetIntValue(QueryResults, 'DATA_SCALE');
      Col.Nullable := GetBoolValue(QueryResults, 'NULLABLE');
      Col.DefaultValue := GetStringValue(QueryResults, 'DATA_DEFAULT');
      Col.Position := GetIntValue(QueryResults, 'COLUMN_ID');
      
      ATable.Columns.Add(Col);
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractPKColumns(ATable: TTableObject; const AConstraintName: string);
var
  QueryResults: TOCIQueryResult;
  Col: TColumn;
  ColName: string;
begin
  QueryResults := ExecuteQuery(
    'SELECT COLUMN_NAME, POSITION FROM ALL_CONS_COLUMNS ' +
    'WHERE OWNER = ''' + ATable.Owner + ''' AND CONSTRAINT_NAME = ''' + AConstraintName + ''' ' +
    'ORDER BY POSITION'
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      ColName := GetStringValue(QueryResults, 'COLUMN_NAME');
      // Find column in table and add to PK
      for Col in ATable.Columns do
      begin
        if SameText(Col.ColumnName, ColName) then
        begin
          if Assigned(ATable.PrimaryKey) then
            ATable.PrimaryKey.PKColumns.Add(ColName);
          Break;
        end;
      end;
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractFKColumns(AFK: TForeignKey; const AConstraintName: string);
var
  QueryResults: TOCIQueryResult;
begin
  QueryResults := ExecuteQuery(
    'SELECT COLUMN_NAME, POSITION FROM ALL_CONS_COLUMNS ' +
    'WHERE CONSTRAINT_NAME = ''' + AConstraintName + ''' ' +
    'ORDER BY POSITION'
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      AFK.FKColumns.Add(GetStringValue(QueryResults, 'COLUMN_NAME'));
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractUniqueColumns(AUK: TForeignKey; const AConstraintName: string);
var
  QueryResults: TOCIQueryResult;
begin
  QueryResults := ExecuteQuery(
    'SELECT COLUMN_NAME, POSITION FROM ALL_CONS_COLUMNS ' +
    'WHERE CONSTRAINT_NAME = ''' + AConstraintName + ''' ' +
    'ORDER BY POSITION'
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      AUK.UKColumns.Add(GetStringValue(QueryResults, 'COLUMN_NAME'));
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractConstraints(ATable: TTableObject);
var
  QueryResults: TOCIQueryResult;
  ConstraintType: string;
  FK: TForeignKey;
  UK: TForeignKey;
  CheckConstr: TCheckConstraint;
begin
  // Get all constraints for the table
  QueryResults := ExecuteQuery(
    'SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, SEARCH_CONDITION, STATUS ' +
    'FROM ALL_CONSTRAINTS ' +
    'WHERE OWNER = ''' + ATable.Owner + ''' AND TABLE_NAME = ''' + ATable.ObjectName + ''''
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      ConstraintType := GetStringValue(QueryResults, 'CONSTRAINT_TYPE');
      
      if ConstraintType = CONSTRAINT_PK then
      begin
        // Primary Key
        FK := TForeignKey.Create;
        FK.ConstraintName := GetStringValue(QueryResults, 'CONSTRAINT_NAME');
        FK.PKTableName := ATable.ObjectName;
        FK.FKTableName := ATable.ObjectName;
        ATable.PrimaryKey := FK;
        
        // Get PK columns from ALL_CONS_COLUMNS
        ExtractPKColumns(ATable, FK.ConstraintName);
      end
      else if ConstraintType = CONSTRAINT_FK then
      begin
        // Foreign Key - will be processed separately in ExtractForeignKeys
      end
      else if ConstraintType = CONSTRAINT_UNIQUE then
      begin
        // Unique constraint
        UK := TForeignKey.Create;
        UK.ConstraintName := GetStringValue(QueryResults, 'CONSTRAINT_NAME');
        UK.PKTableName := ATable.ObjectName;
        UK.FKTableName := ATable.ObjectName;
        ATable.UniqueConstraints.Add(UK);
        
        // Get UK columns from ALL_CONS_COLUMNS
        ExtractUniqueColumns(UK, UK.ConstraintName);
      end
      else if ConstraintType = CONSTRAINT_CHECK then
      begin
        // Check constraint
        CheckConstr := TCheckConstraint.Create;
        CheckConstr.ConstraintName := GetStringValue(QueryResults, 'CONSTRAINT_NAME');
        CheckConstr.TableName := ATable.ObjectName;
        CheckConstr.SearchCondition := GetStringValue(QueryResults, 'SEARCH_CONDITION');
        CheckConstr.Enabled := SameText(GetStringValue(QueryResults, 'STATUS'), 'ENABLED');
        ATable.CheckConstraints.Add(CheckConstr);
      end;
    end;
  finally
    QueryResults.Free;
  end;
end;

procedure TMetadataExtractor.ExtractForeignKeys(AModel: TERModel);
var
  QueryResults: TOCIQueryResult;
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
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      FKTable := AModel.GetTable(GetStringValue(QueryResults, 'FK_TABLE'));
      PKTable := AModel.GetTable(GetStringValue(QueryResults, 'PK_TABLE'));
      
      if Assigned(FKTable) and Assigned(PKTable) then
      begin
        FK := TForeignKey.Create;
        FK.ConstraintName := GetStringValue(QueryResults, 'CONSTRAINT_NAME');
        FK.FKTableName := FKTable.ObjectName;
        FK.PKTableName := PKTable.ObjectName;
        FK.DeleteRule := GetStringValue(QueryResults, 'DELETE_RULE');
        FK.UpdateRule := GetStringValue(QueryResults, 'UPDATE_RULE');
        
        // Get FK columns from ALL_CONS_COLUMNS
        ExtractFKColumns(FK, FK.ConstraintName);
        
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
  QueryResults: TOCIQueryResult;
  Col: TColumn;
begin
  // Get table comment
  QueryResults := ExecuteQuery(
    'SELECT COMMENTS FROM ALL_TAB_COMMENTS ' +
    'WHERE OWNER = ''' + ATable.Owner + ''' AND TABLE_NAME = ''' + ATable.ObjectName + ''''
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    if QueryResults.Next then
      ATable.Comments := GetStringValue(QueryResults, 'COMMENTS');
  finally
    QueryResults.Free;
  end;
  
  // Get column comments
  QueryResults := ExecuteQuery(
    'SELECT COLUMN_NAME, COMMENTS FROM ALL_COL_COMMENTS ' +
    'WHERE OWNER = ''' + ATable.Owner + ''' AND TABLE_NAME = ''' + ATable.ObjectName + ''''
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    while QueryResults.Next do
    begin
      for Col in ATable.Columns do
      begin
        if SameText(Col.ColumnName, GetStringValue(QueryResults, 'COLUMN_NAME')) then
        begin
          Col.Comments := GetStringValue(QueryResults, 'COMMENTS');
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
  QueryResults: TOCIQueryResult;
begin
  QueryResults := ExecuteQuery(
    'SELECT NUM_ROWS, LAST_ANALYZED FROM ALL_TABLES ' +
    'WHERE OWNER = ''' + ATable.Owner + ''' AND TABLE_NAME = ''' + ATable.ObjectName + ''''
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    if QueryResults.Next then
    begin
      ATable.NumRows := GetIntValue(QueryResults, 'NUM_ROWS');
      // Parse LAST_ANALYZED date if needed
    end;
  finally
    QueryResults.Free;
  end;
end;

function TMetadataExtractor.ResolveSynonym(const ASynonymName: string; out AOwner: string; out ATableName: string): Boolean;
var
  QueryResults: TOCIQueryResult;
begin
  Result := False;
  AOwner := '';
  ATableName := '';
  
  QueryResults := ExecuteQuery(
    'SELECT TABLE_OWNER, TABLE_NAME, DB_LINK FROM ALL_SYNONYMS ' +
    'WHERE SYNONYM_NAME = ''' + ASynonymName + ''''
  );
  
  try
    if not Assigned(QueryResults) then
      Exit;
      
    if QueryResults.Next then
    begin
      AOwner := GetStringValue(QueryResults, 'TABLE_OWNER');
      ATableName := GetStringValue(QueryResults, 'TABLE_NAME');
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
  SchemaQuery: TOCIQueryResult;
  SchemaName: string;
begin
  Result := TERModel.Create;
  Result.DatabaseName := FDatabaseName;
  
  // Get all schemas
  SchemaQuery := ExecuteQuery(
    'SELECT DISTINCT OWNER FROM ALL_TABLES ORDER BY OWNER'
  );
  
  try
    if not Assigned(SchemaQuery) then
      Exit;
      
    while SchemaQuery.Next do
    begin
      SchemaName := GetStringValue(SchemaQuery, 'OWNER');
      ExtractTablesForSchema(SchemaName, Result);
    end;
  finally
    SchemaQuery.Free;
  end;
  
  // Extract detailed information for all tables
  // Columns, constraints, etc. would be extracted here
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
