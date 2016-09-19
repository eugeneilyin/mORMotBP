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
    procedure SetP3P;
    procedure ForceMIMEType;
    procedure ForceTextUTF8Charset;
    procedure ForceUTF8Charset;
    procedure ForceHTTPS;
    procedure SupportWWWRewrite;
    procedure SetXFrameOptions;
    procedure SupportContentSecurityPolicy;
    procedure DelegateBlocked;
    procedure SupportStrictSSL;
    procedure PreventMIMESniffing;
    procedure EnableXSSFilter;
    procedure DeleteXPoweredBy;
    procedure FixMangledAcceptEncoding;
    procedure SupportGZipByMIMEType;
    procedure ForceGZipHeader;
    procedure SetCacheNoTransform;
    procedure SetCachePublic;
    procedure EnableCacheByETag;
    procedure EnableCacheByLastModified;
    procedure SetExpires;
    procedure SetCacheMaxAge;
    procedure EnableCacheBusting;
    procedure SupportStaticRoot;
    procedure DelegateRootToIndex;
    procedure DeleteServerInternalState;
    procedure DelegateIndexToInheritedDefault;
    procedure Delegate404ToInherited_404;
    procedure RegisterCustomOptions;
    procedure UnregisterCustomOptions;
    procedure SetVaryAcceptEncoding;
  end;

  TBoilerplateFeatures = class(TSynTests)
    procedure Scenarios;
  end;

procedure CleanUp;

implementation

uses
  SysUtils,
  SynCommons,
  SynCrtSock,
  mORMot,
  mORMotMVC,
  mORMotHttpServer,
  BoilerplateAssets,
  BoilerplateHTTPServer;

type

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
    property OutCustomHeaders: SockString read FOutCustomHeaders write FOutCustomHeaders;
    property Result: Cardinal read FResult write FResult;
    property UseSSL: boolean read FUseSSL write FUseSSL;
  end;

  TBoilerplateHTTPServerSteps = class(TBoilerplateHTTPServer)
  private
    FTestCase: TSynTestCase;
    FModel: TSQLModel;
    FServer: TSQLRestServer;
    FApplication: TMVCApplication;
    FContext: THttpServerRequestStub;
  public
    constructor Create(const TestCase: TSynTestCase;
      const Auth: Boolean = False);
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
    procedure GivenExpires(const Value: RawUTF8);
    procedure GivenGZipLevel(const Value: TGZipLevel);
    procedure GivenStaticRoot(const Value: TFileName);
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
  end;

  IBoilerplateApplication = interface(IMVCApplication)
    ['{79968060-F121-46B9-BA5C-C4740B4445D6}']
    procedure _404(out Scope: Variant);
  end;

  TBoilerplateApplication = class(TMVCApplication, IBoilerplateApplication)
  public
    procedure Start(Server: TSQLRestServer); reintroduce;
  published
    procedure Error(var Msg: RawUTF8; var Scope: Variant);
    procedure Default(var Scope: Variant);
    procedure _404(out Scope: Variant);
  end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOrigin;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/fonts/Roboto-Regular.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginFonts]);
    WhenRequest('/fonts/Roboto-Regular.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoAllowCrossOriginFonts]);
    GivenInHeader('Origin', 'localhost');
    WhenRequest('/fonts/Roboto-Regular.woff2');
    ThenOutHeaderValueIs('Access-Control-Allow-Origin', '*');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SpecifyCrossOriginForImages;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Security-Policy', '');
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

procedure TBoilerplateHTTPServerShould.SupportGZipByMIMEType;
var
  Steps: TBoilerplateHTTPServerSteps;
  Data: RawByteString;
  Level: TGZipLevel;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceMIMEType]);
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceMIMEType]);
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceMIMEType, bpoEnableGZipByMIMETypes]);
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceMIMEType, bpoEnableGZipByMIMETypes]);
    GivenInHeader('Accept-Encoding', 'deflate, sdch, br, gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceMIMEType, bpoEnableGZipByMIMETypes]);
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    for Level := Low(TGZipLevel) to High(TGZipLevel) do
    begin
      GivenClearServer;
      GivenGZipLevel(Level);
      GivenAssets;
      GivenOptions([bpoEnableGZipByMIMETypes]);
      GivenInHeader('Accept-Encoding', 'gzip');
      WhenRequest('/index.html');
      Data := StringFromFile('Assets\index.html');
      CompressGZip(Data, Integer(Level));
      ThenOutContentIs(Data);
      ThenRequestResultIs(HTTP_SUCCESS);
    end;
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportStaticRoot;
var
  Steps: TBoilerplateHTTPServerSteps;
  StaticData, RequiredData: RawByteString;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenStaticRoot('static');
    WhenRequest('/index.html');
    ThenOutContentIsStaticFile('static\cache.plain\index.html',
      'Assets\index.html');
    DeleteFile('static\cache.plain\index.html');
    RemoveDir('static\cache.plain');
    RemoveDir('static');

    GivenClearServer;
    GivenGZipLevel(gz9);
    GivenAssets;
    GivenOptions([bpoEnableGZipByMIMETypes]);
    GivenStaticRoot('static');
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutContentIsStatic('static\cache.gz\index.html.9.gz');
    StaticData := StringFromFile('static\cache.gz\index.html.9.gz');
    RequiredData := StringFromFile('Assets\index.html');
    CompressGZip(RequiredData, 9);
    Check(StaticData = RequiredData);
    DeleteFile('static\cache.gz\index.html.9.gz');
    RemoveDir('static\cache.gz');
    RemoveDir('static');
  end;
end;

procedure TBoilerplateHTTPServerShould.SupportStrictSSL;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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

procedure TBoilerplateHTTPServerShould.SupportWWWRewrite;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
    UnregisterCustomOptions(['/index.html', '/404.html']);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-transform');
  end;
end;

procedure TBoilerplateHTTPServerShould.CallInherited;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    WhenRequest;
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.Delegate404ToInherited_404;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
    ThenOutContentIs('404 CONTENT');
    ThenRequestResultIs(HTTP_NOTFOUND);
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateBadRequestTo404;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  end;
end;

procedure TBoilerplateHTTPServerShould.DelegateForbiddenTo404;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self, True));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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

