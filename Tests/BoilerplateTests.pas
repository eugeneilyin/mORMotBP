unit BoilerplateTests;

interface

uses
  SynTests;

type
  TBoilerplateHTTPServerShould = class(TSynTestCase)
    procedure CallInherited;
    procedure ServeExactCaseURL;
    procedure LoadAndReturnAssets;
    procedure SpecifyCrossOrigin;
    procedure SpecifyCrossOriginForImages;
    procedure SpecifyCrossOriginForFonts;
    procedure SpecifyCrossOriginTiming;
    procedure DelegateBadRequestTo404;
    procedure DelegateForbiddenTo404;
    procedure DelegateNotFoundTo404;
    procedure SetXUACompatible;
    procedure ForceMIMEType;
    procedure ForceTextUTF8Charset;
    procedure ForceUTF8Charset;
    procedure ForceHTTPS;
    procedure ForceHTTPSExceptLetsEncrypt;
    procedure SupportWWWRewrite;
    procedure SetXFrameOptions;
    procedure SupportContentSecurityPolicy;
    procedure DelegateBlocked;
    procedure SupportStrictSSLOverHTTP;
    procedure SupportStrictSSLOverHTTPS;
    procedure PreventMIMESniffing;
    procedure EnableXSSFilter;
    procedure EnableReferrerPolicy;
    procedure DeleteXPoweredBy;
    procedure FixMangledAcceptEncoding;
    procedure ForceGZipHeader;
    procedure SetCacheNoTransform;
    procedure SetCachePublic;
    procedure EnableCacheByETag;
    procedure EnableCacheByLastModified;
    procedure SetExpires;
    procedure SetCacheMaxAge;
    procedure EnableCacheBusting;
    procedure EnableCacheBustingBeforeExt;
    procedure SupportStaticRoot;
    procedure DelegateRootToIndex;
    procedure DeleteServerInternalState;
    procedure DelegateIndexToInheritedDefault;
    procedure DelegateIndexToInheritedDefaultOverSSL;
    procedure Delegate404ToInherited_404;
    procedure RegisterCustomOptions;
    procedure UnregisterCustomOptions;
    procedure SetVaryAcceptEncoding;
    procedure RedirectInInherited_404;
    procedure UpdateStaticAsset;
  end;

  TBoilerplateFeatures = class(TSynTests)
    procedure Scenarios;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  SysUtils,
  SynCommons,
  SynCrtSock,
  mORMot,
  mORMotMVC,
  mORMotHttpServer,
  BoilerplateAssets,
  BoilerplateHTTPServer;

{$IFDEF CONDITIONALEXPRESSIONS}  // Delphi 6 or newer
  {$IFNDEF VER140}
    {$WARN UNSAFE_CODE OFF} // Delphi for .Net does not exist any more!
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CAST OFF}
  {$ENDIF}
{$ENDIF}

// The time constants were introduced in Delphi 2009 and
// missed in Delphi 5/6/7/2005/2006/2007, and FPC
{$IF DEFINED(FPC) OR (CompilerVersion < 20)}
const
  HoursPerDay = 24;
  MinsPerHour = 60;
  SecsPerMin  = 60;
  MinsPerDay  = HoursPerDay * MinsPerHour;
  SecsPerDay  = MinsPerDay * SecsPerMin;
  SecsPerHour = SecsPerMin * MinsPerHour;
{$IFEND}

type

{ THttpServerRequestStub }

  IBoilerplateApplication = interface(IMVCApplication)
    ['{79968060-F121-46B9-BA5C-C4740B4445D6}']
    procedure _404(const Dummy: Integer; out Scope: Variant);
  end;

  THttpServerRequestStub = class(THttpServerRequest)
  private
    FResult: Cardinal;
  public
    procedure Init;
    property URL: SockString read FURL write FURL;
    property Method: SockString read FMethod write FMethod;
    property InHeaders: SockString read FInHeaders write FInHeaders;
    property InContent: SockString read FInContent;
    property InContentType: SockString read FInContentType;
    property OutContent: SockString read FOutContent;
    property OutContentType: SockString read FOutContentType;
    property OutCustomHeaders: SockString read FOutCustomHeaders
      write FOutCustomHeaders;
    property Result: Cardinal read FResult write FResult;
    property UseSSL: boolean read FUseSSL write FUseSSL;
  end;

