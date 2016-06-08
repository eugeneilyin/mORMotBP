/// To embed assets to exe add the next three PRE-BUILD events to your Project
//
// ..\Tools\assetslz.exe Assets Assets.synlz
// ..\Tools\resedit.exe $(INPUTNAME).res rcdata ASSETS Assets.synlz
// DEL Assets.synlz

program mORMotBPTests;

{$APPTYPE CONSOLE}

{$R *.res}

{$I SynDprUses.inc} // Get rid of W1029 annoing warnings

{$UNDEF COMPRESSSYNLZ}

uses
  BoilerplateTests,
  BoilerplateAssets in '..\BoilerplateAssets.pas',
  BoilerplateHTTPServer in '..\BoilerplateHTTPServer.pas';

begin
  with TBoilerplateTestsSuite.Create do
  try
    RunAsConsole;
    CleanUp;
  finally
    Free;
  end;
end.
