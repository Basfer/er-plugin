unit uSQLParser;

interface

uses
  Classes, Generics.Collections;

type
  TSQLTokenType = (
    stKeyword,
    stIdentifier,
    stString,
    stNumber,
    stOperator,
    stComma,
    stDot,
    stParenOpen,
    stParenClose,
    stWhitespace,
    stComment,
    stUnknown
  );

  TSQLToken = record
    TokenType: TSQLTokenType;
    TokenValue: string;
    Position: Integer;
    Length: Integer;
  end;

  TParsedTable = record
    TableName: string;
    SchemaName: string;
    Alias: string;
    ObjectType: string; // TABLE, VIEW, SYNONYM
  end;

  TSQLParser = class
  private
    FSQL: string;
    FTokens: TList<TSQLToken>;
    FCurrentPos: Integer;
    
    procedure Tokenize;
    function GetCurrentToken: TSQLToken;
    procedure Advance;
    function Match(TokenType: TSQLTokenType): Boolean;
    function Expect(TokenType: TSQLTokenType): Boolean;
    
    procedure ParseSelectStatement(ATables: TDictionary<string, TParsedTable>);
    procedure ParseFromClause(ATables: TDictionary<string, TParsedTable>);
    procedure ParseJoinClause(ATables: TDictionary<string, TParsedTable>);
    procedure ParseInsertStatement(ATables: TDictionary<string, TParsedTable>);
    procedure ParseUpdateStatement(ATables: TDictionary<string, TParsedTable>);
    procedure ParseDeleteStatement(ATables: TDictionary<string, TParsedTable>);
    procedure ParseMergeStatement(ATables: TDictionary<string, TParsedTable>);
    
    function ExtractTableName(const ASchema: string; const AName: string; out AObject: TParsedTable): Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // Main parsing method - extracts all table references from SQL
    function ParseSQL(const ASQL: string): TDictionary<string, TParsedTable>;
    
    // Parse specific statement types
    function ParseSelectTables(const ASQL: string): TDictionary<string, TParsedTable>;
    function ParseDMLTables(const ASQL: string): TDictionary<string, TParsedTable>;
    
    // Utility methods
    class function IsKeyword(const AWord: string): Boolean; static;
    class function NormalizeTableName(const AName: string): string; static;
  end;

implementation

uses
  SysUtils, Character, uConstants;

{ TSQLParser }

constructor TSQLParser.Create;
begin
  inherited Create;
  FTokens := TList<TSQLToken>.Create;
end;

destructor TSQLParser.Destroy;
begin
  FTokens.Free;
  inherited Destroy;
end;

class function TSQLParser.IsKeyword(const AWord: string): Boolean;
const
  Keywords: array[0..49] of string = (
    'SELECT', 'FROM', 'WHERE', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'OUTER', 'ON',
    'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE', 'MERGE', 'WHEN', 'THEN', 'ELSE',
    'AND', 'OR', 'NOT', 'IN', 'EXISTS', 'BETWEEN', 'LIKE', 'IS', 'NULL', 'AS',
    'GROUP', 'BY', 'HAVING', 'ORDER', 'ASC', 'DESC', 'UNION', 'ALL', 'DISTINCT',
    'CREATE', 'ALTER', 'DROP', 'TABLE', 'VIEW', 'INDEX', 'CONSTRAINT', 'PRIMARY', 'FOREIGN', 'KEY'
  );
var
  i: Integer;
  UpperWord: string;
begin
  UpperWord := UpperCase(AWord);
  Result := False;
  for i := 0 to High(Keywords) do
  begin
    if UpperWord = Keywords[i] then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

class function TSQLParser.NormalizeTableName(const AName: string): string;
begin
  Result := Trim(AName);
  // Remove quotes if present
  if (Result.StartsWith('"') and Result.EndsWith('"')) or
     (Result.StartsWith('[') and Result.EndsWith(']')) or
     (Result.StartsWith('`') and Result.EndsWith('`')) then
    Result := Copy(Result, 2, Length(Result) - 2);
  // Convert to uppercase for Oracle
  Result := UpperCase(Result);
end;

procedure TSQLParser.Tokenize;
var
  i: Integer;
  CurrentChar: Char;
  Token: TSQLToken;
  StartPos: Integer;
  InString: Boolean;
  StringChar: Char;