{ TBoilerplateHTTPServerSteps }

  TBoilerplateHTTPServerSteps = class(TBoilerplateHTTPServer)
  private
    FTestCase: TSynTestCase;
    FModel: TSQLModel;
    FServer: TSQLRestServer;
    FApplication: IBoilerplateApplication;
    FContext: THttpServerRequestStub;
  public
    function FullFileName(const FileName: string): string;
    procedure DeleteFile(const FileName: string);
    procedure RemoveDir(const FileName: string);
    function GetFileContent(const FileName: TFileName): RawByteString;
  public
    constructor Create(const TestCase: TSynTestCase;
      const Auth: Boolean = False; AApplication: IBoilerplateApplication = nil;
      AUseSSL: Boolean = False); reintroduce;
    destructor Destroy; override;
    procedure GivenClearServer;
    procedure GivenAssets(const Name: string = 'ASSETS');
    procedure GivenOptions(const AOptions: TBoilerplateOptions);
    procedure GivenInHeader(const aName, aValue: RawUTF8);
    procedure GivenOutHeader(const aName, aValue: RawUTF8);
    procedure GivenServeExactCaseURL(const Value: Boolean = True);
    procedure GivenWWWRewrite(const Value: TWWWRewrite = wwwOff);
    procedure GivenContentSecurityPolicy(const Value: RawUTF8);
    procedure GivenStrictSSL(const Value: TStrictSSL);
    procedure GivenReferrerPolicy(const Value: RawUTF8);
    procedure GivenExpires(const Value: RawUTF8);
    procedure GivenStaticRoot(const Value: TFileName);
    procedure GivenStaticFile(const URL: SockString = '');
    procedure GivenModifiedFile(const FileName: TFileName;
      const KeepTimeStamp, KeepSize: Boolean);
    procedure WhenRequest(const URL: SockString = '';
      const Host: SockString = ''; const UseSSL: Boolean = False);
    procedure ThenOutHeaderValueIs(const aName, aValue: RawUTF8);
    procedure ThenOutContentIsEmpty;
    procedure ThenOutContentEqualsFile(const FileName: TFileName); overload;
    procedure ThenOutContentIsStaticFile(
      const StaticFileName, FileName: TFileName); overload;
    procedure ThenOutContentTypeIs(const Value: RawUTF8);
    procedure ThenOutContentIs(const Value: RawByteString);
    procedure ThenOutContentIsStatic(const FileName: TFileName);
    procedure ThenRequestResultIs(const Value: Cardinal);
    procedure ThenApp404Called;
    procedure ThenFileTimeStampAndSizeIsEqualToAsset(const FileName: TFileName;
      const Path: RawUTF8);
    procedure ThenFileContentIsEqualToAsset(const FileName: TFileName;
      const Path: RawUTF8);
    procedure ThenFileContentIsNotEqualToAsset(const FileName: TFileName;
      const Path: RawUTF8);
  end;

{ TBoilerplateApplication }

  TBoilerplateApplication = class(TMVCApplication, IBoilerplateApplication)
  public
    procedure Start(Server: TSQLRestServer;
      const ViewsFolder: TFileName); reintroduce;
  published
    procedure Error(var Msg: RawUTF8; var Scope: Variant);
    procedure Default(var Scope: Variant);
    procedure _404(const Dummy: Integer; out Scope: Variant);
  end;

{ T404Application }

  T404Application = class(TMVCApplication, IBoilerplateApplication)
  public
    Is404Called: Boolean;
    procedure Start(Server: TSQLRestServer;
      const ViewsFolder: TFileName); reintroduce;
  published
    procedure Error(var Msg: RawUTF8; var Scope: Variant);
    procedure Default(var Scope: Variant);
    procedure _404(const Dummy: Integer; out Scope: Variant);
  end;

function GetMustacheParams(
  const Folder: TFileName): TMVCViewsMustacheParameters;
begin
  Result.Folder := Folder;
  Result.CSVExtensions := '';
  Result.FileTimestampMonitorAfterSeconds := 0;
  Result.ExtensionForNotExistingTemplate := '';
  Result.Helpers := nil;
end;

{ TBoilerplateHTTPServerShould }

procedure TBoilerplateHTTPServerShould.SpecifyCrossOrigin;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    WhenRequest;
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');

    GivenClearServer;
    GivenOptions([bpoAllowCrossOrigin]);
    WhenRequest;
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');

    GivenClearServer;
    GivenOptions([bpoAllowCrossOrigin]);
    GivenInHeader('Origin', 'localhost');
    WhenRequest;
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '*');
  end;
end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOriginForFonts;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/sample.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginFonts]);
    WhenRequest('/sample.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginFonts]);
    GivenInHeader('Origin', 'localhost');
    WhenRequest('/sample.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '*');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOriginForImages;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginImages]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginImages]);
    GivenInHeader('Origin', 'localhost');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '*');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOriginTiming;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginTiming]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Timing-Allow-Origin', '*');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportContentSecurityPolicy;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Security-Policy',
      DEFAULT_CONTENT_SECURITY_POLICY);
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Security-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenContentSecurityPolicy('"script-src ''self''; object-src ''self''"');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Security-Policy',
      '"script-src ''self''; object-src ''self''"');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenContentSecurityPolicy('"script-src ''self''; object-src ''self''"');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Security-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

{$IF DEFINED(VER170) OR DEFINED(VER180)}{$HINTS OFF}{$IFEND}
procedure TBoilerplateHTTPServerShould.SupportStaticRoot;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    WhenRequest('/index.html');
    ThenOutContentIsStaticFile('static\identity\index.html',
      'Assets\index.html');
    DeleteFile('static\identity\index.html');
    RemoveDir('static\identity');
    RemoveDir('static');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutContentIsStaticFile('static\gzip\index.html.gz',
      'Assets\index.html.gz');
    DeleteFile('static\gzip\index.html.gz');
    RemoveDir('static\gzip');
    RemoveDir('static');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenInHeader('Accept-Encoding', 'br');
    WhenRequest('/index.html');
    ThenOutContentIsStaticFile('static\brotli\index.html.br',
      'Assets\index.html.br');
    DeleteFile('static\brotli\index.html.br');
    RemoveDir('static\brotli');
    RemoveDir('static');
  end;
