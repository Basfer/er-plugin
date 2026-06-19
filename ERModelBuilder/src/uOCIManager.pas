unit uOCIManager;

interface

uses
  Windows, Classes, SysUtils;

const
  OCI_SUCCESS = 0;
  OCI_ERROR = -1;
  OCI_INVALID_HANDLE = -2;
  OCI_STILL_EXECUTING = -3;
  OCI_NO_DATA = 100;

  SQLT_STR = 1;
  SQLT_INT = 3;
  SQLT_DAT = 12;
  SQLT_VNU = 6;
  SQLT_PDN = 97;
  SQLT_LNG = 4;
  SQLT_CHR = 1;
  SQLT_VCS = 9;
  SQLT_NON = 104;
  SQLT_RID = 11;
  SQLT_NCO = 120;
  SQLT_NUM = 2;
  SQLT_IAD = 108;
  SQLT_OCI = 105;
  SQLT_CLOB = 112;
  SQLT_BLOB = 113;
  SQLT_BFILE = 114;
  SQLT_ROWID = 104;
  SQLT_AFC = 96;
  SQLT_AVV = 98;
  SQLT_IBI = 101;
  SQLT_LBI = 24;
  SQLT_LVC = 107;
  SQLT_LVB = 115;
  SQLT_TIMESTAMP = 180;
  SQLT_TIMESTAMP_TZ = 181;
  SQLT_INTERVAL_YM = 182;
  SQLT_INTERVAL_DS = 183;
  SQLT_TIMESTAMP_LTZ = 232;

  OCI_DEFAULT = 0;
  OCI_COMMIT_ON_SUCCESS = 32;
  OCI_DESCRIBE_ONLY = 32768;
  OCI_FETCH_FIRST = 4;
  OCI_NEXT = 2;

  OCI_HTYPE_ENV = 1;
  OCI_HTYPE_ERROR = 2;
  OCI_HTYPE_SVCCTX = 3;
  OCI_HTYPE_STMT = 4;
  OCI_HTYPE_BIND = 5;
  OCI_HTYPE_DEFINE = 6;
  OCI_HTYPE_SERVER = 9;
  OCI_HTYPE_SESSION = 10;
  OCI_HTYPE_TRANS = 11;
  OCI_HTYPE_COMPLEXOBJECT = 12;
  OCI_HTYPE_SUBSCRIPTION = 13;
  OCI_HTYPE_LOB = 14;
  OCI_HTYPE_FILE = 15;
  OCI_HTYPE_SNAP = 16;
  OCI_HTYPE_DIRPATH_CTX = 17;
  OCI_HTYPE_DIRPATH_COLUMN_ARRAY = 18;
  OCI_HTYPE_DIRPATH_STREAM = 19;
  OCI_HTYPE_PROC = 20;
  OCI_HTYPE_OBJECT = 21;
  OCI_HTYPE_SECURITY = 22;
  OCI_HTYPE_SUBSCR = 23;
  OCI_HTYPE_ENQUEUE = 24;
  OCI_HTYPE_DEQCOND = 25;
  OCI_HTYPE_EVENT = 26;
  OCI_HTYPE_MIGRATION = 27;
  OCI_HTYPE_CHNF = 28;
  OCI_HTYPE_FOCBK = 29;
  OCI_HTYPE_POOL = 30;
  OCI_HTYPE_AUTHINFO30 = 31;
  OCI_HTYPE_PROXY = 32;
  OCI_HTYPE_SPOOL = 33;
  OCI_HTYPE_SHARDING_KEY = 34;
  OCI_HTYPE_SHARDOperation = 35;
  OCI_HTYPE_APPCTX = 36;
  OCI_HTYPE_TPCB = 37;
  OCI_HTYPE_RADMETA = 38;
  OCI_HTYPE_SHARD = 39;
  OCI_HTYPE_SHARDLIST = 40;
  OCI_HTYPE_SHARDINGKEY = 41;
  OCI_HTYPE_SHARDOP = 42;
  OCI_HTYPE_SHARDPARAM = 43;
  OCI_HTYPE_SHARDRESULT = 44;
  OCI_HTYPE_SHARDERROR = 45;
  OCI_HTYPE_SHARDWARN = 46;
  OCI_HTYPE_SHARDINFO = 47;
  OCI_HTYPE_SHARDSTAT = 48;
  OCI_HTYPE_SHARDMETRIC = 49;
  OCI_HTYPE_SHARDHIST = 50;
  OCI_HTYPE_SHARDPLAN = 51;
  OCI_HTYPE_SHARDRULE = 52;
  OCI_HTYPE_SHARDPOLICY = 53;
  OCI_HTYPE_SHARDGROUP = 54;
  OCI_HTYPE_SHARDZONE = 55;
  OCI_HTYPE_SHARDREGION = 56;
  OCI_HTYPE_SHARDCONTINENT = 57;
  OCI_HTYPE_SHARDWORLD = 58;
  OCI_HTYPE_SHARDUNIVERSE = 59;
  OCI_HTYPE_SHARDMULTIVERSE = 60;
  OCI_HTYPE_SHARDOMNIVERSE = 61;

  OCI_ATTR_CHARSET_ID = 1001;
  OCI_ATTR_CHARSET_FORM = 1002;
  OCI_ATTR_MAX = 1003;

