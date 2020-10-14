/// HTML5 Boilerplate integration with Synopse mORMot Framework
// Licensed under The MIT License (MIT)
unit BoilerplateHTTPServer;

(*
  This unit is a path of integration project between HTML5 Boilerplate and
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

  Version 2.2
  - Add TBoilerplateHTTPServer.ContentSecurityPolicyReportOnly property

  Version 2.3
  - Upgrade options to Apache Server Configs v4.0.0
  - bpoDelegateUnauthorizedTo404 set content for HTTP 401 "Unauthorized"
    response code equals to '/404'
  - bpoDelegateNotAcceptableTo404 set content for HTTP 406 "Not Acceptable"
    response code equals to '/404'
  - bpoDelegateHidden block access to all hidden files and directories except
    for the visible content from within the "/.well-known/" hidden directory
  - bpoDisableTRACEMethod prevents TRACE requests being made via JavaScript
  - TStrictSSL supports strictSSLIncludeSubDomainsPreload
  - DNSPrefetchControl property to control DNS prefetching

*)

interface

{$I Synopse.inc} // define HASINLINE CPU32 CPU64

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
    //
    // Allow cross-origin requests.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
    // https://enable-cors.org/
    // https://www.w3.org/TR/cors/
    //
    // (!) Do not use this without understanding the consequences.
    //     This will permit access from any other website.
    //     Instead of using this file, consider using a specific rule such as
    //     allowing access based on (sub)domain: "subdomain.example.com"
    bpoAllowCrossOrigin,

    /// Cross-origin images
    //
    // Send the CORS header for images when browsers request it.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTML/CORS_enabled_image
    // https://blog.chromium.org/2011/07/using-cross-domain-images-in-webgl-and.html
    //
    // - Use TBoilerplateHTTPServer.FileTypesImage to specify file types
    bpoAllowCrossOriginImages,

    /// Cross-origin web fonts
    //
    // Allow cross-origin access to web fonts.
    //
    // https://developers.google.com/fonts/docs/troubleshooting
    //
    // - Use TBoilerplateHTTPServer.FileTypesFont to specify file types
    bpoAllowCrossOriginFonts,

    /// Cross-origin resource timing
    //
    // Allow cross-origin access to the timing information for all resources.
    //
    // If a resource isn't served with a `Timing-Allow-Origin` header that would
    // allow its timing information to be shared with the document, some of the
    // attributes of the `PerformanceResourceTiming` object will be set to zero.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin
    // https://www.w3.org/TR/resource-timing/
    // https://www.stevesouders.com/blog/2014/08/21/resource-timing-practical-tips/
    bpoAllowCrossOriginTiming,

    /// Custom error messages/pages
    // Customize what server returns to the client in case of an error.

    // Set content for HTTP 400 "Bad Request" response code equals to '/404'
    bpoDelegateBadRequestTo404,

    // Set content for HTTP 401 "Unauthorized" response code equals to '/404'
    bpoDelegateUnauthorizedTo404,

    // Set content for HTTP 403 "Forbidden" response code equals to '/404'
    bpoDelegateForbiddenTo404,

    // Set content for HTTP 404 "Not Found" response code equals to '/404'
    bpoDelegateNotFoundTo404,

    // Set content for HTTP 405 "Not Allowed" response code equals to '/404'
    bpoDelegateNotAllowedTo404,

    // Set content for HTTP 406 "Not Acceptable" response code equals to '/404'
    bpoDelegateNotAcceptableTo404,

    /// Internet Explorer Document modes
    //
    // Force Internet Explorer 8/9/10 to render pages in the highest mode
    // available in various cases when it may not.
    //
    // https://hsivonen.fi/doctype/#ie8
    //
    // (!) Starting with Internet Explorer 11, document modes are deprecated.
    //     If your business still relies on older web apps and services that were
    //     designed for older versions of Internet Explorer, you might want to
    //     consider enabling `Enterprise Mode` throughout your company.
    //
    // https://msdn.microsoft.com/en-us/library/ie/bg182625.aspx#docmode
    // https://blogs.msdn.microsoft.com/ie/2014/04/02/stay-up-to-date-with-enterprise-mode-for-internet-explorer-11/
    // https://msdn.microsoft.com/en-us/library/ff955275.aspx
    bpoSetXUACompatible,

    /// Media types
    //
    // Serve resources with the proper media types (f.k.a. MIME types).
    //
    // http://www.iana.org/assignments/media-types/
    // https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
    //
    // - Use TBoilerplateOption.ForceMIMETypes to set MIME types
    bpoForceMIMEType,

    /// Character encodings
    // Serve all resources labeled as `text/html` or `text/plain`
    // with the media type `charset` parameter set to `UTF-8`.
    bpoForceTextUTF8Charset,

    /// Serve the following file types with the media type `charset` parameter
    // set to `UTF-8`.
    //
    // - Use TBoilerplateHTTPServer.FileTypesRequiredCharSet to setup file types
    bpoForceUTF8Charset,

    /// Forcing `https://`
    //
    // Redirect from the `http://` to the `https://` version of the URL.
    bpoForceHTTPS,

    /// Forcing `https://`
    //
    // (1) If you're using cPanel AutoSSL or the Let's Encrypt webroot method it
    //     will fail to validate the certificate if validation requests are
    //     redirected to HTTPS. Turn on the condition(s) you need.
    //
    //     https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml
    //     https://tools.ietf.org/html/draft-ietf-acme-acme-12
    //
    //     /.well-known/acme-challenge/
    //     /.well-known/cpanel-dcv/[\w-]+$
    //     /.well-known/pki-validation/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
    //
    //     The next simplified patterns are used:
    //
    //       /.well-known/acme-challenge/*
    //       /.well-known/cpanel-dcv/*
    //       /.well-known/pki-validation/*
    bpoForceHTTPSExceptLetsEncrypt,

    /// Protect website against clickjacking.
    //
    // The example below sends the `X-Frame-Options` response header with the
    // value `DENY`, informing browsers not to display the content of the web
    // page in any frame.

    // This might not be the best setting for everyone. You should read about
    // the other two possible values the `X-Frame-Options` header field can
    // have: `SAMEORIGIN` and `ALLOW-FROM`.
    // https://tools.ietf.org/html/rfc7034#section-2.1.
    //
    // Keep in mind that while you could send the `X-Frame-Options` header for
    // all of your website's pages, this has the potential downside that it
    // forbids even non-malicious framing of your content (e.g.: when users
    // visit your website using a Google Image Search results page).
    //
    // Nonetheless, you should ensure that you send the `X-Frame-Options` header
    // for all pages that allow a user to make a state-changing operation
    // (e.g: pages that contain one-click purchase links, checkout or
    // bank-transfer confirmation pages, pages that make permanent configuration
    // changes, etc.).
    //
    // Sending the `X-Frame-Options` header can also protect your website
    // against more than just clickjacking attacks.
    // https://cure53.de/xfo-clickjacking.pdf.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
    // https://tools.ietf.org/html/rfc7034
    // https://blogs.msdn.microsoft.com/ieinternals/2010/03/30/combating-clickjacking-with-x-frame-options/
    // https://www.owasp.org/index.php/Clickjacking
    bpoSetXFrameOptions,

    /// Block access to all hidden files and directories except for the
    // visible content from within the `/.well-known/` hidden directory.
    //
    // These types of files usually contain user preferences or the preserved
    // state of a utility, and can include rather private places like, for
    // example, the `.git` or `.svn` directories.
    //
    // The `/.well-known/` directory represents the standard (RFC 5785) path
    // prefix for "well-known locations" (e.g.: `/.well-known/manifest.json`,
    // `/.well-known/keybase.txt`), and therefore, access to its visible content
    // should not be blocked.
    //
    // https://www.mnot.net/blog/2010/04/07/well-known
    // https://tools.ietf.org/html/rfc5785
    bpoDelegateHidden,

    /// Block access to files that can expose sensitive information.
    //
    // By default, block access to backup and source files that may be left by
    // some text editors and can pose a security risk when anyone has access to
    // them.
    //
    // https://feross.org/cmsploit/
    //
    // (!) Update TBoilerplateHTTPServer.FileTypesBlocked property to include
    //     any files that might end up on your production server and can expose
    //     sensitive information about your website. These files may include:
    //     configuration files, files that contain metadata about the project
    //     (e.g.: project dependencies, build scripts, etc.).
    //
    // - Use TBoilerplateHTTPServer.FileTypesBlocked to specify file types
    // - This option also blocks any URL paths ended with '~' or '#'
    bpoDelegateBlocked,

    // Content Type Options
    //
    // Prevent some browsers from MIME-sniffing the response.
    //
    // This reduces exposure to drive-by download attacks and cross-origin data
    // leaks, and should be left uncommented, especially if the server is
    // serving user-uploaded content or content that could potentially be
    // treated as executable by the browser.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options
    // https://blogs.msdn.microsoft.com/ie/2008/07/02/ie8-security-part-v-comprehensive-protection/
    // https://mimesniff.spec.whatwg.org/
    bpoPreventMIMESniffing,

    // Cross-Site Scripting (XSS) Protection
    //
    // Protect website reflected Cross-Site Scripting (XSS) attacks.
    //
    // (1) Try to re-enable the cross-site scripting (XSS) filter built into
    //     most web browsers.
    //
    //     The filter is usually enabled by default, but in some cases, it may
    //     be disabled by the user. However, in Internet Explorer, for example,
    //     it can be re-enabled just by sending the  `X-XSS-Protection` header
    //     with the value of `1`.
    //
    // (2) Prevent web browsers from rendering the web page if a potential
    //     reflected (a.k.a non-persistent) XSS attack is detected by the
    //     filter.
    //
    //     By default, if the filter is enabled and browsers detect a reflected
    //     XSS attack, they will attempt to block the attack by making the
    //     smallest possible modifications to the returned web page.
    //
    //     Unfortunately, in some browsers (e.g.: Internet Explorer), this
    //     default behavior may allow the XSS filter to be exploited. Therefore,
    //     it's better to inform browsers to prevent the rendering of the page
    //     altogether, instead of attempting to modify it.
    //
    //     https://hackademix.net/2009/11/21/ies-xss-filter-creates-xss-vulnerabilities
    //
    // (!) Do not rely on the XSS filter to prevent XSS attacks! Ensure that you
    //     are taking all possible measures to prevent XSS attacks, the most
    //     obvious being: validating and sanitizing your website's inputs.
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
    // Set a strict Referrer Policy to mitigate information leakage.
    //
    // (1) The `Referrer-Policy` header is included in responses for resources
    //     that are able to request (or navigate to) other resources.
    //
    //     This includes the commonly used resource types:
    //     HTML, CSS, XML/SVG, PDF documents, scripts and workers.
    //
    // To prevent referrer leakage entirely, specify the `no-referrer` value
    // instead. Note that the effect could impact analytics metrics negatively.
    //
    // To check your Referrer Policy, you can use an online service, such as:
    // https://securityheaders.com/
    // https://observatory.mozilla.org/
    //
    // https://scotthelme.co.uk/a-new-security-header-referrer-policy/
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy
    //
    // - Use TBoilerplateHTTPServer.ReferrerPolicy property
    // - Use TBoilerplateHTTPServer.ReferrerPolicyContentTypes property
    bpoEnableReferrerPolicy,

    /// Disable TRACE HTTP Method
    //
    // Prevent HTTP Server from responding to `TRACE` HTTP request.
    //
    // The TRACE method, while seemingly harmless, can be successfully leveraged
    // in some scenarios to steal legitimate users' credentials.
    //
    // Modern browsers now prevent TRACE requests being made via JavaScript,
    // however, other ways of sending TRACE requests with browsers have been
    // discovered, such as using Java.
    //
    // https://tools.ietf.org/html/rfc7231#section-4.3.8
    // https://www.owasp.org/index.php/Cross_Site_Tracing
    // https://www.owasp.org/index.php/Test_HTTP_Methods_(OTG-CONFIG-006)
    // https://httpd.apache.org/docs/current/mod/core.html#traceenable
    bpoDisableTRACEMethod,

    /// Server-side technology information
    //
    // Remove the `X-Powered-By` response header that:
    //
    // Better add Conditional Define: NOXPOWEREDNAME into the Project / Options
    //
    //  * is set by some frameworks and server-side languages (e.g.: ASP.NET, PHP),
    //    and its value contains information about them (e.g.: their name, version
    //    number)
    //
    //  * doesn't provide any value to users, contributes to header bloat, and in
    //    some cases, the information it provides can expose vulnerabilities
    //
    // (!) If you can, you should disable the `X-Powered-By` header from the
    //     language/framework level (e.g.: for PHP, you can do that by setting
    //     `expose_php = off` in `php.ini`).
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

    /// Map the following filename extensions to the specified encoding type in
    // order to make HTTP Server serve the file types with the appropriate
    // `Content-Encoding` response header (do note that this will NOT make
    // HTTP Server compress them!).
    //
    // If these files types would be served without an appropriate
    // `Content-Encoding` response header, client applications (e.g.: browsers)
    // wouldn't know that they first need to uncompress the response, and thus,
    // wouldn't be able to understand the content.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding
    // https://httpd.apache.org/docs/current/mod/mod_mime.html#addencoding
    //
    // - Use TBoilerplateHTTPServer.FileTypesForceGZipHeader to setup file types
    bpoForceGZipHeader,

    /// Allow static assets to be cached by proxy servers
    bpoSetCachePublic,

    /// Allow static assets to be cached only by browser, but not by intermediate proxy servers
    bpoSetCachePrivate,

    /// Content transformation                                             |
    //
    // Prevent intermediate caches or proxies (such as those used by mobile
    // network providers) and browsers data-saving features from modifying
    // the website's content using the `cache-control: no-transform` directive.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
    // https://tools.ietf.org/html/rfc7234#section-5.2.2.4
    //
    // (!) Carefully consider the impact on your visitors before disabling
    //     content transformation. These transformations are performed to
    //     improve the experience for data- and cost-constrained users
    //     (e.g. users on a 2G connection).
    //
    //     You can test the effects of content transformation applied by
    //     Google's Lite Mode by visiting:
    //     https://googleweblight.com/i?u=https://www.example.com
    //
    //     https://support.google.com/webmasters/answer/6211428
    //
    //     https://developers.google.com/speed/pagespeed/module/configuration#notransform
    bpoSetCacheNoTransform,

    /// Allow static assets to be validated with server before return cached copy
    bpoSetCacheNoCache,

    /// Allow static assets not to be cached
    bpoSetCacheNoStore,

    /// Allow static assets to be cached strictly following the server rules
    bpoSetCacheMustRevalidate,

    /// Add 'max-age' value based on content-type/expires mapping
    //
    // Serve resources with a far-future expiration date.
    //
    // (!) If you don't control versioning with filename-based cache busting, you
    //     should consider lowering the cache times to something like one week.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires
    //
    // - Use TBoilerplateHTTPServer.Expires options to control expirations
    bpoSetCacheMaxAge,

    // Use ETag / If-None-Match caching
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag
    // https://developer.yahoo.com/performance/rules.html#etags
    // https://tools.ietf.org/html/rfc7232#section-2.3
    bpoEnableCacheByETag,

    // Use Last-Modified/If-Modified-Since caching
    // https://developer.yahoo.com/performance/rules.html#etags
    // https://tools.ietf.org/html/rfc7232#section-2.3
    bpoEnableCacheByLastModified,

    /// Cache expiration
    //
    // Serve resources with a far-future expiration date.
    //
    // (!) If you don't control versioning with filename-based cache busting, you
    // should consider lowering the cache times to something like one week.
    //
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires
    // https://httpd.apache.org/docs/current/mod/mod_expires.html
    //
    // - TBoilerplateHTTPServer.Expires
    bpoSetExpires,

    /// Enables filename-based cache busting
    // Removes all query path of the URL `/style.css?v231` to `/style.css`
    bpoEnableCacheBusting,

    /// Filename-based cache busting
    // Removes infix query path of the URL `/style.123456.css` to `/style.css`
    //
    // If you're not using a build process to manage your filename version revving,
    // you might want to consider enabling the following directives.
    //
    // To understand why this is important and even a better solution than using
    // something like `*.css?v231`, please see:
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

  /// Suppressing or forcing the `www.` at the beginning of URLs
  //
  // The same content should never be available under two different URLs,
  // especially not with and without `www.` at the beginning.
  // This can cause SEO problems (duplicate content), and therefore, you should
  // choose one of the alternatives and redirect the other one.
  //
  // (!) NEVER USE BOTH WWW-RELATED RULES AT THE SAME TIME!
  //
  // (1) The rule assumes by default that both HTTP and HTTPS environments are
  //     available for redirection.
  //     If your SSL certificate could not handle one of the domains used during
  //     redirection, you should turn the condition on.
  //
  // - wwwOff:
  //   Do not suppress or force 'www.' at the beginning of URLs
  //
  // - wwwSuppress:
  //   Suppressing the `www.` at the beginning of URLs
  //   Redirects www.example.com --> example.com
  //
  // wwwForce:
  //   Forcing the `www.` at the beginning of URLs
  //   Redirects example.com --> www.example.com
  //   Be aware that wwwForce might not be a good idea if you use "real"
  //   subdomains for certain parts of your website.
  TWWWRewrite = (wwwOff, wwwSuppress, wwwForce);

  /// HTTP Strict Transport Security (HSTS)
  //
  // Force client-side TLS (Transport Layer Security) redirection.
  //
  // If a user types `example.com` in their browser, even if the server redirects
  // them to the secure version of the website, that still leaves a window of
  // opportunity (the initial HTTP connection) for an attacker to downgrade or
  // redirect the request.
  //
  // The following header ensures that a browser only connects to your server
  // via HTTPS, regardless of what the users type in the browser's address bar.
  //
  // (!) Be aware that Strict Transport Security is not revokable and you
  //     must ensure being able to serve the site over HTTPS for the duration
  //     you've specified in the `max-age` directive. When you don't have a
  //     valid TLS connection anymore (e.g. due to an expired TLS certificate)
  //     your visitors will see a nasty error message even when attempting to
  //     connect over HTTP.
  //
  // (1) Preloading Strict Transport Security.
  //     To submit your site for HSTS preloading, it is required that:
  //     * the `includeSubDomains` directive is specified
  //     * the `preload` directive is specified
  //     * the `max-age` is specified with a value of at least 31536000 seconds
  //       (1 year).
  //     https://hstspreload.org/#deployment-recommendations
  //
  // https://tools.ietf.org/html/rfc6797#section-6.1
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security
  // https://www.html5rocks.com/en/tutorials/security/transport-layer-security/
  // https://blogs.msdn.microsoft.com/ieinternals/2014/08/18/strict-transport-security/
  // https://hstspreload.org/
  //
  // - strictSSLOff:
  //   Do not provide HSTS header
  //
  // - strictSSLOn:
  //   Add 'max-age=31536000' HSTS header value
  //
  // - strictSSLIncludeSubDomains:
  //   Add 'max-age=31536000; includeSubDomains' HSTS header value
  //
  // - strictSSLIncludeSubDomainsPreload:
  //   Add 'max-age=31536000; includeSubDomains; preload' HSTS header value
  TStrictSSL = (strictSSLOff, strictSSLOn, strictSSLIncludeSubDomains,
    strictSSLIncludeSubDomainsPreload);

  /// DNS Prefetch control
  //
  // Control DNS prefetching, a feature by which browsers proactively perform
  // domain name resolution on both links that the user may choose to follow
  // as well as URLs for items referenced by the document, including images,
  // CSS, JavaScript, and so forth.
  //
  // This prefetching is performed in the background, so that the DNS is likely
  // to have been resolved by the time the referenced items are needed. This
  // reduces latency when the user clicks a link.
  //
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control
  //
  // dnsPrefetchNone - Do not add `X-DNS-Prefetch-Control` header
  // dnsPrefetchOff - Turn off DNS Prefetch
  // dnsPrefetchOn - Turn on DNS Prefetch (default)
  TDNSPrefetchControl = (dnsPrefetchNone, dnsPrefetchOff, dnsPrefetchOn);

