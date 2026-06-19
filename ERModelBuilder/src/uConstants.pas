unit uConstants;

interface

const
  // Plugin information
  PLUGIN_NAME = 'ER Model Builder';
  PLUGIN_VERSION = '1.0.0';
  PLUGIN_AUTHOR = 'Plugin Developer';
  
  // Menu items
  MENU_ITEM_MAIN = 'Build ER Model...';
  MENU_ITEM_WHOLE_DB = 'ER Model: Whole Database';
  MENU_ITEM_SCHEMA = 'ER Model: Selected Schema...';
  MENU_ITEM_SELECTED_TABLES = 'ER Model: Selected Tables';
  
  // Operation modes
  MODE_WHOLE_DB = 0;
  MODE_SCHEMA = 1;
  MODE_SELECTED_TABLES = 2;
  
  // Object types
  OBJ_TYPE_TABLE = 'TABLE';
  OBJ_TYPE_VIEW = 'VIEW';
  OBJ_TYPE_SYNONYM = 'SYNONYM';
  
  // Constraint types
  CONSTRAINT_PK = 'P';
  CONSTRAINT_FK = 'R';
  CONSTRAINT_UNIQUE = 'U';
  CONSTRAINT_CHECK = 'C';
  
  // File formats
  FORMAT_JSON = 'JSON';
  FORMAT_XML = 'XML';
  FORMAT_PDF = 'PDF';
  FORMAT_VISIO = 'VISIO';
  
  // Default settings
  DEFAULT_CANVAS_WIDTH = 2000;
  DEFAULT_CANVAS_HEIGHT = 2000;
  TABLE_MIN_WIDTH = 150;
  TABLE_ROW_HEIGHT = 20;
  TABLE_HEADER_HEIGHT = 25;
  CONNECTION_LINE_COLOR = clGray;
  PK_COLOR = clYellow;
  FK_COLOR = clLtGray;
  
implementation

end.