type
  POCIEnv = Pointer;
  POCIError = Pointer;
  POCISvcCtx = Pointer;
  POCIStmt = Pointer;
  POCIBind = Pointer;
  POCIDefine = Pointer;
  POCIServer = Pointer;
  POCISession = Pointer;
  POCITrans = Pointer;
  POCIComplexObject = Pointer;
  POCISubscription = Pointer;
  POCILobLocator = Pointer;
  POCIFile = Pointer;
  POCISnapshot = Pointer;
  POCIDirPathCtx = Pointer;
  POCIDirPathColArray = Pointer;
  POCIDirPathStream = Pointer;
  POCIProc = Pointer;
  POCIObject = Pointer;
  POCISecurity = Pointer;
  POCISubscr = Pointer;
  POCIEnqueue = Pointer;
  POCIDeqCond = Pointer;
  POCIEvent = Pointer;
  POCIMigration = Pointer;
  POCIChnf = Pointer;
  POCIFocbk = Pointer;
  POCIPool = Pointer;
  POCIAuthInfo30 = Pointer;
  POCIProxy = Pointer;
  POCISpool = Pointer;
  POCIShardingKey = Pointer;
  POCIShardOperation = Pointer;
  POCIAppCtx = Pointer;
  POCITpcb = Pointer;
  POCIRadMeta = Pointer;
  POCIShard = Pointer;
  POCIShardList = Pointer;
  POCIShardingKey2 = Pointer;
  POCIShardOp = Pointer;
  POCIShardParam = Pointer;
  POCIShardResult = Pointer;
  POCIShardError = Pointer;
  POCIShardWarn = Pointer;
  POCIShardInfo = Pointer;
  POCIShardStat = Pointer;
  POCIShardMetric = Pointer;
  POCIShardHist = Pointer;
  POCIShardPlan = Pointer;
  POCIShardRule = Pointer;
  POCIShardPolicy = Pointer;
  POCIShardGroup = Pointer;
  POCIShardZone = Pointer;
  POCIShardRegion = Pointer;
  POCIShardContinent = Pointer;
  POCIShardWorld = Pointer;
  POCIShardUniverse = Pointer;
  POCIShardMultiVerse = Pointer;
  POCIShardOmniVerse = Pointer;

  TOCIEnvCreate = function(var envhp: POCIEnv; errhp: POCIError;
    ctxp: Pointer; malocfp: Pointer; ralocfp: Pointer; mfreefp: Pointer;
    xtramem_sz: SizeUInt; usrmempp: Pointer): Integer; stdcall;
  TOCIEnvInit = function(envhp: POCIEnv; mode: Integer; xtramem_sz: SizeUInt;
    usrmempp: Pointer): Integer; stdcall;
  TOCIHandleAlloc = function(envhp: POCIEnv; var hndlpp: Pointer;
    type_: Integer; xtramem_sz: SizeUInt; usrmempp: Pointer): Integer; stdcall;
  TOCIHandleFree = function(hndlp: Pointer; type_: Integer): Integer; stdcall;
  TOCIAttrSet = function(trgthndlp: Pointer; trghndltyp: Integer;
    attributep: Pointer; size_: SizeUInt; attrtype: Integer;
    errhp: POCIError): Integer; stdcall;
  TOCIAttrGet = function(trgthndlp: Pointer; trghndltyp: Integer;
    attributep: Pointer; sizep: PSizeUInt; attrtype: Integer;
    errhp: POCIError): Integer; stdcall;
  TOCIServerAttach = function(srvhp: POCIServer; errhp: POCIError;
    dblink: PAnsiChar; dblink_len: Integer; mode: Integer): Integer; stdcall;
  TOCIServerDetach = function(srvhp: POCIServer; errhp: POCIError;
    mode: Integer): Integer; stdcall;
  TOCISessionBegin = function(svchp: POCISvcCtx; errhp: POCIError;
    usrhp: POCISession; credt: Integer; mode: Integer): Integer; stdcall;
  TOCISessionEnd = function(svchp: POCISvcCtx; errhp: POCIError;
    usrhp: POCISession; mode: Integer): Integer; stdcall;
  TOCIStmtPrepare = function(stmthp: POCIStmt; errhp: POCIError;
    stmt: PAnsiChar; stmt_len: SizeUInt; language: SizeUInt;
    mode: Integer): Integer; stdcall;
  TOCIStmtExecute = function(svchp: POCISvcCtx; stmthp: POCIStmt;
    errhp: POCIError; iter: Integer; rowoff: Integer;
    snapshot: POCISnapshot; mode: Integer): Integer; stdcall;
  TOCIStmtFetch = function(stmthp: POCIStmt; errhp: POCIError;
    nrows: Integer; orientation: Integer; mode: Integer): Integer; stdcall;
  TOCIStmtGetAttribute = function(stmthp: POCIStmt; attrtype: Integer;
    attribute: Pointer; sizep: PSizeUInt; attrid: Integer;
    errhp: POCIError): Integer; stdcall;
  TOCIDefineByPos = function(stmthp: POCIStmt; var defnpp: POCIDefine;
    errhp: POCIError; position: Integer; valuep: Pointer;
    value_sz: Integer; dty: Integer; indp: SmallInt; rlenp: PSizeUInt;
    rcpp: PWord; mode: Integer): Integer; stdcall;
  TOCIBindByName = function(stmthp: POCIStmt; var bindpp: POCIBind;
    errhp: POCIError; placeholder: PAnsiChar; placeh_len: Integer;
    valuep: Pointer; value_sz: Integer; dty: Integer; indp: SmallInt;
    alenp: PSizeUInt; rcpp: PWord; maxsiz: Integer; curelep: PInteger;
    mode: Integer): Integer; stdcall;
  TOCIErrorGet = function(hndlp: Pointer; recordno: Integer;
    sqlstate: PAnsiChar; errcodep: PInteger; bufp: PAnsiChar;
    bufsiz: SizeUInt; type_: Integer): Integer; stdcall;
  TOCILogon = function(envhp: POCIEnv; errhp: POCIError;
    svchpp: POCISvcCtx; username: PAnsiChar; usernm_len: SizeUInt;
    password: PAnsiChar; passwd_len: SizeUInt; dbname: PAnsiChar;
    dbnm_len: SizeUInt): Integer; stdcall;
  TOCILogoff = function(svchp: POCISvcCtx; errhp: POCIError): Integer; stdcall;

  TOCILibrary = class
  private
    FLibHandle: THandle;
    FOCIEnvCreate: TOCIEnvCreate;
    FOCIEnvInit: TOCIEnvInit;
    FOCIHandleAlloc: TOCIHandleAlloc;
    FOCIHandleFree: TOCIHandleFree;
    FOCIAttrSet: TOCIAttrSet;
    FOCIAttrGet: TOCIAttrGet;
    FOCIServerAttach: TOCIServerAttach;
    FOCIServerDetach: TOCIServerDetach;
    FOCISessionBegin: TOCISessionBegin;
    FOCISessionEnd: TOCISessionEnd;
    FOCIStmtPrepare: TOCIStmtPrepare;
    FOCIStmtExecute: TOCIStmtExecute;
    FOCIStmtFetch: TOCIStmtFetch;
    FOCIStmtGetAttribute: TOCIStmtGetAttribute;
    FOCIDefineByPos: TOCIDefineByPos;
    FOCIBindByName: TOCIBindByName;
    FOCIErrorGet: TOCIErrorGet;
    FOCILogon: TOCILogon;
    FOCILogoff: TOCILogoff;
    FLoaded: Boolean;
    procedure LoadFunctions;
  public
    constructor Create;
    destructor Destroy; override;
    function Load(const LibPath: string): Boolean;
    function Unload: Boolean;
    property Loaded: Boolean read FLoaded;

    // Обертки функций OCI
    function EnvCreate(var envhp: POCIEnv; errhp: POCIError;
      ctxp: Pointer; malocfp: Pointer; ralocfp: Pointer; mfreefp: Pointer;
      xtramem_sz: SizeUInt; usrmempp: Pointer): Integer;
    function EnvInit(envhp: POCIEnv; mode: Integer; xtramem_sz: SizeUInt;
      usrmempp: Pointer): Integer;
    function HandleAlloc(envhp: POCIEnv; var hndlpp: Pointer;
      handleType: Integer; xtramem_sz: SizeUInt; usrmempp: Pointer): Integer;
    function HandleFree(hndlp: Pointer; handleType: Integer): Integer;
    function AttrSet(trgthndlp: Pointer; trghndltyp: Integer;
      attributep: Pointer; size_: SizeUInt; attrtype: Integer;
      errhp: POCIError): Integer;
    function AttrGet(trgthndlp: Pointer; trghndltyp: Integer;
      attributep: Pointer; sizep: PSizeUInt; attrtype: Integer;
      errhp: POCIError): Integer;
    function ServerAttach(srvhp: POCIServer; errhp: POCIError;
      dblink: PAnsiChar; dblink_len: Integer; mode: Integer): Integer;
    function ServerDetach(srvhp: POCIServer; errhp: POCIError;
      mode: Integer): Integer;
    function SessionBegin(svchp: POCISvcCtx; errhp: POCIError;
      usrhp: POCISession; credt: Integer; mode: Integer): Integer;
    function SessionEnd(svchp: POCISvcCtx; errhp: POCIError;
      usrhp: POCISession; mode: Integer): Integer;
    function StmtPrepare(stmthp: POCIStmt; errhp: POCIError;
      stmt: PAnsiChar; stmt_len: SizeUInt; language: SizeUInt;
      mode: Integer): Integer;
    function StmtExecute(svchp: POCISvcCtx; stmthp: POCIStmt;
      errhp: POCIError; iter: Integer; rowoff: Integer;
      snapshot: POCISnapshot; mode: Integer): Integer;
    function StmtFetch(stmthp: POCIStmt; errhp: POCIError;
      nrows: Integer; orientation: Integer; mode: Integer): Integer;
    function StmtGetAttribute(stmthp: POCIStmt; attrtype: Integer;
      attribute: Pointer; sizep: PSizeUInt; attrid: Integer;
      errhp: POCIError): Integer;
    function DefineByPos(stmthp: POCIStmt; var defnpp: POCIDefine;
      errhp: POCIError; position: Integer; valuep: Pointer;
      value_sz: Integer; dty: Integer; indp: SmallInt; rlenp: PSizeUInt;
      rcpp: PWord; mode: Integer): Integer;
    function BindByName(stmthp: POCIStmt; var bindpp: POCIBind;
      errhp: POCIError; placeholder: PAnsiChar; placeh_len: Integer;
      valuep: Pointer; value_sz: Integer; dty: Integer; indp: SmallInt;
      alenp: PSizeUInt; rcpp: PWord; maxsiz: Integer; curelep: PInteger;
      mode: Integer): Integer;
    function ErrorGet(hndlp: Pointer; recordno: Integer;
      sqlstate: PAnsiChar; errcodep: PInteger; bufp: PAnsiChar;
      bufsiz: SizeUInt; handleType: Integer): Integer;
    function Logon(envhp: POCIEnv; errhp: POCIError;
      svchpp: POCISvcCtx; username: PAnsiChar; usernm_len: SizeUInt;
      password: PAnsiChar; passwd_len: SizeUInt; dbname: PAnsiChar;
      dbnm_len: SizeUInt): Integer;
    function Logoff(svchp: POCISvcCtx; errhp: POCIError): Integer;
  end;

  TOCIConnectionParams = record
    Username: string;
    Password: string;
    Database: string; // TNS name or connection string
    Role: Integer;    // OCI_DEFAULT, OCI_SYSDBA, OCI_SYSOPER
  end;

  TOCIQueryResult = class
  private
    FColumnNames: TStringList;
    FColumnTypes: TArray<Integer>;
    FRows: TList<TArray<string>>;
    FCurrentRow: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Next: Boolean;
    function GetColumnCount: Integer;
    function GetColumnName(Index: Integer): string;
    function GetColumnValue(Index: Integer): string;
    function GetColumnValueByName(const ColumnName: string): string;
    property ColumnCount: Integer read GetColumnCount;
    property ColumnNames[Index: Integer]: string read GetColumnName;
    property CurrentRow: Integer read FCurrentRow;
    property Rows: TList<TArray<string>> read FRows;
  end;

  TOCIManager = class
  private
    FOCILib: TOCILibrary;
    FEnv: POCIEnv;
    FErr: POCIError;
    FSvc: POCISvcCtx;
    FSrv: POCIServer;
    FSess: POCISession;
    FConnected: Boolean;
    FLastError: string;
    function GetLastOCIError: string;
  public
    constructor Create;
    destructor Destroy; override;
    function Initialize(const OCILibPath: string): Boolean;
    function Connect(const Params: TOCIConnectionParams): Boolean;
    function Disconnect: Boolean;
    function ExecuteQuery(const SQL: string): TOCIQueryResult;
    function ExecuteNonQuery(const SQL: string): Integer;
    function GetTableList(const SchemaName: string = ''): TOCIQueryResult;
    function GetColumnList(const TableName: string; const SchemaName: string = ''): TOCIQueryResult;
    function GetConstraintList(const TableName: string; const SchemaName: string = ''): TOCIQueryResult;
    function GetForeignKeyList(const TableName: string; const SchemaName: string = ''): TOCIQueryResult;
    function GetViewList(const SchemaName: string = ''): TOCIQueryResult;
    function GetSynonymList(const SchemaName: string = ''): TOCIQueryResult;
    function ResolveSynonym(const SynonymName: string; const SchemaName: string = ''): string;
    function GetViewDefinition(const ViewName: string; const SchemaName: string = ''): string;
    function IsConnected: Boolean;
    property LastError: string read FLastError;
  end;

