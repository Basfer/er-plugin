library ERModelBuilder;

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  uPluginMain;

{$R *.res}

// DLL export for PL/SQL Developer plugin interface
exports
  pdev_init,
  pdev_uninit,
  pdev_getinfo,
  pdev_execute;

begin
end.
