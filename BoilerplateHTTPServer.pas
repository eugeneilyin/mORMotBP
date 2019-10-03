/// HTML5 Boilerplate integration with Synopse mORMot Framework
// Licensed under The MIT License (MIT)
unit BoilerplateHTTPServer;

(*
  This file is a path of integration project between HTML5 Boilerplate and
  Synopse mORMot Framework.

    https://synopse.info
    https://html5boilerplate.com

  Boilerplate HTTP Server
  (c) 2016-Present Yevgeny Iliyn

  https://github.com/eugeneilyin/mORMotBP

  Version 1.0
  - First public release

  Version 1.1
  - minor "Cache-Control" parameters order changes
  - added bpoDelegateIndexToInheritedDefault to delegate index.html to Default()
  - added bpoDelegate404ToInherited_404 to delegate 404.html to _404()

  Version 1.2
  - fix "Accept-Encoding" parsing when gzip in the end of encodings list
  - make Pre-Build events notice more visible in tests and demo
  - minor code refactoring

  Version 1.3
  - fix bug in packassets tool when asset name started with '.'

  Version 1.4
  - make TAsset to be packed record for better x86/x64 platforms compatibility

  Version 1.5
  - fix EnableCacheByETag test scenarios

  Version 1.6
  - add custom options registration
  - add Vary header into http response for compressible resources

  Version 1.7
  - add custom options registration for group of URLs

  Version 1.8
  - support redirections in /404 response
  - changed HTML_* to HTTP_* constants following the mORMot refactoring
  - support new HTTP context initialization spec

  Version 1.8.1
  - RegisterCustomOptions now supports URLs prefixes

  Version 2.0
  - Align all boilerplate assets to recent HTML 5 Boilerplate 7.2.0
  - All Delphi compilers support started from Delphi 6
    (special BuildEvents IDE extenstion provided for old Delphi 6/7/2005/2006)
  - Free Pascal support
    (for Lazarus IDE pre-build.sh scipt provided to compress and embed static
    assets over "Run / Build File" IDE option)
  - Kylix 3 support (over CrossKilyx)
  - Zopfli compression support for static assets
    (save up to 5-15% of traffic and delivery time compared to max GZip Level)
  - Brotli compression support for static assets as per RFC 7932
    (save another 15%-25% of traffic and delivery time compared to Zopfli)
  - All assets compressions (GZip/Zopfli, and Brotli) now precomputed and
    embedded, so you save your CPU cycles by skipping any static assets
    compression on production
  - Add additional cache bursting strategy. See bpoEnableCacheBustingBeforeExt
  - Following RFC 7946 the GeoJSON applications now
    use application/geo+json MIME type
  - MIME Type for RDF XML documents now application/rdf+xml
    following as per RFC 3870
  - Add support of .mjs files with EcmaScript modules
    (or JavaScript modules) MIME types
  - Add web assembly (.wasm) MIME type support
  - Woff fonts (.woff) now have updated font/woff MIME type
  - Woff version 2 fonts (.woff2) now have updated font/woff2 MIME type
  - True Type collection .ttc fonts now have separate font/collection MIME type
  - TTF fonts (.ttf) now have separate font/ttf MIME type
  - OTF fonts (.otf) now have separate font/otf MIME type
  - Add support for .ics (text/calendar), and .markdown, .md (text/markdown)
    MIME types
  - Upgrade the required 'charset=UTF-8' MIME type list
  - Upgrade Content Sequrity Policy (CSP)
  - New bpoEnableReferrerPolicy options
  - The GZippedMimeTypes has been removed
    (just pack your assets with updated assetslz tool)
  - Deprecation of Iframes cookies support in Internet Explorer
  - TAssets.SaveAssets remove regexp for assets matching
    (this excludes dependency over SynTable.pas)

  Version 2.1
  - bpoVaryAcceptEncoding now supports content created by the inherited class
  - bpoDeleteXPoweredBy was excluded from DEFAULT_BOILERPLATE_OPTIONS

*)