end;
{$IF DEFINED(VER170) OR DEFINED(VER180)}{$HINTS ON}{$IFEND}

procedure TBoilerplateHTTPServerShould.SupportStrictSSLOverHTTP;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOff);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Strict-Transport-Security', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOn);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Strict-Transport-Security', 'max-age=16070400');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLIncludeSubDomains);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Strict-Transport-Security',
      'max-age=16070400; includeSubDomains');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportStrictSSLOverHTTPS;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOff);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLOn);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security', 'max-age=31536000');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenStrictSSL(strictSSLIncludeSubDomains);
    WhenRequest('/index.html', '', True);
    ThenOutHeaderValueIs('Strict-Transport-Security',
      'max-age=31536000; includeSubDomains; preload');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportWWWRewrite;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwOff);
    GivenOptions([]);
    WhenRequest('/index.html', 'www.domain.com');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwOff);
    GivenOptions([]);
    WhenRequest('/index.html', 'www.domain.com', True);
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwSuppress);
    WhenRequest('/index.html', 'www.domain.com');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'http://domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwSuppress);
    WhenRequest('/index.html', 'www.domain.com', True);
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwForce);
    WhenRequest('/index.html', 'domain.com');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'http://www.domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenWWWRewrite(wwwForce);
    WhenRequest('/index.html', 'domain.com', True);
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://www.domain.com/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);
  end;
end;

procedure TBoilerplateHTTPServerShould.UnregisterCustomOptions;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    UnregisterCustomOptions('/index.html');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    RegisterCustomOptions('/404.html', [bpoSetCacheNoCache]);
    UnregisterCustomOptions(TRawUTF8DynArrayFrom(['/index.html', '/404.html']));
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index*', [bpoSetCacheNoCache]);
    UnregisterCustomOptions('/index*');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
  end;
end;

procedure TBoilerplateHTTPServerShould.UpdateStaticAsset;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', True, True);
    WhenRequest('/index.html');
    ThenFileTimeStampAndSizeIsEqualToAsset(
      'static\identity\index.html', '/index.html');
    ThenFileContentIsNotEqualToAsset(
      'static\identity\index.html', '/index.html');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', False, True);
    WhenRequest('/index.html');
    ThenFileContentIsEqualToAsset(
      'static\identity\index.html', '/index.html');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', True, False);
    WhenRequest('/index.html');
    ThenFileContentIsEqualToAsset(
      'static\identity\index.html', '/index.html');

    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    GivenStaticFile('/index.html');
    GivenModifiedFile('static\identity\index.html', False, False);
    WhenRequest('/index.html');
    ThenFileContentIsEqualToAsset(
      'static\identity\index.html', '/index.html');

    DeleteFile('static\identity\index.html');
    RemoveDir('static\identity');
    RemoveDir('static');
  end;
end;

procedure TBoilerplateHTTPServerShould.CallInherited;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    WhenRequest;
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.Delegate404ToInherited_404;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenInHeader('Host', 'localhost');
    GivenOptions([bpoDelegateBadRequestTo404]);
    WhenRequest('123456');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenInHeader('Host', 'localhost');
    GivenOptions([bpoDelegateBadRequestTo404, bpoDelegate404ToInherited_404]);
    WhenRequest;
    ThenOutContentIs('404 NOT FOUND');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateBadRequestTo404;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_BADREQUEST);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBadRequestTo404]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateBlocked;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    GivenAssets;
    WhenRequest('/sample.conf');
    ThenOutContentEqualsFile('Assets\sample.conf');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBlocked]);
    WhenRequest('/sample.conf');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html~');
    ThenOutContentEqualsFile('Assets\index.html~');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBlocked]);
    WhenRequest('/index.html~');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html#');
    ThenOutContentEqualsFile('Assets\index.html#');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateBlocked]);
    WhenRequest('/index.html#');
    ThenOutContentEqualsFile('Assets\404.html');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateForbiddenTo404;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self, True));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_FORBIDDEN);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateForbiddenTo404]);
    WhenRequest('root/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateNotFoundTo404;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateNotFoundTo404]);
    WhenRequest('/12345');
    ThenRequestResultIs(HTTP_NOTFOUND);
    ThenOutContentEqualsFile('Assets\404.html');
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateRootToIndex;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('');
    ThenOutContentIs('');
    ThenRequestResultIs(HTTP_BADREQUEST);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/');
    ThenOutContentIs('');
    ThenRequestResultIs(HTTP_BADREQUEST);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateRootToIndex]);
    WhenRequest('');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDelegateRootToIndex]);
    WhenRequest('/');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.DeleteServerInternalState;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    GivenOutHeader('Server-InternalState', '1');
    WhenRequest('');
    ThenOutHeaderValueIs('Server-InternalState', '1');

    GivenClearServer;
    GivenOptions([bpoDeleteServerInternalState]);
    GivenOutHeader('Server-InternalState', '1');
    WhenRequest('');
    ThenOutHeaderValueIs('Server-InternalState', '');
  end;
