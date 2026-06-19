unit uDataModel;

interface

uses
  Classes, Generics.Collections;

type
  // Column information
  TColumn = class
  private
    FTableName: string;
    FColumnName: string;
    FDataType: string;
    FDataLength: Integer;
    FDataPrecision: Integer;
    FDataScale: Integer;
    FNullable: Boolean;
    FIsPrimaryKey: Boolean;
    FIsForeignKey: Boolean;
    FPosition: Integer;
    FDefaultValue: string;
    FComments: string;
  public
    property TableName: string read FTableName write FTableName;
    property ColumnName: string read FColumnName write FColumnName;
    property DataType: string read FDataType write FDataType;
    property DataLength: Integer read FDataLength write FDataLength;
    property DataPrecision: Integer read FDataPrecision write FDataPrecision;
    property DataScale: Integer read FDataScale write FDataScale;
    property Nullable: Boolean read FNullable write FNullable;
    property IsPrimaryKey: Boolean read FIsPrimaryKey write FIsPrimaryKey;
    property IsForeignKey: Boolean read FIsForeignKey write FIsForeignKey;
    property Position: Integer read FPosition write FPosition;
    property DefaultValue: string read FDefaultValue write FDefaultValue;
    property Comments: string read FComments write FComments;
    
    function GetFullTypeName: string;
  end;

  // Foreign Key relationship (supports composite keys)
  TForeignKeyColumn = record
    PKColumn: string;
    FKColumn: string;
    Position: Integer;
  end;

  TForeignKey = class
  private
    FConstraintName: string;
    FPKTableName: string;
    FFKTableName: string;
    FColumns: TList<TForeignKeyColumn>;
    FDeleteRule: string;
    FUpdateRule: string;
  public
    constructor Create;
    destructor Destroy; override;
    
    property ConstraintName: string read FConstraintName write FConstraintName;
    property PKTableName: string read FPKTableName write FPKTableName;
    property FKTableName: string read FFKTableName write FFKTableName;
    property Columns: TList<TForeignKeyColumn> read FColumns;
    property DeleteRule: string read FDeleteRule write FDeleteRule;
    property UpdateRule: string read FUpdateRule write FUpdateRule;
    
    function GetColumnCount: Integer;
    function GetSourceColumns: string;
    function GetTargetColumns: string;
  end;

  // Check constraint
  TCheckConstraint = class
  private
    FConstraintName: string;
    FTableName: string;
    FSearchCondition: string;
    FEnabled: Boolean;
  public
    property ConstraintName: string read FConstraintName write FConstraintName;
    property TableName: string read FTableName write FTableName;
    property SearchCondition: string read FSearchCondition write FSearchCondition;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

  // Table object (includes views and synonyms)
  TTableObject = class
  private
    FObjectName: string;
    FOriginalName: string; // For synonyms - the actual table name
    FObjectType: string; // TABLE, VIEW, SYNONYM
    FOwner: string;
    FColumns: TObjectList<TColumn>;
    FPrimaryKey: TForeignKey;
    FForeignKeys: TObjectList<TForeignKey>;
    FUniqueConstraints: TObjectList<TForeignKey>;
    FCheckConstraints: TObjectList<TCheckConstraint>;
    FComments: string;
    FNumRows: Int64;
    FLastAnalyzed: TDateTime;
    // Visual properties
    FLeft: Integer;
    FTop: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FSelected: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    property ObjectName: string read FObjectName write FObjectName;
    property OriginalName: string read FOriginalName write FOriginalName;
    property ObjectType: string read FObjectType write FObjectType;
    property Owner: string read FOwner write FOwner;
    property Columns: TObjectList<TColumn> read FColumns;
    property PrimaryKey: TForeignKey read FPrimaryKey write FPrimaryKey;
    property ForeignKeys: TObjectList<TForeignKey> read FForeignKeys;
    property UniqueConstraints: TObjectList<TForeignKey> read FUniqueConstraints;
    property CheckConstraints: TObjectList<TCheckConstraint> read FCheckConstraints;
    property Comments: string read FComments write FComments;
    property NumRows: Int64 read FNumRows write FNumRows;
    property LastAnalyzed: TDateTime read FLastAnalyzed write FLastAnalyzed;
    
    // Visual properties
    property Left: Integer read FLeft write FLeft;
    property Top: Integer read FTop write FTop;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property Selected: Boolean read FSelected write FSelected;
    
    function GetFullQualifiedName: string;
    function GetDisplayHeight: Integer;
    function GetDisplayWidth: Integer;
    procedure AutoSize;
  end;

  // ER Model - collection of tables and relationships
  TERModel = class
  private
    FTables: TObjectList<TTableObject>;
    FAllForeignKeys: TObjectList<TForeignKey>;
    FDatabaseName: string;
    FSchemaName: string;
    FCreated: TDateTime;
    FModified: TDateTime;
    FCanvasWidth: Integer;
    FCanvasHeight: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    
    property Tables: TObjectList<TTableObject> read FTables;
    property AllForeignKeys: TObjectList<TForeignKey> read FAllForeignKeys;
    property DatabaseName: string read FDatabaseName write FDatabaseName;
    property SchemaName: string read FSchemaName write FSchemaName;
    property Created: TDateTime read FCreated write FCreated;
    property Modified: TDateTime read FModified write FModified;
    property CanvasWidth: Integer read FCanvasWidth write FCanvasWidth;
    property CanvasHeight: Integer read FCanvasHeight write FCanvasHeight;
    
    function GetTable(const AName: string): TTableObject;
    function GetTableCount: Integer;
    procedure AddTable(ATable: TTableObject);
    procedure RemoveTable(const AName: string);
    procedure Clear;
    
    function GetRelatedTables(const ATableName: string): TList<TTableObject>;
    procedure AddRelatedTablesRecursively(const ATableName: string; AVisited: TDictionary<string, Boolean>);
    
    procedure AutoLayout;
  end;

