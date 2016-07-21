/// HTML5 Boilerplate integration with Synopse mORMot Framework
// Licensed under The MIT License (MIT)
unit BoilerplateHTTPServer;

(*
  This file is a path of integration project between HTML5 Boilerplate and
  Synopse mORMot Framework.

    http://synopse.info
    https://html5boilerplate.com

  Boilerplate HTTP Server
  (c) 2016 Yevgeny Iliyn

  https://github.com/eugeneilyin/mORMotBP

  Version 1.0
  - First public release

  Version 1.1
  - minor "Cache-Control" parameters order changes
  - added bpoDelegateIndexToInheritedDefault to delegate index.html to Default()
  - added bpoDelegate404ToInherited_404 to delegate 404.html to _404()

  Version 1.2
  - fix "Accept-Encoding" parsing when gzip in the end of encoding list
  - make Pre-Build events notice more visible in tests and demo
  - minor code refactoring
*)

interface

uses
  SysUtils,
  SynCommons,
  SynCrtSock,
  mORMot,
  mORMotHttpServer,
  BoilerplateAssets;

type

  /// Primary options for TBoilerplateHTTPServer class instance
  TBoilerplateOption = (

    /// Cross-origin requests
    // Allow cross-origin requests.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
    // http://enable-cors.org/
    // http://www.w3.org/TR/cors/
    bpoAllowCrossOrigin,

    /// Cross-origin images
    // Send the CORS header for images when browsers request it.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTML/CORS_enabled_image
    // https://blog.chromium.org/2011/07/using-cross-domain-images-in-webgl-and.html
    //
    // - Use TBoilerplateHTTPServer.FileTypesImage to specify file types
    bpoAllowCrossOriginImages,

    /// Cross-origin web fonts
    // Allow cross-origin access to web fonts.
    //
    // - Use TBoilerplateHTTPServer.FileTypesFont to specify file types
    bpoAllowCrossOriginFonts,

    /// Cross-origin resource timing
    // Allow cross-origin access to the timing information for all resources.
    //
    // If a resource isn't served with a `Timing-Allow-Origin` header that
    // would allow its timing information to be shared with the document,
    // some of the attributes of the `PerformanceResourceTiming` object will
    // be set to zero.
    //
    // http://www.w3.org/TR/resource-timing/
    // http://www.stevesouders.com/blog/2014/08/21/resource-timing-practical-tips/
    bpoAllowCrossOriginTiming,

    /// Custom error messages/pages
    // Customize what server returns to the client in case of an error.

    // Delete content generation for HTTP 400 responce code to '/404'
    bpoDelegateBadRequestTo404,

    // Delete content generation for HTTP 403 responce code to '/404'
    bpoDelegateForbiddenTo404,

    // Delete content generation for HTTP 404 responce code to '/404'
    bpoDelegateNotFoundTo404,

    /// Internet Explorer Document modes                                                     |
    // Force Internet Explorer 8/9/10 to render pages in the highest mode
    // available in the various cases when it may not.
    //
    // https://hsivonen.fi/doctype/#ie8
    //
    // (!) Starting with Internet Explorer 11, document modes are deprecated.
    // If your business still relies on older web apps and services that were
    // designed for older versions of Internet Explorer, you might want to
    // consider enabling `Enterprise Mode` throughout your company.
    //
    // https://msdn.microsoft.com/en-us/library/ie/bg182625.aspx#docmode
    // http://blogs.msdn.com/b/ie/archive/2014/04/02/stay-up-to-date-with-enterprise-mode-for-internet-explorer-11.aspx
    //
    // - Use TBoilerplateHTTPServer.FileTypesAsset to exclude some file types
    bpoSetXUACompatible,

    /// Internet Explorer Iframes cookies
    // Allow cookies to be set from iframes in Internet Explorer.
    //
    // https://msdn.microsoft.com/en-us/library/ms537343.aspx
    // http://www.w3.org/TR/2000/CR-P3P-20001215/
    bpoSetP3P,

    /// Media types
    // Serve resources with the proper media types (f.k.a. MIME types).
    //
    // https://www.iana.org/assignments/media-types/media-types.xhtml
    bpoForceMIMEType,

    /// Character encodings
    // Serve all resources labeled as `text/html` or `text/plain`
    // with the media type `charset` parameter set to `UTF-8`.
    bpoForceTextUTF8Charset,

    /// Serve the following file types with the media type `charset`
    // parameter set to `UTF-8`.
    // - Use TBoilerplateHTTPServer.FileTypesRequiredCharSet to setup file types
    bpoForceUTF8Charset,

    /// Forcing `https://`
    //
    // Redirect from the `http://` to the `https://` version of the URL.
    bpoForceHTTPS,

    /// Protect website against clickjacking.
    //
    // The example below sends the `X-Frame-Options` response header with
    // the value `DENY`, informing browsers not to display the content of
    // the web page in any frame.
    //
    // This might not be the best setting for everyone. You should read
    // about the other two possible values the `X-Frame-Options` header
    // field can have: `SAMEORIGIN` and `ALLOW-FROM`.
    // https://tools.ietf.org/html/rfc7034section-2.1.
    //
    // Keep in mind that while you could send the `X-Frame-Options` header
    // for all of your website’s pages, this has the potential downside that
    // it forbids even non-malicious framing of your content (e.g.: when
    // users visit your website using a Google Image Search results page).
    //
    // Nonetheless, you should ensure that you send the `X-Frame-Options`
    // header for all pages that allow a user to make a state changing
    // operation (e.g: pages that contain one-click purchase links, checkout
    // or bank-transfer confirmation pages, pages that make permanent
    // configuration changes, etc.).
    //
    // Sending the `X-Frame-Options` header can also protect your website
    // against more than just clickjacking attacks:
    // https://cure53.de/xfo-clickjacking.pdf.
    //
    // https://tools.ietf.org/html/rfc7034
    // http://blogs.msdn.com/b/ieinternals/archive/2010/03/30/combating-clickjacking-with-x-frame-options.aspx
    // https://www.owasp.org/index.php/Clickjacking
    //
    // - Use TBoilerplateHTTPServer.FileTypesAsset to exclude some file types
    bpoSetXFrameOptions,

    /// Block access to files that can expose sensitive information.
    //
    // By default, block access to backup and source files that may be
    // left by some text editors and can pose a security risk when anyone
    // has access to them.
    //
    // http://feross.org/cmsploit/
    //
    // - Use TBoilerplateHTTPServer.FileTypesBlocked to specify file types
    bpoDelegateBlocked,

    /// Reducing MIME type security risks
    // Prevent some browsers from MIME-sniffing the response.
    //
    // This reduces exposure to drive-by download attacks and cross-origin
    // data leaks, and should be left uncommented, especially if the server
    // is serving user-uploaded content or content that could potentially be
    // treated as executable by the browser.
    //
    // http://www.slideshare.net/hasegawayosuke/owasp-hasegawa
    // http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
    // https://msdn.microsoft.com/en-us/library/ie/gg622941.aspx
    // https://mimesniff.spec.whatwg.org/
    bpoPreventMIMESniffing,

    /// Reflected Cross-Site Scripting (XSS) attacks
    //  The filter is usually enabled by default, but in some cases it
    //  may be disabled by the user. However, in Internet Explorer for
    //  example, it can be re-enabled just by sending the
    //  `X-XSS-Protection` header with the value of `1`.
    //
    //  Prevent web browsers from rendering the web page if a potential
    //  reflected (a.k.a non-persistent) XSS attack is detected by the
    //  filter.
    //
    //  By default, if the filter is enabled and browsers detect a
    //  reflected XSS attack, they will attempt to block the attack
    //  by making the smallest possible modifications to the returned
    //  web page.
    //
    //  Unfortunately, in some browsers (e.g.: Internet Explorer),
    //  this default behavior may allow the XSS filter to be exploited,
    //  thereby, it's better to inform browsers to prevent the rendering
    //  of the page altogether, instead of attempting to modify it.
    //
    //  https://hackademix.net/2009/11/21/ies-xss-filter-creates-xss-vulnerabilities
    //
    // (!) Do not rely on the XSS filter to prevent XSS attacks! Ensure that
    //     you are taking all possible measures to prevent XSS attacks, the
    //     most obvious being: validating and sanitizing your website's inputs.
    //
    // http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-iv-the-xss-filter.aspx
    // http://blogs.msdn.com/b/ieinternals/archive/2011/01/31/controlling-the-internet-explorer-xss-filter-with-the-x-xss-protection-http-header.aspx
    // https://www.owasp.org/index.php/Cross-site_Scripting_%28XSS%29
    //
    // - Use TBoilerplateHTTPServer.FileTypesAsset to exclude some file types
    bpoEnableXSSFilter,

    /// Remove the `X-Powered-By` response header that:
    // Better add NOXPOWEREDNAME into Conditional Defines in the Project Options
    //
    //  * is set by some frameworks and server-side languages
    //    (e.g.: ASP.NET, PHP), and its value contains information
    //    about them (e.g.: their name, version number)
    //
    //  * doesn't provide any value as far as users are concern,
    //    and in some cases, the information provided by it can
    //    be used by attackers
    //
    // (!) If you can, you should disable the `X-Powered-By` header from the
    // language / framework level (e.g.: for PHP, you can do that by setting
    // `expose_php = off` in `php.ini`)
    //
    // https://php.net/manual/en/ini.core.php#ini.expose-php
    bpoDeleteXPoweredBy,

    /// Force compression for mangled `Accept-Encoding` request headers
    // https://developer.yahoo.com/blogs/ydn/pushing-beyond-gzipping-25601.html
    //
    // - Use TBoilerplateHTTPServer.MangledEncodingHeaders
    // - Use TBoilerplateHTTPServer.MangledEncodingHeaderValues
    bpoFixMangledAcceptEncoding,

    /// Compress all output labeled with one of the known media types.
    //
    // - Use TBoilerplateHTTPServer.GZippedMIMETypes to specify file types
    bpoEnableGZipByMIMETypes,

    /// Map the following filename extensions to the specified
    // encoding type in order to make serve the file types
    // with the appropriate `Content-Encoding` response header
    // (do note that this will NOT make server compress them!).
    //
    // If these files types would be served without an appropriate
    // `Content-Enable` response header, client applications (e.g.:
    // browsers) wouldn't know that they first need to uncompress
    // the response, and thus, wouldn't be able to understand the
    // content.
    //
    // - Use TBoilerplateHTTPServer.FileTypesForceGZipHeader to setup file types
    bpoForceGZipHeader,

    /// Content transformation
    // Prevent intermediate caches or proxies (e.g.: such as the ones
    // used by mobile network providers) from modifying the website's
    // content.
    //
    // https://tools.ietf.org/html/rfc2616#section-14.9.5
    //
    // (!) If you are using `mod_pagespeed`, please note that setting
    // the `Cache-Control: no-transform` response header will prevent
    // `PageSpeed` from rewriting `HTML` files, and, if the
    // `ModPagespeedDisableRewriteOnNoTransform` directive isn't set
    // to `off`, also from rewriting other resources.
    //
    // https://developers.google.com/speed/pagespeed/module/configuration#notransform
    bpoSetCacheNoTransform,

    /// Allow static assets to be cached by proxy servers
    bpoSetCachePublic,

    /// Allow static assets to be cached only by browser, but not by intermediate proxy servers
    bpoSetCachePrivate,

    /// Allow static assets to be validated with server before return cached copy
    bpoSetCacheNoCache,

    /// Allow static assets not to be cached
    bpoSetCacheNoStore,

    /// Allow static assets to be cached strictly following the server rules
    bpoSetCacheMustRevalidate,

    /// Add 'max-age' value based on content-type/expires mapping
    //
    // - TBoilerplateHTTPServer.Expires
    bpoSetCacheMaxAge,

    // Use ETag/If-None-Match caching
    // https://developer.yahoo.com/performance/rules.html#etags
    // https://tools.ietf.org/html/rfc7232#section-2.3
    bpoEnableCacheByETag,

    // Use Last-Modified/If-Modified-Since caching
    // https://developer.yahoo.com/performance/rules.html#etags
    // https://tools.ietf.org/html/rfc7232#section-2.3
    bpoEnableCacheByLastModified,

    /// Expires headers
    // Serve resources with far-future expires headers.
    //
    // (!) If you don't control versioning with filename-based
    // cache busting, you should consider lowering the cache times
    // to something like one week.
    //
    // - TBoilerplateHTTPServer.Expires
    bpoSetExpires,

    ///Filename-based cache busting
    //
    // If you're not using a build process to manage your filename version
    // revving, you might want to consider enabling the following directives
    // to route all requests such as `/style.12345.css` to `/style.css`.
    //
    // To understand why this is important and even a better solution than
    // using something like `*.css?v231`, please see:
    // http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/
    bpoEnableCacheBusting,

    // Delete content generation for '' and '/' URLs to '/index.html'
    bpoDelegateRootToIndex,

    /// Remove 'Server-InternalState' HTTP header
    bpoDeleteServerInternalState,

    /// Instead of index.html rendering the inherited "/Default" URL will be called
    // It allows to inject custom IMVCApplication.Default() interface method
    bpoDelegateIndexToInheritedDefault,

    /// Instead of 404.html rendering the inherited "/404" URL will be called
    // It allows to inject custom IMVCApplication._404() interface method
    bpoDelegate404ToInherited_404,

    /// Add 'Vary: Accept-Encoding' header for resource types specified in
    // TBoilerplateHTTPServer.GZippedMIMETypes
    bpoVaryAcceptEncoding
  );

  TBoilerplateOptions = set of TBoilerplateOption;

  /// Suppressing / Forcing the `www.` at the beginning of URLs
  // The same content should never be available under two different
  // URLs, especially not with and without `www.` at the beginning.
  // This can cause SEO problems (duplicate content), and therefore,
  // you should choose one of the alternatives and redirect the other
  // one.
  //
  // wwwSuppress: Rewrite www.example.com --> example.com
  // wwwForce: Rewrite example.com --> www.example.com
  //
  // Be aware that wwwForce might not be a good idea if you use "real"
  // subdomains for certain parts of your website.
  TWWWRewrite = (wwwOff, wwwSuppress, wwwForce);

  /// HTTP Strict Transport Security (HSTS
  // Force client-side SSL redirection.
  //
  // If a user types `example.com` in their browser, even if the server
  // redirects them to the secure version of the website, that still leaves
  // a window of opportunity (the initial HTTP connection) for an attacker
  // to downgrade or redirect the request.
  //
  // The following header ensures that browser will ONLY connect to your
  // server via HTTPS, regardless of what the users type in the browser's
  // address bar.
  //
  // (!) Do not use strictSSLIncludeSubDomains if the website's subdomains
  // are not using HTTPS (e.g. http://static.domain.com).
  //
  // http://www.html5rocks.com/en/tutorials/security/transport-layer-security/
  // https://tools.ietf.org/html/draft-ietf-websec-strict-transport-sec-14section-6.1
  // http://blogs.msdn.com/b/ieinternals/archive/2014/08/18/hsts-strict-transport-security-attacks-mitigations-deployment-https.aspx
  TStrictSSL = (strictSSLOff, strictSSLOn, strictSSLIncludeSubDomains);

  /// GZip level used for response compression
  TGZipLevel = (gz0, gz1, gz2, gz3, gz4, gz5, gz6, gz7, gz8, gz9);