end;

procedure TBoilerplateHTTPServerShould.DeleteXPoweredBy;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    GivenOutHeader('X-Powered-By', '123');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Powered-By', '123');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoDeleteXPoweredBy]);
    GivenOutHeader('X-Powered-By', '123');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Powered-By', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheBusting;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html?123');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheBusting]);
    WhenRequest('/index.html?123');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheBustingBeforeExt;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.xyz123.html');
    ThenRequestResultIs(HTTP_NOTFOUND);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheBustingBeforeExt]);
    WhenRequest('/index.xyz123.html');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheByETag;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
  Hash: RawUTF8;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    Hash := FormatUTF8('"%"',
      [crc32cUTF8ToHex(GetFileContent('Assets\index.html'))]);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    GivenInHeader('If-None-Match', Hash);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByETag]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', Hash);
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByETag]);
    GivenInHeader('If-None-Match', Hash);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('ETag', '');
    ThenOutContentIsEmpty;
    ThenRequestResultIs(HTTP_NOTMODIFIED);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableCacheByLastModified;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
  LastModified: RawUTF8;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    LastModified := DateTimeToHTTPDate(FAssets.Find('/index.html').Modified);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Last-Modified', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    GivenInHeader('If-Modified-Since', LastModified);
    WhenRequest('/index.html');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenOutHeaderValueIs('Last-Modified', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByLastModified]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Last-Modified', LastModified);
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableCacheByLastModified]);
    GivenInHeader('If-Modified-Since', LastModified);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Last-Modified', '');
    ThenOutContentIsEmpty;
    ThenRequestResultIs(HTTP_NOTMODIFIED);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableReferrerPolicy;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Referrer-Policy', 'no-referrer-when-downgrade');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    GivenReferrerPolicy('custom-referrer-policy');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Referrer-Policy', 'custom-referrer-policy');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableReferrerPolicy]);
    GivenReferrerPolicy('custom-referrer-policy');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Referrer-Policy', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.EnableXSSFilter;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-XSS-Protection', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-XSS-Protection', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableXSSFilter]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-XSS-Protection', '1; mode=block');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableXSSFilter]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-XSS-Protection', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.FixMangledAcceptEncoding;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoFixMangledAcceptEncoding]);
    GivenInHeader('Accept-EncodXng', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoFixMangledAcceptEncoding]);
    GivenInHeader('X-cept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceGZipHeader;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/sample.svgz');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceGZipHeader]);
    WhenRequest('/sample.svgz');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenOutContentEqualsFile('Assets\sample.svgz');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceHTTPS;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html', 'localhost');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS]);
    WhenRequest('/index.html', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://localhost/index.html');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceHTTPSExceptLetsEncrypt;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoForceHTTPS]);
    GivenAssets;
    WhenRequest('/.well-known/acme-challenge/sample.txt', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location',
      'https://localhost/.well-known/acme-challenge/sample.txt');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS]);
    WhenRequest('/.well-known/cpanel-dcv/sample.txt', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location',
      'https://localhost/.well-known/cpanel-dcv/sample.txt');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS]);
    WhenRequest('/.well-known/pki-validation/sample.txt', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location',
      'https://localhost/.well-known/pki-validation/sample.txt');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS, bpoForceHTTPSExceptLetsEncrypt]);
    WhenRequest('/.well-known/acme-challenge/sample.txt');
    {$IFDEF LINUX}
    // .well-known directory is hidden on linux and was not included into Assets
    ThenRequestResultIs(HTTP_NOTFOUND);
    {$ELSE}
    ThenOutContentIs('acme challenge sample');
    ThenRequestResultIs(HTTP_SUCCESS);
    {$ENDIF}

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS, bpoForceHTTPSExceptLetsEncrypt]);
    WhenRequest('/.well-known/cpanel-dcv/sample.txt');
    {$IFDEF LINUX}
    // .well-known directory is hidden on linux and was not included into Assets
    ThenRequestResultIs(HTTP_NOTFOUND);
    {$ELSE}
    ThenOutContentIs('cpanel dcv sample');
    ThenRequestResultIs(HTTP_SUCCESS);
    {$ENDIF}

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceHTTPS, bpoForceHTTPSExceptLetsEncrypt]);
    WhenRequest('/.well-known/pki-validation/sample.txt');
    {$IFDEF LINUX}
    // .well-known directory is hidden on linux and was not included into Assets
    ThenRequestResultIs(HTTP_NOTFOUND);
    {$ELSE}
    ThenOutContentIs('pki validation sample');
    ThenRequestResultIs(HTTP_SUCCESS);
    {$ENDIF}
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateIndexToInheritedDefault;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenInHeader('Host', 'localhost');
    GivenOptions([bpoDelegateRootToIndex]);
    WhenRequest;
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenInHeader('Host', 'localhost');
    GivenOptions([bpoDelegateRootToIndex, bpoDelegateIndexToInheritedDefault]);
    WhenRequest;
    ThenOutContentIs('DEFAULT CONTENT');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateIndexToInheritedDefaultOverSSL;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps,
    TBoilerplateHTTPServerSteps.Create(Self, False, nil, True));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenInHeader('Host', 'localhost');
    GivenOptions([bpoDelegateRootToIndex, bpoDelegateIndexToInheritedDefault]);
    WhenRequest('', '', True);
    ThenOutContentIs('DEFAULT CONTENT');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceMIMEType;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.geojson');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.geojson');
    ThenOutContentTypeIs('application/geo+json');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.rdf');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.rdf');
    ThenOutContentTypeIs('application/rdf+xml');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.xml');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.xml');
    ThenOutContentTypeIs('application/xml');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.mjs');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.mjs');
    ThenOutContentTypeIs('text/javascript');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.js');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.js');
    ThenOutContentTypeIs('text/javascript');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.wasm');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.wasm');
    ThenOutContentTypeIs('application/wasm');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.woff');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.woff');
    ThenOutContentTypeIs('font/woff');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.woff2');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.woff2');
    ThenOutContentTypeIs('font/woff2');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.ttf');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.ttf');
    ThenOutContentTypeIs('font/ttf');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.ttc');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.ttc');
    ThenOutContentTypeIs('font/collection');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.otf');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.otf');
    ThenOutContentTypeIs('font/otf');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.ics');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.ics');
    ThenOutContentTypeIs('text/calendar');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.md');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.md');
    ThenOutContentTypeIs('text/markdown');

    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.markdown');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.markdown');
    ThenOutContentTypeIs('text/markdown');
  end;