begin
  FTokens.Clear;
  i := 1;
  
  while i <= Length(FSQL) do
  begin
    CurrentChar := FSQL[i];
    StartPos := i;
    
    // Skip whitespace
    if CurrentChar.IsWhiteSpace then
    begin
      while (i <= Length(FSQL)) and FSQL[i].IsWhiteSpace do
        Inc(i);
      Token.TokenType := stWhitespace;
      Token.TokenValue := Copy(FSQL, StartPos, i - StartPos);
      Token.Position := StartPos;
      Token.Length := i - StartPos;
      FTokens.Add(Token);
      Continue;
    end;
    
    // Check for comments
    if (i < Length(FSQL)) and (FSQL[i] = '-') and (FSQL[i+1] = '-') then
    begin
      // Single line comment
      while (i <= Length(FSQL)) and (FSQL[i] <> #10) do
        Inc(i);
      Token.TokenType := stComment;
      Token.TokenValue := Copy(FSQL, StartPos, i - StartPos);
      Token.Position := StartPos;
      Token.Length := i - StartPos;
      FTokens.Add(Token);
      Continue;
    end;
    
    if (i < Length(FSQL)) and (FSQL[i] = '/') and (FSQL[i+1] = '*') then
    begin
      // Multi-line comment
      Inc(i, 2);
      while (i < Length(FSQL)) and not ((FSQL[i] = '*') and (FSQL[i+1] = '/')) do
        Inc(i);
      Inc(i, 2);
      Token.TokenType := stComment;
      Token.TokenValue := Copy(FSQL, StartPos, i - StartPos);
      Token.Position := StartPos;
      Token.Length := i - StartPos;
      FTokens.Add(Token);
      Continue;
    end;
    
    // Check for strings
    if (CurrentChar = '''') or (CurrentChar = '"') then
    begin
      StringChar := CurrentChar;
      Inc(i);
      while (i <= Length(FSQL)) and (FSQL[i] <> StringChar) do
      begin
        if FSQL[i] = '\' then
          Inc(i, 2) // Skip escaped character
        else
          Inc(i);
      end;
      if i <= Length(FSQL) then
        Inc(i); // Skip closing quote
      
      Token.TokenType := stString;
      Token.TokenValue := Copy(FSQL, StartPos, i - StartPos);
      Token.Position := StartPos;
      Token.Length := i - StartPos;
      FTokens.Add(Token);
      Continue;
    end;
    
    // Check for operators and punctuation
    case CurrentChar of
      ',': begin
        Token.TokenType := stComma;
        Token.TokenValue := ',';
        Inc(i);
      end;
      '.': begin
        Token.TokenType := stDot;
        Token.TokenValue := '.';
        Inc(i);
      end;
      '(': begin
        Token.TokenType := stParenOpen;
        Token.TokenValue := '(';
        Inc(i);
      end;
      ')': begin
        Token.TokenType := stParenClose;
        Token.TokenValue := ')';
        Inc(i);
      end;
      '+', '-', '*', '/', '=', '<', '>', '!': begin
        Token.TokenType := stOperator;
        Token.TokenValue := CurrentChar;
        Inc(i);
        // Check for two-character operators
        if (i <= Length(FSQL)) and (FSQL[i] in ['=', '<', '>']) then
        begin
          Token.TokenValue := Token.TokenValue + FSQL[i];
          Inc(i);
        end;
      end;
    else
      begin
        // Identifier or keyword
        while (i <= Length(FSQL)) and 
              (not FSQL[i].IsWhiteSpace) and 
              (not (FSQL[i] in [',', '.', '(', ')', '+', '-', '*', '/', '=', '<', '>', '!', ''', '"'])) do
          Inc(i);
        
        Token.TokenValue := Copy(FSQL, StartPos, i - StartPos);
        Token.Position := StartPos;
        Token.Length := i - StartPos;
        
        if IsKeyword(Token.TokenValue) then
          Token.TokenType := stKeyword
        else
          Token.TokenType := stIdentifier;
      end;
    end;
    
    Token.Position := StartPos;
    Token.Length := i - StartPos;
    FTokens.Add(Token);
  end;
end;

