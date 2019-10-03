Version 1.0.0
  - First public release

Version 1.1.0
  - minor "Cache-Control" parameters order changes
  - added bpoDelegateIndexToInheritedDefault to delegate index.html to Default()
  - added bpoDelegate404ToInherited_404 to delegate 404.html to _404()

Version 1.2.0
  - fix "Accept-Encoding" parsing when gzip in the end of encodings list
  - make Pre-Build events notice more visible in tests and demo
  - minor code refactoring

Version 1.3.0
  - fix bug in packassets tool when asset name started with '.'

Version 1.4.0
  - make TAsset to be packed record for better x86/x64 platforms compatibility

Version 1.5.0
 - fix EnableCacheByETag test scenarios

Version 1.6.0
 - add custom options registration
 - add Vary header into http response for compressible resources

Version 1.7.0
 - add custom options registration for group of URLs
 - get rid of system PosEx for better compatibility with Delphi 2007 and below

Version 1.8.0
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