end;


procedure TBoilerplateHTTPServerShould.LoadAndReturnAssets;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    WhenRequest('/img/marmot.jpg');
    ThenOutContentEqualsFile('Assets\img\marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.PreventMIMESniffing;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Content-Type-Options', '');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoPreventMIMESniffing]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Content-Type-Options', 'nosniff');
    ThenOutContentEqualsFile('Assets\index.html');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.RedirectInInherited_404;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self, False,
    T404Application.Create));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoDelegateBadRequestTo404, bpoDelegate404ToInherited_404]);
    GivenInHeader('Host', 'localhost');
    WhenRequest('123456');
    ThenApp404Called;
  end;
end;

procedure TBoilerplateHTTPServerShould.RegisterCustomOptions;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/404.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index.html', [bpoSetCacheNoCache]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions(
      TRawUTF8DynArrayFrom(['/index.html', '/404.html']), [bpoSetCacheNoCache]);
    WhenRequest('/404.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    RegisterCustomOptions('/index*', [bpoSetCacheNoCache]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceTextUTF8Charset;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/index.html');
    ThenOutContentTypeIs('text/html');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/index.txt');
    ThenOutContentTypeIs('text/plain');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType, bpoForceTextUTF8Charset]);
    WhenRequest('/index.html');
    ThenOutContentTypeIs('text/html; charset=UTF-8');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType, bpoForceTextUTF8Charset]);
    WhenRequest('/index.txt');
    ThenOutContentTypeIs('text/plain; charset=UTF-8');
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceUTF8Charset;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/data.webmanifest');
    ThenOutContentTypeIs('application/manifest+json');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType, bpoForceUTF8Charset]);
    WhenRequest('/data.webmanifest');
    ThenOutContentTypeIs('application/manifest+json; charset=UTF-8');
  end;
end;

procedure TBoilerplateHTTPServerShould.ServeExactCaseURL;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    WhenRequest('/img/marmot.JPG', 'localhost');
    ThenOutContentEqualsFile('Assets\img\marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenServeExactCaseURL;
    WhenRequest('/img/marmot.JPG', 'localhost');
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'http://localhost/img/marmot.jpg');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);

    GivenClearServer;
    GivenAssets;
    GivenServeExactCaseURL;
    WhenRequest('/img/marmot.JPG', 'localhost', True);
    ThenOutContentIsEmpty;
    ThenOutHeaderValueIs('Location', 'https://localhost/img/marmot.jpg');
    ThenRequestResultIs(HTTP_MOVEDPERMANENTLY);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetCacheMaxAge;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', '');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=0');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('*=12');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=12');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=10');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=10');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=15s');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=15');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=20S');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=20');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=25h');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [25 * SecsPerHour]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=30H');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [30 * SecsPerHour]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=35d');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [35 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=40D');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [40 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=45w');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [45 * 7 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=50W');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [50 * 7 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=6m');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [6 * 2629746]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=7M');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [7 * 2629746]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=8y');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [8 * 365 * SecsPerDay]));

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMaxAge]);
    GivenExpires('text/html=9Y');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control',
      FormatUTF8('max-age=%', [9 * 365 * SecsPerDay]));
  end;
end;