function TSQLParser.GetCurrentToken: TSQLToken;
begin
  if (FCurrentPos >= 0) and (FCurrentPos < FTokens.Count) then
    Result := FTokens[FCurrentPos]
  else
  begin
    Result.TokenType := stUnknown;
    Result.TokenValue := '';
    Result.Position := -1;
    Result.Length := 0;
  end;
end;

procedure TSQLParser.Advance;
begin
  Inc(FCurrentPos);
end;

function TSQLParser.Match(TokenType: TSQLTokenType): Boolean;
begin
  Result := GetCurrentToken.TokenType = TokenType;
  if Result then
    Advance;
end;

function TSQLParser.Expect(TokenType: TSQLTokenType): Boolean;
begin
  Result := Match(TokenType);
  // Could add error handling here if needed
end;

function TSQLParser.ExtractTableName(const ASchema: string; const AName: string; out AObject: TParsedTable): Boolean;
begin
  AObject.TableName := NormalizeTableName(AName);
  AObject.SchemaName := NormalizeTableName(ASchema);
  AObject.Alias := '';
  AObject.ObjectType := OBJ_TYPE_TABLE; // Default, will be resolved later
  Result := AObject.TableName <> '';
end;

procedure TSQLParser.ParseFromClause(ATables: TDictionary<string, TParsedTable>);
var
  Token: TSQLToken;
  SchemaName, TableName, AliasName: string;
  ParsedObj: TParsedTable;