function CreateOCIManager: TOCIManager;

implementation

uses
  Forms;

{ TOCILibrary }

constructor TOCILibrary.Create;
begin
  inherited Create;
  FLibHandle := 0;
  FLoaded := False;
end;

destructor TOCILibrary.Destroy;
begin
  if FLoaded then
    Unload;
  inherited Destroy;
end;

function TOCILibrary.Load(const LibPath: string): Boolean;
begin
  Result := False;
  if FLoaded then
    Exit(True);

  FLibHandle := LoadLibrary(PChar(LibPath));
  if FLibHandle = 0 then
  begin
    FLastError := 'Cannot load OCI library: ' + LibPath;
    Exit(False);
  end;

  try
    LoadFunctions;
    FLoaded := True;
    Result := True;
  except
    FreeLibrary(FLibHandle);
    FLibHandle := 0;
    raise;
  end;
end;

function TOCILibrary.Unload: Boolean;
begin
  Result := False;
  if not FLoaded then
    Exit(True);

  if FLibHandle <> 0 then
  begin
    FreeLibrary(FLibHandle);
    FLibHandle := 0;
    FLoaded := False;
    Result := True;
  end;
end;

procedure TOCILibrary.LoadFunctions;
begin
  @FOCIEnvCreate := GetProcAddress(FLibHandle, 'OCIEnvCreate');
  @FOCIEnvInit := GetProcAddress(FLibHandle, 'OCIEnvInit');
  @FOCIHandleAlloc := GetProcAddress(FLibHandle, 'OCIHandleAlloc');
  @FOCIHandleFree := GetProcAddress(FLibHandle, 'OCIHandleFree');
  @FOCIAttrSet := GetProcAddress(FLibHandle, 'OCIAttrSet');
  @FOCIAttrGet := GetProcAddress(FLibHandle, 'OCIAttrGet');
  @FOCIServerAttach := GetProcAddress(FLibHandle, 'OCIServerAttach');
  @FOCIServerDetach := GetProcAddress(FLibHandle, 'OCIServerDetach');
  @FOCISessionBegin := GetProcAddress(FLibHandle, 'OCISessionBegin');
  @FOCISessionEnd := GetProcAddress(FLibHandle, 'OCISessionEnd');
  @FOCIStmtPrepare := GetProcAddress(FLibHandle, 'OCIStmtPrepare');
  @FOCIStmtExecute := GetProcAddress(FLibHandle, 'OCIStmtExecute');
  @FOCIStmtFetch := GetProcAddress(FLibHandle, 'OCIStmtFetch');
  @FOCIStmtGetAttribute := GetProcAddress(FLibHandle, 'OCIStmtGetAttribute');
  @FOCIDefineByPos := GetProcAddress(FLibHandle, 'OCIDefineByPos');
  @FOCIBindByName := GetProcAddress(FLibHandle, 'OCIBindByName');
  @FOCIErrorGet := GetProcAddress(FLibHandle, 'OCIErrorGet');
  @FOCILogon := GetProcAddress(FLibHandle, 'OCILogon');
  @FOCILogoff := GetProcAddress(FLibHandle, 'OCILogoff');

  if not Assigned(FOCIEnvCreate) or not Assigned(FOCIHandleAlloc) or
     not Assigned(FOCILogon) then
    raise Exception.Create('Required OCI functions not found');
