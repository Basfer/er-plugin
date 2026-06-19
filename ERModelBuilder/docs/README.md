# ER Model Builder Plugin for PL/SQL Developer

## Overview

ER Model Builder is a plugin for PL/SQL Developer version 15 that allows you to build Entity-Relationship (ER) models from Oracle database metadata.

## Features

### Three Operation Modes

1. **Whole Database** - Build an ER model for all schemas in the database
2. **Selected Schema** - Build an ER model for a specific schema
3. **Selected Tables** - Parse SQL text from the active editor tab and build a model for:
   - Tables explicitly mentioned in the SQL
   - All tables related via foreign keys (recursive)

### Supported Objects

- Tables
- Views
- Synonyms (automatically resolved to base tables)

### Constraint Support

- Primary Keys (including composite)
- Foreign Keys (including composite)
- Unique Constraints
- Check Constraints

### Export Formats

- **JSON** - Full model serialization with layout information
- **XML** - Alternative serialization format
- PDF (planned)
- Visio VSDX (planned)

## Installation

1. Compile the plugin using Delphi (recommended: Delphi 10.x or later)
2. Copy `ERModelBuilder.dll` to the PL/SQL Developer plugins directory:
   ```
   C:\Program Files\PLSQL Developer\Plugins\
   ```
3. Restart PL/SQL Developer

## Usage

After installation, the plugin adds menu items under the "Tools" or "Plugins" menu:

- **ER Model: Whole Database** - Build model for entire database
- **ER Model: Selected Schema...** - Choose a schema and build its model
- **ER Model: Selected Tables** - Use on selected SQL text in editor

### Building a Model from SQL Text

1. Open a SQL file or query in PL/SQL Developer
2. Select the SQL text (or place cursor in the editor)
3. Choose "ER Model: Selected Tables" from the menu
4. The parser will extract table names from:
   - SELECT ... FROM clauses
   - JOIN clauses
   - INSERT INTO statements
   - UPDATE statements
   - DELETE FROM statements
   - MERGE INTO statements
5. Related tables (via FK relationships) are automatically included

## File Formats

### JSON Format

```json
{
  "version": "1.0",
  "databaseName": "ORCL",
  "schemaName": "HR",
  "created": "2024-01-15 10:30:00",
  "modified": "2024-01-15 10:30:00",
  "canvasWidth": 2000,
  "canvasHeight": 2000,
  "tables": [
    {
      "objectName": "EMPLOYEES",
      "objectType": "TABLE",
      "owner": "HR",
      "columns": [...],
      "primaryKey": {...},
      "foreignKeys": [...],
      "uniqueConstraints": [...],
      "checkConstraints": [...]
    }
  ],
  "allForeignKeys": [...]
}
```

### XML Format

```xml
<?xml version="1.0" encoding="UTF-8"?>
<erModel version="1.0">
  <header>
    <databaseName>ORCL</databaseName>
    <schemaName>HR</schemaName>
    <created>2024-01-15 10:30:00</created>
    ...
  </header>
  <tables>
    <table>
      <objectName>EMPLOYEES</objectName>
      ...
    </table>
  </tables>
  <allForeignKeys>
    ...
  </allForeignKeys>
</erModel>
```

## Architecture

### Core Components

| Unit | Description |
|------|-------------|
| `uConstants` | Plugin constants and configuration |
| `uDataModel` | Data structures for tables, columns, constraints |
| `uMetadataExtractor` | Oracle metadata extraction via OCI |
| `uSQLParser` | SQL text parser for table extraction |
| `uJsonSerializer` | JSON serialization/deserialization |
| `uXmlSerializer` | XML serialization/deserialization |
| `uERDiagramForm` | Interactive diagram visualization (in development) |
| `uPluginMain` | PL/SQL Developer API integration |

### Data Model Classes

- `TColumn` - Column metadata
- `TForeignKey` - Foreign key relationship (supports composite keys)
- `TCheckConstraint` - Check constraint
- `TTableObject` - Table/view/synonym with all metadata
- `TERModel` - Complete ER model container

## Development

### Requirements

- Delphi 10.x or later (or compatible Pascal compiler)
- Oracle Client (OCI) installed
- PL/SQL Developer 15 SDK headers

### Building

```bash
dcc32 -B src\ERModelBuilder.dpr
```

### Testing

1. Set up a test Oracle database with sample schemas (HR, OE, etc.)
2. Create test tables with various constraints
3. Test each operation mode
4. Verify JSON/XML output

## Roadmap

### MVP (Current)
- [x] Basic plugin structure
- [x] Data model classes
- [x] SQL parser for table extraction
- [x] Metadata extractor interface
- [x] JSON/XML serialization
- [ ] OCI implementation for queries
- [ ] Interactive diagram form
- [ ] Auto-layout algorithm

### Future Releases
- [ ] Interactive ER diagram with drag-and-drop
- [ ] PDF export
- [ ] Visio VSDX export
- [ ] Reverse engineering (DDL generation)
- [ ] Model comparison
- [ ] PNG/SVG export
- [ ] Custom styling options

## License

[Your License Here]

## Support

For issues and feature requests, please contact [Your Contact Info].