procedure TBoilerplateHTTPServerShould.EnableCacheByETag;
var
  Steps: TBoilerplateHTTPServerSteps;
  Hash: RawUTF8;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    Hash := FormatUTF8('"%"',
      [crc32cUTF8ToHex(StringFromFile('Assets\index.html'))]);

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
  Steps: TBoilerplateHTTPServerSteps;
  Assets: TAssets;
  LastModified: RawUTF8;
begin
  Assets.Init;
  Assets.Add('Assets', 'Assets\index.html');
  LastModified := DateTimeToHTTPDate(Assets.Assets[0].Modified);

  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
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

procedure TBoilerplateHTTPServerShould.EnableXSSFilter;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
    GivenOptions([bpoEnableGZipByMIMETypes]);
    GivenInHeader('Accept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableGZipByMIMETypes]);
    GivenInHeader('Accept-Encoding', 'gzip, deflate, sdch');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableGZipByMIMETypes]);
    GivenInHeader('Accept-EncodXng', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableGZipByMIMETypes, bpoFixMangledAcceptEncoding]);
    GivenInHeader('Accept-EncodXng', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoEnableGZipByMIMETypes, bpoFixMangledAcceptEncoding]);
    GivenInHeader('X-cept-Encoding', 'gzip');
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceGZipHeader;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/img/sample.svgz');
    ThenOutHeaderValueIs('Content-Encoding', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoForceGZipHeader]);
    WhenRequest('/img/sample.svgz');
    ThenOutHeaderValueIs('Content-Encoding', 'gzip');
    ThenOutContentEqualsFile('Assets\img\sample.svgz');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceHTTPS;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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

procedure TBoilerplateHTTPServerShould.DelegateIndexToInheritedDefault;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenInHeader('Host', 'localhost');
    GivenOptions([bpoDelegateRootToIndex]);
    WhenRequest('');
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

procedure TBoilerplateHTTPServerShould.ForceMIMEType;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([]);
    WhenRequest('/sample.geojson');
    ThenOutContentTypeIs('');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/sample.geojson');
    ThenOutContentTypeIs('application/vnd.geo+json');
  end;
end;


procedure TBoilerplateHTTPServerShould.LoadAndReturnAssets;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenAssets;
    WhenRequest('/img/marmot.jpg');
    ThenOutContentEqualsFile('Assets\img\marmot.jpg');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.PreventMIMESniffing;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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

