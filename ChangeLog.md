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
  - fix bug in assetslz tool when asset name started with '.'

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