type

  /// TBoilerplateHTTPServer
  TBoilerplateHTTPServer = class(TSQLHttpServer)
  protected
    FAssets: TAssets;
    FOptions: TBoilerplateOptions;
    FContentSecurityPolicy: SockString;
    FStrictSSL: TStrictSSL;
    FWWWRewrite: TWWWRewrite;
    FGZipLevel: TGZipLevel;
    FFileTypesImage: RawUTF8;
    FFileTypesImageArray: TRawUTF8DynArray;
    FFileTypesFont: RawUTF8;
    FFileTypesFontArray: TRawUTF8DynArray;
    FFileTypesAsset: RawUTF8;
    FFileTypesAssetArray: TRawUTF8DynArray;
    FForceMIMETypes: RawUTF8;
    FForceMIMETypesValues: TSynNameValue;
    FFileTypesRequiredCharSet: RawUTF8;
    FFileTypesRequiredCharSetValues: TRawUTF8DynArray;
    FFileTypesBlocked: RawUTF8;
    FFileTypesBlockedArray: TRawUTF8DynArray;
    FMangledEncodingHeaders: RawUTF8;
    FMangledEncodingHeadersArray: TRawUTF8DynArray;
    FMangledEncodingHeaderValues: RawUTF8;
    FMangledEncodingHeaderValuesArray: TRawUTF8DynArray;
    FGZippedMIMETypes: RawUTF8;
    FGZippedMIMETypesArray: TRawUTF8DynArray;
    FFileTypesForceGZipHeader: RawUTF8;
    FFileTypesForceGZipHeaderArray: TRawUTF8DynArray;
    FExpires: RawUTF8;
    FExpiresDefault: PtrInt;
    FExpiresValues: TSynNameValue;
    FGZippedAssets: TSynNameValue;
    FStaticRoot: TFileName;
    FCustomOptions: TSynNameValue;

    /// Init assets and set default values for properties
    procedure Init; virtual;

    /// Cut '?' and the next URL content
    // This is usefull for reload cached resources like '/img.jpg?v=1.2.3'
    // Extract and lowercase file type like '.css' or '.jpg'
    procedure SplitURL(const URL: SockString; out Path, Ext: SockString;
      const EnableCacheBusting: Boolean); {$ifdef HASINLINE}inline;{$endif}

    /// Fill the RawUTF8 array with unique, lower-cased and
    // sorted values ready for binary search
    procedure ArrayFromCSV(out anArray: TRawUTF8DynArray; const CSV: RawUTF8;
      const Prefix: RawUTF8 = '.'; const Sep: AnsiChar = ',');
        {$ifdef HASINLINE}inline;{$endif}

    /// Binary search of file type in sorted array with unique values
    function FastInArray(const Ext: SockString;
      const Exts: TRawUTF8DynArray): Boolean; {$ifdef HASINLINE}inline;{$endif}

    /// Add HTTP header value to Context.OutHeaders
    procedure AddCustomHeader(Context: THttpServerRequest;
      const Header, Value: SockString);
      {$ifdef HASINLINE}inline;{$endif}

    /// Remove HTTP header value from Context.OutHeaders
    function DeleteCustomHeader(Context: THttpServerRequest;
      const HeaderUp: SockString): SockString; {$ifdef HASINLINE}inline;{$endif}

    /// Validate that HTTP responce content can be GZipped
    function IsGZipAccepted(Context: THttpServerRequest;
      const FixMangled: Boolean): Boolean; {$ifdef HASINLINE}inline;{$endif}

    /// Check ETag of Last-Modified values
    function IsContentModified(Context: THttpServerRequest; const Asset: PAsset;
      const CheckETag, CheckModified: Boolean): Boolean; virtual;
        {$ifdef HASINLINE}inline;{$endif}

    /// Convert "text/html=1m", "image/x-icon=1w", etc. expires to seconds
    function ExpiresToSecs(const Value: RawUTF8): PtrInt; virtual;
      {$ifdef HASINLINE}inline;{$endif}

    /// Get number of seconds, when content will be expired
    function GetExpires(const ContentType: RawUTF8): PtrInt;
      {$ifdef HASINLINE}inline;{$endif}

    /// Removes charset from content type
    function ContentTypeWithoutCharset(const ContentType: RawUTF8): RawUTF8;
      {$ifdef HASINLINE}inline;{$endif}

    /// Compress HTTP responce content
    // Taken from SynZip.pas only compression level customization has added
    procedure CompressGZip(var DataRawByteString; const Level: Integer);
      {$ifdef HASINLINE}inline;{$endif}

    /// Rebuild assets GZipped cache
    procedure CreateGZippedAssets; {$ifdef HASINLINE}inline;{$endif}

    /// Save static content to delegate file sending to low-level API
    procedure SaveStaticAsset(const Context: THttpServerRequest;
      const Asset: PAsset; const GZippedContent: RawByteString); virtual;
        {$ifdef HASINLINE}inline;{$endif}

    /// Find host for redirection rules. Returns '' if host not found
    function FindHost(const Context: THttpServerRequest): SockString; virtual;
      {$ifdef HASINLINE}inline;{$endif}

    function FindCustomOptions(const URL: RawUTF8;
      const Default: TBoilerplateOptions): TBoilerplateOptions;

    procedure SetFileTypesImage(const Value: RawUTF8);
    procedure SetFileTypesFont(const Value: RawUTF8);
    procedure SetFileTypesAsset(const Value: RawUTF8);
    procedure SetForceMIMETypes(const Value: RawUTF8);
    procedure SetFileTypesRequiredCharSet(const Value: RawUTF8);
    procedure SetFileTypesBlocked(const Value: RawUTF8);
    procedure SetMangledEncodingHeaders(const Value: RawUTF8);
    procedure SetMangledEncodingHeaderValues(const Value: RawUTF8);
    procedure SetGZippedMIMETypes(const Value: RawUTF8);
    procedure SetFileTypesForceGZipHeader(const Value: RawUTF8);
    procedure SetExpires(const Value: RawUTF8);
    procedure SetGZipLevel(const Value: TGZipLevel);

  protected
    function Request(Context: THttpServerRequest): Cardinal; override;

  public
    /// Standart TSQLHttpServer constructor
    constructor Create(const aPort: AnsiString;
      const aServers: array of TSQLRestServer;
      const aDomainName: AnsiString='+';
      aHttpServerKind: TSQLHttpServerOptions=HTTP_DEFAULT_MODE;
      ServerThreadPoolCount: Integer=32;
      aHttpServerSecurity: TSQLHttpServerSecurity=secNone;
      const aAdditionalURL: AnsiString=''; const aQueueName: SynUnicode='');
        overload;

    /// Standart TSQLHttpServer constructor
    constructor Create(const aPort: AnsiString; aServer: TSQLRestServer;
      const aDomainName: AnsiString='+';
      aHttpServerKind: TSQLHttpServerOptions=HTTP_DEFAULT_MODE;
      aRestAccessRights: PSQLAccessRights=nil;
      ServerThreadPoolCount: Integer=32;
      aHttpServerSecurity: TSQLHttpServerSecurity=secNone;
      const aAdditionalURL: AnsiString=''; const aQueueName: SynUnicode='');
        overload;

    /// Standart TSQLHttpServer constructor
    constructor Create(aServer: TSQLRestServer;
      aDefinition: TSQLHttpServerDefinition); overload;

  public
    /// Load assets from RT_RCDATA synzl-compressed resource
    procedure LoadFromResource(const ResName: string);

    /// Register custom Cache-Control options for specific URL's
    // For example if you want cache most *.html pages with standart
    // Cache-Control options, but change this rule for default page or login page
    procedure RegisterCustomOptions(const URL: RawUTF8;
      CustomCacheOptions: TBoilerplateOptions);

    /// Removes custom options usage for specific URL
    procedure UnregisterCustomOptions(const URL: RawUTF8);

    /// See TBoilerplateOptions
    property Options: TBoilerplateOptions read FOptions write FOptions;

    /// See TWWWRewrite
    property WWWRewrite: TWWWRewrite read FWWWRewrite write FWWWRewrite;

    /// Content Security Policy (CSP)
    //
    // Mitigate the risk of cross-site scripting and other content-injection
    // attacks.
    //
    // This can be done by setting a `Content Security Policy` which
    // whitelists trusted sources of content for your website.
    //
    // The example header below allows ONLY scripts that are loaded from
    // the current website's origin (no inline scripts, no CDN, etc).
    // That almost certainly won't work as-is for your website!
    //
    // To make things easier, you can use an online CSP header generator
    // such as: http://cspisawesome.com/.
    //
    // http://content-security-policy.com/
    // http://www.html5rocks.com/en/tutorials/security/content-security-policy/
    // http://www.w3.org/TR/CSP11/
    //
    // Very strict example (block all external, not usefull in practice):
    //   ContentSecurityPolicy :=  'script-src ''self''; object-src ''self''';
    //
    // - Use FileTypesAsset property to exclude some file types
    property ContentSecurityPolicy: SockString
      read FContentSecurityPolicy write FContentSecurityPolicy;

    /// See TStrictSSL
    property StrictSSL: TStrictSSL read FStrictSSL write FStrictSSL;

    /// See TGZipLevel
    property GZipLevel: TGZipLevel read FGZipLevel write SetGZipLevel;

    /// See TBoilerplateOption.bpoAllowCrossOriginImages
    property FileTypesImage: RawUTF8 read FFileTypesImage
      write SetFileTypesImage;

    /// See TBoilerplateOption.bpoAllowCrossOriginFonts
    property FileTypesFont: RawUTF8 read FFileTypesFont
      write SetFileTypesFont;

    /// See TBoilerplateOption.bpoSetXUACompatible, .bpoSetXFrameOptions,
    // .bpoEnableXSSFilter and ContentSecurityPolicy
    property FileTypesAsset: RawUTF8 read FFileTypesAsset
      write SetFileTypesAsset;

    /// See TBoilerplateOption.bpoForceMIMEType
    property ForceMIMETypes: RawUTF8 read FForceMIMETypes
      write SetForceMIMETypes;

    /// TBoilerplateOption.bpoForceUTF8Charset
    property FileTypesRequiredCharSet: RawUTF8 read FFileTypesRequiredCharSet
      write SetFileTypesRequiredCharSet;

    /// TBoilerplateOption.bpoDelegateBlocked
    property FileTypesBlocked: RawUTF8 read FFileTypesBlocked
      write SetFileTypesBlocked;

    /// TBoilerplateOption.bpoFixMangledAcceptEncoding
    property MangledEncodingHeaders: RawUTF8 read FMangledEncodingHeaders
      write SetMangledEncodingHeaders;

    /// TBoilerplateOption.bpoFixMangledAcceptEncoding
    property MangledEncodingHeaderValues: RawUTF8
      read FMangledEncodingHeaderValues write SetMangledEncodingHeaderValues;

    /// TBoilerplateOption.bpoEnableGZipByMIMETypes
    property GZippedMIMETypes: RawUTF8 read FGZippedMIMETypes
      write SetGZippedMIMETypes;

    /// TBoilerplateOption.bpoForceGZipHeader
    property FileTypesForceGZipHeader: RawUTF8 read FFileTypesForceGZipHeader
      write SetFileTypesForceGZipHeader;

    /// TBoilerplateOption.bpoSetExpires
    property Expires: RawUTF8 read FExpires write SetExpires;

    /// If this folder is not empty, all assets will be pre-saved as
    // files into this folder. To minimize disk IO operations file attributes
    // Created, Modified and Size (size only for not gzipped assets) will
    // be checked before saving.
    // The STATICFILE_CONTENT_TYPE will be used to inform the lower level API
    // to send the responce as file content. For files without compression
    // 'cache.plain' sub-folder is used, for files with GZip compression
    // 'cache.gz' sub-folder is used with .gz suffix added to each file. All
    // files will be stored only once or if their Created, Modified or Size
    // attributes differ from mem-cached variant.
    property StaticRoot: TFileName read FStaticRoot write FStaticRoot;
  end;