procedure TBoilerplateHTTPServerShould.SetCacheNoTransform;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetCachePublic;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoTransform]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCachePublic]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'public');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCachePrivate]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'private');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoCache]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheNoStore]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'no-store');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCacheMustRevalidate]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'must-revalidate');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetCachePublic]);
    GivenOutHeader('Cache-Control', 'max-age=0');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Cache-Control', 'max-age=0, public');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetExpires;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
  LExpires: RawUTF8;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', '');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    LExpires := DateTimeToHTTPDate(NowUTC);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('*=12');
    LExpires := DateTimeToHTTPDate(NowUTC + 12 / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=10');
    LExpires := DateTimeToHTTPDate(NowUTC + 10 / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=15s');
    LExpires := DateTimeToHTTPDate(NowUTC + 15 / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=20S');
    LExpires := DateTimeToHTTPDate(NowUTC + 20 / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=25h');
    LExpires := DateTimeToHTTPDate(NowUTC + 25 * SecsPerHour / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=30H');
    LExpires := DateTimeToHTTPDate(NowUTC + 30 * SecsPerHour / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=35d');
    LExpires := DateTimeToHTTPDate(NowUTC + 35);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=40D');
    LExpires := DateTimeToHTTPDate(NowUTC + 40);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=45w');
    LExpires := DateTimeToHTTPDate(NowUTC + 45 * 7);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=50W');
    LExpires := DateTimeToHTTPDate(NowUTC + 50 * 7);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=6m');
    LExpires := DateTimeToHTTPDate(NowUTC + 6 * 2629746 / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=7M');
    LExpires := DateTimeToHTTPDate(NowUTC + 7 * 2629746 / SecsPerDay);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=8y');
    LExpires := DateTimeToHTTPDate(NowUTC + 8 * 365);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetExpires]);
    GivenExpires('text/html=9Y');
    LExpires := DateTimeToHTTPDate(NowUTC + 9 * 365);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Expires', LExpires);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetVaryAcceptEncoding;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Vary', '');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoVaryAcceptEncoding]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Vary', 'Accept-Encoding');

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoVaryAcceptEncoding]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Vary', '');
  end;
end;

procedure TBoilerplateHTTPServerShould.SetXFrameOptions;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Frame-Options', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-Frame-Options', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXFrameOptions]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-Frame-Options', 'DENY');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXFrameOptions]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-Frame-Options', '');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetXUACompatible;
var
  Auto: IAutoFree; // This variable required only under FPC
  Steps: TBoilerplateHTTPServerSteps;
begin
  Auto := TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-UA-Compatible', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-UA-Compatible', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXUACompatible]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('X-UA-Compatible', 'IE=edge');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXUACompatible]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('X-UA-Compatible', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetXUACompatible, bpoDelegateNotFoundTo404]);
    WhenRequest('/404');
    ThenOutHeaderValueIs('X-UA-Compatible', 'IE=edge');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

{ TBoilerplateHTTPServerSteps }

procedure TBoilerplateHTTPServerSteps.GivenOptions(
  const AOptions: TBoilerplateOptions);
begin
  inherited Options := AOptions;
end;

procedure TBoilerplateHTTPServerSteps.GivenOutHeader(const aName,
  aValue: RawUTF8);
begin
  FContext.OutCustomHeaders := FContext.OutCustomHeaders +
    FormatUTF8('%: %', [aName, aValue]);
end;

procedure TBoilerplateHTTPServerSteps.GivenReferrerPolicy(const Value: RawUTF8);
begin
  ReferrerPolicy := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenServeExactCaseURL(
  const Value: Boolean);
begin
  RedirectServerRootUriForExactCase := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenStaticFile(const URL: SockString);
begin
  FContext.URL := URL;
  FContext.Method := 'GET';
  FContext.Result := inherited Request(FContext);
end;

procedure TBoilerplateHTTPServerSteps.GivenStaticRoot(const Value: TFileName);
begin
  StaticRoot := ExtractFilePath(ParamStr(0)) + Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenStrictSSL(const Value: TStrictSSL);
begin
  StrictSSL := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenWWWRewrite(const Value: TWWWRewrite);
begin
  WWWRewrite := Value;
end;

