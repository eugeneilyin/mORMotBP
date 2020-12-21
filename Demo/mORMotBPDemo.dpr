{===============================================================================

WARNING!
Before running the tests you must build Assets.res file

To do this add the next two events to the "Pre-build events" project options:

"$(PROJECTDIR)\..\Tools\assetslz" -GZ1 -B1 "$(PROJECTDIR)\..\Assets" "$(PROJECTDIR)\Assets.tmp"
"$(PROJECTDIR)\..\Tools\resedit" -D "$(PROJECTDIR)\Assets.res" rcdata ASSETS "$(PROJECTDIR)\Assets.tmp"

For Delphi 2007 IDE and above:

  Project / Options / Build Events / Pre-build events / Commands

    (if you don't see the "Build Events" section: save, close and reopen
    the project. This is known issue on old IDEs when .dproj missed)

For Delphi 6/7/2005/2006 IDE:

  Component / Install Packages / Add

    Tools\BuildEvents\BuildEventsD6.bpl for Delphi 6
    Tools\BuildEvents\BuildEventsD7.bpl for Delphi 7
    Tools\BuildEvents\BuildEventsD2005.bpl for Delphi 2005
    Tools\BuildEvents\BuildEventsD2006.bpl for Delphi 2006

  Project / Build Events / Pre-build events

For Free Pascal Lazarus IDE (when this file opened):

  Run / Build File

===============================================================================}

{$IFDEF LINUX}
  {%BuildCommand pre-build.sh $ProjPath()}
{$ENDIF}
{$IFDEF MSWINDOWS}
  {%BuildCommand pre-build.bat "$ProjPath()"}
{$ENDIF}

program mORMotBPDemo;

{$APPTYPE CONSOLE}

{$R Assets.res}

uses
  {$I SynDprUses.inc} // enable FastMM4 prior to Delphi 2006, and enable FPC on Linux
  SynCommons,
  mORMot,
  mORMotHttpServer,
  BoilerplateAssets in '..\BoilerplateAssets.pas',
  BoilerplateHTTPServer in '..\BoilerplateHTTPServer.pas';

var
  Model: TSQLModel;
  Server: TSQLRestServer;
  HTTPServer: TBoilerplateHTTPServer;
  AutoModel, AutoServer, AutoHTTPServer: IAutoFree;
begin
  AutoModel := TAutoFree.One(Model, TSQLModel.Create([]));
  AutoServer := TAutoFree.One(Server, TSQLRestServerFullMemory.Create(Model));
  AutoHTTPServer := TAutoFree.One(HTTPServer, TBoilerplateHTTPServer.Create(
    '8092', Server, '+', HTTP_DEFAULT_MODE, 32, secNone, '/'));

  HTTPServer.LoadFromResource('ASSETS');
  // Uncomment the next line to use low-level HTTP.sys file transferring
  // HTTPServer.StaticRoot := 'static';

  Writeln('mORMot Boilerplate HTTP Server launched on port 8092');
  Writeln('Using ' + HTTPServer.HttpServer.ClassName);
  Writeln('');
  Writeln('You can check it on http://localhost:8092');
  Writeln('');
  Writeln('Press [Enter] to close the server.');
  ReadLn;

  // There is a known mORMotHTTPServer issue with a termination sequesnce
  // So we can detach DBServers from HTTPServer before destruction
  {$IFDEF FPC} HTTPServer.RemoveServer(Server); {$ENDIF}
end.