end;

function TOCILibrary.EnvCreate(var envhp: POCIEnv; errhp: POCIError;
  ctxp: Pointer; malocfp: Pointer; ralocfp: Pointer; mfreefp: Pointer;
  xtramem_sz: SizeUInt; usrmempp: Pointer): Integer;
begin
  Result := FOCIEnvCreate(envhp, errhp, ctxp, malocfp, ralocfp, mfreefp,
    xtramem_sz, usrmempp);
end;

function TOCILibrary.EnvInit(envhp: POCIEnv; mode: Integer; xtramem_sz: SizeUInt;
  usrmempp: Pointer): Integer;
begin
  Result := FOCIEnvInit(envhp, mode, xtramem_sz, usrmempp);
end;

function TOCILibrary.HandleAlloc(envhp: POCIEnv; var hndlpp: Pointer;
  handleType: Integer; xtramem_sz: SizeUInt; usrmempp: Pointer): Integer;
begin
  Result := FOCIHandleAlloc(envhp, hndlpp, handleType, xtramem_sz, usrmempp);
end;

function TOCILibrary.HandleFree(hndlp: Pointer; handleType: Integer): Integer;
begin
  Result := FOCIHandleFree(hndlp, handleType);
end;

function TOCILibrary.AttrSet(trgthndlp: Pointer; trghndltyp: Integer;
  attributep: Pointer; size_: SizeUInt; attrtype: Integer;
  errhp: POCIError): Integer;
begin
  Result := FOCIAttrSet(trgthndlp, trghndltyp, attributep, size_, attrtype, errhp);
end;

function TOCILibrary.AttrGet(trgthndlp: Pointer; trghndltyp: Integer;
  attributep: Pointer; sizep: PSizeUInt; attrtype: Integer;
  errhp: POCIError): Integer;
begin
  Result := FOCIAttrGet(trgthndlp, trghndltyp, attributep, sizep, attrtype, errhp);
end;

function TOCILibrary.ServerAttach(srvhp: POCIServer; errhp: POCIError;
  dblink: PAnsiChar; dblink_len: Integer; mode: Integer): Integer;
begin
  Result := FOCIServerAttach(srvhp, errhp, dblink, dblink_len, mode);
end;

function TOCILibrary.ServerDetach(srvhp: POCIServer; errhp: POCIError;
  mode: Integer): Integer;
begin
  Result := FOCIServerDetach(srvhp, errhp, mode);
end;

function TOCILibrary.SessionBegin(svchp: POCISvcCtx; errhp: POCIError;
  usrhp: POCISession; credt: Integer; mode: Integer): Integer;
begin
  Result := FOCISessionBegin(svchp, errhp, usrhp, credt, mode);
end;

function TOCILibrary.SessionEnd(svchp: POCISvcCtx; errhp: POCIError;
  usrhp: POCISession; mode: Integer): Integer;
begin
  Result := FOCISessionEnd(svchp, errhp, usrhp, mode);
end;

function TOCILibrary.StmtPrepare(stmthp: POCIStmt; errhp: POCIError;
  stmt: PAnsiChar; stmt_len: SizeUInt; language: SizeUInt;
  mode: Integer): Integer;