implementation

uses
  SysUtils, uConstants;

{ TColumn }

function TColumn.GetFullTypeName: string;
begin
  Result := FDataType;
  if FDataType in ['VARCHAR2', 'CHAR', 'NVARCHAR2', 'NCHAR'] then
  begin
    if FDataLength > 0 then
      Result := Result + '(' + IntToStr(FDataLength) + ')';
  end
  else if FDataType in ['NUMBER'] then
  begin
    if FDataPrecision > 0 then
    begin
      if FDataScale > 0 then
        Result := Result + '(' + IntToStr(FDataPrecision) + ',' + IntToStr(FDataScale) + ')'
      else
        Result := Result + '(' + IntToStr(FDataPrecision) + ')';
    end;
  end
  else if FDataType in ['FLOAT'] then
  begin
    if FDataPrecision > 0 then
      Result := Result + '(' + IntToStr(FDataPrecision) + ')';
  end;
end;

{ TForeignKey }

constructor TForeignKey.Create;
begin
  inherited Create;
  FColumns := TList<TForeignKeyColumn>.Create;
end;

destructor TForeignKey.Destroy;
begin
  FColumns.Free;
  inherited Destroy;
end;

function TForeignKey.GetColumnCount: Integer;
begin
  Result := FColumns.Count;
end;

function TForeignKey.GetSourceColumns: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FColumns.Count - 1 do
  begin
    if i > 0 then
      Result := Result + ', ';
    Result := Result + FColumns[i].FKColumn;
  end;
end;

function TForeignKey.GetTargetColumns: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FColumns.Count - 1 do
  begin
    if i > 0 then
      Result := Result + ', ';
    Result := Result + FColumns[i].PKColumn;
  end;
end;

{ TTableObject }

constructor TTableObject.Create;
begin
  inherited Create;
  FColumns := TObjectList<TColumn>.Create(True);
  FForeignKeys := TObjectList<TForeignKey>.Create(True);
  FUniqueConstraints := TObjectList<TForeignKey>.Create(True);
  FCheckConstraints := TObjectList<TCheckConstraint>.Create(True);
  FLeft := 0;
  FTop := 0;
  FWidth := TABLE_MIN_WIDTH;
  FHeight := TABLE_HEADER_HEIGHT;
  FSelected := False;
end;

destructor TTableObject.Destroy;
begin
  FColumns.Free;
  FForeignKeys.Free;
  FUniqueConstraints.Free;
  FCheckConstraints.Free;
  inherited Destroy;
end;

function TTableObject.GetFullQualifiedName: string;
begin
  if FOwner <> '' then
    Result := FOwner + '.' + FObjectName
  else
    Result := FObjectName;
end;

function TTableObject.GetDisplayHeight: Integer;
begin
  Result := TABLE_HEADER_HEIGHT + (FColumns.Count * TABLE_ROW_HEIGHT);
end;

function TTableObject.GetDisplayWidth: Integer;
var
  MaxWidth: Integer;
  Col: TColumn;
  TextWidth: Integer;