interface

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

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
    // https://enable-cors.org/
    // https://www.w3.org/TR/cors/
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
    // https://developers.google.com/fonts/docs/troubleshooting
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
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin
    // https://www.w3.org/TR/resource-timing/
    // https://www.stevesouders.com/blog/2014/08/21/resource-timing-practical-tips/
    bpoAllowCrossOriginTiming,

    /// Custom error messages/pages
    // Customize what server returns to the client in case of an error.

    // Set content for HTTP 400 Bad Request response code equal '/404' content
    bpoDelegateBadRequestTo404,

    // Set content for HTTP 403 Forbidden response code to '/404' content
    bpoDelegateForbiddenTo404,

    // Set content for HTTP 404 Not Found response code to '/404' content
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
    // https://blogs.msdn.microsoft.com/ie/2014/04/02/stay-up-to-date-with-enterprise-mode-for-internet-explorer-11/
    // https://msdn.microsoft.com/en-us/library/ff955275.aspx
    bpoSetXUACompatible,

    /// Media types
    // Serve resources with the proper media types (f.k.a. MIME types).
    //
    // https://www.iana.org/assignments/media-types/media-types.xhtml
    // - Use TBoilerplateOption.ForceMIMETypes to set MIME types
    bpoForceMIMEType,

    /// Serve the following file types with the media type `charset`
    // parameter set to `UTF-8`.
    // - Use TBoilerplateHTTPServer.FileTypesRequiredCharSet to setup file types
    bpoForceUTF8Charset,

    /// Character encodings
    // Serve all resources labeled as `text/html` or `text/plain`
    // with the media type `charset` parameter set to `UTF-8`.
    bpoForceTextUTF8Charset,

    /// Forcing `https://`
    //
    // Redirect from the `http://` to the `https://` version of the URL.
    bpoForceHTTPS,

    // If you're using cPanel AutoSSL or the Let's Encrypt webroot
    // method it will fail to validate the certificate if validation
    // requests are redirected to HTTPS. Turn on the condition(s)
    // you need.
    //
    // https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml
    // https://tools.ietf.org/html/draft-ietf-acme-acme-12
    //
    // /.well-known/acme-challenge/
    // /.well-known/cpanel-dcv/[\w-]+$
    // /.well-known/pki-validation/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
    //
    // The simplified locations are used:
    //
    // /.well-known/acme-challenge/*
    // /.well-known/cpanel-dcv/*
    // /.well-known/pki-validation/*
    bpoForceHTTPSExceptLetsEncrypt,

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
    // for all of your websites pages, this has the potential downside that
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
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
    // https://tools.ietf.org/html/rfc7034
    // https://blogs.msdn.microsoft.com/ieinternals/2010/03/30/combating-clickjacking-with-x-frame-options/
    // https://www.owasp.org/index.php/Clickjacking
    bpoSetXFrameOptions,

    /// Block access to files that can expose sensitive information.
    //
    // By default, block access to backup and source files that may be
    // left by some text editors and can pose a security risk when anyone
    // has access to them.
    //
    // https://feross.org/cmsploit/
    //
    // (!) Update TBoilerplateHTTPServer.FileTypesBlocked property to
    // include any files that might end up on your production server and
    // can expose sensitive information about your website. These files may
    // include: configuration files, files that contain metadata about the
    // project (e.g.: project dependencies), build scripts, etc..
    //
    // - Use TBoilerplateHTTPServer.FileTypesBlocked to specify file types
    // - This option also blocks any URL path ended with '~' or '#'
    bpoDelegateBlocked,

    /// Reducing MIME type security risks
    // Prevent some browsers from MIME-sniffing the response.
    //
    // This reduces exposure to drive-by download attacks and cross-origin
    // data leaks, and should be left uncommented, especially if the server
    // is serving user-uploaded content or content that could potentially be
    // treated as executable by the browser.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options
    // https://blogs.msdn.microsoft.com/ie/2008/07/02/ie8-security-part-v-comprehensive-protection/
    // https://mimesniff.spec.whatwg.org/
    bpoPreventMIMESniffing,

    /// Reflected Cross-Site Scripting (XSS) attacks
    // The filter is usually enabled by default, but in some cases it
    // may be disabled by the user. However, in Internet Explorer for
    // example, it can be re-enabled just by sending the
    // `X-XSS-Protection` header with the value of `1`.
    //
    // Prevent web browsers from rendering the web page if a potential
    // reflected (a.k.a non-persistent) XSS attack is detected by the
    // filter.
    //
    // By default, if the filter is enabled and browsers detect a
    // reflected XSS attack, they will attempt to block the attack
    // by making the smallest possible modifications to the returned
    // web page.
    //
    // Unfortunately, in some browsers (e.g.: Internet Explorer),
    // this default behavior may allow the XSS filter to be exploited,
    // thereby, it's better to inform browsers to prevent the rendering
    // of the page altogether, instead of attempting to modify it.
    //
    // https://hackademix.net/2009/11/21/ies-xss-filter-creates-xss-vulnerabilities
    //
    // (!) Do not rely on the XSS filter to prevent XSS attacks! Ensure that
    //     you are taking all possible measures to prevent XSS attacks, the
    //     most obvious being: validating and sanitizing your website's inputs.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection
    // https://blogs.msdn.microsoft.com/ie/2008/07/02/ie8-security-part-iv-the-xss-filter/
    // https://blogs.msdn.microsoft.com/ieinternals/2011/01/31/controlling-the-xss-filter/
    // https://www.owasp.org/index.php/Cross-site_Scripting_%28XSS%29
    //
    // - Use TBoilerplateHTTPServer.FileTypesAsset to exclude some file types
    bpoEnableXSSFilter,

    /// Referrer Policy
    //
    // A web application uses HTTPS and a URL-based session identifier.
    // The web application might wish to link to HTTPS resources on other
    // web sites without leaking the user's session identifier in the URL.
    //
    // This can be done by setting a `Referrer Policy` which
    // whitelists trusted sources of content for your website.
    //
    // To check your referrer policy, you can use an online service
    // such as: https://securityheaders.io/.
    //
    // https://scotthelme.co.uk/a-new-security-header-referrer-policy/
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy
    bpoEnableReferrerPolicy,

    /// Remove the `X-Powered-By` response header that:
    // Better add NOXPOWEREDNAME into Conditional Defines in the Project Options
    //
    //  * is set by some frameworks and server-side languages
    //    (e.g.: ASP.NET, PHP), and its value contains information
    //    about them (e.g.: their name, version number)
    //
    //  * doesn't provide any value to users, contributes to header
    //    bloat, and in some cases, the information it provides can
    //    expose vulnerabilities
    //
    // (!) If you can, you should disable the `X-Powered-By` header from the
    // language / framework level (e.g.: for PHP, you can do that by setting
    // `expose_php = off` in `php.ini`)
    //
    // https://php.net/manual/en/ini.core.php#ini.expose-php
    bpoDeleteXPoweredBy,

    /// Force compression for mangled `Accept-Encoding` request headers
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding
    // https://calendar.perfplanet.com/2010/pushing-beyond-gzipping/
    //
    // - Use TBoilerplateHTTPServer.MangledEncodingHeaders
    // - Use TBoilerplateHTTPServer.MangledEncodingHeaderValues
    bpoFixMangledAcceptEncoding,

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
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding
    //
    // - Use TBoilerplateHTTPServer.FileTypesForceGZipHeader to setup file types
    bpoForceGZipHeader,

    /// Allow static assets to be cached by proxy servers
    bpoSetCachePublic,

    /// Allow static assets to be cached only by browser, but not by intermediate proxy servers
    bpoSetCachePrivate,

    /// Content transformation
    // Prevent intermediate caches or proxies (e.g.: such as the ones
    // used by mobile network providers) from modifying the website's
    // content.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
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
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag
    // https://developer.yahoo.com/performance/rules.html#etags
    // https://tools.ietf.org/html/rfc7232#section-2.3
    bpoEnableCacheByETag,

    // Use Last-Modified/If-Modified-Since caching
    // https://developer.yahoo.com/performance/rules.html#etags
    // https://tools.ietf.org/html/rfc7232#section-2.3
    bpoEnableCacheByLastModified,

    /// Cache expiration
    // Serve resources with far-future expiration date.
    //
    // (!) If you don't control versioning with filename-based
    // cache busting, you should consider lowering the cache times
    // to something like one week.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires
    //
    // - TBoilerplateHTTPServer.Expires
    bpoSetExpires,

    ///Filename-based cache busting
    //
    // Removes all query path of the URL `/style.css?v231` to `/style.css`
    bpoEnableCacheBusting,

    ///Filename-based cache busting
    //
    // If you're not using a build process to manage your filename version
    // revving, you might want to consider enabling the following directives
    // to route all requests such as `/style.12345.css` to `/style.css`.
    //
    // To understand why this is important and even a better solution than
    // using something like `*.css?v231`, please see:
    // https://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/
    bpoEnableCacheBustingBeforeExt,

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

    /// Add 'Vary: Accept-Encoding' header for assets with GZip/Brotli encoding
    bpoVaryAcceptEncoding
  );

  TBoilerplateOptions = set of TBoilerplateOption;

  // (!) NEVER USE BOTH WWW-RELATED RULES AT THE SAME TIME!
  //
  // The same content should never be available under two different
  // URLs, especially not with and without `www.` at the beginning.
  // This can cause SEO problems (duplicate content), and therefore,
  // you should choose one of the alternatives and redirect the other
  // one.
  //
  // wwwSuppress:
  //   Suppressing the `www.` at the beginning of URLs
  //   Rewrite www.example.com --> example.com
  //
  // wwwForce:
  //   Forcing the `www.` at the beginning of URLs
  //   Rewrite example.com --> www.example.com
  //   Be aware that wwwForce might not be a good idea if you use "real"
  //   subdomains for certain parts of your website.
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
  // (!) Be aware that this, once published, is not revokable and you must ensure
  // being able to serve the site via SSL for the duration you've specified
  // in max-age. When you don't have a valid SSL connection (anymore) your
  // visitors will see a nasty error message even when attempting to connect
  // via simple HTTP.
  //
  // (!) Do not use strictSSLIncludeSubDomains if the website's subdomains
  // are not using HTTPS (e.g. http://static.domain.com).
  //
  // (1) If you want to submit your site for HSTS preload (2) you must
  //     * ensure the `includeSubDomains` directive to be present
  //     * the `preload` directive to be specified
  //     * the `max-age` to be at least 31536000 seconds (1 year) according to the current status.
  //
  //     It is also advised (3) to only serve the HSTS header via a secure connection
  //     which can be done with either `env=https` or `"expr=%{HTTPS} == 'on'"` (4). The
  //     exact way depends on your environment and might just be tried.
  //
  // (2) https://hstspreload.org/
  // (3) https://tools.ietf.org/html/rfc6797#section-7.2
  // (4) https://stackoverflow.com/questions/24144552/how-to-set-hsts-header-from-htaccess-only-on-https/24145033#comment81632711_24145033
  //
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security
  // https://tools.ietf.org/html/rfc6797#section-6.1
  // https://www.html5rocks.com/en/tutorials/security/transport-layer-security/
  // https://blogs.msdn.microsoft.com/ieinternals/2014/08/18/strict-transport-security/
  TStrictSSL = (strictSSLOff, strictSSLOn, strictSSLIncludeSubDomains);