procedure TBoilerplateHTTPServerShould.RegisterCustomOptions;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
    RegisterCustomOptions(['/index.html', '/404.html'], [bpoSetCacheNoCache]);
    WhenRequest('/404.html');
    ThenOutHeaderValueIs('Cache-Control', 'no-cache');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.ForceTextUTF8Charset;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenOptions([bpoForceMIMEType]);
    WhenRequest('/data.rss');
    ThenOutContentTypeIs('application/rss+xml');

    GivenClearServer;
    GivenOptions([bpoForceMIMEType, bpoForceUTF8Charset]);
    WhenRequest('/data.rss');
    ThenOutContentTypeIs('application/rss+xml; charset=UTF-8');
  end;
end;

procedure TBoilerplateHTTPServerShould.ServeExactCaseURL;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
  LExpires: RawUTF8;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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

procedure TBoilerplateHTTPServerShould.SetP3P;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
  with Steps do
  begin
    GivenClearServer;
    GivenAssets;
    GivenOptions([]);
    WhenRequest('/index.html');
    ThenOutHeaderValueIs('P3P', '');
    ThenRequestResultIs(HTTP_SUCCESS);

    GivenClearServer;
    GivenAssets;
    GivenOptions([bpoSetP3P]);
    WhenRequest('/img/marmot.jpg');
    ThenOutHeaderValueIs('P3P', 'policyref="/w3c/p3p.xml", CP="IDC ' +
      'DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"');
    ThenRequestResultIs(HTTP_SUCCESS);
  end;
end;

procedure TBoilerplateHTTPServerShould.SetVaryAcceptEncoding;
var
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  Steps: TBoilerplateHTTPServerSteps;
begin
  TAutoFree.One(Steps, TBoilerplateHTTPServerSteps.Create(Self));
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
  end;
end;

procedure TBoilerplateHTTPServerSteps.GivenOptions(const AOptions: TBoilerplateOptions);
begin
  inherited Options := AOptions;
end;

procedure TBoilerplateHTTPServerSteps.GivenOutHeader(const aName,
  aValue: RawUTF8);
begin
  FContext.OutCustomHeaders := FContext.OutCustomHeaders +
    FormatUTF8('%: %', [aName, aValue]);
end;

procedure TBoilerplateHTTPServerSteps.GivenServeExactCaseURL(
  const Value: Boolean);
begin
  RedirectServerRootUriForExactCase := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenStaticRoot(const Value: TFileName);
begin
  StaticRoot := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenStrictSSL(const Value: TStrictSSL);
begin
  StrictSSL := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenWWWRewrite(const Value: TWWWRewrite);
begin
  WWWRewrite := Value;
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

procedure TBoilerplateHTTPServerSteps.GivenExpires(const Value: RawUTF8);
begin
  Expires := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenGZipLevel(const Value: TGZipLevel);
begin
  GZipLevel := Value;
end;

procedure TBoilerplateHTTPServerSteps.GivenAssets(const Name: string);
begin
  inherited LoadFromResource(Name);
end;

constructor TBoilerplateHTTPServerSteps.Create(const TestCase: TSynTestCase;
  const Auth: Boolean);
begin
  FTestCase := TestCase;
  FModel := TSQLModel.Create([]);
  FServer := TSQLRestServerFullMemory.Create(FModel, Auth);
  FApplication := TBoilerplateApplication.Create;
  TBoilerplateApplication(FApplication).Start(FServer);
  FContext := THttpServerRequestStub.Create(nil, 0, nil);
  inherited Create('0', FServer, '+', useHttpSocket, nil, 0);
  DomainHostRedirect('localhost', 'root');
end;

procedure TBoilerplateHTTPServerSteps.ThenRequestResultIs(const Value: Cardinal);
begin
  FTestCase.Check(FContext.Result = Value,
    Format('Request result expected=%d, actual=%d',
      [Value, FContext.Result]));
end;

destructor TBoilerplateHTTPServerSteps.Destroy;
begin
  inherited;
  FContext.Free;
  FApplication.Free;
  FServer.Free;
  FModel.Free;
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentEqualsFile(const FileName: TFileName);
begin
  FTestCase.Check(FileExists(FileName),
    Format('File doesn''t not exists ''%s''', [FileName]));
  FTestCase.Check(FContext.OutContent = StringFromFile(FileName),
    Format('File content mismatch ''%s''', [FileName]));