begin
  // Skip FROM keyword
  if not Match(stKeyword) then Exit;
  
  while FCurrentPos < FTokens.Count do
  begin
    Token := GetCurrentToken;
    
    // Stop at WHERE, GROUP, ORDER, UNION, etc.
    if Token.TokenType = stKeyword then
    begin
      if Token.TokenValue.ToUpper in ['WHERE', 'GROUP', 'ORDER', 'UNION', 'INTERSECT', 'MINUS'] then
        Break;
      // Check for JOIN keywords
      if Token.TokenValue.ToUpper in ['JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'OUTER', 'CROSS'] then
      begin
        ParseJoinClause(ATables);
        Continue;
      end;
    end;
    
    // Read table name (possibly schema.table)
    SchemaName := '';
    TableName := '';
    AliasName := '';
    
    if Token.TokenType = stIdentifier then
    begin
      TableName := Token.TokenValue;
      Advance;
      
      // Check for schema.table
      if Match(stDot) then
      begin
        SchemaName := TableName;
        if GetCurrentToken.TokenType = stIdentifier then
        begin
          TableName := GetCurrentToken.TokenValue;
          Advance;
        end;
      end;
      
      // Check for alias (AS keyword is optional)
      if Match(stKeyword) and (GetCurrentToken.TokenValue.ToUpper = 'AS') then
        Advance;
      
      if GetCurrentToken.TokenType = stIdentifier then
      begin
        AliasName := GetCurrentToken.TokenValue;
        Advance;
      end;
      
      // Add to tables dictionary
      if ExtractTableName(SchemaName, TableName, ParsedObj) then
      begin
        ParsedObj.Alias := AliasName;
        ATables.AddOrSetValue(ParsedObj.TableName, ParsedObj);
      end;
    end
    else
    begin
      Advance;
    end;
    
    // Check for comma (multiple tables in FROM)
    if not Match(stComma) then
      Break;
  end;
end;

procedure TSQLParser.ParseJoinClause(ATables: TDictionary<string, TParsedTable>);
var
  Token: TSQLToken;
  SchemaName, TableName, AliasName: string;
  ParsedObj: TParsedTable;
begin
  // Skip join type keywords (INNER, LEFT, RIGHT, etc.)
  while GetCurrentToken.TokenType = stKeyword do
  begin
    Token := GetCurrentToken;
    if Token.TokenValue.ToUpper = 'JOIN' then
    begin
      Advance;
      Break;
    end;
    Advance;
  end;
  
  // Read table name
  if GetCurrentToken.TokenType = stIdentifier then
  begin
    TableName := GetCurrentToken.TokenValue;
    Advance;
    
    // Check for schema.table
    if Match(stDot) then
    begin
      SchemaName := TableName;
      if GetCurrentToken.TokenType = stIdentifier then
      begin
        TableName := GetCurrentToken.TokenValue;
        Advance;
      end;
    end
    else
      SchemaName := '';
    
    // Check for alias
    AliasName := '';
    if Match(stKeyword) and (GetCurrentToken.TokenValue.ToUpper = 'AS') then
      Advance;
    
    if GetCurrentToken.TokenType = stIdentifier then
    begin
      AliasName := GetCurrentToken.TokenValue;
      Advance;
    end;
    
    // Add to tables
    if ExtractTableName(SchemaName, TableName, ParsedObj) then
    begin
      ParsedObj.Alias := AliasName;
      ATables.AddOrSetValue(ParsedObj.TableName, ParsedObj);
    end;
  end;
  
  // Skip ON clause
  if GetCurrentToken.TokenType = stKeyword then
  begin
    if GetCurrentToken.TokenValue.ToUpper = 'ON' then
    begin
      Advance;
      // Skip until next JOIN or end of condition
      while (FCurrentPos < FTokens.Count) and 
            not ((GetCurrentToken.TokenType = stKeyword) and 
                 (GetCurrentToken.TokenValue.ToUpper in ['JOIN', 'WHERE', 'GROUP', 'ORDER', 'UNION'])) do
        Advance;
    end;
  end;
end;

procedure TSQLParser.ParseSelectStatement(ATables: TDictionary<string, TParsedTable>);
begin
  // Skip SELECT keyword and column list
  while FCurrentPos < FTokens.Count do
  begin
    if GetCurrentToken.TokenType = stKeyword then
    begin
      if GetCurrentToken.TokenValue.ToUpper = 'FROM' then
      begin
        ParseFromClause(ATables);
        Break;
      end;
    end;
    Advance;
  end;
end;

procedure TSQLParser.ParseInsertStatement(ATables: TDictionary<string, TParsedTable>);
var
  SchemaName, TableName: string;
  ParsedObj: TParsedTable;
begin
  // Skip INSERT keyword
  if not Match(stKeyword) then Exit;
  
  // Check for INTO
  if GetCurrentToken.TokenType = stKeyword then
  begin
    if GetCurrentToken.TokenValue.ToUpper = 'INTO' then
      Advance;
  end;
  
  // Read table name
  if GetCurrentToken.TokenType = stIdentifier then
  begin
    TableName := GetCurrentToken.TokenValue;
    Advance;
    
    // Check for schema.table
    if Match(stDot) then
    begin
      SchemaName := TableName;
      if GetCurrentToken.TokenType = stIdentifier then
      begin
        TableName := GetCurrentToken.TokenValue;
        Advance;
      end;
    end
    else
      SchemaName := '';
    
    if ExtractTableName(SchemaName, TableName, ParsedObj) then
      ATables.AddOrSetValue(ParsedObj.TableName, ParsedObj);
  end;
end;

procedure TSQLParser.ParseUpdateStatement(ATables: TDictionary<string, TParsedTable>);
var
  SchemaName, TableName: string;
  ParsedObj: TParsedTable;
begin
  // Skip UPDATE keyword
  if not Match(stKeyword) then Exit;
  
  // Read table name
  if GetCurrentToken.TokenType = stIdentifier then
  begin
    TableName := GetCurrentToken.TokenValue;
    Advance;
    
    // Check for schema.table
    if Match(stDot) then
    begin
      SchemaName := TableName;
      if GetCurrentToken.TokenType = stIdentifier then
      begin
        TableName := GetCurrentToken.TokenValue;
        Advance;
      end;
    end
    else
      SchemaName := '';
    
    if ExtractTableName(SchemaName, TableName, ParsedObj) then
      ATables.AddOrSetValue(ParsedObj.TableName, ParsedObj);
  end;
  
  // Skip SET clause and parse FROM/WHERE if present
  while FCurrentPos < FTokens.Count do
  begin
    if GetCurrentToken.TokenType = stKeyword then
    begin
      if GetCurrentToken.TokenValue.ToUpper = 'FROM' then
        ParseFromClause(ATables)
      else if GetCurrentToken.TokenValue.ToUpper = 'WHERE' then
        Break;
    end;
    Advance;
  end;
end;

procedure TSQLParser.ParseDeleteStatement(ATables: TDictionary<string, TParsedTable>);
var
  SchemaName, TableName: string;
  ParsedObj: TParsedTable;
begin
  // Skip DELETE keyword
  if not Match(stKeyword) then Exit;
  
  // Check for FROM
  if GetCurrentToken.TokenType = stKeyword then
  begin
    if GetCurrentToken.TokenValue.ToUpper = 'FROM' then
      Advance;
  end;
  
  // Read table name
  if GetCurrentToken.TokenType = stIdentifier then
  begin
    TableName := GetCurrentToken.TokenValue;
    Advance;
    
    // Check for schema.table
    if Match(stDot) then
    begin
      SchemaName := TableName;
      if GetCurrentToken.TokenType = stIdentifier then
      begin
        TableName := GetCurrentToken.TokenValue;
        Advance;
      end;
    end
    else
      SchemaName := '';
    
    if ExtractTableName(SchemaName, TableName, ParsedObj) then
      ATables.AddOrSetValue(ParsedObj.TableName, ParsedObj);
  end;
end;

procedure TSQLParser.ParseMergeStatement(ATables: TDictionary<string, TParsedTable>);
var
  SchemaName, TableName: string;
  ParsedObj: TParsedTable;
begin
  // Skip MERGE keyword
  if not Match(stKeyword) then Exit;
  
  // Skip INTO if present
  if GetCurrentToken.TokenType = stKeyword then
  begin
    if GetCurrentToken.TokenValue.ToUpper = 'INTO' then
      Advance;
  end;
  
  // Read target table name
  if GetCurrentToken.TokenType = stIdentifier then
  begin
    TableName := GetCurrentToken.TokenValue;
    Advance;
    
    // Check for schema.table
    if Match(stDot) then
    begin
      SchemaName := TableName;
      if GetCurrentToken.TokenType = stIdentifier then
      begin
        TableName := GetCurrentToken.TokenValue;
        Advance;
      end;
    end
    else
      SchemaName := '';
    
    if ExtractTableName(SchemaName, TableName, ParsedObj) then
      ATables.AddOrSetValue(ParsedObj.TableName, ParsedObj);
  end;
  
  // Skip USING and source table/subquery
  while FCurrentPos < FTokens.Count do
  begin
    if GetCurrentToken.TokenType = stKeyword then
    begin
      if GetCurrentToken.TokenValue.ToUpper = 'USING' then
      begin
        Advance;
        // Source could be a table or subquery
        if GetCurrentToken.TokenType = stIdentifier then
        begin
          TableName := GetCurrentToken.TokenValue;
          Advance;
          
          if Match(stDot) then
          begin
            SchemaName := TableName;
            if GetCurrentToken.TokenType = stIdentifier then
            begin
              TableName := GetCurrentToken.TokenValue;
              Advance;
            end;
          end
          else
            SchemaName := '';
          
          if ExtractTableName(SchemaName, TableName, ParsedObj) then
            ATables.AddOrSetValue(ParsedObj.TableName, ParsedObj);
        end;
        Break;
      end;
    end;
    Advance;
  end;
end;

function TSQLParser.ParseSQL(const ASQL: string): TDictionary<string, TParsedTable>;
var
  UpperSQL: string;
begin
  Result := TDictionary<string, TParsedTable>.Create;
  FSQL := ASQL;
  FCurrentPos := 0;
  
  Tokenize;
  
  while FCurrentPos < FTokens.Count do
  begin
    if GetCurrentToken.TokenType = stKeyword then
    begin
      UpperSQL := GetCurrentToken.TokenValue.ToUpper;
      
      if UpperSQL = 'SELECT' then
        ParseSelectStatement(Result)
      else if UpperSQL = 'INSERT' then
        ParseInsertStatement(Result)
      else if UpperSQL = 'UPDATE' then
        ParseUpdateStatement(Result)
      else if UpperSQL = 'DELETE' then
        ParseDeleteStatement(Result)
      else if UpperSQL = 'MERGE' then
        ParseMergeStatement(Result);
    end
    else
      Advance;
  end;
end;

function TSQLParser.ParseSelectTables(const ASQL: string): TDictionary<string, TParsedTable>;
begin
  Result := ParseSQL(ASQL);
end;

function TSQLParser.ParseDMLTables(const ASQL: string): TDictionary<string, TParsedTable>;
begin
  Result := ParseSQL(ASQL);
end;

end.