const
  /// See TBoilerplateOption
  DEFAULT_BOILERPLATE_OPTIONS: TBoilerplateOptions = [
    bpoAllowCrossOrigin,
    bpoAllowCrossOriginImages,
    bpoAllowCrossOriginFonts,
    bpoDelegateBadRequestTo404,
    bpoDelegateForbiddenTo404,
    bpoDelegateNotFoundTo404,
    bpoSetXUACompatible,
    bpoForceMIMEType,
    bpoForceTextUTF8Charset,
    bpoForceUTF8Charset,
    bpoSetXFrameOptions,
    bpoDelegateBlocked,
    bpoPreventMIMESniffing,
    bpoEnableXSSFilter,
    bpoDeleteXPoweredBy,
    bpoSetCachePublic,
    bpoSetCacheMaxAge,
    bpoEnableCacheByLastModified,
    bpoEnableCacheBusting,
    bpoSetExpires,
    bpoDelegateRootToIndex,
    bpoDeleteServerInternalState,
    bpoVaryAcceptEncoding];

  /// See TBoilerplateHTTPServer.ContentSecurityPolicy
  DEFAULT_CONTENT_SECURITY_POLICY: SockString = '';

  /// See TStrictSSL
  DEFAULT_STRICT_SLL: TStrictSSL = strictSSLOff;

  /// See TWWWRewrite
  DEFAULT_WWW_REWRITE:TWWWRewrite = wwwSuppress;

  /// See TGZipLevel
  DEFAULT_GZIP_LEVEL: TGZipLevel = High(TGZipLevel);

  /// See TBoilerplateHTTPServer.FileTypesImage
  DEFAULT_FILE_TYPES_IMAGE =
    'bmp,cur,gif,ico,jpg,jpeg,png,svg,svgz,webp';

  /// See TBoilerplateHTTPServer.FileTypesFont
  DEFAULT_FILE_TYPES_FONT =
    'eot,otf,ttc,ttf,woff,woff2';

  /// See TBoilerplateHTTPServer.FileTypesAsset
  DEFAULT_FILE_TYPES_ASSET =
    'appcache,atom,bbaw,bmp,crx,css,cur,eot,f4a,f4b,f4p,f4v,flv,geojson,gif,' +
    'htc,ico,jpeg,jpg,js,json,jsonld,m4a,m4v,manifest,map,mp4,oex,oga,ogg,' +
    'ogv,opus,otf,pdf,png,rdf,rss,safariextz,svg,svgz,swf,topojson,ttc,ttf,' +
    'txt,vcard,vcf,vtt,webapp,webm,webmanifest,webp,woff,woff2,xloc,xml,xpi';

  /// See TBoilerplateHTTPServer.FileTypesRequiredCharSet
  DEFAULT_FILE_TYPES_REQUIRED_CHARSET =
    'atom,bbaw,css,geojson,js,json,jsonld,manifest,rdf,rss,topojson,vtt,' +
    'webapp,webmanifest,xloc,xml';

  /// See TBoilerplateHTTPServer.FileTypesBlocked
  DEFAULT_FILE_TYPES_BLOCKED =
    'bak,conf,dist,fla,inc,ini,log,psd,sh,sql,swo,swp';

  /// See TBoilerplateHTTPServer.MangledEncodingHeaders
  DEFAULT_MANGLED_ENCODING_HEADERS =
    'Accept-EncodXng,X-cept-Encoding,XXXXXXXXXXXXXXX,~~~~~~~~~~~~~~~,' +
    '---------------';

  /// TBoilerplateHTTPServer.MangledEncodingHeaderValues
  DEFAULT_MANGLED_ENCODING_HEADER_VALUES = 'gzip|deflate|gzip,deflate|' +
    'deflate,gzip|XXXX|XXXXX|XXXXXX|XXXXXXX|XXXXXXXX|XXXXXXXXX|XXXXXXXXXX|' +
    'XXXXXXXXXXX|XXXXXXXXXXXX|XXXXXXXXXXXXX|~~~~|~~~~~|~~~~~~|~~~~~~~|' +
    '~~~~~~~~|~~~~~~~~~|~~~~~~~~~~|~~~~~~~~~~~|~~~~~~~~~~~~|~~~~~~~~~~~~~|' +
    '----|-----|------|-------|--------|---------|----------|-----------|' +
    '------------|-------------';

  /// TBoilerplateHTTPServer.GZippedMIMETypes
  DEFAULT_GZIPPED_MIME_TYPES =
    'application/atom+xml,application/javascript,application/json,' +
    'application/ld+json,application/manifest+json,application/rdf+xml,' +
    'application/rss+xml,application/schema+json,application/vnd.geo+json,' +
    'application/vnd.ms-fontobject,application/x-font-ttf,' +
    'application/xhtml+xml,application/x-javascript,application/xml,' +
    'application/x-web-app-manifest+json,font/eot,font/opentype,image/bmp,' +
    'image/svg+xml,image/vnd.microsoft.icon,image/x-icon,text/cache-manifest,' +
    'text/css,text/html,text/javascript,text/plain,text/vcard,' +
    'text/vnd.rim.location.xloc,text/vtt,text/x-component,' +
    'text/x-cross-domain-policy,text/xml';

  /// See TBoilerplateHTTPServer.FileTypesForceGZipHeader
  DEFAULT_FILE_TYPES_FORCE_GZIP_HEADER = 'svgz';

  /// See TBoilerplateHTTPServer.Expires
  DEFAULT_EXPIRES =

    // Default
    '*=1m'#10 +

    // CSS
    'text/css=1y'#10 +

    // Data interchange
    'application/atom+xml=1h'#10 +
    'application/rdf+xml=1h'#10 +
    'application/rss+xml=1h'#10 +

    'application/json=0s'#10 +
    'application/ld+json=0s'#10 +
    'application/schema+json=0s'#10 +
    'application/vnd.geo+json=0s'#10 +
    'application/xml=0s'#10 +
    'text/xml=0s'#10 +

    // Favicon (cannot be renamed!) and cursor images
    'image/vnd.microsoft.icon=1w'#10 +
    'image/x-icon=1w'#10 +

    // HTML
    'text/html=0s'#10 +

    // JavaScript
    'application/javascript=1y'#10 +
    'application/x-javascript=1y'#10 +
    'text/javascript=1y'#10 +

    // Manifest files
    'application/manifest+json=1w'#10 +
    'application/x-web-app-manifest+json=0s'#10 +
    'text/cache-manifest=0s'#10 +

    // Media files
    'audio/ogg=1m'#10 +
    'image/bmp=1m'#10 +
    'image/gif=1m'#10 +
    'image/jpeg=1m'#10 +
    'image/png=1m'#10 +
    'image/svg+xml=1m'#10 +
    'image/webp=1m'#10 +
    'video/mp4=1m'#10 +
    'video/ogg=1m'#10 +
    'video/webm=1m'#10 +

    // Web fonts

    // Embedded OpenType (EOT)
    'application/vnd.ms-fontobject=1m'#10 +
    'font/eot=1m'#10 +

    // OpenType
    'font/opentype=1m'#10 +

    // TrueType
    'application/x-font-ttf=1m'#10 +

    // Web Open Font Format (WOFF) 1.0
    'application/font-woff=1m'#10 +
    'application/x-font-woff=1m'#10 +
    'font/woff=1m'#10 +

    // Web Open Font Format (WOFF) 2.0
    'application/font-woff2=1m'#10 +

    // Other
    'text/x-cross-domain-policy=1w'#10 +
    '';