procedure TBoilerplateHTTPServerSteps.RemoveDir(const FileName: string);
begin
  SysUtils.RemoveDir(
    StringReplace(FullFileName(FileName), '\', PathDelim, [rfReplaceAll]));
end;

procedure TBoilerplateHTTPServerSteps.GivenClearServer;
begin
  FContext.Init;
  inherited Init;
end;

procedure TBoilerplateHTTPServerSteps.GivenContentSecurityPolicy(
  const Value: RawUTF8);
begin
  ContentSecurityPolicy := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenModifiedFile(
  const FileName: TFileName;
  const KeepTimeStamp, KeepSize: Boolean);
const
  ADD_BYTE: array[Boolean] of Integer = (0, 1);
var
  LFileName: string;
  Modified: TDateTime;
  Size: Int64;
begin
  LFileName := StringReplace(
    FullFileName(FileName), '\', PathDelim, [rfReplaceAll]);
  GetFileInfo(LFileName, @Modified, @Size);
  FileFromString(
    ToUTF8(StringOfChar(#0, Size + ADD_BYTE[not KeepSize])), LFileName, True);
  if KeepTimeStamp then
    SetFileTime(LFileName, Modified)
  else
    SetFileTime(LFileName, NowUTC);
end;

procedure TBoilerplateHTTPServerSteps.GivenExpires(const Value: RawUTF8);
begin
  Expires := Value;
end;

function TBoilerplateHTTPServerSteps.GetFileContent(
  const FileName: TFileName): RawByteString;
var
  LFileName: string;
begin
  LFileName := StringReplace(
    FullFileName(FileName), '\', PathDelim, [rfReplaceAll]);
  FTestCase.CheckUTF8(FileExists(LFileName),
    'File not found ''%''', [LFileName]);
  Result := StringFromFile(LFileName);
end;

procedure TBoilerplateHTTPServerSteps.GivenAssets(const Name: string);
begin
  inherited LoadFromResource(Name);
end;

constructor TBoilerplateHTTPServerSteps.Create(const TestCase: TSynTestCase;
  const Auth: Boolean; AApplication: IBoilerplateApplication; AUseSSL: Boolean);
const
  DEFAULT_PORT = {$IFDEF MSWINDOWS} '888' {$ELSE} '8888' {$ENDIF MSWINDOWS};
  SERVER_SECURITY: array[Boolean] of TSQLHTTPServerSecurity = (secNone, secSSL);
begin
  FTestCase := TestCase;
  FModel := TSQLModel.Create([]);
  FServer := TSQLRestServerFullMemory.Create(FModel, Auth);
  FApplication := AApplication;
  if FApplication = nil then
  begin
    FApplication := TBoilerplateApplication.Create;
    TBoilerplateApplication(ObjectFromInterface(FApplication)).Start(
      FServer, FullFileName('Views'));
  end else
    if ObjectFromInterface(FApplication).ClassType = TBoilerplateApplication then
      TBoilerplateApplication(ObjectFromInterface(FApplication)).Start(
        FServer, FullFileName('Views'))
    else if ObjectFromInterface(FApplication).ClassType = T404Application then
      T404Application(ObjectFromInterface(FApplication)).Start(
        FServer, FullFileName('Views'))
    else
      TMVCApplication(ObjectFromInterface(FApplication)).Start(
        FServer, TypeInfo(IBoilerplateApplication));
  FContext := THttpServerRequestStub.Create(nil, 0, nil);
  inherited Create(DEFAULT_PORT, FServer, '+', useHttpSocket, nil, 0,
    SERVER_SECURITY[AUseSSL]);
  DomainHostRedirect('localhost', 'root');
end;

procedure TBoilerplateHTTPServerSteps.ThenRequestResultIs(const Value: Cardinal);
begin
  FTestCase.CheckUTF8(FContext.Result = Value,
    'Request result expected=%, actual=%', [Value, FContext.Result]);
end;

procedure TBoilerplateHTTPServerSteps.DeleteFile(const FileName: string);
begin
  SysUtils.DeleteFile(
    StringReplace(FullFileName(FileName), '\', PathDelim, [rfReplaceAll]));
end;

destructor TBoilerplateHTTPServerSteps.Destroy;
begin
  inherited Destroy;
  FContext.Free;
  FApplication := nil;
  FServer.Free;
  FModel.Free;
end;

function TBoilerplateHTTPServerSteps.FullFileName(
  const FileName: string): string;
begin
  Result := ExtractFilePath(ParamStr(0)) + FileName;
end;

procedure TBoilerplateHTTPServerSteps.ThenApp404Called;
begin
  FTestCase.Check(
    T404Application(ObjectFromInterface(FApplication)).Is404Called,
    'App404 not called');
end;

procedure TBoilerplateHTTPServerSteps.ThenFileContentIsEqualToAsset(
  const FileName: TFileName; const Path: RawUTF8);
var
  Asset: PAsset;
begin
  Asset := FAssets.Find(Path);
  FTestCase.CheckUTF8(Asset <> nil, 'Asset not found ''%''', [Path]);
  FTestCase.CheckUTF8(GetFileContent(FileName) = Asset.Content,
    'Non-equal content between file ''%'' and asset ''%''', [FileName, Path]);
end;

procedure TBoilerplateHTTPServerSteps.ThenFileContentIsNotEqualToAsset(
  const FileName: TFileName; const Path: RawUTF8);
var
  Asset: PAsset;
begin
  Asset := FAssets.Find(Path);
  FTestCase.CheckUTF8(Asset <> nil, 'Asset not found ''%''', [Path]);
  FTestCase.CheckUTF8(GetFileContent(FileName) <> Asset.Content,
    'Equal content between file ''%'' and asset ''%''', [FileName, Path]);
end;

procedure TBoilerplateHTTPServerSteps.ThenFileTimeStampAndSizeIsEqualToAsset(
  const FileName: TFileName; const Path: RawUTF8);
var
  Asset: PAsset;
  Modified: TDateTime;
  Size: Int64;
begin
  Asset := FAssets.Find(Path);
  FTestCase.CheckUTF8(Asset <> nil, 'Asset not found ''%''', [Path]);
  FTestCase.CheckUTF8(
    GetFileInfo(
      StringReplace(FullFileName(FileName), '\', PathDelim, [rfReplaceAll]),
        @Modified, @Size),
    'GetFileInfo failed ''%''', [FileName]);
  FTestCase.CheckUTF8(Round((Modified - Asset.Modified) * SecsPerDay) = 0,
    'File modified are not equal to asset file=%, asset=%', [
      FormatDateTime('YYYY-MM-DD HH:NN:SS.ZZZ', Modified),
      FormatDateTime('YYYY-MM-DD HH:NN:SS.ZZZ', Asset.Modified)]);
  FTestCase.CheckUTF8(Size = Length(Asset.Content),
    'File size are not equal to asset file=%, asset=%',
      [Size, Length(Asset.Content)]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentEqualsFile(
  const FileName: TFileName);
begin
  FTestCase.CheckUTF8(FContext.OutContent = GetFileContent(FileName),
    'File content mismatch ''%'' actual=''%''expected=''%''',
      [FileName, FContext.OutContent, GetFileContent(FileName)]);
end;

procedure TBoilerplateHTTPServerSteps.GivenInHeader(
  const aName, aValue: RawUTF8);
begin
  FContext.InHeaders := FContext.InHeaders +
    FormatUTF8('%: %', [aName, aValue]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutHeaderValueIs(
  const aName, aValue: RawUTF8);
var
  NameUp: SockString;
  Value: RawUTF8;
begin
  NameUp := SockString(SynCommons.UpperCase(aName) + ': ');
  Value := FindIniNameValue(Pointer(FContext.OutCustomHeaders),
    Pointer(NameUp));
  FTestCase.CheckUTF8(Value = aValue,
    'OutHeader ''%'' expected=''%'', actual=''%''', [aName, aValue, Value]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsStaticFile(
  const StaticFileName, FileName: TFileName);
begin
  FTestCase.CheckUTF8(GetFileContent(StaticFileName) = GetFileContent(FileName),
    'File content mismatch ''%''', [FileName]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIs(
  const Value: RawByteString);
begin
  FTestCase.CheckUTF8(FContext.OutContent = Value,
    'OutContent expected=''%'', actual=''%''', [Value, FContext.OutContent]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsEmpty;
begin
  FTestCase.CheckUTF8(FContext.OutContent = '',
    'HTTP Response content is not empty ''%''', [FContext.OutContent]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsStatic(
  const FileName: TFileName);
var
  LFileName: string;
begin
  FTestCase.CheckUTF8(FContext.OutContentType = HTTP_RESP_STATICFILE,
    'OutContentIsStatic expected=''%'', actual=''%''',
    [HTTP_RESP_STATICFILE, FContext.OutContentType]);

  LFileName := StringReplace(FileName, '\',PathDelim, [rfReplaceAll]);
  FTestCase.CheckUTF8(TFileName(FContext.OutContent) = LFileName,
    'OutContentIsStatic expected=''%'', actual=''%''',
    [LFileName, FContext.OutContent]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentTypeIs(
  const Value: RawUTF8);
begin
  FTestCase.CheckUTF8(FContext.OutContentType = Value,
    'OutContentType expected=''%'', actual=''%''',
    [Value, FContext.OutContentType]);
end;

procedure TBoilerplateHTTPServerSteps.WhenRequest(const URL: SockString;
  const Host: SockString; const UseSSL: Boolean);
begin
  if URL <> '' then
    FContext.URL := URL;
  if Host <> '' then
    FContext.InHeaders :=
      FormatUTF8('%Host: %'#$D#$A, [FContext.InHeaders, Host]);
  FContext.Method := 'GET';
  FContext.UseSSL := UseSSL;
  FContext.Result := inherited Request(FContext);
end;

{ THttpServerRequestStub }

procedure THttpServerRequestStub.Init;
begin
  Prepare('', '', '', '', '', '', False);
  FOutCustomHeaders := '';
  FOutContentType := '';
  FOutContent := '';
  FResult := 0;
end;

{ TBoilerplateApplication }

procedure TBoilerplateApplication.Default(var Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'CONTENT';
end;

procedure TBoilerplateApplication.Error(var Msg: RawUTF8; var Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'CONTENT';
end;

procedure TBoilerplateApplication.Start(Server: TSQLRestServer;
  const ViewsFolder: TFileName);
begin
  inherited Start(Server, TypeInfo(IBoilerplateApplication));
  FMainRunner := TMVCRunOnRestServer.Create(Self, fRestServer, '',
    TMVCViewsMustache.Create(FFactory.InterfaceTypeInfo,
      GetMustacheParams(ViewsFolder), (FRestModel as TSQLRestServer).LogClass));
end;

procedure TBoilerplateApplication._404(
  const Dummy: Integer; out Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'NOT FOUND';
end;

procedure TBoilerplateFeatures.Scenarios;
begin
  AddCase(TBoilerplateHTTPServerShould);
end;

{ T404Application }

procedure T404Application.Default(var Scope: Variant);
begin
end;

procedure T404Application.Error(var Msg: RawUTF8; var Scope: Variant);
begin
end;

procedure T404Application.Start(Server: TSQLRestServer;
  const ViewsFolder: TFileName);
begin
  inherited Start(Server, TypeInfo(IBoilerplateApplication));
  FMainRunner := TMVCRunOnRestServer.Create(Self, fRestServer, '',
    TMVCViewsMustache.Create(FFactory.InterfaceTypeInfo,
      GetMustacheParams(ViewsFolder), (FRestModel as TSQLRestServer).LogClass));
end;

procedure T404Application._404(const Dummy: Integer; out Scope: Variant);
begin
  Is404Called := True;
end;

end.