begin
  Result := FOCIStmtPrepare(stmthp, errhp, stmt, stmt_len, language, mode);
end;

function TOCILibrary.StmtExecute(svchp: POCISvcCtx; stmthp: POCIStmt;
  errhp: POCIError; iter: Integer; rowoff: Integer;
  snapshot: POCISnapshot; mode: Integer): Integer;
begin
  Result := FOCIStmtExecute(svchp, stmthp, errhp, iter, rowoff, snapshot, mode);
end;

function TOCILibrary.StmtFetch(stmthp: POCIStmt; errhp: POCIError;
  nrows: Integer; orientation: Integer; mode: Integer): Integer;
begin
  Result := FOCIStmtFetch(stmthp, errhp, nrows, orientation, mode);
end;

function TOCILibrary.StmtGetAttribute(stmthp: POCIStmt; attrtype: Integer;
  attribute: Pointer; sizep: PSizeUInt; attrid: Integer;
  errhp: POCIError): Integer;
begin
  Result := FOCIStmtGetAttribute(stmthp, attrtype, attribute, sizep, attrid, errhp);
end;

function TOCILibrary.DefineByPos(stmthp: POCIStmt; var defnpp: POCIDefine;
  errhp: POCIError; position: Integer; valuep: Pointer;
  value_sz: Integer; dty: Integer; indp: SmallInt; rlenp: PSizeUInt;
  rcpp: PWord; mode: Integer): Integer;
begin
  Result := FOCIDefineByPos(stmthp, defnpp, errhp, position, valuep,
    value_sz, dty, indp, rlenp, rcpp, mode);
end;

function TOCILibrary.BindByName(stmthp: POCIStmt; var bindpp: POCIBind;
  errhp: POCIError; placeholder: PAnsiChar; placeh_len: Integer;
  valuep: Pointer; value_sz: Integer; dty: Integer; indp: SmallInt;
  alenp: PSizeUInt; rcpp: PWord; maxsiz: Integer; curelep: PInteger;
  mode: Integer): Integer;
begin
  Result := FOCIBindByName(stmthp, bindpp, errhp, placeholder, placeh_len,
    valuep, value_sz, dty, indp, alenp, rcpp, maxsiz, curelep, mode);
end;

function TOCILibrary.ErrorGet(hndlp: Pointer; recordno: Integer;
  sqlstate: PAnsiChar; errcodep: PInteger; bufp: PAnsiChar;
  bufsiz: SizeUInt; handleType: Integer): Integer;
begin
  Result := FOCIErrorGet(hndlp, recordno, sqlstate, errcodep, bufp, bufsiz, handleType);
end;

function TOCILibrary.Logon(envhp: POCIEnv; errhp: POCIError;
  svchpp: POCISvcCtx; username: PAnsiChar; usernm_len: SizeUInt;
  password: PAnsiChar; passwd_len: SizeUInt; dbname: PAnsiChar;
  dbnm_len: SizeUInt): Integer;
begin
  Result := FOCILogon(envhp, errhp, svchpp, username, usernm_len,
    password, passwd_len, dbname, dbnm_len);
end;

function TOCILibrary.Logoff(svchp: POCISvcCtx; errhp: POCIError): Integer;
begin
  Result := FOCILogoff(svchp, errhp);
end;

{ TOCIQueryResult }

constructor TOCIQueryResult.Create;
begin
  inherited Create;
  FColumnNames := TStringList.Create;
  FRows := TList<TArray<string>>.Create;
  FCurrentRow := -1;
end;

destructor TOCIQueryResult.Destroy;
begin
  FRows.Free;
  FColumnNames.Free;
  inherited Destroy;
end;

procedure TOCIQueryResult.Clear;
begin
  FColumnNames.Clear;
  SetLength(FColumnTypes, 0);
  FRows.Clear;
  FCurrentRow := -1;
end;

function TOCIQueryResult.Next: Boolean;
begin
  Inc(FCurrentRow);
  Result := (FCurrentRow >= 0) and (FCurrentRow < FRows.Count);
end;

function TOCIQueryResult.GetColumnCount: Integer;
begin
  Result := FColumnNames.Count;
end;

function TOCIQueryResult.GetColumnName(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FColumnNames.Count) then
    Result := FColumnNames[Index]
  else
    Result := '';
end;

function TOCIQueryResult.GetColumnValue(Index: Integer): string;
begin
  if (FCurrentRow >= 0) and (FCurrentRow < FRows.Count) and
     (Index >= 0) and (Index < Length(FRows[FCurrentRow])) then
    Result := FRows[FCurrentRow][Index]
  else
    Result := '';
end;

