{===============================================================================

WARNING!
Before running the tests embed required Boilerplate Assets into application

To do this add the next three events to "Pre-Build Events" project options:

Project / Options / BuildEvents / Pre-Build Events

..\Tools\assetslz.exe Assets Assets.synlz
..\Tools\resedit.exe $(INPUTNAME).res rcdata ASSETS Assets.synlz
DEL Assets.synlz

===============================================================================}

program mORMotBPTests;

{$APPTYPE CONSOLE}

{$R *.res}

{$I SynDprUses.inc} // Get rid of W1029 annoing warnings

uses
  BoilerplateTests,
  BoilerplateAssets in '..\BoilerplateAssets.pas',
  BoilerplateHTTPServer in '..\BoilerplateHTTPServer.pas';

begin
  with TBoilerplateFeatures.Create do
  try
    RunAsConsole;
    CleanUp;
  finally
    Free;
  end;
end.