begin
  MaxWidth := TABLE_MIN_WIDTH;
  // Simple width calculation based on column names
  for Col in FColumns do
  begin
    TextWidth := Length(Col.ColumnName) * 8 + 20;
    if TextWidth > MaxWidth then
      MaxWidth := TextWidth;
  end;
  Result := MaxWidth;
end;

procedure TTableObject.AutoSize;
begin
  FWidth := GetDisplayWidth;
  FHeight := GetDisplayHeight;
end;

{ TERModel }

constructor TERModel.Create;
begin
  inherited Create;
  FTables := TObjectList<TTableObject>.Create(True);
  FAllForeignKeys := TObjectList<TForeignKey>.Create(True);
  FCreated := Now;
  FModified := Now;
  FCanvasWidth := DEFAULT_CANVAS_WIDTH;
  FCanvasHeight := DEFAULT_CANVAS_HEIGHT;
end;

destructor TERModel.Destroy;
begin
  FTables.Free;
  FAllForeignKeys.Free;
  inherited Destroy;
end;

function TERModel.GetTable(const AName: string): TTableObject;
var
  Table: TTableObject;
begin
  Result := nil;
  for Table in FTables do
  begin
    if SameText(Table.ObjectName, AName) or SameText(Table.GetFullQualifiedName, AName) then
    begin
      Result := Table;
      Exit;
    end;
  end;
end;

function TERModel.GetTableCount: Integer;
begin
  Result := FTables.Count;
end;

procedure TERModel.AddTable(ATable: TTableObject);
begin
  FTables.Add(ATable);
  FModified := Now;
end;

procedure TERModel.RemoveTable(const AName: string);
var
  Table: TTableObject;
begin
  Table := GetTable(AName);
  if Assigned(Table) then
  begin
    FTables.Remove(Table);
    FModified := Now;
  end;
end;

procedure TERModel.Clear;
begin
  FTables.Clear;
  FAllForeignKeys.Clear;
  FModified := Now;
end;

function TERModel.GetRelatedTables(const ATableName: string): TList<TTableObject>;
var
  FK: TForeignKey;
  RelatedTable: TTableObject;
begin
  Result := TList<TTableObject>.Create;
  
  for FK in FAllForeignKeys do
  begin
    if SameText(FK.PKTableName, ATableName) or SameText(FK.FKTableName, ATableName) then
    begin
      // Add PK table
      RelatedTable := GetTable(FK.PKTableName);
      if Assigned(RelatedTable) and (Result.IndexOf(RelatedTable) < 0) then
        Result.Add(RelatedTable);
      
      // Add FK table
      RelatedTable := GetTable(FK.FKTableName);
      if Assigned(RelatedTable) and (Result.IndexOf(RelatedTable) < 0) then
        Result.Add(RelatedTable);
    end;
  end;
end;

procedure TERModel.AddRelatedTablesRecursively(const ATableName: string; AVisited: TDictionary<string, Boolean>);
var
  RelatedTables: TList<TTableObject>;
  Table: TTableObject;
  TableName: string;
begin
  if AVisited.TryGetValue(ATableName, TableName) then
    Exit;
  
  AVisited.AddOrSetValue(ATableName, ATableName);
  
  Table := GetTable(ATableName);
  if not Assigned(Table) then
    Exit;
  
  // If table not already in model, we assume it's being added by caller
  
  RelatedTables := GetRelatedTables(ATableName);
  try
    for Table in RelatedTables do
    begin
      if not AVisited.ContainsKey(Table.ObjectName) then
      begin
        // Table should be added by caller if needed
        AddRelatedTablesRecursively(Table.ObjectName, AVisited);
      end;
    end;
  finally
    RelatedTables.Free;
  end;
end;

procedure TERModel.AutoLayout;
var
  i, j: Integer;
  Table: TTableObject;
  X, Y, RowHeight: Integer;
  TablesPerRow: Integer;
begin
  TablesPerRow := 5;
  RowHeight := 200;
  X := 50;
  Y := 50;
  
  for i := 0 to FTables.Count - 1 do
  begin
    Table := FTables[i];
    Table.Left := X;
    Table.Top := Y;
    Table.AutoSize;
    
    Inc(X, Table.Width + 50);
    
    if ((i + 1) mod TablesPerRow = 0) and (i < FTables.Count - 1) then
    begin
      X := 50;
      Inc(Y, RowHeight);
    end;
  end;
end;

end.