type

  /// TBoilerplateHTTPServer
  TBoilerplateHTTPServer = class(TSQLHttpServer)
  protected
    FAssets: TAssets;
    FOptions: TBoilerplateOptions;
    FContentSecurityPolicy: SockString;
    FStrictSSL: TStrictSSL;
    FReferrerPolicy: SockString;
    FWWWRewrite: TWWWRewrite;
    FFileTypesImage: RawUTF8;
    FFileTypesImageArray: TRawUTF8DynArray;
    FFileTypesFont: RawUTF8;
    FFileTypesFontArray: TRawUTF8DynArray;
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
    FFileTypesForceGZipHeader: RawUTF8;
    FFileTypesForceGZipHeaderArray: TRawUTF8DynArray;
    FExpires: RawUTF8;
    FExpiresDefault: PtrInt;
    FExpiresValues: TSynNameValue;
    FStaticRoot: TFileName;
    FCustomOptions: TSynNameValue;
    FCustomOptionPrefixes: TSynNameValue;

    /// Init assets and set properties default values
    procedure Init; virtual;

    /// Extract url path and file type
    // - Ext
    //   Extracted lowercased file type (e.g. '.css', or '.svg')
    // - EnableCacheBusting
    //   Removes '?' sign and all followed URL content. This is usefull for
    //   resources cache busting on client side for urls like '/bkg.jpg?v=1.2.3'
    //   See bpoEnableCacheBusting
    // - EnableCacheBustingBeforeExt
    //   Use more effective cache bust strategy to route all requests such
    //   as `/style.12345.css` to `/style.css`.
    //   See bpoEnableCacheBustingBeforeExt
    procedure SplitURL(const URL: SockString; out Path, Ext: SockString;
      const EnableCacheBusting, EnableCacheBustingBeforeExt: Boolean);
        {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Binary search of file type in sorted array with unique values
    function FastInArray(const Ext: SockString;
      const Exts: TRawUTF8DynArray): Boolean;

    /// Add HTTP header value to Context.OutHeaders
    procedure AddCustomHeader(Context: THttpServerRequest;
      const Header, Value: SockString); {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Remove HTTP header value from Context.OutHeaders
    function DeleteCustomHeader(Context: THttpServerRequest;
      const HeaderUp: SockString): SockString; {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Validate that HTTP client can accept GZip and Brotli content encodings
    procedure GetAcceptedEncodings(Context: THttpServerRequest;
      const FixMangled: Boolean; out GZipAccepted, BrotliAccepted: Boolean);
        {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Check ETag of Last-Modified values
    function WasModified(Context: THttpServerRequest; Asset: PAsset;
      const Encoding: TAssetEncoding;
      const CheckETag, CheckModified: Boolean): Boolean;

    /// Convert "text/html=1m", "image/x-icon=1w", etc. expires to seconds
    function ExpiresToSecs(const Value: RawUTF8): PtrInt;
      {$IFNDEF VER180}{$IFDEF HASINLINE}inline;{$ENDIF}{$ENDIF}

    /// Get number of seconds, when content will be expired
    function GetExpires(const ContentType: RawUTF8): PtrInt;
      {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Removes charset from content type
    function ContentTypeWithoutCharset(const ContentType: RawUTF8): RawUTF8;
      {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Find host for redirection rules. Returns '' if not found
    function FindHost(const Context: THttpServerRequest): SockString;
      {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Find custom options registered for specific URL by RegisterCustomOptions
    function FindCustomOptions(const URLPath: RawUTF8;
      const Default: TBoilerplateOptions): TBoilerplateOptions;
        {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetFileTypesImage(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetFileTypesFont(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetForceMIMETypes(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetFileTypesRequiredCharSet(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetFileTypesBlocked(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetMangledEncodingHeaders(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetMangledEncodingHeaderValues(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetFileTypesForceGZipHeader(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    procedure SetExpires(const Value: RawUTF8);
      {$IFDEF HASINLINE}inline;{$ENDIF}

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
    /// Load static assets from specific RT_RCDATA synzl-compressed resource
    procedure LoadFromResource(const ResName: string);
      {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Register custom Cache-Control options for specific URL
    // For example if you want to cache most of *.html pages with standart
    // Cache-Control options, but change this rule for
    // default page or login page.
    // For URL prefixes use asterisk char postfix, e.g. '/customer/*'
    procedure RegisterCustomOptions(const URLPath: RawUTF8;
      const CustomOptions: TBoilerplateOptions); overload;
        {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Register custom Cache-Control options for specific URL's
    // For example if you want cache most *.html pages with standart
    // Cache-Control options, but change this rule for default page or api calls
    // For URL prefixes use asterisk char postfix, e.g. '/customer/*'
    procedure RegisterCustomOptions(const URLParts: TRawUTF8DynArray;
      CustomOptions: TBoilerplateOptions); overload;
        {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Removes custom options usage for specific URL
    procedure UnregisterCustomOptions(const URLPath: RawUTF8); overload;
      {$IFDEF HASINLINE}inline;{$ENDIF}

    /// Removes custom options usage for specific URLs
    procedure UnregisterCustomOptions(
      const URLPaths: TRawUTF8DynArray); overload;
        {$IFDEF HASINLINE}inline;{$ENDIF}

    /// If this directory is not empty, all loaded static assets will be
    // pre-saved as files into this directory. To minimize disk IO operations
    // file modified timestamp and file size will be checked before saving.
    // The STATICFILE_CONTENT_TYPE will be used to inform the lower level API
    // to send the response as file content. All assets will be saved into
    // three different sub-directories 'identity' for plain unmodified assets,
    // 'gzip' for gzipped assets versions, 'brotli' for assets with brotli
    // compression.
    // See LoadFromResource method to preliminary load server static assets from
    // the embedded synlz-packed RC_RTDATA resource.
    property StaticRoot: TFileName read FStaticRoot write FStaticRoot;

    /// See TBoilerplateOptions
    property Options: TBoilerplateOptions read FOptions write FOptions;

    /// See TStrictSSL
    property StrictSSL: TStrictSSL read FStrictSSL write FStrictSSL;

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
    // There is no policy that fits all websites, you will have to modify
    // the `Content-Security-Policy` directives in the example below depending
    // on your needs.
    //
    // The example policy below aims to:
    //
    //  (1) default-src 'self'
    //      Restrict all fetches by default to the origin of the current website
    //      by setting the `default-src` directive to `'self'` - which acts as a
    //      fallback to all "Fetch directives" (https://developer.mozilla.org/en-US/docs/Glossary/Fetch_directive).
    //
    //      This is convenient as you do not have to specify all Fetch directives
    //      that apply to your site, for example:
    //      `connect-src 'self'; font-src 'self'; script-src 'self'; style-src 'self'`, etc.
    //
    //      This restriction also means that you must explicitly define from
    //      which site(s) your website is allowed to load resources from.
    //
    //  (2) base-uri 'none'
    //      The `<base>` element is not allowed on the website. This is to
    //      prevent attackers from changing the locations of resources loaded
    //      from relative URLs.
    //
    //      If you want to use the `<base>` element, then `base-uri 'self'`
    //      can be used instead.
    //
    //  (3) form-action 'self'
    //      Form submissions are only allowed from the current website by
    //      setting: `form-action 'self'`.
    //
    //  (4) frame-ancestors 'none'
    //      Prevents all websites (including your own) from embedding your
    //      webpages within e.g. the `<iframe>` or `<object>` element by
    //      setting `frame-ancestors 'none'`.
    //
    //      The `frame-ancestors` directive helps avoid "Clickjacking" attacks
    //      and is similar to the `X-Frame-Options` header.
    //
    //      Browsers that support the CSP header will ignore `X-Frame-Options`
    //      if `frame-ancestors` is also specified.
    //
    //  (5) upgrade-insecure-requests
    //      Forces the browser to treat all the resources that are served over
    //      HTTP as if they were loaded securely over HTTPS by setting the
    //      `upgrade-insecure-requests` directive.
    //      Please note that `upgrade-insecure-requests` does not ensure
    //      HTTPS for the top-level navigation. If you want to force the
    //      website itself to be loaded over HTTPS you must include the
    //      `Strict-Transport-Security` header.
    //
    // To make your CSP implementation easier, you can use an online CSP header
    // generator such as:
    // https://report-uri.com/home/generate/
    //
    // It is encouraged that you validate your CSP header using a CSP validator
    // such as:
    // https://csp-evaluator.withgoogle.com
    //
    // https://csp.withgoogle.com/docs/
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
    // https://www.html5rocks.com/en/tutorials/security/content-security-policy/
    // https://www.w3.org/TR/CSP/
    //
    // - Use FileTypesAsset property to exclude some file types
    property ContentSecurityPolicy: SockString
      read FContentSecurityPolicy write FContentSecurityPolicy;

    /// See TBoilerplateOption.bpoEnableReferrerPolicy
    property ReferrerPolicy: SockString read FReferrerPolicy
      write FReferrerPolicy;

    /// See TBoilerplateOption.bpoAllowCrossOriginImages
    property FileTypesImage: RawUTF8 read FFileTypesImage
      write SetFileTypesImage;

    /// See TBoilerplateOption.bpoAllowCrossOriginFonts
    property FileTypesFont: RawUTF8 read FFileTypesFont write SetFileTypesFont;

    /// See TBoilerplateOption.bpoForceMIMEType
    property ForceMIMETypes: RawUTF8 read FForceMIMETypes
      write SetForceMIMETypes;

    /// TBoilerplateOption.bpoForceUTF8Charset
    property FileTypesRequiredCharSet: RawUTF8 read FFileTypesRequiredCharSet
      write SetFileTypesRequiredCharSet;

    /// TBoilerplateOption.bpoForceGZipHeader
    property FileTypesForceGZipHeader: RawUTF8 read FFileTypesForceGZipHeader
      write SetFileTypesForceGZipHeader;

    /// TBoilerplateOption.bpoDelegateBlocked
    property FileTypesBlocked: RawUTF8 read FFileTypesBlocked
      write SetFileTypesBlocked;

    /// TBoilerplateOption.bpoFixMangledAcceptEncoding
    property MangledEncodingHeaders: RawUTF8 read FMangledEncodingHeaders
      write SetMangledEncodingHeaders;

    /// TBoilerplateOption.bpoFixMangledAcceptEncoding
    property MangledEncodingHeaderValues: RawUTF8
      read FMangledEncodingHeaderValues write SetMangledEncodingHeaderValues;

    /// TBoilerplateOption.bpoSetExpires
    property Expires: RawUTF8 read FExpires write SetExpires;
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
    bpoForceUTF8Charset,
    bpoForceTextUTF8Charset,
    bpoSetXFrameOptions,
    bpoDelegateBlocked,
    bpoPreventMIMESniffing,
    bpoEnableXSSFilter,
    bpoEnableReferrerPolicy,
    bpoFixMangledAcceptEncoding,
    bpoForceGZipHeader,
    bpoSetCachePublic,
    bpoSetCacheNoTransform,
    bpoSetCacheMaxAge,
    bpoEnableCacheByLastModified,
    bpoSetExpires,
    bpoEnableCacheBusting,
    bpoDelegateRootToIndex,
    bpoDeleteServerInternalState,
    bpoVaryAcceptEncoding];

  /// See TWWWRewrite
  DEFAULT_WWW_REWRITE: TWWWRewrite = wwwSuppress;

  /// See TStrictSSL
  DEFAULT_STRICT_SLL: TStrictSSL = strictSSLOff;

  /// See TBoilerplateHTTPServer.ContentSecurityPolicy
  DEFAULT_CONTENT_SECURITY_POLICY: SockString = '';

  CONTENT_SECURITY_POLICY_STRICT =
    'default-src ''self''; ' +
    'base-uri ''none''; ' +
    'form-action ''self''; ' +
    'frame-ancestors ''none''; ' +
    'upgrade-insecure-requests';

  /// See TBoilerplateHTTPServer.ReferrerPolicy
  DEFAULT_REFERRER_POLICY: SockString = 'no-referrer-when-downgrade';

  /// See TBoilerplateHTTPServer.FileTypesImage
  DEFAULT_FILE_TYPES_IMAGE =
    'bmp,cur,gif,ico,jpg,jpeg,png,svg,svgz,webp';

  /// See TBoilerplateHTTPServer.FileTypesFont
  DEFAULT_FILE_TYPES_FONT =
    'eot,otf,ttc,ttf,woff,woff2';

  /// See TBoilerplateHTTPServer.FileTypesRequiredCharSet
  DEFAULT_FILE_TYPES_REQUIRED_CHARSET =
    'appcache,bbaw,css,htc,ics,js,json,manifest,map,markdown,md,mjs,topojson,' +
    'vtt,vcard,vcf,webmanifest,xloc';

  /// See TBoilerplateHTTPServer.FileTypesForceGZipHeader
  DEFAULT_FILE_TYPES_FORCE_GZIP_HEADER = 'svgz';

  /// See TBoilerplateHTTPServer.FileTypesBlocked
  DEFAULT_FILE_TYPES_BLOCKED =
    'bak,conf,dist,fla,inc,ini,log,orig,psd,sh,sql,swo,swp';

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
    'application/geo+json=0s'#10 +
    'application/xml=0s'#10 +
    'text/calendar=0s'#10 +
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

    // Markdown
    'text/markdown=0s'#10 +

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

    // WebAssembly
    'application/wasm=1y'#10 +

    // Web fonts

    // Collection
    'font/collection=1m'#10 +

    // Embedded OpenType (EOT)
    'application/vnd.ms-fontobject=1m'#10 +
    'font/eot=1m'#10 +

    // OpenType
    'font/opentype=1m'#10 +
    'font/otf=1m'#10 +

    // TrueType
    'application/x-font-ttf=1m'#10 +
    'font/ttf=1m'#10 +

    // Web Open Font Format (WOFF) 1.0
    'application/font-woff=1m'#10 +
    'application/x-font-woff=1m'#10 +
    'font/woff=1m'#10 +

    // Web Open Font Format (WOFF) 2.0
    'application/font-woff2=1m'#10 +
    'application/woff2=1m'#10 +

    // Other
    'text/x-cross-domain-policy=1w'#10 +
    '';

implementation

// The time constants were introduced in Delphi 2009 and
// missed in Delphi 5/6/7/2005/2006/2007, or FPC
{$IF DEFINED(FPC) OR (CompilerVersion < 20)}
const
  HoursPerDay = 24;
  MinsPerHour = 60;
  SecsPerMin  = 60;
  MinsPerDay  = HoursPerDay * MinsPerHour;
  SecsPerDay  = MinsPerDay * SecsPerMin;
  SecsPerHour = SecsPerMin * MinsPerHour;
{$IFEND}

// This is copy from SynCrtSock.pas which is not available in interface secion
function GetHeaderValue(var headers: SockString; const upname: SockString;
  deleteInHeaders: boolean): SockString;
    {$IFDEF HASINLINE}inline;{$ENDIF}
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
        while true do // delete also ending #13#10
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
const
  SecsPerMonth = 2629746; // SecsPerDay * 365.2425 / 12
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
    'M', 'm': Scale := SecsPerMonth;
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

function TBoilerplateHTTPServer.FindCustomOptions(const URLPath: RawUTF8;
  const Default: TBoilerplateOptions): TBoilerplateOptions;
var
  Index: Integer;

  function FindPrefix(const Prefixes: TSynNameValue;
    const UpperURL: RawUTF8): Integer;
      {$IFDEF HASINLINE}inline;{$ENDIF}
  begin
    for Result := 0 to Prefixes.Count - 1 do
      if IdemPChar(Pointer(UpperURL), Pointer(Prefixes.List[Result].Name)) then
        Exit;
    Result := -1;
  end;

  function StrToOptions(const Str: RawUTF8): TBoilerplateOptions;
    {$IFDEF HASINLINE}inline;{$ENDIF}
  begin
    MoveFast(Str[1], Result, SizeOf(Result));
  end;

begin
  Index := FCustomOptions.Find(URLPath);
  if Index >= 0 then
  begin
    Result := StrToOptions(FCustomOptions.List[Index].Value);
    Exit;
  end;

  Index := FindPrefix(FCustomOptionPrefixes, UpperCase(URLPath));
  if Index >= 0 then
  begin
    Result := StrToOptions(FCustomOptionPrefixes.List[Index].Value);
    Exit;
  end;

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
  if Result <> '' then
  begin
    Index := PosEx(';', Result);
    if Index > 0 then
      Delete(Result, Index, MaxInt);
  end;
end;

constructor TBoilerplateHTTPServer.Create(aServer: TSQLRestServer;
  aDefinition: TSQLHttpServerDefinition);
begin
  inherited Create(aServer, aDefinition);
  Init;
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
  FOptions := DEFAULT_BOILERPLATE_OPTIONS;
  FContentSecurityPolicy := DEFAULT_CONTENT_SECURITY_POLICY;
  FStrictSSL := DEFAULT_STRICT_SLL;
  FReferrerPolicy := DEFAULT_REFERRER_POLICY;
  FWWWRewrite := DEFAULT_WWW_REWRITE;
  SetFileTypesImage(DEFAULT_FILE_TYPES_IMAGE);
  SetFileTypesFont(DEFAULT_FILE_TYPES_FONT);
  SetForceMIMETypes(MIME_CONTENT_TYPES);
  SetFileTypesRequiredCharSet(DEFAULT_FILE_TYPES_REQUIRED_CHARSET);
  SetFileTypesBlocked(DEFAULT_FILE_TYPES_BLOCKED);
  SetMangledEncodingHeaders(DEFAULT_MANGLED_ENCODING_HEADERS);
  SetMangledEncodingHeaderValues(DEFAULT_MANGLED_ENCODING_HEADER_VALUES);
  SetFileTypesForceGZipHeader(DEFAULT_FILE_TYPES_FORCE_GZIP_HEADER);
  SetExpires(DEFAULT_EXPIRES);
  FCustomOptions.Init(False);
  FCustomOptionPrefixes.Init(False);
end;

function TBoilerplateHTTPServer.WasModified(Context: THttpServerRequest;
  Asset: PAsset; const Encoding: TAssetEncoding;
  const CheckETag, CheckModified: Boolean): Boolean;
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
    FastSetString(ServerHash, PRawUTF8(SERVER_HASH), Length(SERVER_HASH));
    if Encoding = aeIdentity then
      BinToHexDisplay(@Asset.Hash,
        Pointer(@ServerHash[2]), SizeOf(Cardinal))
    else if Encoding = aeGZip then
      BinToHexDisplay(@Asset.GZipHash,
        Pointer(@ServerHash[2]), SizeOf(Cardinal))
    else if Encoding = aeBrotli then
      BinToHexDisplay(@Asset.BrotliHash,
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

procedure TBoilerplateHTTPServer.GetAcceptedEncodings(
  Context: THttpServerRequest; const FixMangled: Boolean;
  out GZipAccepted, BrotliAccepted: Boolean);
var
  AcceptEncoding: RawUTF8;
  Index: Integer;
begin
  AcceptEncoding := LowerCase(FindIniNameValue(
    Pointer(Context.InHeaders), 'ACCEPT-ENCODING:'));
  GZipAccepted := PosEx('gzip', AcceptEncoding) > 0;
  BrotliAccepted := PosEx('br', AcceptEncoding) > 0;

  if (GZipAccepted or BrotliAccepted) and not FixMangled then Exit;

  for Index := Low(FMangledEncodingHeadersArray) to
    High(FMangledEncodingHeadersArray) do
  begin
    AcceptEncoding := LowerCase(FindIniNameValue(
      Pointer(Context.InHeaders),
      PAnsiChar(FMangledEncodingHeadersArray[Index])));
    if AcceptEncoding <> '' then
    begin
      GZipAccepted := FastInArray(AcceptEncoding,
        FMangledEncodingHeaderValuesArray);
      if GZipAccepted then Exit;
    end;
  end;
end;

procedure TBoilerplateHTTPServer.LoadFromResource(const ResName: string);
begin
  FAssets.LoadFromResource(ResName);
end;

procedure TBoilerplateHTTPServer.RegisterCustomOptions(const URLPath: RawUTF8;
  const CustomOptions: TBoilerplateOptions);

  function GetOptionsValue(const CustomOptions: TBoilerplateOptions): RawUTF8;
    {$IFDEF HASINLINE}inline;{$ENDIF}
  begin
    SetLength(Result, SizeOf(CustomOptions));
    MoveFast(CustomOptions, Result[1], SizeOf(CustomOptions));
  end;

begin
  if Copy(URLPath, Length(URLPath), 1) = '*' then
    FCustomOptionPrefixes.Add(
      UpperCase(Copy(URLPath, 1, Length(URLPath) - 1)),
        GetOptionsValue(CustomOptions))
  else
    FCustomOptions.Add(URLPath, GetOptionsValue(CustomOptions));
end;

procedure TBoilerplateHTTPServer.RegisterCustomOptions(
  const URLParts: TRawUTF8DynArray; CustomOptions: TBoilerplateOptions);
var
  Index: Integer;
begin
  for Index := Low(URLParts) to High(URLParts) do
    RegisterCustomOptions(URLParts[Index], CustomOptions);
end;

function TBoilerplateHTTPServer.Request(Context: THttpServerRequest): Cardinal;
const
  HTTPS: array[Boolean] of SockString = ('', 's');
var
  Asset: PAsset;
  AssetEncoding: TAssetEncoding;
  AcceptedEncodingsDefined: Boolean;
  LOptions: TBoilerplateOptions;
  Path, PathLowerCased, Ext, Host: SockString;
  GZipAccepted, BrotliAccepted: Boolean;
  OriginExists, CORSEnabled: Boolean;
  ContentType, ForcedContentType, CacheControl: RawUTF8;
  Expires: PtrInt;
  ExpiresDefined: Boolean;
  Vary: RawUTF8;
begin
  SplitURL(Context.URL, Path, Ext, bpoEnableCacheBusting in FOptions,
    bpoEnableCacheBustingBeforeExt in FOptions);

  LOptions := FindCustomOptions(Path, FOptions);

  if (bpoForceHTTPS in LOptions) and not Context.UseSSL then
    if not (bpoForceHTTPSExceptLetsEncrypt in LOptions) or
      not (IdemPCharArray(Pointer(Path), [
        '/.WELL-KNOWN/ACME-CHALLENGE/',
        '/.WELL-KNOWN/CPANEL-DCV/',
        '/.WELL-KNOWN/PKI-VALIDATION/']) >= 0) then
    begin
      Host := FindHost(Context);
      if Host <> '' then
      begin
        AddCustomHeader(Context, 'Location', SockString(
          FormatUTF8('https://%%', [Host, Path])));
        Result := HTTP_MOVEDPERMANENTLY;
        Exit;
      end;
    end;

  if FWWWRewrite = wwwSuppress then
  begin
    Host := FindHost(Context);
    if (Host <> '') and IdemPChar(Pointer(Host), 'WWW.') then
    begin
      Delete(Host, 1, 4);
      AddCustomHeader(Context, 'Location', SockString(
        FormatUTF8('http%://%%', [HTTPS[Context.UseSSL], Host, Path])));
      Result := HTTP_MOVEDPERMANENTLY;
      Exit;
    end;
  end;

  if FWWWRewrite = wwwForce then
  begin
    Host := FindHost(Context);
    if (Host <> '') and not IdemPChar(Pointer(Host), 'WWW.') then
    begin
      Host := 'www.' + Host;
      AddCustomHeader(Context, 'Location', SockString(
        FormatUTF8('http%://%%', [HTTPS[Context.UseSSL], Host, Path])));
      Result := HTTP_MOVEDPERMANENTLY;
      Exit;
    end;
  end;

  if (bpoDelegateRootToIndex in LOptions) and
    ((Context.URL = '') or (Context.URL = '/')) then
    with Context do
      if bpoDelegateIndexToInheritedDefault in LOptions then
      begin
        Prepare('/Default', Method,
          InHeaders, InContent, InContentType, '', UseSSL);
        Path := '/Default';
      end else begin
        Prepare('/index.html', Method,
          InHeaders, InContent, InContentType, '', UseSSL);
        Path := '/index.html';
        Ext := '.html';
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
          Result := HTTP_MOVEDPERMANENTLY;
          Exit;
        end;
      end;
    end;
  end;

  GZipAccepted := False;
  BrotliAccepted := False;
  AssetEncoding := aeIdentity;
  AcceptedEncodingsDefined := False;

  if Asset = nil then
  begin
    Result := inherited Request(Context);
    ContentType := ContentTypeWithoutCharset(Context.OutContentType);
  end else begin
    GetAcceptedEncodings(Context, bpoFixMangledAcceptEncoding in LOptions,
      GZipAccepted, BrotliAccepted);
    AcceptedEncodingsDefined := True;

    if Asset.BrotliExists and BrotliAccepted then
      AssetEncoding := aeBrotli
    else if Asset.GZipExists and GZipAccepted then
      AssetEncoding := aeGZip;

    if not WasModified(Context, Asset, AssetEncoding,
      bpoEnableCacheByETag in LOptions,
      bpoEnableCacheByLastModified in LOptions) then
    begin
      Result := HTTP_NOTMODIFIED;
      Exit;
    end;

    ContentType := ContentTypeWithoutCharset(Asset.ContentType);
    Context.OutContentType := Asset.ContentType;

    if AssetEncoding = aeGZip then
    begin
      AddCustomHeader(Context, 'Content-Encoding', 'gzip');
      Context.OutContent := Asset.GZipEncoding;
    end else if AssetEncoding = aeBrotli then
    begin
      AddCustomHeader(Context, 'Content-Encoding', 'br');
      Context.OutContent := Asset.BrotliEncoding;
    end else
      Context.OutContent := Asset.Content;

    Result := HTTP_SUCCESS;
  end;

  if ((Result = HTTP_BADREQUEST) and (bpoDelegateBadRequestTo404 in LOptions)) or
    ((Result = HTTP_FORBIDDEN) and (bpoDelegateForbiddenTo404 in LOptions)) or
    ((Result = HTTP_NOTFOUND) and (bpoDelegateNotFoundTo404 in LOptions)) or
    ((bpoDelegateBlocked in LOptions) and
      (FastInArray(Ext, FFileTypesBlockedArray) or
      ((Path <> '') and (
         (Path[Length(Path)] = '~') or
         (Path[Length(Path)] = '#'))))) then
  begin
    if bpoDelegate404ToInherited_404 in LOptions then
    begin
      with Context do
        Prepare('/404', Method, InHeaders, InContent, InContentType, '',
          UseSSL);

      Result := inherited Request(Context);
      ContentType := ContentTypeWithoutCharset(Context.OutContentType);

      if Result = HTTP_SUCCESS then
        Result := HTTP_NOTFOUND;
    end else begin
      with Context do
        Prepare('/404.html', Method, InHeaders, InContent, InContentType, '',
          UseSSL);

      Asset := FAssets.Find('/404.html');
      if Asset <> nil then
      begin
        ContentType := ContentTypeWithoutCharset(Asset.ContentType);
        Context.OutContentType := Asset.ContentType;

        if not AcceptedEncodingsDefined then
          GetAcceptedEncodings(Context, bpoFixMangledAcceptEncoding in LOptions,
            GZipAccepted, BrotliAccepted);

        if Asset.BrotliExists and BrotliAccepted then
          AssetEncoding := aeBrotli
        else if Asset.GZipExists and GZipAccepted then
          AssetEncoding := aeGZip
        else
          AssetEncoding := aeIdentity;

        DeleteCustomHeader(Context, 'CONTENT-ENCODING:');
        if AssetEncoding = aeGZip then
        begin
          AddCustomHeader(Context, 'Content-Encoding', 'gzip');
          Context.OutContent := Asset.GZipEncoding;
        end else if AssetEncoding = aeBrotli then
        begin
          AddCustomHeader(Context, 'Content-Encoding', 'br');
          Context.OutContent := Asset.BrotliEncoding;
        end else
          Context.OutContent := Asset.Content;

        Result := HTTP_NOTFOUND;
        Ext := '.html';
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

  if (bpoForceGZipHeader in LOptions) and (AssetEncoding = aeIdentity) and
    FastInArray(Ext, FFileTypesForceGZipHeaderArray) then
      AddCustomHeader(Context, 'Content-Encoding', 'gzip');

  if (bpoForceUTF8Charset in LOptions) and
    FastInArray(Ext, FFileTypesRequiredCharSetValues) then
  begin
    if PosEx('charset', LowerCase(Context.OutContentType)) = 0 then
      Context.OutContentType := Context.OutContentType + '; charset=UTF-8';
  end;

  if bpoForceTextUTF8Charset in LOptions then
  begin
    if Context.OutContentType = 'text/html' then
      Context.OutContentType := 'text/html; charset=UTF-8';
    if Context.OutContentType = 'text/plain' then
      Context.OutContentType := 'text/plain; charset=UTF-8';
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
    IdemPChar(Pointer(ContentType), 'TEXT/HTML') then
      AddCustomHeader(Context, 'X-UA-Compatible', 'IE=edge');

  if (bpoSetXFrameOptions in LOptions) and
    IdemPChar(Pointer(ContentType), 'TEXT/HTML') then
      AddCustomHeader(Context, 'X-Frame-Options', 'DENY');

  if (FContentSecurityPolicy <> '') and
    IdemPChar(Pointer(ContentType), 'TEXT/HTML') then
      AddCustomHeader(Context, 'Content-Security-Policy',
        FContentSecurityPolicy);

  if FStrictSSL = strictSSLOn then
    if Context.UseSSL then
      AddCustomHeader(Context, 'Strict-Transport-Security',
        'max-age=31536000')
    else
      AddCustomHeader(Context, 'Strict-Transport-Security',
        'max-age=16070400')
  else if FStrictSSL = strictSSLIncludeSubDomains then
    if Context.UseSSL then
      AddCustomHeader(Context, 'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains; preload')
    else
      AddCustomHeader(Context, 'Strict-Transport-Security',
        'max-age=16070400; includeSubDomains');

  if bpoPreventMIMESniffing in LOptions then
    AddCustomHeader(Context, 'X-Content-Type-Options', 'nosniff');

  if (bpoEnableXSSFilter in LOptions) and
    IdemPChar(Pointer(ContentType), 'TEXT/HTML') then
      AddCustomHeader(Context, 'X-XSS-Protection', '1; mode=block');

  if (bpoEnableReferrerPolicy in LOptions) and
    IdemPChar(Pointer(ContentType), 'TEXT/HTML') then
      AddCustomHeader(Context, 'Referrer-Policy', FReferrerPolicy);

  if bpoDeleteXPoweredBy in LOptions then
    DeleteCustomHeader(Context, 'X-POWERED-BY:');

  ExpiresDefined := False;

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
      ExpiresDefined := True;
      CacheControl := CacheControl + FormatUTF8(', max-age=%', [Expires]);
    end;

    if CacheControl <> '' then
    begin
      if (CacheControl[1] = ',') and (CacheControl[2] = ' ') then
        CacheControl := Copy(CacheControl, 3, MaxInt);
      AddCustomHeader(Context, 'Cache-Control', CacheControl);
    end;
  end;

  if bpoSetExpires in LOptions then
  begin
    if not ExpiresDefined then
      Expires := GetExpires(ContentType);
    AddCustomHeader(Context, 'Expires',
      DateTimeToHTTPDate(NowUTC + Expires / SecsPerDay));
  end;

  if bpoDeleteServerInternalState in LOptions then
    DeleteCustomHeader(Context, 'SERVER-INTERNALSTATE:');

  if (bpoVaryAcceptEncoding in LOptions) and
    ((Asset = nil) or
     (Asset <> nil) and (Asset.GZipExists or Asset.BrotliExists)) then
  begin
    Vary := DeleteCustomHeader(Context, 'VARY:');
    if Vary <> '' then
      Vary := Vary + ',Accept-Encoding'
    else
      Vary := 'Accept-Encoding';
    AddCustomHeader(Context, 'Vary', Vary);
  end;

  if (Asset <> nil) and (FStaticRoot <> '') then
  begin
    AddCustomHeader(Context, 'Content-Type', Context.OutContentType);
    Context.OutContentType := HTTP_RESP_STATICFILE;
    Context.OutContent :=
      SockString(Asset.SaveToFile(FStaticRoot, AssetEncoding));
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
  out Path, Ext: SockString;
  const EnableCacheBusting, EnableCacheBustingBeforeExt: Boolean);
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
    if QueryPos = 0 then
      if (P^ = '/') then
        ExtPos := 0
      else if (P^ = '.') then
        ExtPos := Index
      else if (P^ = '?') or (P^ = '#') then
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

  if EnableCacheBustingBeforeExt and (ExtPos > 0) then
  begin
    P := @URL[ExtPos - 1];
    for Index := ExtPos - 1 downto 1 do
    begin
      if P^ = '.' then
      begin
        Delete(Path, Index, ExtPos - Index);
        Break;
      end;
      if P^ = '/' then Break;
      Dec(P);
    end;
  end;
end;

procedure TBoilerplateHTTPServer.UnregisterCustomOptions(
  const URLPath: RawUTF8);
begin
  if Copy(URLPath, Length(URLPath), 1) = '*' then
    FCustomOptionPrefixes.Delete(
      UpperCase(Copy(URLPath, 1, Length(URLPath) - 1)))
  else
    FCustomOptions.Delete(URLPath);
end;

procedure TBoilerplateHTTPServer.UnregisterCustomOptions(
  const URLPaths: TRawUTF8DynArray);
var
  Index: Integer;
begin
  for Index := Low(URLPaths) to High(URLPaths) do
    UnregisterCustomOptions(URLPaths[Index]);
end;

end.