end;

procedure TBoilerplateHTTPServerSteps.GivenInHeader(const aName, aValue: RawUTF8);
begin
  FContext.InHeaders := FContext.InHeaders +
    FormatUTF8('%: %', [aName, aValue]);
end;

procedure TBoilerplateHTTPServerSteps.ThenOutHeaderValueIs(const aName, aValue: RawUTF8);
var
  NameUp: SockString;
  Value: RawUTF8;
begin
  NameUp := UpperCase(aName) + ': ';
  Value := FindIniNameValue(Pointer(FContext.OutCustomHeaders),
    Pointer(NameUp));
  FTestCase.Check(Value = aValue, Format(
    '_Out ''%s'' expected=''%s'', actual=''%s''', [aName, aValue, Value]));
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsStaticFile(
  const StaticFileName, FileName: TFileName);
begin
  FTestCase.Check(FileExists(FileName),
    Format('File doesn''t not exists ''%s''', [FileName]));
  FTestCase.Check(FileExists(StaticFileName),
    Format('File doesn''t not exists ''%s''', [StaticFileName]));
  FTestCase.Check(StringFromFile(StaticFileName) = StringFromFile(FileName),
    Format('File content mismatch ''%s''', [FileName]));
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIs(
  const Value: RawByteString);
begin
  FTestCase.Check(FContext.OutContent = Value, Format(
    '_OutContentIs expected=''%s'', actual=''%s''',
      [Value, FContext.OutContent]));
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsEmpty;
begin
  FTestCase.Check(FContext.OutContent = '', 'HTTP Responce content is not empty');
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentIsStatic(
  const FileName: TFileName);
begin
  FTestCase.Check(FContext.OutContentType = HTTP_RESP_STATICFILE, Format(
    '_OutContentIsStatic expected=''%s'', actual=''%s''',
      [HTTP_RESP_STATICFILE, FContext.OutContentType]));
  FTestCase.Check(TFileName(FContext.OutContent) = FileName, Format(
    '_OutContentIsStatic expected=''%s'', actual=''%s''',
      [FileName, FContext.OutContent]));
end;

procedure TBoilerplateHTTPServerSteps.ThenOutContentTypeIs(
  const Value: RawUTF8);
begin
  FTestCase.Check(FContext.OutContentType = Value, Format(
    '_OutContentType expected=''%s'', actual=''%s''',
      [Value, FContext.OutContentType]));
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

procedure THttpServerRequestStub.Init;
begin
  Prepare('', '', '', '', '');
  FOutCustomHeaders := '';
  FOutContentType := '';
  FOutContent := '';
  FResult := 0;
end;

procedure TBoilerplateApplication.Default(var Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'DEFAULT CONTENT';
end;

procedure TBoilerplateApplication.Error(var Msg: RawUTF8; var Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := 'ERROR CONTENT';
end;

procedure TBoilerplateApplication.Start(Server: TSQLRestServer);
var
  Params: TMVCViewsMustacheParameters;
  Views: TMVCViewsAbtract;
begin
  inherited Start(Server, TypeInfo(IBoilerplateApplication));

  FillChar(Params, SizeOf(Params), 0);
  with Params do
  begin
    Folder := 'Views';
    FileTimestampMonitorAfterSeconds := 0;
    ExtensionForNotExistingTemplate := '';
  end;
  Views := TMVCViewsMustache.Create(FFactory.InterfaceTypeInfo, Params,
    (fRestModel as TSQLRestServer).LogClass);

  FMainRunner := TMVCRunOnRestServer.Create(Self, fRestServer, '', Views);
end;

procedure TBoilerplateApplication._404(out Scope: Variant);
begin
  TDocVariant.NewFast(Scope);
  Scope.Content := '404 CONTENT';
end;

procedure TBoilerplateFeatures.Scenarios;
begin
  AddCase(TBoilerplateHTTPServerShould);
end;

procedure CleanUp;
var
  LogFiles: TFindFilesDynArray;
  Index: Integer;
begin
  LogFiles := FindFiles(GetCurrentDir, 'mORMotBPTests ???????? ??????.log');
  for Index := Low(LogFiles) to High(LogFiles) do
    DeleteFile(LogFiles[Index].Name);
end;

end.
