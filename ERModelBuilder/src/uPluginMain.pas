unit uPluginMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Menus,
  uConstants, uDataModel, uMetadataExtractor, uSQLParser, uJsonSerializer, uXmlSerializer;

// PL/SQL Developer Plugin API types and constants
const
  PDEV_VERSION = 150; // Version 15.0
  
type
  PPDevPluginInfo = ^TPDevPluginInfo;
  TPDevPluginInfo = record
    Version: Integer;
    Name: PWideChar;
    Description: PWideChar;
    Author: PWideChar;
    MenuItems: Integer;
  end;

  PPDevExecuteParams = ^TPDevExecuteParams;
  TPDevExecuteParams = record
    MenuItem: Integer;
    ConnectionHandle: Pointer; // OCI connection
    DatabaseName: PWideChar;
    CurrentSchema: PWideChar;
    SelectedText: PWideChar;
  end;

// Plugin API functions (exported)
function pdev_init: Integer; stdcall;
procedure pdev_uninit; stdcall;
function pdev_getinfo: PPDevPluginInfo; stdcall;
procedure pdev_execute(Params: PPDevExecuteParams); stdcall;

// Internal plugin state
var
  G_PluginInfo: TPDevPluginInfo;
  G_PluginInfoStr_Name: WideString;
  G_PluginInfoStr_Desc: WideString;
  G_PluginInfoStr_Author: WideString;

implementation

var
  FMainForm: TForm;

function pdev_init: Integer; stdcall;
begin
  // Initialize plugin
  Result := 0; // Success
end;

procedure pdev_uninit; stdcall;
begin
  // Cleanup
  if Assigned(FMainForm) then
    FMainForm.Free;
end;

function pdev_getinfo: PPDevPluginInfo; stdcall;
begin
  G_PluginInfoStr_Name := PLUGIN_NAME;
  G_PluginInfoStr_Desc := 'Build ER models from database metadata';
  G_PluginInfoStr_Author := PLUGIN_AUTHOR;
  
  G_PluginInfo.Version := PDEV_VERSION;
  G_PluginInfo.Name := PWideChar(G_PluginInfoStr_Name);
  G_PluginInfo.Description := PWideChar(G_PluginInfoStr_Desc);
  G_PluginInfo.Author := PWideChar(G_PluginInfoStr_Author);
  G_PluginInfo.MenuItems := 3; // Three menu items for three modes
  
  Result := @G_PluginInfo;
end;

procedure pdev_execute(Params: PPDevExecuteParams); stdcall;
var
  Mode: Integer;
  Extractor: TMetadataExtractor;
  Model: TERModel;
  Parser: TSQLParser;
  TableNames: TStringList;
  Tables: TDictionary<string, TParsedTable>;
  TableName: string;
  ParsedTable: TParsedTable;
  JsonSer: TJsonSerializer;
  XmlSer: TXmlSerializer;
begin
  Mode := Params^.MenuItem;
  
  try
    // Create metadata extractor with current connection
    Extractor := TMetadataExtractor.Create(
      Params^.ConnectionHandle,
      Params^.DatabaseName,
      Params^.CurrentSchema
    );
    try
      case Mode of
        MODE_WHOLE_DB:
          begin
            // Build model for entire database
            Model := Extractor.ExtractWholeDatabase;
          end;
          
        MODE_SCHEMA:
          begin
            // Build model for current schema
            Model := Extractor.ExtractSchema(Params^.CurrentSchema);
          end;
          
        MODE_SELECTED_TABLES:
          begin
            // Parse selected text to extract table names
            Parser := TSQLParser.Create;
            TableNames := TStringList.Create;
            try
              if (Params^.SelectedText <> nil) and (Params^.SelectedText <> '') then
              begin
                Tables := Parser.ParseSQL(Params^.SelectedText);
                for TableName in Tables.Keys do
                  TableNames.Add(TableName);
              end;
              
              // Extract tables with their relations
              if TableNames.Count > 0 then
                Model := Extractor.ExtractTablesWithRelations(TableNames)
              else
              begin
                // No tables found in selection, show error or prompt
                MessageBox(0, 'No tables found in selected text', 'ER Model Builder', MB_OK or MB_ICONWARNING);
                Exit;
              end;
            finally
              Parser.Free;
              TableNames.Free;
              Tables.Free;
            end;
          end;
      else
        Exit;
      end;
      
      // Show the ER diagram form (to be implemented)
      // ShowERDiagramForm(Model);
      
      // For now, just save to JSON as demo
      if Assigned(Model) and (Model.GetTableCount > 0) then
      begin
        JsonSer := TJsonSerializer.Create;
        try
          JsonSer.SaveToFile(Model, 'C:\temp\er_model.json');
          MessageBox(0, 
            PChar('ER Model built successfully!' + #13#10 + 
                  Format('Tables: %d', [Model.GetTableCount]) + #13#10 +
                  'Saved to C:\temp\er_model.json'),
            'ER Model Builder', MB_OK or MB_ICONINFORMATION);
        finally
          JsonSer.Free;
        end;
      end
      else
      begin
        MessageBox(0, 'No tables found in the selected scope', 'ER Model Builder', MB_OK or MB_ICONWARNING);
      end;
      
    finally
      Extractor.Free;
    end;
    
  except
    on E: Exception do
    begin
      MessageBox(0, PChar('Error: ' + E.Message), 'ER Model Builder', MB_OK or MB_ICONERROR);
    end;
  end;
end;

end.