implementation

uses
  SynZip;

function IdemPChar(P, Up: PAnsiChar): Boolean;
// if the beginning of p^ is same as up^ (ignore case - up^ must be already Upper)
var
  C: AnsiChar;
begin
  Result := False;
  if P = nil then
    Exit;
  if (Up <> nil) and (Up^ <> #0) then
    repeat
      C := P^;
      if Up^ <> C then
        if C in ['a'..'z'] then begin
          Dec(C, 32);
          if Up^ <> C then
            Exit;
        end else
          Exit;
      Inc(Up);
      Inc(P);
    until Up^ = #0;
  Result := True;
end;

// This code taken from SynCrtSock.pas - not found in interface secion
function GetHeaderValue(var headers: SockString; const upname: SockString;
  deleteInHeaders: boolean): SockString;
var i,j,k: integer;
begin
  result := '';
  if (headers='') or (upname='') then
    exit;
  i := 1;
  repeat
    k := length(headers)+1;
    for j := i to k-1 do
      if headers[j]<' ' then begin
        k := j;
        break;
      end;
    if IdemPChar(@headers[i],pointer(upname)) then begin
      j := i;
      inc(i,length(upname));
      while headers[i]=' ' do inc(i);
      result := copy(headers,i,k-i);
      if deleteInHeaders then begin
        while true do
          if (headers[k]=#0) or (headers[k]>=' ') then
            break else
            inc(k);
        delete(headers,j,k-j);
      end;
      exit;
    end;
    i := k;
    while headers[i]<' ' do
      if headers[i]=#0 then
        exit else
        inc(i);
  until false;
end;

{ TBoilerplateHTTPServer }

procedure TBoilerplateHTTPServer.AddCustomHeader(Context: THttpServerRequest;
  const Header, Value: SockString);
begin
  if Context.OutCustomHeaders <> '' then
    Context.OutCustomHeaders :=
      FormatUTF8('%%%: %', [Context.OutCustomHeaders, #$D#$A, Header, Value])
  else
    Context.OutCustomHeaders :=
      FormatUTF8('%%: %', [Context.OutCustomHeaders, Header, Value]);
end;

function TBoilerplateHTTPServer.DeleteCustomHeader(Context: THttpServerRequest;
  const HeaderUp: SockString): SockString;
var
  Headers: SockString;
begin
  Headers := Context.OutCustomHeaders;
  Result := GetHeaderValue(Headers, HeaderUp, True);
  Context.OutCustomHeaders := Headers;
end;

function TBoilerplateHTTPServer.ExpiresToSecs(const Value: RawUTF8): PtrInt;
var
  LastChar: AnsiChar;
  Scale: PtrInt;
begin
  if Value = '' then
  begin
    Result := 0;
    Exit;
  end;

  LastChar := Value[Length(Value)];
  case LastChar of
    'S', 's': Scale := 1;
    'H', 'h': Scale := SecsPerHour;
    'D', 'd': Scale := SecsPerDay;
    'W', 'w': Scale := 7 * SecsPerDay;
    'M', 'm': Scale := 2629746; // SecsPerDay * 365.2425 / 12
    'Y', 'y': Scale := 365 * SecsPerDay;
    else begin
      Result := UTF8ToInteger(Value);
      Exit;
    end;
  end;

  Result := Scale * UTF8ToInteger(Copy(Value, 1, Length(Value) - 1));
end;

function TBoilerplateHTTPServer.FastInArray(const Ext: SockString;
  const Exts: TRawUTF8DynArray): Boolean;
begin
  Result := FastLocatePUTF8CharSorted(
    Pointer(Exts), High(Exts), Pointer(Ext)) = -1;
end;

function TBoilerplateHTTPServer.FindCustomOptions(const URL: RawUTF8;
  const Default: TBoilerplateOptions): TBoilerplateOptions;
var
  Index: Integer;

  function StrToOptions(const Str: RawUTF8): TBoilerplateOptions;
  begin
    MoveFast(Str[1], Result, SizeOf(Result));
  end;

begin
  Index := FCustomOptions.Find(URL);
  if Index >= 0 then
    Result := StrToOptions(FCustomOptions.List[Index].Value)
  else
    Result := Default;
end;

function TBoilerplateHTTPServer.FindHost(
  const Context: THttpServerRequest): SockString;
begin
  Result := TrimLeft(FindIniNameValue(Pointer(Context.InHeaders), 'HOST:'));
end;

function TBoilerplateHTTPServer.GetExpires(const ContentType: RawUTF8): PtrInt;
begin
  Result := FExpiresValues.Find(ContentType);
  if Result >= 0 then
    Result := FExpiresValues.List[Result].Tag
  else
    Result := FExpiresDefault;
end;

function TBoilerplateHTTPServer.ContentTypeWithoutCharset(
  const ContentType: RawUTF8): RawUTF8;
var
  Index: Integer;
begin
  Result := ContentType;
  Index := PosEx(';', Result);
  if Index > 0 then
    Delete(Result, Index, MaxInt);
end;

procedure TBoilerplateHTTPServer.CompressGZip(var DataRawByteString;
  const Level: Integer);
const
  GZIP_HEADER: array [0..2] of Cardinal = ($88B1F, 0, 0);
var
  L: Integer;
  P: PAnsiChar;
  Buffer: AnsiString;
  Data: ZipString absolute DataRawByteString;
begin
  L := Length(Data);
  SetString(Buffer, nil, L + 128 + L shr 3); // maximum possible memory required
  P := Pointer(Buffer);
  MoveFast(GZIP_HEADER, P^, 10);
  Inc(P, 10);
  Inc(P, CompressMem(Pointer(Data), P, L, Length(Buffer) - 20, Level));
  PCardinal(P)^ := crc32(0, Pointer(Data), L);
  Inc(P, 4);
  PCardinal(P)^ := L;
  Inc(P, 4);
  SetString(Data, PAnsiChar(Pointer(Buffer)), P - Pointer(Buffer));
end;

constructor TBoilerplateHTTPServer.Create(aServer: TSQLRestServer;
  aDefinition: TSQLHttpServerDefinition);
begin
  inherited Create(aServer, aDefinition);
  Init;
end;

procedure TBoilerplateHTTPServer.CreateGZippedAssets;
const
  GZIP_LEVELS: array[TGZipLevel] of Integer = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
var
  Index: Integer;
  LContent: RawByteString;
begin
  FGZippedAssets.Init(True);
  for Index := 0 to FAssets.Count - 1 do
    with FAssets.Assets[Index] do
    begin
      LContent := Content;
      CompressGZip(LContent, GZIP_LEVELS[FGZipLevel]);
      FGZippedAssets.Add(Path, LContent);
    end;
end;

constructor TBoilerplateHTTPServer.Create(const aPort: AnsiString;
  const aServers: array of TSQLRestServer; const aDomainName: AnsiString;
  aHttpServerKind: TSQLHttpServerOptions; ServerThreadPoolCount: Integer;
  aHttpServerSecurity: TSQLHttpServerSecurity; const aAdditionalURL: AnsiString;
  const aQueueName: SynUnicode);
begin
  inherited Create(aPort, aServers, aDomainName, aHttpServerKind,
    ServerThreadPoolCount, aHttpServerSecurity, aAdditionalURL, aQueueName);
  Init;
end;

constructor TBoilerplateHTTPServer.Create(const aPort: AnsiString;
  aServer: TSQLRestServer; const aDomainName: AnsiString;
  aHttpServerKind: TSQLHttpServerOptions; aRestAccessRights: PSQLAccessRights;
  ServerThreadPoolCount: Integer; aHttpServerSecurity: TSQLHttpServerSecurity;
  const aAdditionalURL: AnsiString; const aQueueName: SynUnicode);
begin
  inherited Create(aPort, aServer, aDomainName, aHttpServerKind,
    aRestAccessRights, ServerThreadPoolCount, aHttpServerSecurity,
    aAdditionalURL, aQueueName);
  Init;
end;

procedure TBoilerplateHTTPServer.Init;
begin
  FAssets.Init;
  FGZippedAssets.Init(True);
  FOptions := DEFAULT_BOILERPLATE_OPTIONS;
  FContentSecurityPolicy := DEFAULT_CONTENT_SECURITY_POLICY;
  FStrictSSL := DEFAULT_STRICT_SLL;
  FWWWRewrite := DEFAULT_WWW_REWRITE;
  FGZipLevel := DEFAULT_GZIP_LEVEL;
  SetFileTypesImage(DEFAULT_FILE_TYPES_IMAGE);
  SetFileTypesFont(DEFAULT_FILE_TYPES_FONT);
  SetFileTypesAsset(DEFAULT_FILE_TYPES_ASSET);
  SetForceMIMETypes(MIME_CONTENT_TYPES);
  SetFileTypesRequiredCharSet(DEFAULT_FILE_TYPES_REQUIRED_CHARSET);
  SetFileTypesBlocked(DEFAULT_FILE_TYPES_BLOCKED);
  SetMangledEncodingHeaders(DEFAULT_MANGLED_ENCODING_HEADERS);
  SetMangledEncodingHeaderValues(DEFAULT_MANGLED_ENCODING_HEADER_VALUES);
  SetGZippedMIMETypes(DEFAULT_GZIPPED_MIME_TYPES);
  SetFileTypesForceGZipHeader(DEFAULT_FILE_TYPES_FORCE_GZIP_HEADER);
  SetExpires(DEFAULT_EXPIRES);
  FCustomOptions.Init(False);
end;

function TBoilerplateHTTPServer.IsContentModified(Context: THttpServerRequest;
  const Asset: PAsset; const CheckETag, CheckModified: Boolean): Boolean;
const
  SERVER_HASH: RawUTF8 = '"00000000"';
var
  ClientHash: RawUTF8;
  ServerHash: RawUTF8;
  ClientModified: RawUTF8;
  ServerModified: RawUTF8;
begin
  Result := not (CheckETag or CheckModified);

  if not Result and CheckETag then
  begin
    SetRawUTF8(ServerHash, PRawUTF8(SERVER_HASH), Length(SERVER_HASH));
    BinToHexDisplay(@Asset.ContentHash,
      Pointer(@ServerHash[2]), SizeOf(Cardinal));
    ClientHash := FindIniNameValue(Pointer(Context.InHeaders),
      'IF-NONE-MATCH: ');
    Result := ClientHash <> ServerHash;
    if Result then
      Context.OutCustomHeaders := FormatUTF8('%ETag: %'#$D#$A,
        [Context.OutCustomHeaders, ServerHash]);
  end;

  if not Result and CheckModified then
  begin
    ServerModified := DateTimeToHTTPDate(Asset.Modified);
    ClientModified := FindIniNameValue(Pointer(Context.InHeaders),
      'IF-MODIFIED-SINCE: ');
    Result := (ClientModified = '') or
      (StrIComp(Pointer(ClientModified), Pointer(ServerModified)) <> 0);
    if Result then
      Context.OutCustomHeaders := FormatUTF8('%Last-Modified: %'#$D#$A,
        [Context.OutCustomHeaders, ServerModified]);
  end;
end;

function TBoilerplateHTTPServer.IsGZipAccepted(Context: THttpServerRequest;
  const FixMangled: Boolean): Boolean;
var
  AcceptEncoding: RawUTF8;
  Index: Integer;
begin
  AcceptEncoding := LowerCase(Trim(FindIniNameValue(
    Pointer(Context.InHeaders),'ACCEPT-ENCODING:')));
  Result := PosEx('gzip', AcceptEncoding) > 0;

  if (not FixMangled) or Result then Exit;

  for Index := Low(FMangledEncodingHeadersArray) to
    High(FMangledEncodingHeadersArray) do
  begin
    AcceptEncoding := LowerCase(Trim(FindIniNameValue(
      Pointer(Context.InHeaders),
      PAnsiChar(FMangledEncodingHeadersArray[Index]))));
    if AcceptEncoding <> '' then
    begin
      Result := FastInArray(AcceptEncoding, FMangledEncodingHeaderValuesArray);
      if Result then Exit;
    end;
  end;

  Result := False;
end;

procedure TBoilerplateHTTPServer.LoadFromResource(const ResName: string);
begin
  FAssets.DecompressFromResource(ResName);
  CreateGZippedAssets;
end;

procedure TBoilerplateHTTPServer.RegisterCustomOptions(const URL: RawUTF8;
  CustomCacheOptions: TBoilerplateOptions);

  function GetOptionsValue: RawUTF8;
  begin
    SetLength(Result, SizeOf(CustomCacheOptions));
    MoveFast(CustomCacheOptions, Result[1], SizeOf(CustomCacheOptions));
  end;

begin
  FCustomOptions.Add(URL, GetOptionsValue);
end;

function TBoilerplateHTTPServer.Request(Context: THttpServerRequest): Cardinal;
const
  HTTPS: array[Boolean] of SockString = ('', 's');
var
  Asset: PAsset;
  Path, PathLowerCased, Ext, Host: SockString;
  OriginExists, CORSEnabled: Boolean;
  ContentType, ForcedContentType, CacheControl: RawUTF8;
  GZippedContent: RawByteString;
  Expires: PtrInt;
  LOptions: TBoilerplateOptions;
  Vary: RawUTF8;
begin
  if (bpoDelegateRootToIndex in FOptions) and
    ((Context.URL = '') or (Context.URL = '/')) then
    with Context do
      if bpoDelegateIndexToInheritedDefault in FOptions then
        Prepare('/Default', Method, InHeaders, InContent, InContentType)
      else
        Prepare('/index.html', Method, InHeaders, InContent, InContentType);

  SplitURL(Context.URL, Path, Ext, bpoEnableCacheBusting in FOptions);

  LOptions := FindCustomOptions(Path, FOptions);

  if FWWWRewrite = wwwSuppress then
  begin
    Host := FindHost(Context);
    if (Host <> '') and IdemPChar(PAnsiChar(Host), 'WWW.') then
    begin
      Delete(Host, 1, 4);
      AddCustomHeader(Context, 'Location', SockString(
        FormatUTF8('http%://%%', [HTTPS[Context.UseSSL], Host, Path])));
      Result := HTML_MOVEDPERMANENTLY;
      Exit;
    end;
  end;

  if FWWWRewrite = wwwForce then
  begin
    Host := FindHost(Context);
    if (Host <> '') and not IdemPChar(PAnsiChar(Host), 'WWW.') then
    begin
      Host := 'www.' + Host;
      AddCustomHeader(Context, 'Location', SockString(
        FormatUTF8('http%://%%', [HTTPS[Context.UseSSL], Host, Path])));
      Result := HTML_MOVEDPERMANENTLY;
      Exit;
    end;
  end;

  if (bpoForceHTTPS in LOptions) and not Context.UseSSL then
  begin
    Host := FindHost(Context);
    if Host <> '' then
    begin
      AddCustomHeader(Context, 'Location', SockString(
        FormatUTF8('https://%%', [Host, Path])));
      Result := HTML_MOVEDPERMANENTLY;
      Exit;
    end;
  end;

  Asset := FAssets.Find(Path);
  if Asset = nil then
  begin
    PathLowerCased := LowerCase(Path);
    if PathLowerCased <> Path then
    begin
      Asset := FAssets.Find(PathLowerCased);
      if (Asset <> nil) and RedirectServerRootUriForExactCase then
      begin
        Host := FindHost(Context);
        if Host <> '' then
        begin
          AddCustomHeader(Context, 'Location', SockString(
            FormatUTF8('http%://%%',
              [HTTPS[Context.UseSSL], Host, PathLowerCased])));
          Result := HTML_MOVEDPERMANENTLY;
          Exit;
        end;
      end;
    end;
  end;

  if Asset <> nil then
  begin
    if not IsContentModified(Context, Asset, bpoEnableCacheByETag in LOptions,
      bpoEnableCacheByLastModified in LOptions) then
    begin
      Result := HTML_NOTMODIFIED;
      Exit;
    end;
    ContentType := ContentTypeWithoutCharset(Asset.ContentType);
    Context.OutContentType := Asset.ContentType;
    Context.OutContent := Asset.Content;
    Result := HTML_SUCCESS;
  end else begin
    Result := inherited Request(Context);
    ContentType := ContentTypeWithoutCharset(Context.OutContentType);
  end;

  if ((Result = HTML_BADREQUEST) and (bpoDelegateBadRequestTo404 in LOptions)) or
    ((Result = HTML_FORBIDDEN) and (bpoDelegateForbiddenTo404 in LOptions)) or
    ((Result = HTML_NOTFOUND) and (bpoDelegateNotFoundTo404 in LOptions)) or
    ((bpoDelegateBlocked in LOptions) and
      FastInArray(Ext, FFileTypesBlockedArray)) then
  begin
    if bpoDelegate404ToInherited_404 in LOptions then
    begin
      with Context do
        Prepare('/404', Method, InHeaders, InContent, InContentType);
      inherited Request(Context);
      ContentType := ContentTypeWithoutCharset(Context.OutContentType);
      Result := HTML_NOTFOUND;
    end else begin
      with Context do
        Prepare('/404.html', Method, InHeaders, InContent, InContentType);
      Asset := FAssets.Find('/404.html');
      if Asset <> nil then
      begin
        Ext := '.html';
        Context.OutContentType := Asset.ContentType;
        Context.OutContent := Asset.Content;
        ContentType := ContentTypeWithoutCharset(Asset.ContentType);
        Result := HTML_NOTFOUND;
      end;
    end;
  end;

  if bpoForceMIMEType in LOptions then
  begin
    ForcedContentType := FForceMIMETypesValues.Value(Ext, #0);
    if ForcedContentType <> #0 then
    begin
      ContentType := ContentTypeWithoutCharset(ForcedContentType);
      Context.OutContentType := ForcedContentType;
    end;
  end;

  GZippedContent := #0;

  if (bpoForceGZipHeader in LOptions) and
    FastInArray(Ext, FFileTypesForceGZipHeaderArray) then
      AddCustomHeader(Context, 'Content-Encoding', 'gzip');

  if (bpoEnableGZipByMIMETypes in LOptions) and
    IsGZipAccepted(Context, bpoFixMangledAcceptEncoding in LOptions) and
      FastInArray(ContentType, FGZippedMIMETypesArray) then
      begin
        GZippedContent := FGZippedAssets.Value(Path, #0);
        if GZippedContent <> #0 then
        begin
          AddCustomHeader(Context, 'Content-Encoding', 'gzip');
          Context.OutContent := GZippedContent;
        end
      end;

  if bpoForceTextUTF8Charset in LOptions then
  begin
    if Context.OutContentType = 'text/html' then
      Context.OutContentType := 'text/html; charset=UTF-8';
    if Context.OutContentType = 'text/plain' then
      Context.OutContentType := 'text/plain; charset=UTF-8';
  end;

  if (bpoForceUTF8Charset in LOptions) and
    FastInArray(Ext, FFileTypesRequiredCharSetValues) then
  begin
    if PosEx('charset', LowerCase(Context.OutContentType)) = 0 then
      Context.OutContentType := Context.OutContentType + '; charset=UTF-8';
  end;

  CORSEnabled := False;
  OriginExists := ExistsIniName(Pointer(Context.InHeaders), 'ORIGIN:');

  if bpoAllowCrossOrigin in LOptions then
  begin
    if OriginExists then
    begin
      AddCustomHeader(Context, 'Access-Control-Allow-Origin', '*');
      CORSEnabled := True;
    end;
  end;

  if not CORSEnabled and (bpoAllowCrossOriginImages in LOptions) then
  begin
    if OriginExists and FastInArray(Ext, FFileTypesImageArray) then
    begin
      AddCustomHeader(Context, 'Access-Control-Allow-Origin', '*');
      CORSEnabled := True;
    end;
  end;

  if not CORSEnabled and (bpoAllowCrossOriginFonts in LOptions) then
    if OriginExists and FastInArray(Ext, FFileTypesFontArray) then
      AddCustomHeader(Context, 'Access-Control-Allow-Origin', '*');

  if bpoAllowCrossOriginTiming in LOptions then
    AddCustomHeader(Context, 'Timing-Allow-Origin', '*');

  if (bpoSetXUACompatible in LOptions) and
    not FastInArray(Ext, FFileTypesAssetArray) then
      AddCustomHeader(Context, 'X-UA-Compatible', 'IE=edge');

  if bpoSetP3P in LOptions then
    AddCustomHeader(Context, 'P3P', 'policyref="/w3c/p3p.xml", CP="IDC ' +
      'DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"');

  if (bpoSetXFrameOptions in LOptions) and
    not FastInArray(Ext, FFileTypesAssetArray) then
      AddCustomHeader(Context, 'X-Frame-Options', 'DENY');

  if (ContentSecurityPolicy <> '') and
    not FastInArray(Ext, FFileTypesAssetArray) then
      AddCustomHeader(Context, 'Content-Security-Policy',
        ContentSecurityPolicy);

  if FStrictSSL = strictSSLOn then
    AddCustomHeader(Context, 'Strict-Transport-Security', 'max-age=16070400');

  if FStrictSSL = strictSSLIncludeSubDomains then
    AddCustomHeader(Context, 'Strict-Transport-Security',
      'max-age=16070400; includeSubDomains');

  if bpoPreventMIMESniffing in LOptions then
    AddCustomHeader(Context, 'X-Content-Type-Options', 'nosniff');

  if (bpoEnableXSSFilter in LOptions) and
    not FastInArray(Ext, FFileTypesAssetArray) then
      AddCustomHeader(Context, 'X-XSS-Protection', '1; mode=block');

  if bpoDeleteXPoweredBy in LOptions then
    DeleteCustomHeader(Context, 'X-POWERED-BY:');

  Expires := -1;

  if [bpoSetCacheNoTransform, bpoSetCachePublic, bpoSetCachePrivate,
    bpoSetCacheNoCache, bpoSetCacheNoStore, bpoSetCacheMustRevalidate,
    bpoSetCacheMaxAge] * LOptions <> [] then
  begin
    CacheControl := DeleteCustomHeader(Context, 'CACHE-CONTROL:');

    if bpoSetCacheNoTransform in LOptions then
      CacheControl := CacheControl + ', no-transform';

    if bpoSetCachePublic in LOptions then
      CacheControl := CacheControl + ', public';

    if bpoSetCachePrivate in LOptions then
      CacheControl := CacheControl + ', private';

    if bpoSetCacheNoCache in LOptions then
      CacheControl := CacheControl + ', no-cache';

    if bpoSetCacheNoStore in LOptions then
      CacheControl := CacheControl + ', no-store';

    if bpoSetCacheMustRevalidate in LOptions then
      CacheControl := CacheControl + ', must-revalidate';

    if bpoSetCacheMaxAge in LOptions then
    begin
      Expires := GetExpires(ContentType);
      CacheControl := CacheControl + FormatUTF8(', max-age=%', [Expires]);
    end;

    if CacheControl <> '' then
    begin
      if CacheControl[1] = ',' then
        CacheControl := Copy(CacheControl, 2, MaxInt);
      AddCustomHeader(Context, 'Cache-Control', TrimLeft(CacheControl));
    end;
  end;

  if bpoSetExpires in LOptions then
  begin
    if Expires = -1 then
      Expires := GetExpires(ContentType);
    AddCustomHeader(Context, 'Expires',
      DateTimeToHTTPDate(NowUTC + Expires / SecsPerDay));
  end;

  if bpoDeleteServerInternalState in LOptions then
    DeleteCustomHeader(Context, 'SERVER-INTERNALSTATE:');

  if FStaticRoot <> '' then
    SaveStaticAsset(Context, Asset, GZippedContent);

  if bpoVaryAcceptEncoding in LOptions then
  begin
    if FastInArray(ContentType, FGZippedMIMETypesArray) then
    begin
      Vary := DeleteCustomHeader(Context, 'VARY:');
      if Vary <> '' then
        Vary := Vary + ',Accept-Encoding'
      else
        Vary := 'Accept-Encoding';
      AddCustomHeader(Context, 'Vary', Vary);
    end;
  end;
end;

procedure TBoilerplateHTTPServer.SetExpires(const Value: RawUTF8);
var
  Index: Integer;
begin
  if FExpires <> Value then
  begin
    FExpires := Value;
    FExpiresValues.InitFromCSV(Pointer(Value));
    for Index := 0 to FExpiresValues.Count - 1 do
      with FExpiresValues.List[Index] do
        Tag := ExpiresToSecs(Value);

    Index := FExpiresValues.Find('*');
    if Index >= 0 then
      FExpiresDefault := FExpiresValues.List[Index].Tag
    else
      FExpiresDefault := 0;
  end;
end;

procedure TBoilerplateHTTPServer.ArrayFromCSV(out anArray: TRawUTF8DynArray;
  const CSV: RawUTF8; const Prefix: RawUTF8; const Sep: AnsiChar);
var
  Values: PUTF8Char;
  Value: RawUTF8;
  ArrayDA: TDynArray;
  ArrayCount: Integer;
  Index: Integer;
begin
  ArrayDA.Init(TypeInfo(TRawUTF8DynArray), anArray, @ArrayCount);
  Values := PUTF8Char(CSV);
  while Values <> nil do
  begin
    Value := GetNextItem(Values, Sep);
    if Value <> '' then
    begin
      Value := Prefix + LowerCase(Value);
      ArrayDA.Add(Value);
    end;
  end;
  ArrayDA.Sort(SortDynArrayPUTF8Char);
  for Index := ArrayDA.Count - 1 downto 1 do
    if anArray[Index] = anArray[Index - 1] then
      ArrayDA.Delete(Index);
  SetLength(anArray, ArrayDA.Count);
end;

procedure TBoilerplateHTTPServer.SetFileTypesAsset(const Value: RawUTF8);
begin
  if FFileTypesAsset <> Value then
  begin
    FFileTypesAsset := Value;
    ArrayFromCSV(FFileTypesAssetArray, Value);
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesBlocked(const Value: RawUTF8);
begin
  if FFileTypesBlocked <> Value then
  begin
    FFileTypesBlocked := Value;
    ArrayFromCSV(FFileTypesBlockedArray, Value);
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesFont(const Value: RawUTF8);
begin
  if FFileTypesFont <> Value then
  begin
    FFileTypesFont := Value;
    ArrayFromCSV(FFileTypesFontArray, Value);
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesForceGZipHeader(
  const Value: RawUTF8);
begin
  if FFileTypesForceGZipHeader <> Value then
  begin
    FFileTypesForceGZipHeader := Value;
    ArrayFromCSV(FFileTypesForceGZipHeaderArray, Value);
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesImage(const Value: RawUTF8);
begin
  if FFileTypesImage <> Value then
  begin
    FFileTypesImage := Value;
    ArrayFromCSV(FFileTypesImageArray, Value);
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesRequiredCharSet(
  const Value: RawUTF8);
begin
  if FFileTypesRequiredCharSet <> Value then
  begin
    FFileTypesRequiredCharSet := Value;
    ArrayFromCSV(FFileTypesRequiredCharSetValues, Value);
  end;
end;

procedure TBoilerplateHTTPServer.SetForceMIMETypes(const Value: RawUTF8);
begin
  if FForceMIMETypes <> Value then
  begin
    FForceMIMETypes := Value;
    FForceMIMETypesValues.InitFromCSV(Pointer(FForceMIMETypes));
  end;
end;

procedure TBoilerplateHTTPServer.SetGZipLevel(const Value: TGZipLevel);
begin
  if FGZipLevel <> Value then
  begin
    FGZipLevel := Value;
    CreateGZippedAssets;
  end;
end;

procedure TBoilerplateHTTPServer.SetGZippedMIMETypes(const Value: RawUTF8);
begin
  if FGZippedMIMETypes <> Value then
  begin
    FGZippedMIMETypes := Value;
    ArrayFromCSV(FGZippedMIMETypesArray, Value, '');
  end;
end;

procedure TBoilerplateHTTPServer.SetMangledEncodingHeaders(
  const Value: RawUTF8);
var
  Index: Integer;
begin
  if FMangledEncodingHeaders <> Value then
  begin
    FMangledEncodingHeaders := Value;
    ArrayFromCSV(FMangledEncodingHeadersArray, Value, '');
    for Index := Low(FMangledEncodingHeadersArray) to
      High(FMangledEncodingHeadersArray) do
        FMangledEncodingHeadersArray[Index] :=
          UpperCase(FMangledEncodingHeadersArray[Index]) + ': ';
  end;
end;

procedure TBoilerplateHTTPServer.SetMangledEncodingHeaderValues(
  const Value: RawUTF8);
begin
  if FMangledEncodingHeaderValues <> Value then
  begin
    FMangledEncodingHeaderValues := Value;
    ArrayFromCSV(FMangledEncodingHeaderValuesArray, Value, '', '|');
  end;
end;

procedure TBoilerplateHTTPServer.SplitURL(const URL: SockString;
  out Path, Ext: SockString; const EnableCacheBusting: Boolean);
var
  Index: Integer;
  P: PAnsiChar;
  ExtPos, QueryPos: Integer;
begin
  if URL = '' then
  begin
    Path := '';
    Ext := '';
    Exit;
  end;

  ExtPos := 0;
  QueryPos := 0;
  Index := 1;
  P := @URL[1];
  while P^ <> #0 do
  begin
    if (P^ = '.') and (QueryPos = 0) then
      ExtPos := Index;
    if (P^ = '?') and (QueryPos = 0) then
    begin
      QueryPos := Index;
      Break;
    end;
    Inc(Index);
    Inc(P);
  end;

  if EnableCacheBusting and (QueryPos > 0) then
    SetString(Path, PAnsiChar(URL), QueryPos - 1)
  else
    Path := URL;

  if ExtPos > 0 then
  begin
    if QueryPos > 0 then
      SetString(Ext, PAnsiChar(@URL[ExtPos]), QueryPos - ExtPos + 1)
    else
      SetString(Ext, PAnsiChar(@URL[ExtPos]), Length(URL) - ExtPos + 1);

    for Index := 0 to Length(Ext) - 1 do
      if PByteArray(Ext)[Index] in [Ord('A')..Ord('Z')] then
        Inc(PByteArray(Ext)[Index], 32);
  end else
    Ext := '';
end;

procedure TBoilerplateHTTPServer.UnregisterCustomOptions(const URL: RawUTF8);
begin
  FCustomOptions.Delete(URL);
end;

procedure TBoilerplateHTTPServer.SaveStaticAsset(
  const Context: THttpServerRequest; const Asset: PAsset;
  const GZippedContent: RawByteString);
var
  Index: Integer;
  FileName: TFileName;
  LCreated, LModified: TDateTime;
  FileNotModified: Boolean;
begin
  if Asset = nil then Exit;
  if FStaticRoot = '' then Exit;

  FileName := UTF8ToString(Asset.Path);
  if PathDelim <> '/' then
    for Index := 1 to Length(FileName) do
      if FileName[Index] = '/' then
        FileName[Index] := PathDelim;

  AddCustomHeader(Context, 'Content-Type', Context.OutContentType);
  Context.OutContentType := HTTP_RESP_STATICFILE;

  if GZippedContent = #0 then begin
    FileName := IncludeTrailingPathDelimiter(FStaticRoot) +
      'cache.plain' + FileName;
    Asset.SaveToFile(FileName);
  end else begin
    FileName := Format('%scache.gz%s.%d.gz', [
      IncludeTrailingPathDelimiter(FStaticRoot), FileName, Integer(GZipLevel)]);

    FileNotModified := False;
    if FileExists(FileName) and
      GetFileInfo(FileName, @LCreated, @LModified, nil) then
        FileNotModified := (LCreated = Asset.Created) and
          (LModified = Asset.Modified);

    if not FileNotModified then
    begin
      CreateDirectories(FileName);
      FileFromString(GZippedContent, FileName);
      SetFileTime(FileName, Asset.Created, Asset.Modified);
    end;
  end;

  Context.OutContent := SockString(FileName);
end;

end.
