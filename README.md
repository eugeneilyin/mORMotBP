![mORMotBP](/Tests/Assets/img/marmot.jpg)

# mORMotBP
Boilerplate HTTP Server for Synopse mORMot Framework

This project is embedding of **HTML5 Boilerplate** v.5.3.0 apache server settings into **Synopse mORMot Framework**
  * http://synopse.info
  * https://html5boilerplate.com

## Quick Start

1. Download and unpack the latest mORMotBP release from GitHub [**Dist**](/Dist/) directory
2. Add the next three project **Pre-Build** events (to embed all **h5bp** assets as application resource file):
  * `Tools\assetslz.exe Assets Assets.synlz`
  * `Tools\resedit.exe $(INPUTNAME).res rcdata ASSETS Assets.synlz`
  * `DEL Assets.synlz`
3. Add `BoilerplateAssets.pas` and `BoilerplateHTTPServer.pas` files into your project
4. Replace your `TSQLHttpServer` instance creation with `TBoilerplateHTTPServer`
5. Add assets decompression by calling `YourHTTPServerInstance.LoadFromResource('Assets');`

## Features

* Embed all your mORMot project assets **as resource** into application file as highly compressed **synlz** archive
* Allows to build single file distributions (fully aligned with **Instant Deployment** approach)
* Save your cloud hosting **Disk IO** operations by return all static assets from mem-cached repository
* Fully aligned with **HTML5 Boilerplate** Apache Server configs with more than *35+* options and properties
* Server side `ETag/Last-Modified` or more user-friendly `Last-Modified/If-Modified-Since` cache strategies
* Browsed side `Expires` or `Cache-Control: max-age` cache strategies
* Pre-compressed **GZip** variants of all assets, up to maximum level 9 compression
* Fix well known mangled **"Accept-Encoding"** values in HTTP headers
* Apply all HTTP headers corrections following **HTML5 Boilerplate** apache settings
* Delegate all static assets transferring to low-level API (e.g. `http.sys`) even GZipped content!
* You can safely replace anywhere your **TSQLHttpServer** with `TBoilerplateHTTPServer = class(TSQLHttpServer)`

## Test Suite

The `TBoilerplateHTTPServer` is fully test covered with **mORMot Test Suite** framework. Instead of classical **TDD** approach more modern **Behaviour Driven Development (BDD)** scenarios are used. Please see `Tests\mORMotBPTests.dpr` test project.

## License

The code is available under the [MIT license](License.txt).

## Contacts

Feel free to contact me at **@gmail.com**: **eugene.ilyin**