type

  /// TBoilerplateHTTPServer
  TBoilerplateHTTPServer = class(TSQLHttpServer)
  protected
    FAssets: TAssets;
    FOptions: TBoilerplateOptions;
    FContentSecurityPolicy: SockString;
    FContentSecurityPolicyReportOnly: SockString;
    FStrictSSL: TStrictSSL;
    FReferrerPolicy: SockString;
    FReferrerPolicyContentTypes: SockString;
    FReferrerPolicyContentTypesUpArray: TSockStringDynArray;
    FWWWRewrite: TWWWRewrite;
    FDNSPrefetchControl: TDNSPrefetchControl;
    FDNSPrefetchControlContentTypes: SockString;
    FDNSPrefetchControlContentTypesUpArray: TSockStringDynArray;
    FFileTypesImage: SockString;
    FFileTypesImageUpArray: TSockStringDynArray;
    FFileTypesFont: SockString;
    FFileTypesFontUpArray: TSockStringDynArray;
    FForceMIMETypesValues: TSynNameValue;
    FFileTypesRequiredCharSet: SockString;
    FFileTypesRequiredCharSetUpArray: TSockStringDynArray;
    FFileTypesBlocked: SockString;
    FFileTypesBlockedUpArray: TSockStringDynArray;
    FMangledEncodingHeaders: SockString;
    FMangledEncodingHeadersUpArray: TSockStringDynArray;
    FMangledEncodingHeaderValues: SockString;
    FMangledEncodingHeaderValuesUpArray: TSockStringDynArray;
    FFileTypesForceGZipHeader: SockString;
    FFileTypesForceGZipHeaderUpArray: TSockStringDynArray;
    FExpires: SockString;
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
    procedure SplitURL(const URL: SockString; var Path, ExtUp: SockString;
      const EnableCacheBusting, EnableCacheBustingBeforeExt: Boolean);
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Fills the RawUTF8 array with upper-cased, sorted, deduplicated values
    // ready for binary search
    procedure UpArrayFromCSV(const CSV: SockString;
      var Values: TSockStringDynArray; const PrefixUp: SockString = '';
      const PostfixUp: SockString = ''; const Sep: AnsiChar = ',');
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Binary search of value in sorted, deduplicated, upper-cased array
    function InArray(const UpValue: SockString;
      const UpValues: TSockStringDynArray): Boolean;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Extracts HTTP Header value and returns the headers without header
    function ExtractCustomHeader(const Headers, NameUp: SockString;
      out Value: SockString): SockString;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Retrieves HTTP Header trimmed value
    function GetCustomHeader(const Headers: SockString;
      const NameUp: SockString): SockString;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Add HTTP header value to Context.OutHeaders
    procedure AddCustomHeader(Context: THttpServerRequest;
      const Name, Value: SockString);
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Remove HTTP header value from Context.OutHeaders
    function DeleteCustomHeader(Context: THttpServerRequest;
      const NameUp: SockString): SockString;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Validate that HTTP client can accept GZip and Brotli content encodings
    procedure GetAcceptedEncodings(Context: THttpServerRequest;
      const FixMangled: Boolean; var GZipAccepted, BrotliAccepted: Boolean);
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Check ETag of Last-Modified values
    function WasModified(Context: THttpServerRequest; Asset: PAsset;
      const Encoding: TAssetEncoding;
      const CheckETag, CheckModified: Boolean): Boolean;

    /// Converts "text/html=1m", "image/x-icon=1w", etc. expires to seconds
    function ExpiresToSecs(const Value: RawUTF8): PtrInt;
      {$IFNDEF VER180}{$IFDEF HASINLINE} inline; {$ENDIF}{$ENDIF}

    /// Get number of seconds, when content will be expired
    function GetExpires(const ContentTypeUp: SockString): PtrInt;
      {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Removes charset from content type
    function GetContentTypeUp(const Value: SockString): SockString;
      {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Find custom options registered for specific URL by RegisterCustomOptions
    function FindCustomOptions(const URLPath: RawUTF8;
      const Default: TBoilerplateOptions): TBoilerplateOptions;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Checks that Path is not started from '.' and has no '/.' sequences,
    // except '/.well-known/' sequence.
    // - See bpoDelegateHidden option
    function ContainsHiddenExceptWellKnown(const Path: SockString): Boolean;
      {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Check that Path is not ended with '~' or '#' and upper-cased file
    // extension is not in blocked list
    // - See bpoDelegateBlocked option
    // - Use TBoilerplateHTTPServer.FileTypesBlocked to specify file types
    function IsBlockedPathOrExt(const Path, ExtUp: SockString): Boolean;
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure InitForceMIMETypesValues;
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetReferrerPolicyContentTypes(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetDNSPrefetchControlContentTypes(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetFileTypesImage(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetFileTypesFont(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetFileTypesRequiredCharSet(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetFileTypesBlocked(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetMangledEncodingHeaders(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetMangledEncodingHeaderValues(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetFileTypesForceGZipHeader(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    procedure SetExpires(const Value: SockString);
      {$IFDEF HASINLINE} inline; {$ENDIF}

  protected
    function Request(Context: THttpServerRequest): Cardinal; override;

  public
    /// Standart TSQLHttpServer constructor
    constructor Create(const aPort: AnsiString;
      const aServers: array of TSQLRestServer;
      const aDomainName: AnsiString = '+';
      aHttpServerKind: TSQLHttpServerOptions = HTTP_DEFAULT_MODE;
      ServerThreadPoolCount: Integer = 32;
      aHttpServerSecurity: TSQLHttpServerSecurity = secNone;
      const aAdditionalURL: AnsiString = ''; const aQueueName: SynUnicode = '');
        overload;

    /// Standart TSQLHttpServer constructor
    constructor Create(const aPort: AnsiString; aServer: TSQLRestServer;
      const aDomainName: AnsiString = '+';
      aHttpServerKind: TSQLHttpServerOptions = HTTP_DEFAULT_MODE;
      aRestAccessRights: PSQLAccessRights = nil;
      ServerThreadPoolCount: Integer = 32;
      aHttpServerSecurity: TSQLHttpServerSecurity = secNone;
      const aAdditionalURL: AnsiString = ''; const aQueueName: SynUnicode = '');
        overload;

    /// Standart TSQLHttpServer constructor
    constructor Create(aServer: TSQLRestServer;
      aDefinition: TSQLHttpServerDefinition); overload;

  public
    /// Load static assets from specific RT_RCDATA synzl-compressed resource
    procedure LoadFromResource(const ResName: string);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Register custom Cache-Control options for specific URL
    // For example if you want to cache most of *.html pages with standart
    // Cache-Control options, but change this rule for
    // default page or login page.
    // For URL prefixes use asterisk char postfix, e.g. '/customer/*'
    procedure RegisterCustomOptions(const URLPath: RawUTF8;
      const CustomOptions: TBoilerplateOptions); overload;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Register custom Cache-Control options for specific URL's
    // For example if you want cache most *.html pages with standart
    // Cache-Control options, but change this rule for default page or api calls
    // For URL prefixes use asterisk char postfix, e.g. '/customer/*'
    procedure RegisterCustomOptions(const URLParts: TRawUTF8DynArray;
      CustomOptions: TBoilerplateOptions); overload;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Removes custom options usage for specific URL
    procedure UnregisterCustomOptions(const URLPath: RawUTF8); overload;
      {$IFDEF HASINLINE} inline; {$ENDIF}

    /// Removes custom options usage for specific URLs
    procedure UnregisterCustomOptions(
      const URLPaths: TRawUTF8DynArray); overload;
        {$IFDEF HASINLINE} inline; {$ENDIF}

    /// See TBoilerplateOption.bpoForceMIMEType
    procedure SetForceMIMETypes(const ExtMIMETypePairs: TRawUTF8DynArray);
      {$IFDEF HASINLINE} inline; {$ENDIF}

    /// If this directory is not empty, all loaded static assets will be
    // pre-saved as files into this directory.
    //
    // To minimize disk IO operations file modified timestamp and file size
    // will be checked before saving.
    //
    // The STATICFILE_CONTENT_TYPE will be used to inform the lower level API
    // to send the response as file content. All assets will be saved into
    // three different sub-directories:
    // - 'identity' for plain unmodified assets
    // - 'gzip' for assets with gzip/zipfli compression
    // - 'brotli' for assets with brotli compression
    //
    // See 'assetslz', 'resedit' tools and LoadFromResource method to load
    // server static assets from the prepared and embedded synlz-packed
    // RC_RTDATA resource.
    property StaticRoot: TFileName read FStaticRoot write FStaticRoot;

    /// See TBoilerplateOptions
    property Options: TBoilerplateOptions read FOptions write FOptions;

    /// See TStrictSSL
    property StrictSSL: TStrictSSL read FStrictSSL write FStrictSSL;

    /// See TWWWRewrite
    property WWWRewrite: TWWWRewrite read FWWWRewrite write FWWWRewrite;

    /// See TDNSPrefetchControl
    property DNSPrefetchControl: TDNSPrefetchControl read FDNSPrefetchControl
      write FDNSPrefetchControl;

    /// Specified CSV list of content types used for DNS prefetch control
    property DNSPrefetchControlContentTypes: SockString
      read FDNSPrefetchControlContentTypes
      write SetDNSPrefetchControlContentTypes;

    /// Content Security Policy (CSP)
    //
    // Mitigate the risk of cross-site scripting and other content-injection
    // attacks.
    //
    // This can be done by setting a `Content Security Policy` which whitelists
    // trusted sources of content for your website.
    //
    // There is no policy that fits all websites, you will have to modify the
    // `Content-Security-Policy` directives in the example depending on your
    // needs.
    //
    // The example policy below aims to:
    //
    //  (1) Restrict all fetches by default to the origin of the current website
    //      by setting the `default-src` directive to `'self'` - which acts as a
    //      fallback to all "Fetch directives"
    //      (https://developer.mozilla.org/en-US/docs/Glossary/Fetch_directive).
    //
    //      This is convenient as you do not have to specify all Fetch
    //      directives that apply to your site, for example:
    //      `connect-src 'self'; font-src 'self'; script-src 'self'; style-src
    //      'self'`, etc.
    //
    //      This restriction also means that you must explicitly define from
    //      which site(s) your website is allowed to load resources from.
    //
    //  (2) The `<base>` element is not allowed on the website. This is to
    //      prevent attackers from changing the locations of resources loaded
    //      from relative URLs.
    //
    //      If you want to use the `<base>` element, then `base-uri 'self'` can
    //      be used instead.
    //
    //  (3) Form submissions are only allowed from the current website by
    //      setting: `form-action 'self'`.
    //
    //  (4) Prevents all websites (including your own) from embedding your
    //      webpages within e.g. the `<iframe>` or `<object>` element by
    //      setting: `frame-ancestors 'none'`.
    //
    //      The `frame-ancestors` directive helps avoid "Clickjacking" attacks
    //      and is similar to the `X-Frame-Options` header.
    //
    //      Browsers that support the CSP header will ignore `X-Frame-Options`
    //      if `frame-ancestors` is also specified.
    //
    //  (5) Forces the browser to treat all the resources that are served over
    //      HTTP as if they were loaded securely over HTTPS by setting the
    //      `upgrade-insecure-requests` directive.
    //
    //      Please note that `upgrade-insecure-requests` does not ensure HTTPS
    //      for the top-level navigation. If you want to force the website
    //      itself to be loaded over HTTPS you must include the
    //      `Strict-Transport-Security` header.
    //
    //  (6) The `Content-Security-Policy` header is included in all responses
    //      that are able to execute scripting. This includes the commonly used
    //      file types: HTML, XML and PDF documents. Although Javascript files
    //      can not execute script in a "browsing context", they are still
    //      included to target workers:
    //      https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy#CSP_in_workers
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
    // - See CONTENT_SECURITY_POLICY_STRICT const as an example
    // - Use CSP.pas unit for detailed property values
    property ContentSecurityPolicy: SockString
      read FContentSecurityPolicy write FContentSecurityPolicy;

    /// Content Security Policy (CSP) incidents reporting
    // See CSP.pas unit for detailed property values
    property ContentSecurityPolicyReportOnly: SockString
      read FContentSecurityPolicyReportOnly
      write FContentSecurityPolicyReportOnly;

    /// See TBoilerplateOption.bpoEnableReferrerPolicy
    property ReferrerPolicy: SockString read FReferrerPolicy
      write FReferrerPolicy;

    /// See TBoilerplateOption.bpoEnableReferrerPolicy
    property ReferrerPolicyContentTypes: SockString
      read FReferrerPolicyContentTypes
      write SetReferrerPolicyContentTypes;

    /// See TBoilerplateOption.bpoAllowCrossOriginImages
    property FileTypesImage: SockString read FFileTypesImage
      write SetFileTypesImage;

    /// See TBoilerplateOption.bpoAllowCrossOriginFonts
    property FileTypesFont: SockString read FFileTypesFont
      write SetFileTypesFont;

    /// TBoilerplateOption.bpoForceUTF8Charset
    property FileTypesRequiredCharSet: SockString read FFileTypesRequiredCharSet
      write SetFileTypesRequiredCharSet;

    /// TBoilerplateOption.bpoForceGZipHeader
    property FileTypesForceGZipHeader: SockString read FFileTypesForceGZipHeader
      write SetFileTypesForceGZipHeader;

    /// TBoilerplateOption.bpoDelegateBlocked
    property FileTypesBlocked: SockString read FFileTypesBlocked
      write SetFileTypesBlocked;

    /// TBoilerplateOption.bpoFixMangledAcceptEncoding
    property MangledEncodingHeaders: SockString read FMangledEncodingHeaders
      write SetMangledEncodingHeaders;

    /// TBoilerplateOption.bpoFixMangledAcceptEncoding
    property MangledEncodingHeaderValues: SockString
      read FMangledEncodingHeaderValues write SetMangledEncodingHeaderValues;

    /// TBoilerplateOption.bpoSetExpires
    property Expires: SockString read FExpires write SetExpires;
  end;

const

  /// See TBoilerplateOption
  DEFAULT_BOILERPLATE_OPTIONS: TBoilerplateOptions = [
    // bpoAllowCrossOrigin,
    bpoAllowCrossOriginImages,
    bpoAllowCrossOriginFonts,
    // bpoAllowCrossOriginTiming,
    bpoDelegateBadRequestTo404,
    bpoDelegateUnauthorizedTo404,
    bpoDelegateForbiddenTo404,
    bpoDelegateNotFoundTo404,
    bpoDelegateNotAllowedTo404,
    bpoDelegateNotAcceptableTo404,
    bpoSetXUACompatible,
    bpoForceMIMEType,
    bpoForceTextUTF8Charset,
    bpoForceUTF8Charset,
    // bpoForceHTTPS,
    // bpoForceHTTPSExceptLetsEncrypt,
    // bpoSetXFrameOptions,
    bpoDelegateHidden,
    bpoDelegateBlocked,
    bpoPreventMIMESniffing,
    // bpoEnableXSSFilter,
    // bpoEnableReferrerPolicy,
    // bpoDisableTRACEMethod,
    bpoDeleteXPoweredBy,
    bpoFixMangledAcceptEncoding,
    bpoForceGZipHeader,
    bpoSetCachePublic,
    // bpoSetCachePrivate,
    // bpoSetCacheNoTransform,
    // bpoSetCacheNoCache,
    // bpoSetCacheNoStore,
    // bpoSetCacheMustRevalidate,
    bpoSetCacheMaxAge,
    // bpoEnableCacheByETag,
    bpoEnableCacheByLastModified,
    bpoSetExpires,
    // bpoEnableCacheBusting,
    // bpoEnableCacheBustingBeforeExt,
    bpoDelegateRootToIndex,
    bpoDeleteServerInternalState,
    // bpoDelegateIndexToInheritedDefault,
    // bpoDelegate404ToInherited_404,
    bpoVaryAcceptEncoding];

  /// See TWWWRewrite
  DEFAULT_WWW_REWRITE: TWWWRewrite = wwwSuppress;

  /// See TStrictSSL
  DEFAULT_STRICT_SLL: TStrictSSL = strictSSLOff;

  /// See TDNSPrefetchControl
  DEFAULT_DNS_PREFETCH_CONTROL: TDNSPrefetchControl = dnsPrefetchOn;

  /// See TBoilerplateHTTPServer.DNSPrefetchControlContentTypes
  DEFAULT_DNS_PREFETCH_CONTROL_CONTENT_TYPES =
    'text/css,' +
    'text/html,' +
    'text/javascript';

  /// See TBoilerplateHTTPServer.ContentSecurityPolicy
  DEFAULT_CONTENT_SECURITY_POLICY: SockString = '';

  /// See TBoilerplateHTTPServer.ContentSecurityPolicyReportOnly
  DEFAULT_CONTENT_SECURITY_POLICY_REPORT_ONLY: SockString = '';

  CONTENT_SECURITY_POLICY_STRICT =
    'default-src ''self''; ' +
    'base-uri ''none''; ' +
    'form-action ''self''; ' +
    'frame-ancestors ''none''; ' +
    'upgrade-insecure-requests';

  /// See TBoilerplateHTTPServer.ReferrerPolicy
  DEFAULT_REFERRER_POLICY: SockString = 'strict-origin-when-cross-origin';

  /// See TBoilerplateHTTPServer.ReferrerPolicy
  DEFAULT_REFERRER_POLICY_CONTENT_TYPES =
    'text/css,' +
    'text/html,' +
    'text/javascript,' +
    'application/pdf,' +
    'application/xml';

  /// See TBoilerplateHTTPServer.FileTypesImage
  DEFAULT_FILE_TYPES_IMAGE =
    'bmp,cur,gif,ico,jpg,jpeg,png,apng,svg,svgz,webp';

  /// See TBoilerplateHTTPServer.FileTypesFont
  DEFAULT_FILE_TYPES_FONT =
    'eot,otf,ttc,ttf,woff,woff2';

  /// See TBoilerplateHTTPServer.FileTypesRequiredCharSet
  DEFAULT_FILE_TYPES_REQUIRED_CHARSET =
    'appcache,bbaw,css,htc,ics,js,json,manifest,map,markdown,md,mjs,' +
    'topojson,vtt,vcard,vcf,webmanifest,xloc';

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
    'image/apng=1m'#10 +
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

function IdemPCharUp(P: PByteArray; Up: PByte): Boolean;
  {$IFDEF HASINLINE} inline; {$ENDIF}
var
  U: Byte;
begin
  if P = nil then
  begin
    Result := False;
    Exit;
  end else if Up = nil then
  begin
    Result := True;
    Exit
  end else begin
    Dec(PtrUInt(P), PtrUInt(Up));
    repeat
      U := Up^;
      if U = 0 then Break;
      if PByteArray(@NormToUpper)[P[PtrUInt(Up)]] <> U then
      begin
        Result := False;
        Exit;
      end;
      Inc(Up);
    until False;
    Result := True;
  end;
end;

function TrimCopy(const S: SockString; Start, Count: PtrInt): SockString;
  {$IFDEF HASINLINE} inline; {$ENDIF}
var
  L: PtrInt;
begin
  if Count <= 0 then
  begin
    Result := '';
    Exit;
  end;
  if Start <= 0 then
    Start := 1;
  L := Length(S);
  while (Start <= L) and (S[Start] <= ' ') do
  begin
    Inc(Start);
    Dec(Count);
  end;
  Dec(Start);
  Dec(L, Start);
  if Count < L then
    L := Count;
  while L > 0 do
    if S[Start + L] <= ' ' then
      Dec(L)
    else
      Break;
  if L > 0 then
    SetString(Result, PAnsiChar(@PByteArray(S)[Start]), L)
  else
    Result := '';
end;

{ TBoilerplateHTTPServer }

procedure TBoilerplateHTTPServer.AddCustomHeader(Context: THttpServerRequest;
  const Name, Value: SockString);
begin
  if Context.OutCustomHeaders <> '' then
    Context.OutCustomHeaders := FormatUTF8(
      '%'#$D#$A'%: %', [Context.OutCustomHeaders, Name, Value])
  else
    Context.OutCustomHeaders := FormatUTF8('%: %', [Name, Value])
end;

function TBoilerplateHTTPServer.DeleteCustomHeader(Context: THttpServerRequest;
  const NameUp: SockString): SockString;
begin
  Context.OutCustomHeaders :=
    ExtractCustomHeader(Context.OutCustomHeaders, NameUp, Result);
end;

function TBoilerplateHTTPServer.ExpiresToSecs(const Value: RawUTF8): PtrInt;
const
  SecsPerWeek = 7 * SecsPerDay;
  SecsPerMonth = 2629746; // SecsPerDay * 365.2425 / 12
  SecsPerYear = 12 * SecsPerMonth;
var
  P: PUTF8Char;
  Len: Integer;
begin
  if Value = '' then
  begin
    Result := 0;
    Exit;
  end;
  P := Pointer(Value);
  Len := Length(Value);
  case Value[Len] of
    'S', 's': Result := GetInteger(P, P + Len);
    'H', 'h': Result := SecsPerHour * GetInteger(P, P + Len);
    'D', 'd': Result := SecsPerDay * GetInteger(P, P + Len);
    'W', 'w': Result := SecsPerWeek * GetInteger(P, P + Len);
    'M', 'm': Result := SecsPerMonth * GetInteger(P, P + Len);
    'Y', 'y': Result := SecsPerYear * GetInteger(P, P + Len);
    else
      Result := GetInteger(P, P + Len + 1);
  end;
end;

function TBoilerplateHTTPServer.ExtractCustomHeader(
  const Headers, NameUp: SockString; out Value: SockString): SockString;
var
  I, J, K: PtrInt;
begin
  Result := Headers;
  if (Result = '') or (NameUp = '') then Exit;
  I := 1;
  repeat
    K := Length(Result) + 1;
    for J := I to K - 1 do
      if Result[J] < ' ' then
      begin
        K := J;
        Break;
      end;

    if IdemPCharUp(@PByteArray(Result)[I - 1], Pointer(NameUp)) then
    begin
      J := I;
      Inc(I, Length(NameUp));
      Value := TrimCopy(Result, I, K - I);
      while True do // Delete also ending #13#10
        if (Result[K] = #0) or (Result[K] >= ' ') then
          Break
        else
          Inc(K);
      Delete(Result, J, K - J);
      Exit;
    end;

    I := K;
    while Result[I] < ' ' do
      if Result[I] = #0 then
        Exit
      else
        Inc(I);
  until False;
end;

function TBoilerplateHTTPServer.InArray(const UpValue: SockString;
  const UpValues: TSockStringDynArray): Boolean;
begin
  Result := FastFindPUTF8CharSorted(
    Pointer(UpValues), High(UpValues), Pointer(UpValue)) >= 0;
end;

function TBoilerplateHTTPServer.FindCustomOptions(const URLPath: RawUTF8;
  const Default: TBoilerplateOptions): TBoilerplateOptions;
var
  Index: Integer;

  function FindPrefix(const Prefixes: TSynNameValue;
    const UpperURL: RawUTF8): Integer;
      {$IFDEF HASINLINE} inline; {$ENDIF}
  begin
    for Result := 0 to Prefixes.Count - 1 do
      if IdemPChar(Pointer(UpperURL), Pointer(Prefixes.List[Result].Name)) then
        Exit;
    Result := -1;
  end;

  function StrToOptions(const Str: RawUTF8): TBoilerplateOptions;
    {$IFDEF HASINLINE} inline; {$ENDIF}
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

function TBoilerplateHTTPServer.GetExpires(
  const ContentTypeUp: SockString): PtrInt;
begin
  Result := FExpiresValues.Find(ContentTypeUp);
  if Result >= 0 then
    Result := FExpiresValues.List[Result].Tag
  else
    Result := FExpiresDefault;
end;

function TBoilerplateHTTPServer.GetContentTypeUp(
  const Value: SockString): SockString;
var
  Index, Len: Integer;
  Found: Boolean;
begin
  if Value = '' then
  begin
    Result := '';
    Exit;
  end;
  Found := False;
  Len := Length(Value);
  for Index := 1 to Len do
    if Value[Index] = ';' then
    begin
      Len := Index - 1;
      SetString(Result, PAnsiChar(Pointer(Value)), Len);
      Found := True;
      Break;
    end;
  if not Found then
    SetString(Result, PAnsiChar(Pointer(Value)), Len);
  for Index := 0 to Len - 1 do
    if PByteArray(Result)[Index] in [Ord('a')..Ord('z')] then
      Dec(PByteArray(Result)[Index], $20);
end;

function TBoilerplateHTTPServer.GetCustomHeader(const Headers,
  NameUp: SockString): SockString;
var
  I, J, K: PtrInt;
begin
  Result := '';
  if (Headers = '') or (NameUp = '') then Exit;
  I := 1;
  repeat
    K := Length(Headers) + 1;
    for J := I to K - 1 do
      if Headers[J] < ' ' then
      begin
        K := J;
        Break;
      end;

    if IdemPCharUp(@PByteArray(Headers)[I - 1], Pointer(NameUp)) then
    begin
      Inc(I, Length(NameUp));
      Result := TrimCopy(Headers, I, K - I);
      Exit;
    end;

    I := K;
    while Headers[I] < ' ' do
      if Headers[I] = #0 then
        Exit
      else
        Inc(I);
  until False;
end;

function TBoilerplateHTTPServer.ContainsHiddenExceptWellKnown(
  const Path: SockString): Boolean;

  function HiddenPos(const Path: SockString; const Index: Integer = 1): Integer;
    {$IFDEF HASINLINE} inline; {$ENDIF}
  begin
    for Result := Index to Length(Path) - 1 do
      if (Path[Result] = '/') and (Path[Result + 1] = '.') then Exit;
    Result := 0;
  end;

begin
  if Path = '' then
  begin
    Result := False;
    Exit;
  end;

  // Check the beginning for '.well-known/' no '/.' sequences after
  if IdemPCharUp(Pointer(Path), Pointer(PAnsiChar('.WELL-KNOWN/'))) and
    (HiddenPos(Path, 12) = 0) then
  begin
    Result := False;
    Exit;
  end;

  // Check the beginning for '/.well-known/' no '/.' sequences after
  if IdemPCharUp(Pointer(Path), Pointer(PAnsiChar('/.WELL-KNOWN/'))) and
    (HiddenPos(Path, 13) = 0) then
  begin
    Result := False;
    Exit;
  end;

  Result := (Path[1] = '.') or (HiddenPos(Path) > 0);
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
  FContentSecurityPolicyReportOnly := DEFAULT_CONTENT_SECURITY_POLICY_REPORT_ONLY;
  FStrictSSL := DEFAULT_STRICT_SLL;
  FReferrerPolicy := DEFAULT_REFERRER_POLICY;
  SetReferrerPolicyContentTypes(DEFAULT_REFERRER_POLICY_CONTENT_TYPES);
  FWWWRewrite := DEFAULT_WWW_REWRITE;
  FDNSPrefetchControl := DEFAULT_DNS_PREFETCH_CONTROL;
  SetDNSPrefetchControlContentTypes(DEFAULT_DNS_PREFETCH_CONTROL_CONTENT_TYPES);
  SetFileTypesImage(DEFAULT_FILE_TYPES_IMAGE);
  SetFileTypesFont(DEFAULT_FILE_TYPES_FONT);
  SetFileTypesRequiredCharSet(DEFAULT_FILE_TYPES_REQUIRED_CHARSET);
  SetFileTypesBlocked(DEFAULT_FILE_TYPES_BLOCKED);
  SetMangledEncodingHeaders(DEFAULT_MANGLED_ENCODING_HEADERS);
  SetMangledEncodingHeaderValues(DEFAULT_MANGLED_ENCODING_HEADER_VALUES);
  SetFileTypesForceGZipHeader(DEFAULT_FILE_TYPES_FORCE_GZIP_HEADER);
  SetExpires(DEFAULT_EXPIRES);
  FCustomOptions.Init(False);
  FCustomOptionPrefixes.Init(False);
  InitForceMIMETypesValues;
end;

procedure TBoilerplateHTTPServer.InitForceMIMETypesValues;
var
  Index: Integer;
begin
  FForceMIMETypesValues.Init(False);
  for Index := 0 to Length(MIME_TYPES_FILE_EXTENSIONS) shr 1 - 1 do
    FForceMIMETypesValues.Add(MIME_TYPES_FILE_EXTENSIONS[Index shl 1 + 1],
      MIME_TYPES_FILE_EXTENSIONS[Index shl 1]);
end;

function TBoilerplateHTTPServer.IsBlockedPathOrExt(
  const Path, ExtUp: SockString): Boolean;
begin
  Result := InArray(ExtUp, FFileTypesBlockedUpArray) or ((Path <> '') and
    (PByteArray(Path)[Length(Path) - 1] in [Ord('~'), Ord('#')]));
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
      BinToHexDisplay(@Asset.ContentHash,
        Pointer(@ServerHash[2]), SizeOf(Cardinal))
    else if Encoding = aeGZip then
      BinToHexDisplay(@Asset.GZipHash,
        Pointer(@ServerHash[2]), SizeOf(Cardinal))
    else if Encoding = aeBrotli then
      BinToHexDisplay(@Asset.BrotliHash,
        Pointer(@ServerHash[2]), SizeOf(Cardinal));
    ClientHash := GetCustomHeader(Context.InHeaders, 'IF-NONE-MATCH:');
    Result := ClientHash <> ServerHash;
    if Result then
      Context.OutCustomHeaders := FormatUTF8('%ETag: %'#$D#$A,
        [Context.OutCustomHeaders, ServerHash]);
  end;

  if not Result and CheckModified then
  begin
    ServerModified := DateTimeToHTTPDate(Asset.Timestamp);
    ClientModified := GetCustomHeader(Context.InHeaders, 'IF-MODIFIED-SINCE:');
    Result := (ClientModified = '') or
      (StrIComp(Pointer(ClientModified), Pointer(ServerModified)) <> 0);
    if Result then
      Context.OutCustomHeaders := FormatUTF8('%Last-Modified: %'#$D#$A,
        [Context.OutCustomHeaders, ServerModified]);
  end;
end;

procedure TBoilerplateHTTPServer.GetAcceptedEncodings(
  Context: THttpServerRequest; const FixMangled: Boolean;
  var GZipAccepted, BrotliAccepted: Boolean);
var
  AcceptEncoding: RawUTF8;
  Index: Integer;
begin
  AcceptEncoding := GetCustomHeader(Context.InHeaders, 'ACCEPT-ENCODING:');
  UpperCaseSelf(AcceptEncoding);
  GZipAccepted := PosEx('GZIP', AcceptEncoding) > 0;
  BrotliAccepted := PosEx('BR', AcceptEncoding) > 0;

  if GZipAccepted or BrotliAccepted or not FixMangled then Exit;

  for Index := Low(FMangledEncodingHeadersUpArray) to
    High(FMangledEncodingHeadersUpArray) do
  begin
    AcceptEncoding := GetCustomHeader(
      Context.InHeaders, FMangledEncodingHeadersUpArray[Index]);
    if AcceptEncoding = '' then Continue;
    UpperCaseSelf(AcceptEncoding);
    GZipAccepted := InArray(AcceptEncoding,
      FMangledEncodingHeaderValuesUpArray);
    if GZipAccepted then Break;
  end;
end;

procedure TBoilerplateHTTPServer.LoadFromResource(const ResName: string);
begin
  FAssets.LoadFromResource(ResName);
end;

procedure TBoilerplateHTTPServer.RegisterCustomOptions(const URLPath: RawUTF8;
  const CustomOptions: TBoilerplateOptions);

  function GetOptionsValue(const CustomOptions: TBoilerplateOptions): RawUTF8;
    {$IFDEF HASINLINE} inline; {$ENDIF}
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
  HTTPS: array[Boolean] of SockString = ('http://', 'https://');
  LETS_ENCRYPT_WELL_KNOWN_PATHS: array[0..2] of PAnsiChar = (
    '/.WELL-KNOWN/ACME-CHALLENGE/',
    '/.WELL-KNOWN/CPANEL-DCV/',
    '/.WELL-KNOWN/PKI-VALIDATION/');
  CACHE_NO_TRANSFORM: ShortString = ', no-transform';
  CACHE_PUBLIC: ShortString = ', public';
  CACHE_PRIVATE: ShortString = ', private';
  CAHCE_NO_CACHE: ShortString = ', no-cache';
  CACHE_NO_STORE: ShortString = ', no-store';
  CACHE_MUST_REVALIDATE: ShortString = ', must-revalidate';
  CACHE_MAX_AGE: ShortString = ', max-age=';
var
  Asset: PAsset;
  AssetEncoding: TAssetEncoding;
  AcceptedEncodingsDefined: Boolean;
  LOptions: TBoilerplateOptions;
  Path, PathLowerCased, ExtUp, Host: SockString;
  GZipAccepted, BrotliAccepted: Boolean;
  OriginExists, CORSEnabled: Boolean;
  ContentTypeUp, ForcedContentType, CacheControl: SockString;
  CacheControlBuffer: array[0..127] of Byte;
  IntBuffer: array[0..23] of AnsiChar;
  Expires: PtrInt;
  ExpiresDefined: Boolean;
  Vary: RawUTF8;
  P, PInt: PAnsiChar;
  Len: PtrInt;
begin
  SplitURL(Context.URL, Path, ExtUp, bpoEnableCacheBusting in FOptions,
    bpoEnableCacheBustingBeforeExt in FOptions);

  LOptions := FindCustomOptions(Path, FOptions);

  if (bpoForceHTTPS in LOptions) and not Context.UseSSL then
    if not (bpoForceHTTPSExceptLetsEncrypt in LOptions) or not
      (IdemPCharArray(Pointer(Path), LETS_ENCRYPT_WELL_KNOWN_PATHS) >= 0) then
    begin
      Host := GetCustomHeader(Context.InHeaders, 'HOST:');
      if Host <> '' then
      begin
        AddCustomHeader(Context, 'Location',
          FormatUTF8('https://%%', [Host, Path]));
        Result := HTTP_MOVEDPERMANENTLY;
        Exit;
      end;
    end;

  if FWWWRewrite = wwwSuppress then
  begin
    Host := GetCustomHeader(Context.InHeaders, 'HOST:');
    if IdemPChar(Pointer(Host), 'WWW.') then
    begin
      AddCustomHeader(Context, 'Location', FormatUTF8('%%%',
        [HTTPS[Context.UseSSL], Copy(Host, 5, MaxInt), Path]));
      Result := HTTP_MOVEDPERMANENTLY;
      Exit;
    end;
  end;

  if FWWWRewrite = wwwForce then
  begin
    Host := GetCustomHeader(Context.InHeaders, 'HOST:');
    if not IdemPChar(Pointer(Host), 'WWW.') then
    begin
      AddCustomHeader(Context, 'Location',
        FormatUTF8('%www.%%', [HTTPS[Context.UseSSL], Host, Path]));
      Result := HTTP_MOVEDPERMANENTLY;
      Exit;
    end;
  end;

  if (bpoDelegateRootToIndex in LOptions) and
    ((Context.URL = '') or (Context.URL = '/')) then
    with Context do
      if bpoDelegateIndexToInheritedDefault in LOptions then
      begin
        Prepare('/Default', Method, InHeaders, InContent, InContentType,
          RemoteIP, UseSSL);
        Path := '/Default';
      end else begin
        Prepare('/index.html', Method, InHeaders, InContent, InContentType,
          RemoteIP, UseSSL);
        Path := '/index.html';
        ExtUp := '.HTML';
      end;

  if StrIComp(Pointer(Context.Method), PAnsiChar('GET')) = 0 then
  begin
    Asset := FAssets.Find(Path);
    if Asset = nil then
    begin
      PathLowerCased := LowerCase(Path);
      if PathLowerCased <> Path then
      begin
        Asset := FAssets.Find(PathLowerCased);
        if RedirectServerRootUriForExactCase and (Asset <> nil) then
        begin
          Host := GetCustomHeader(Context.InHeaders, 'HOST:');
          if Host <> '' then
          begin
            AddCustomHeader(Context, 'Location', FormatUTF8('%%%',
              [HTTPS[Context.UseSSL], Host, PathLowerCased]));
            Result := HTTP_MOVEDPERMANENTLY;
            Exit;
          end;
        end;
      end;
    end;
  end else
    Asset := nil;

  GZipAccepted := False;
  BrotliAccepted := False;
  AssetEncoding := aeIdentity;
  AcceptedEncodingsDefined := False;

  if Asset = nil then
  begin
    if (bpoDisableTRACEMethod in LOptions) and
      (StrIComp(Pointer(Context.Method), PAnsiChar('TRACE')) = 0) then
        Result := HTTP_NOTALLOWED
    else begin
      Result := inherited Request(Context);
      ContentTypeUp := GetContentTypeUp(Context.OutContentType);
    end;
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

    Context.OutContentType := Asset.ContentType;
    ContentTypeUp := GetContentTypeUp(Asset.ContentType);

    if AssetEncoding = aeGZip then
    begin
      AddCustomHeader(Context, 'Content-Encoding', 'gzip');
      Context.OutContent := Asset.GZipContent;
    end else if AssetEncoding = aeBrotli then
    begin
      AddCustomHeader(Context, 'Content-Encoding', 'br');
      Context.OutContent := Asset.BrotliContent;
    end else
      Context.OutContent := Asset.Content;

    Result := HTTP_SUCCESS;
  end;

  if ((Result = HTTP_BADREQUEST) and (bpoDelegateBadRequestTo404 in LOptions)) or
    ((Result = HTTP_UNAUTHORIZED) and (bpoDelegateUnauthorizedTo404 in LOptions)) or
    ((Result = HTTP_FORBIDDEN) and (bpoDelegateForbiddenTo404 in LOptions)) or
    ((Result = HTTP_NOTFOUND) and (bpoDelegateNotFoundTo404 in LOptions)) or
    ((Result = HTTP_NOTALLOWED) and (bpoDelegateNotAllowedTo404 in LOptions)) or
    ((Result = HTTP_NOTACCEPTABLE) and (bpoDelegateNotAcceptableTo404 in LOptions)) or
    ((bpoDelegateHidden in LOptions) and ContainsHiddenExceptWellKnown(Path)) or
    ((bpoDelegateBlocked in LOptions) and (IsBlockedPathOrExt(Path, ExtUp))) then
  begin
    if bpoDelegate404ToInherited_404 in LOptions then
    begin
      with Context do
        Prepare('/404', Method, InHeaders, InContent, InContentType, RemoteIP,
          UseSSL);
      Result := inherited Request(Context);
      ContentTypeUp := GetContentTypeUp(Context.OutContentType);
      if Result = HTTP_SUCCESS then
        Result := HTTP_NOTFOUND;
    end else begin
      with Context do
        Prepare('/404.html', Method, InHeaders, InContent, InContentType,
          RemoteIP, UseSSL);
      Asset := FAssets.Find('/404.html');
      if Asset <> nil then
      begin
        Context.OutContentType := Asset.ContentType;
        ContentTypeUp := GetContentTypeUp(Asset.ContentType);

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
          Context.OutContent := Asset.GZipContent;
        end else if AssetEncoding = aeBrotli then
        begin
          AddCustomHeader(Context, 'Content-Encoding', 'br');
          Context.OutContent := Asset.BrotliContent;
        end else
          Context.OutContent := Asset.Content;

        Result := HTTP_NOTFOUND;
        ExtUp := '.HTML';
      end;
    end;
  end;

  if bpoForceMIMEType in LOptions then
  begin
    ForcedContentType := FForceMIMETypesValues.Value(ExtUp, #0);
    if ForcedContentType <> #0 then
    begin
      Context.OutContentType := ForcedContentType;
      ContentTypeUp := GetContentTypeUp(ForcedContentType);
    end;
  end;

  if (bpoForceGZipHeader in LOptions) and (AssetEncoding = aeIdentity) and
    InArray(ExtUp, FFileTypesForceGZipHeaderUpArray) then
      AddCustomHeader(Context, 'Content-Encoding', 'gzip');

  if bpoForceTextUTF8Charset in LOptions then
  begin
    if Context.OutContentType = 'text/html' then
      Context.OutContentType := 'text/html; charset=UTF-8'
    else if Context.OutContentType = 'text/plain' then
      Context.OutContentType := 'text/plain; charset=UTF-8';
  end;

  if (bpoForceUTF8Charset in LOptions) and
    InArray(ExtUp, FFileTypesRequiredCharSetUpArray) then
  begin
    if PosEx('charset', LowerCase(Context.OutContentType)) = 0 then
      Context.OutContentType := Context.OutContentType + '; charset=UTF-8';
  end;

  CORSEnabled := False;
  OriginExists := GetCustomHeader(Context.InHeaders, 'ORIGIN:') <> '';

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
    if OriginExists and InArray(ExtUp, FFileTypesImageUpArray) then
    begin
      AddCustomHeader(Context, 'Access-Control-Allow-Origin', '*');
      CORSEnabled := True;
    end;
  end;

  if not CORSEnabled and (bpoAllowCrossOriginFonts in LOptions) then
    if OriginExists and InArray(ExtUp, FFileTypesFontUpArray) then
      AddCustomHeader(Context, 'Access-Control-Allow-Origin', '*');

  if bpoAllowCrossOriginTiming in LOptions then
    AddCustomHeader(Context, 'Timing-Allow-Origin', '*');

  if IdemPCharUp(Pointer(ContentTypeUp), Pointer(PAnsiChar('TEXT/HTML'))) then
  begin
    if (bpoSetXUACompatible in LOptions) then
      AddCustomHeader(Context, 'X-UA-Compatible', 'IE=edge');

    if (bpoSetXFrameOptions in LOptions) then
      AddCustomHeader(Context, 'X-Frame-Options', 'DENY');

    if (FContentSecurityPolicy <> '') then
      AddCustomHeader(Context, 'Content-Security-Policy',
        FContentSecurityPolicy);

    if (FContentSecurityPolicyReportOnly <> '') then
      AddCustomHeader(Context, 'Content-Security-Policy-Report-Only',
        FContentSecurityPolicyReportOnly);

    if (bpoEnableXSSFilter in LOptions) then
        AddCustomHeader(Context, 'X-XSS-Protection', '1; mode=block');
  end;

  if Context.UseSSL then
    if FStrictSSL = strictSSLOn then
      AddCustomHeader(Context, 'Strict-Transport-Security',
        'max-age=31536000')
    else if FStrictSSL = strictSSLIncludeSubDomains then
      AddCustomHeader(Context, 'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains')
    else if FStrictSSL = strictSSLIncludeSubDomainsPreload then
      AddCustomHeader(Context, 'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains; preload');

  if bpoPreventMIMESniffing in LOptions then
    AddCustomHeader(Context, 'X-Content-Type-Options', 'nosniff');

  if (bpoEnableReferrerPolicy in LOptions) and
    InArray(ContentTypeUp, FReferrerPolicyContentTypesUpArray) then
      AddCustomHeader(Context, 'Referrer-Policy', FReferrerPolicy);

  if bpoDeleteXPoweredBy in LOptions then
    DeleteCustomHeader(Context, 'X-POWERED-BY:');

  Expires := 0;
  ExpiresDefined := False;

  if [bpoSetCacheNoTransform, bpoSetCachePublic, bpoSetCachePrivate,
    bpoSetCacheNoCache, bpoSetCacheNoStore, bpoSetCacheMustRevalidate,
    bpoSetCacheMaxAge] * LOptions <> [] then
  begin
    CacheControl := DeleteCustomHeader(Context, 'CACHE-CONTROL:');

    P := @CacheControlBuffer[0];

    if bpoSetCacheNoTransform in LOptions then
    begin
      Move(Pointer(@CACHE_NO_TRANSFORM[1])^, P^, Length(CACHE_NO_TRANSFORM));
      Inc(P, Length(CACHE_NO_TRANSFORM));
    end;

    if bpoSetCachePublic in LOptions then
    begin
      Move(Pointer(@CACHE_PUBLIC[1])^, P^, Length(CACHE_PUBLIC));
      Inc(P, Length(CACHE_PUBLIC));
    end;

    if bpoSetCachePrivate in LOptions then
    begin
      Move(Pointer(@CACHE_PRIVATE[1])^, P^, Length(CACHE_PRIVATE));
      Inc(P, Length(CACHE_PRIVATE));
    end;

    if bpoSetCacheNoCache in LOptions then
    begin
      Move(Pointer(@CAHCE_NO_CACHE[1])^, P^, Length(CAHCE_NO_CACHE));
      Inc(P, Length(CAHCE_NO_CACHE));
    end;

    if bpoSetCacheNoStore in LOptions then
    begin
      Move(Pointer(@CACHE_NO_STORE[1])^, P^, Length(CACHE_NO_STORE));
      Inc(P, Length(CACHE_NO_STORE));
    end;

    if bpoSetCacheMustRevalidate in LOptions then
    begin
      Move(Pointer(@CACHE_MUST_REVALIDATE[1])^, P^, Length(CACHE_MUST_REVALIDATE));
      Inc(P, Length(CACHE_MUST_REVALIDATE));
    end;

    if bpoSetCacheMaxAge in LOptions then
    begin
      Move(Pointer(@CACHE_MAX_AGE[1])^, P^, Length(CACHE_MAX_AGE));
      Inc(P, Length(CACHE_MAX_AGE));
      Expires := GetExpires(ContentTypeUp);
      ExpiresDefined := True;
      PInt := StrInt32(@IntBuffer[23], Expires);
      Len := @IntBuffer[23] - PInt;
      Move(PInt^, P^, Len);
      Inc(P, Len);
    end;

    Len := P - @CacheControlBuffer[0];
    if CacheControl <> '' then
    begin
      SetLength(CacheControl, Length(CacheControl) + Len);
      Move(CacheControlBuffer[0], PAnsiChar(PAnsiChar(Pointer(CacheControl)) +
        Length(CacheControl) - Len)^, Len);
    end else
      SetString(CacheControl, PAnsiChar(@CacheControlBuffer[2]), Len - 2);

    AddCustomHeader(Context, 'Cache-Control', CacheControl);
  end;

  if bpoSetExpires in LOptions then
  begin
    if not ExpiresDefined then
      Expires := GetExpires(ContentTypeUp);
    AddCustomHeader(Context, 'Expires',
      DateTimeToHTTPDate(NowUTC + Expires / SecsPerDay));
  end;

  if bpoDeleteServerInternalState in LOptions then
    DeleteCustomHeader(Context, 'SERVER-INTERNALSTATE:');

  if (bpoVaryAcceptEncoding in LOptions) and
    ((Asset = nil) or (Asset <> nil) and
    (Asset.GZipExists or Asset.BrotliExists)) then
  begin
    Vary := DeleteCustomHeader(Context, 'VARY:');
    if Vary <> '' then
      Vary := Vary + ', Accept-Encoding'
    else
      Vary := 'Accept-Encoding';
    AddCustomHeader(Context, 'Vary', Vary);
  end;

  if (FDNSPrefetchControl <> dnsPrefetchNone) and
    InArray(ContentTypeUp, FDNSPrefetchControlContentTypesUpArray) then
      if FDNSPrefetchControl = dnsPrefetchOn then
        AddCustomHeader(Context, 'X-DNS-Prefetch-Control', 'on')
      else
        AddCustomHeader(Context, 'X-DNS-Prefetch-Control', 'off');

  if (Asset <> nil) and (FStaticRoot <> '') then
  begin
    AddCustomHeader(Context, 'Content-Type', Context.OutContentType);
    Context.OutContentType := HTTP_RESP_STATICFILE;
    Context.OutContent :=
      SockString(Asset.SaveToFile(FStaticRoot, AssetEncoding));
  end;
end;

procedure TBoilerplateHTTPServer.SetDNSPrefetchControlContentTypes(
  const Value: SockString);
begin
  if FDNSPrefetchControlContentTypes <> Value then
  begin
    FDNSPrefetchControlContentTypes := Value;
    UpArrayFromCSV(Value, FDNSPrefetchControlContentTypesUpArray);
  end;
end;

procedure TBoilerplateHTTPServer.SetExpires(const Value: SockString);
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

procedure TBoilerplateHTTPServer.SetFileTypesBlocked(const Value: SockString);
begin
  if FFileTypesBlocked <> Value then
  begin
    FFileTypesBlocked := Value;
    UpArrayFromCSV(Value, FFileTypesBlockedUpArray, '.');
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesFont(const Value: SockString);
begin
  if FFileTypesFont <> Value then
  begin
    FFileTypesFont := Value;
    UpArrayFromCSV(Value, FFileTypesFontUpArray, '.');
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesForceGZipHeader(
  const Value: SockString);
begin
  if FFileTypesForceGZipHeader <> Value then
  begin
    FFileTypesForceGZipHeader := Value;
    UpArrayFromCSV(Value, FFileTypesForceGZipHeaderUpArray, '.');
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesImage(const Value: SockString);
begin
  if FFileTypesImage <> Value then
  begin
    FFileTypesImage := Value;
    UpArrayFromCSV(Value, FFileTypesImageUpArray, '.');
  end;
end;

procedure TBoilerplateHTTPServer.SetFileTypesRequiredCharSet(
  const Value: SockString);
begin
  if FFileTypesRequiredCharSet <> Value then
  begin
    FFileTypesRequiredCharSet := Value;
    UpArrayFromCSV(Value, FFileTypesRequiredCharSetUpArray, '.');
  end;
end;

procedure TBoilerplateHTTPServer.SetForceMIMETypes(
  const ExtMIMETypePairs: TRawUTF8DynArray);
var
  Index: Integer;
begin
  FForceMIMETypesValues.Init(False);
  for Index := 0 to Length(MIME_TYPES_FILE_EXTENSIONS) shr 1 - 1 do
    FForceMIMETypesValues.Add(MIME_TYPES_FILE_EXTENSIONS[Index shl 1 + 1],
      MIME_TYPES_FILE_EXTENSIONS[Index shl 1]);
end;

procedure TBoilerplateHTTPServer.SetMangledEncodingHeaders(
  const Value: SockString);
begin
  if FMangledEncodingHeaders <> Value then
  begin
    FMangledEncodingHeaders := Value;
    UpArrayFromCSV(Value, FMangledEncodingHeadersUpArray, '', ': ');
  end;
end;

procedure TBoilerplateHTTPServer.SetMangledEncodingHeaderValues(
  const Value: SockString);
begin
  if FMangledEncodingHeaderValues <> Value then
  begin
    FMangledEncodingHeaderValues := Value;
    UpArrayFromCSV(Value, FMangledEncodingHeaderValuesUpArray, '', '', '|');
  end;
end;

procedure TBoilerplateHTTPServer.SetReferrerPolicyContentTypes(
  const Value: SockString);
begin
  if FReferrerPolicyContentTypes <> Value then
  begin
    FReferrerPolicyContentTypes := Value;
    UpArrayFromCSV(Value, FReferrerPolicyContentTypesUpArray);
  end;
end;

procedure TBoilerplateHTTPServer.SplitURL(const URL: SockString;
  var Path, ExtUp: SockString;
  const EnableCacheBusting, EnableCacheBustingBeforeExt: Boolean);
var
  Index, Len: Integer;
  ExtPos, QueryOrFragmentPos: Integer;
begin
  if URL = '' then
  begin
    Path := '';
    ExtUp := '';
    Exit;
  end;
  Len := Length(URL);

  ExtPos := 0;
  QueryOrFragmentPos := 0;
  for Index := 1 to Len do
    if QueryOrFragmentPos = 0 then
      case URL[Index] of
        '/': ExtPos := 0;
        '.': ExtPos := Index;
        '?', '#':
          begin
            QueryOrFragmentPos := Index;
            Break;
          end;
      end;

  if EnableCacheBusting and (QueryOrFragmentPos > 0) then
    SetString(Path, PAnsiChar(PByteArray(URL)), QueryOrFragmentPos - 1)
  else
    Path := URL;

  if ExtPos > 0 then
  begin
    if QueryOrFragmentPos > 0 then
      SetString(ExtUp, PAnsiChar(@PByteArray(URL)[ExtPos - 1]),
        QueryOrFragmentPos - ExtPos + 1)
    else
      SetString(ExtUp, PAnsiChar(@PByteArray(URL)[ExtPos - 1]),
        Len - ExtPos + 1);
    for Index := 0 to Length(ExtUp) - 1 do
      if PByteArray(ExtUp)[Index] in [Ord('a')..Ord('z')] then
        Dec(PByteArray(ExtUp)[Index], $20);
  end else
    ExtUp := '';

  if EnableCacheBustingBeforeExt and (ExtPos > 0) then
    for Index := ExtPos - 1 downto 1 do
      case URL[Index] of
        '/': Break;
        '.':
          begin
            Delete(Path, Index, ExtPos - Index);
            Break;
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

procedure TBoilerplateHTTPServer.UpArrayFromCSV(const CSV: SockString;
  var Values: TSockStringDynArray; const PrefixUp, PostfixUp: SockString;
  const Sep: AnsiChar);
var
  Index, DeduplicateIndex, Count: Integer;
  ArrayDA: TDynArray;
  P: PUTF8Char;
  Value: RawUTF8;
begin
  if CSV = '' then
  begin
    Values := nil;
    Exit;
  end;
  ArrayDA.Init(TypeInfo(TRawUTF8DynArray), Values, @Count);
  P := Pointer(CSV);
  while P <> nil do
  begin
    GetNextItem(P, Sep, Value);
    if Value <> '' then
    begin
      UpperCaseSelf(Value);
      if (PrefixUp <> '') and (PostfixUp <> '') then
        Value := FormatUTF8('%%%', [PrefixUp, Value, PostfixUp])
      else if PrefixUp <> '' then
        Value := FormatUTF8('%%', [PrefixUp, Value])
      else if PostfixUp <> '' then
        Value := FormatUTF8('%%', [Value, PostfixUp]);
      ArrayDA.Add(Value);
    end;
  end;
  if Count <= 1 then
    SetLength(Values, Count)
  else begin
    ArrayDA.Sort(SortDynArrayPUTF8Char);
    DeduplicateIndex := 0;
    for Index := 1 to Count - 1 do
      if Values[DeduplicateIndex] <> Values[Index] then
      begin
        Inc(DeduplicateIndex);
        if DeduplicateIndex <> Index then
          Values[DeduplicateIndex] := Values[Index];
      end;
    SetLength(Values, DeduplicateIndex + 1);
  end;
end;

end.