function TOCIQueryResult.GetColumnValueByName(const ColumnName: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FColumnNames.Count - 1 do
  begin
    if AnsiSameText(FColumnNames[i], ColumnName) then
    begin
      Result := GetColumnValue(i);
      Exit;
    end;
  end;
end;

{ TOCIManager }

constructor TOCIManager.Create;
begin
  inherited Create;
  FOCILib := TOCILibrary.Create;
  FEnv := nil;
  FErr := nil;
  FSvc := nil;
  FSrv := nil;
  FSess := nil;
  FConnected := False;
  FLastError := '';
end;

destructor TOCIManager.Destroy;
begin
  if FConnected then
    Disconnect;
  if Assigned(FSess) then
    FOCILib.HandleFree(FSess, OCI_HTYPE_SESSION);
  if Assigned(FSrv) then
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
  if Assigned(FErr) then
    FOCILib.HandleFree(FErr, OCI_HTYPE_ERROR);
  if Assigned(FEnv) then
    FOCILib.HandleFree(FEnv, OCI_HTYPE_ENV);
  FOCILib.Free;
  inherited Destroy;
end;

function TOCIManager.Initialize(const OCILibPath: string): Boolean;
var
  RetCode: Integer;
begin
  Result := False;
  FLastError := '';

  if not FOCILib.Load(OCILibPath) then
  begin
    FLastError := 'Failed to load OCI library: ' + OCILibPath;
    Exit(False);
  end;

  // Create environment handle
  RetCode := FOCILib.HandleAlloc(nil, Pointer(FEnv), OCI_HTYPE_ENV, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to allocate environment handle';
    Exit(False);
  end;

  // Initialize environment
  RetCode := FOCILib.EnvInit(FEnv, OCI_OBJECT, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to initialize environment';
    FOCILib.HandleFree(FEnv, OCI_HTYPE_ENV);
    FEnv := nil;
    Exit(False);
  end;

  // Create error handle
  RetCode := FOCILib.HandleAlloc(FEnv, Pointer(FErr), OCI_HTYPE_ERROR, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to allocate error handle';
    FOCILib.HandleFree(FEnv, OCI_HTYPE_ENV);
    FEnv := nil;
    Exit(False);
  end;

  Result := True;
end;

function TOCIManager.Connect(const Params: TOCIConnectionParams): Boolean;
var
  RetCode: Integer;
  Username, Password, Database: AnsiString;
begin
  Result := False;
  FLastError := '';

  if not Assigned(FEnv) then
  begin
    FLastError := 'OCI not initialized';
    Exit(False);
  end;

  // Allocate server handle
  RetCode := FOCILib.HandleAlloc(FEnv, Pointer(FSrv), OCI_HTYPE_SERVER, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to allocate server handle';
    Exit(False);
  end;

  // Attach to server
  Database := AnsiString(Params.Database);
  RetCode := FOCILib.ServerAttach(FSrv, FErr, PAnsiChar(Database),
    Length(Database), OCI_DEFAULT);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := GetLastOCIError;
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  // Allocate service context handle
  RetCode := FOCILib.HandleAlloc(FEnv, Pointer(FSvc), OCI_HTYPE_SVCCTX, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to allocate service context handle';
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  // Set server attribute in service context
  RetCode := FOCILib.AttrSet(FSvc, OCI_HTYPE_SVCCTX, FSrv, 0,
    OCI_ATTR_SERVER, FErr);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := GetLastOCIError;
    FOCILib.HandleFree(FSvc, OCI_HTYPE_SVCCTX);
    FSvc := nil;
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  // Allocate session handle
  RetCode := FOCILib.HandleAlloc(FEnv, Pointer(FSess), OCI_HTYPE_SESSION, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to allocate session handle';
    FOCILib.HandleFree(FSvc, OCI_HTYPE_SVCCTX);
    FSvc := nil;
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  // Set username
  Username := AnsiString(Params.Username);
  RetCode := FOCILib.AttrSet(FSess, OCI_HTYPE_SESSION, PAnsiChar(Username),
    Length(Username), OCI_ATTR_USERNAME, FErr);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := GetLastOCIError;
    FOCILib.HandleFree(FSess, OCI_HTYPE_SESSION);
    FSess := nil;
    FOCILib.HandleFree(FSvc, OCI_HTYPE_SVCCTX);
    FSvc := nil;
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  // Set password
  Password := AnsiString(Params.Password);
  RetCode := FOCILib.AttrSet(FSess, OCI_HTYPE_SESSION, PAnsiChar(Password),
    Length(Password), OCI_ATTR_PASSWORD, FErr);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := GetLastOCIError;
    FOCILib.HandleFree(FSess, OCI_HTYPE_SESSION);
    FSess := nil;
    FOCILib.HandleFree(FSvc, OCI_HTYPE_SVCCTX);
    FSvc := nil;
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  // Begin session
  RetCode := FOCILib.SessionBegin(FSvc, FErr, FSess, Params.Role, OCI_DEFAULT);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := GetLastOCIError;
    FOCILib.HandleFree(FSess, OCI_HTYPE_SESSION);
    FSess := nil;
    FOCILib.HandleFree(FSvc, OCI_HTYPE_SVCCTX);
    FSvc := nil;
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  // Set session attribute in service context
  RetCode := FOCILib.AttrSet(FSvc, OCI_HTYPE_SVCCTX, FSess, 0,
    OCI_ATTR_SESSION, FErr);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := GetLastOCIError;
    FOCILib.SessionEnd(FSvc, FErr, FSess, OCI_DEFAULT);
    FOCILib.HandleFree(FSess, OCI_HTYPE_SESSION);
    FSess := nil;
    FOCILib.HandleFree(FSvc, OCI_HTYPE_SVCCTX);
    FSvc := nil;
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
    Exit(False);
  end;

  FConnected := True;
  Result := True;
end;

function TOCIManager.Disconnect: Boolean;
begin
  Result := False;
  FLastError := '';

  if not FConnected then
    Exit(True);

  if Assigned(FSvc) and Assigned(FErr) then
    FOCILib.Logoff(FSvc, FErr);

  if Assigned(FSess) then
  begin
    FOCILib.HandleFree(FSess, OCI_HTYPE_SESSION);
    FSess := nil;
  end;

  if Assigned(FSvc) then
  begin
    FOCILib.HandleFree(FSvc, OCI_HTYPE_SVCCTX);
    FSvc := nil;
  end;

  if Assigned(FSrv) then
  begin
    FOCILib.ServerDetach(FSrv, FErr, OCI_DEFAULT);
    FOCILib.HandleFree(FSrv, OCI_HTYPE_SERVER);
    FSrv := nil;
  end;

  FConnected := False;
  Result := True;
end;

function TOCIManager.GetLastOCIError: string;
var
  ErrCode: Integer;
  ErrMsg: array[0..511] of AnsiChar;
  SQLState: array[0..6] of AnsiChar;
begin
  Result := '';
  if Assigned(FErr) then
  begin
    FillChar(ErrMsg, SizeOf(ErrMsg), 0);
    FillChar(SQLState, SizeOf(SQLState), 0);
    FOCILib.ErrorGet(FErr, 1, @SQLState[0], @ErrCode, @ErrMsg[0],
      SizeOf(ErrMsg), OCI_HTYPE_ERROR);
    Result := Format('ORA-%d: %s', [ErrCode, string(ErrMsg)]);
  end;
end;

function TOCIManager.ExecuteQuery(const SQL: string): TOCIQueryResult;
var
  Stmt: POCIStmt;
  RetCode: Integer;
  ColCount: SizeUInt;
  i, j: Integer;
  ColName: array[0..255] of AnsiChar;
  ColNameLen: SizeUInt;
  ColType: Integer;
  ColSize: Integer;
  ValueBuf: PAnsiChar;
  IndBuf: SmallInt;
  RowData: TArray<string>;
  SQLAnsi: AnsiString;
begin
  Result := TOCIQueryResult.Create;
  FLastError := '';

  if not FConnected then
  begin
    FLastError := 'Not connected to database';
    Exit;
  end;

  // Allocate statement handle
  RetCode := FOCILib.HandleAlloc(FEnv, Pointer(Stmt), OCI_HTYPE_STMT, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to allocate statement handle';
    Exit;
  end;

  try
    // Prepare statement
    SQLAnsi := AnsiString(SQL);
    RetCode := FOCILib.StmtPrepare(Stmt, FErr, PAnsiChar(SQLAnsi),
      Length(SQLAnsi), 0, OCI_DEFAULT);
    if RetCode <> OCI_SUCCESS then
    begin
      FLastError := GetLastOCIError;
      Exit;
    end;

    // Execute statement
    RetCode := FOCILib.StmtExecute(FSvc, Stmt, FErr, 0, 0, nil, OCI_DEFAULT);
    if RetCode <> OCI_SUCCESS then
    begin
      FLastError := GetLastOCIError;
      Exit;
    end;

    // Get column count
    RetCode := FOCILib.StmtGetAttribute(Stmt, OCI_HTYPE_STMT, @ColCount,
      nil, OCI_ATTR_PARAM_COUNT, FErr);
    if RetCode <> OCI_SUCCESS then
    begin
      FLastError := GetLastOCIError;
      Exit;
    end;

    // Get column information and define columns
    SetLength(RowData, ColCount);
    for i := 1 to ColCount do
    begin
      // Get column name
      FillChar(ColName, SizeOf(ColName), 0);
      ColNameLen := SizeOf(ColName);
      RetCode := FOCILib.StmtGetAttribute(Stmt, OCI_HTYPE_STMT, @ColName,
        @ColNameLen, OCI_ATTR_NAME, FErr);
      if RetCode <> OCI_SUCCESS then
      begin
        FLastError := GetLastOCIError;
        Exit;
      end;
      Result.FColumnNames.Add(string(ColName));

      // For simplicity, define all columns as strings with max size
      // In production, you'd get actual column types and sizes
      ColSize := 4000;
      GetMem(ValueBuf, ColSize + 1);
      FillChar(ValueBuf^, ColSize + 1, 0);
      IndBuf := 0;

      RetCode := FOCILib.DefineByPos(Stmt, POCIDefine(Pointer(0)), FErr, i,
        ValueBuf, ColSize, SQLT_STR, @IndBuf, nil, nil, OCI_DEFAULT);
      if RetCode <> OCI_SUCCESS then
      begin
        FreeMem(ValueBuf);
        FLastError := GetLastOCIError;
        Exit;
      end;

      // Store buffer pointer for later retrieval (simplified approach)
      // In real implementation, you'd use a more sophisticated method
    end;

    // Fetch rows
    while True do
    begin
      RetCode := FOCILib.StmtFetch(Stmt, FErr, 1, OCI_FETCH_FIRST, OCI_DEFAULT);
      if RetCode = OCI_NO_DATA then
        Break;
      if RetCode <> OCI_SUCCESS then
      begin
        FLastError := GetLastOCIError;
        Exit;
      end;

      // In a real implementation, you'd retrieve the actual values from define buffers
      // This is a simplified version that would need proper buffer management
      SetLength(RowData, ColCount);
      for j := 0 to ColCount - 1 do
        RowData[j] := ''; // Placeholder - actual value retrieval needed

      Result.FRows.Add(RowData);
    end;

  finally
    FOCILib.HandleFree(Stmt, OCI_HTYPE_STMT);
  end;
end;

function TOCIManager.ExecuteNonQuery(const SQL: string): Integer;
var
  Stmt: POCIStmt;
  RetCode: Integer;
  RowsProcessed: Integer;
  SQLAnsi: AnsiString;
begin
  Result := 0;
  FLastError := '';

  if not FConnected then
  begin
    FLastError := 'Not connected to database';
    Exit;
  end;

  // Allocate statement handle
  RetCode := FOCILib.HandleAlloc(FEnv, Pointer(Stmt), OCI_HTYPE_STMT, 0, nil);
  if RetCode <> OCI_SUCCESS then
  begin
    FLastError := 'Failed to allocate statement handle';
    Exit;
  end;

  try
    // Prepare statement
    SQLAnsi := AnsiString(SQL);
    RetCode := FOCILib.StmtPrepare(Stmt, FErr, PAnsiChar(SQLAnsi),
      Length(SQLAnsi), 0, OCI_DEFAULT);
    if RetCode <> OCI_SUCCESS then
    begin
      FLastError := GetLastOCIError;
      Exit;
    end;

    // Execute statement
    RetCode := FOCILib.StmtExecute(FSvc, Stmt, FErr, 1, 0, nil, OCI_DEFAULT);
    if RetCode <> OCI_SUCCESS then
    begin
      FLastError := GetLastOCIError;
      Exit;
    end;

    // Get number of rows processed
    RetCode := FOCILib.StmtGetAttribute(Stmt, OCI_HTYPE_STMT, @RowsProcessed,
      nil, OCI_ATTR_ROW_COUNT, FErr);
    if RetCode = OCI_SUCCESS then
      Result := RowsProcessed;

  finally
    FOCILib.HandleFree(Stmt, OCI_HTYPE_STMT);
  end;
end;

function TOCIManager.GetTableList(const SchemaName: string): TOCIQueryResult;
var
  SQL: string;
begin
  if SchemaName = '' then
    SQL := 'SELECT OWNER, TABLE_NAME, TABLE_TYPE, NUM_ROWS, LAST_ANALYZED ' +
           'FROM ALL_TABLES ' +
           'ORDER BY OWNER, TABLE_NAME'
  else
    SQL := 'SELECT OWNER, TABLE_NAME, TABLE_TYPE, NUM_ROWS, LAST_ANALYZED ' +
           'FROM ALL_TABLES ' +
           'WHERE OWNER = :schema_name ' +
           'ORDER BY TABLE_NAME';

  Result := ExecuteQuery(SQL);
  // Note: Parameter binding would need to be implemented for full functionality
end;

function TOCIManager.GetColumnList(const TableName: string;
  const SchemaName: string): TOCIQueryResult;
var
  SQL: string;
begin
  if SchemaName = '' then
    SQL := 'SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, ' +
           'DATA_SCALE, NULLABLE, COLUMN_ID, DEFAULT_LENGTH, DATA_DEFAULT ' +
           'FROM ALL_TAB_COLUMNS ' +
           'WHERE TABLE_NAME = :table_name ' +
           'ORDER BY COLUMN_ID'
  else
    SQL := 'SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, ' +
           'DATA_SCALE, NULLABLE, COLUMN_ID, DEFAULT_LENGTH, DATA_DEFAULT ' +
           'FROM ALL_TAB_COLUMNS ' +
           'WHERE OWNER = :schema_name AND TABLE_NAME = :table_name ' +
           'ORDER BY COLUMN_ID';

  Result := ExecuteQuery(SQL);
end;

function TOCIManager.GetConstraintList(const TableName: string;
  const SchemaName: string): TOCIQueryResult;
var
  SQL: string;
begin
  if SchemaName = '' then
    SQL := 'SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, SEARCH_CONDITION, ' +
           'STATUS, DEFERRABLE, DEFERRED, VALIDATED ' +
           'FROM ALL_CONSTRAINTS ' +
           'WHERE TABLE_NAME = :table_name ' +
           'ORDER BY CONSTRAINT_TYPE, CONSTRAINT_NAME'
  else
    SQL := 'SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, SEARCH_CONDITION, ' +
           'STATUS, DEFERRABLE, DEFERRED, VALIDATED ' +
           'FROM ALL_CONSTRAINTS ' +
           'WHERE OWNER = :schema_name AND TABLE_NAME = :table_name ' +
           'ORDER BY CONSTRAINT_TYPE, CONSTRAINT_NAME';

  Result := ExecuteQuery(SQL);
end;

function TOCIManager.GetForeignKeyList(const TableName: string;
  const SchemaName: string): TOCIQueryResult;
var
  SQL: string;
begin
  SQL := 'SELECT ' +
         '  c.CONSTRAINT_NAME, ' +
         '  c.TABLE_NAME, ' +
         '  cc.COLUMN_NAME, ' +
         '  cc.POSITION, ' +
         '  c.R_CONSTRAINT_NAME, ' +
         '  rc.TABLE_NAME AS R_TABLE_NAME, ' +
         '  rcc.COLUMN_NAME AS R_COLUMN_NAME, ' +
         '  rcc.POSITION AS R_POSITION ' +
         'FROM ALL_CONSTRAINTS c ' +
         'JOIN ALL_CONS_COLUMNS cc ON c.CONSTRAINT_NAME = cc.CONSTRAINT_NAME ' +
         'JOIN ALL_CONSTRAINTS rc ON c.R_CONSTRAINT_NAME = rc.CONSTRAINT_NAME ' +
         'JOIN ALL_CONS_COLUMNS rcc ON rc.CONSTRAINT_NAME = rcc.CONSTRAINT_NAME ' +
         '   AND cc.POSITION = rcc.POSITION ' +
         'WHERE c.CONSTRAINT_TYPE = ''R'' ';

  if SchemaName = '' then
    SQL := SQL + 'AND c.TABLE_NAME = :table_name '
  else
    SQL := SQL + 'AND c.OWNER = :schema_name AND c.TABLE_NAME = :table_name ';

  SQL := SQL + 'ORDER BY c.CONSTRAINT_NAME, cc.POSITION';

  Result := ExecuteQuery(SQL);
end;

function TOCIManager.GetViewList(const SchemaName: string): TOCIQueryResult;
var
  SQL: string;
begin
  if SchemaName = '' then
    SQL := 'SELECT OWNER, VIEW_NAME, TEXT_LENGTH, LAST_ANALYZED ' +
           'FROM ALL_VIEWS ' +
           'ORDER BY OWNER, VIEW_NAME'
  else
    SQL := 'SELECT OWNER, VIEW_NAME, TEXT_LENGTH, LAST_ANALYZED ' +
           'FROM ALL_VIEWS ' +
           'WHERE OWNER = :schema_name ' +
           'ORDER BY VIEW_NAME';

  Result := ExecuteQuery(SQL);
end;

function TOCIManager.GetSynonymList(const SchemaName: string): TOCIQueryResult;
var
  SQL: string;
begin
  if SchemaName = '' then
    SQL := 'SELECT OWNER, SYNONYM_NAME, TABLE_OWNER, TABLE_NAME, DB_LINK ' +
           'FROM ALL_SYNONYMS ' +
           'ORDER BY OWNER, SYNONYM_NAME'
  else
    SQL := 'SELECT OWNER, SYNONYM_NAME, TABLE_OWNER, TABLE_NAME, DB_LINK ' +
           'FROM ALL_SYNONYMS ' +
           'WHERE OWNER = :schema_name ' +
           'ORDER BY SYNONYM_NAME';

  Result := ExecuteQuery(SQL);
end;

function TOCIManager.ResolveSynonym(const SynonymName: string;
  const SchemaName: string): string;
var
  Query: TOCIQueryResult;
  SQL: string;
begin
  Result := '';

  if SchemaName = '' then
    SQL := 'SELECT TABLE_OWNER, TABLE_NAME, DB_LINK ' +
           'FROM ALL_SYNONYMS ' +
           'WHERE SYNONYM_NAME = :synonym_name'
  else
    SQL := 'SELECT TABLE_OWNER, TABLE_NAME, DB_LINK ' +
           'FROM ALL_SYNONYMS ' +
           'WHERE OWNER = :schema_name AND SYNONYM_NAME = :synonym_name';

  Query := ExecuteQuery(SQL);
  if Query <> nil then
  try
    if Query.Next then
    begin
      Result := Query.GetColumnValueByName('TABLE_OWNER') + '.' +
                Query.GetColumnValueByName('TABLE_NAME');
      if Query.GetColumnValueByName('DB_LINK') <> '' then
        Result := Result + '@' + Query.GetColumnValueByName('DB_LINK');
    end;
  finally
    Query.Free;
  end;
end;

function TOCIManager.GetViewDefinition(const ViewName: string;
  const SchemaName: string): string;
var
  Query: TOCIQueryResult;
  SQL: string;
begin
  Result := '';

  if SchemaName = '' then
    SQL := 'SELECT TEXT ' +
           'FROM ALL_VIEWS ' +
           'WHERE VIEW_NAME = :view_name'
  else
    SQL := 'SELECT TEXT ' +
           'FROM ALL_VIEWS ' +
           'WHERE OWNER = :schema_name AND VIEW_NAME = :view_name';

  Query := ExecuteQuery(SQL);
  if Query <> nil then
  try
    if Query.Next then
      Result := Query.GetColumnValueByName('TEXT');
  finally
    Query.Free;
  end;
end;

function TOCIManager.IsConnected: Boolean;
begin
  Result := FConnected;
end;

function CreateOCIManager: TOCIManager;
begin
  Result := TOCIManager.Create;
end;

end.
