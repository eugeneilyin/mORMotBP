<div align="center">

<img src="/Tests/Assets/img/marmot.jpg" alt="mORMotBP" style="max-width:100%;">
<h1>mORMotBP</h1>
<h3>Boilerplate HTTP Server for Synopse mORMot Framework</h3>
</div>

This project is embedding of **HTML5 Boilerplate** v.7.3.0 files and settings into **Synopse mORMot Framework**
  * [html5boilerplate.com][boilerplate]
  * [synopse.info][synopse-mormot]

## Quick Start

1. Download the latest mORMotBP [release][releases] from GitHub repository
2. Add the next two **Pre-Build** events to create resource file `Assets.res` with all **h5bp** resources embedded:
  * `"..\Tools\assetslz" "$(PROJECTDIR)\Assets" "$(PROJECTDIR)\assets.tmp"`
  * `"..\Tools\resedit" -D "$(PROJECTDIR)\Assets.res" rcdata ASSETS "$(PROJECTDIR)\assets.tmp"`
> Replace `"..\Tools"` to mORMorBP relative or full directory location. Also you can add Tools directory to your **PATH** environment veriable and use `assetslz` and `resedit` commands directly.
3. Add `mORMotBP` to your library path or add `BoilerplateAssets.pas`, `BoilerplateHTTPServer.pas` files to the project
4. Replace `TSQLHttpServer` instance creation with `TBoilerplateHTTPServer`
5. Load assets to server instance by calling `YourHTTPServerInstance.LoadFromResource('Assets');`

## Features

* Fully aligned with **HTML5 Boilerplate** HTTP configs with more than **50+** options and properties.
* Designed for **Delphi 6** up to **Delphi 10.3 Rio**, **Kylix 3** (over CrossKylix), and **FPC**, targeting **Windows** or **Linux**, **32-bit** or **64-bit** architectures.
* Embed all static assets into application file as highly compressed **synlz** archive (see `assetslz` and `resedit` tools). This allows to build single file distribution fully aligned with **Instant Deployment** approach.
* Save your cloud hosting **Disk IO** operations by return all static assets from mem-cached repository.
* Don't spend **CPU cycles** to assets compression, all your assets will be pre-compressed by `assetslz` tool.
* Support **GZip Level 9** maximum compression.
* Support **Zopfli** compression (save up to **5-15%** of traffic and delivery time compared to max GZip compression).
* Support **Brotli** compression as per RFC 7932 (save another **15%-25%** of traffic and delivery time compared to Zopfli compression).
* Ability to delegate compressed files transferring to low-level `HTTP.sys` high-performance library (see `.StaticRoot` property) and free your server threads for more interesting work.
* Support `ETag/Last-Modified` or more user-friendly `Last-Modified/If-Modified-Since` cache strategies.
* Server-side `Expires` or `Cache-Control: max-age` cache strategies.
* Different cache busting strategies (see `bpoEnableCacheBusting` and `bpoEnableCacheBustingBeforeExt` options).
* Fix well-known mangled **Accept-Encoding** values in HTTP headers.
* Block access to files that can expose sensitive information (see `bpoDelegateBlocked` option).
* Apply many HTTP headers corrections following **HTML5 Boilerplate** settings.
* Support **Content Security Policy** Level 2 / Level 3 (see `CSP.pas` unit for details).
* You can safely replace anywhere your **TSQLHttpServer** with `TBoilerplateHTTPServer = class(TSQLHttpServer)`.

## Lazarus Free Pascal support

To build or update `Assets.res` file under Lazarus IDE use the next menu (when project file is opened):

  `Run / Build File`

This menu command call **pre-build.sh** script which is use `assetslz32`/`assetslz64` and `resedit32`/`resedit64` tools to compress and embed assets under Linux environment.

Add the next FPC Lazarus IDE directive to any project file for ability to rebuild resource files:

```delphi
{%BuildCommand pre-build.sh $ProjPath()}
```

## Delphi 6/7/2005/2006 support

Many thanks to [Kiran Kurapaty][kiran-kurapaty] with his BuildOptions package for Delphi 5 and Delphi 7.
Based on his code the modified IDE packages for Delphi 5/6/7/2005/2006 were created to enable Build Events support on all Delphi IDE versions before Delphi 2007, where Build Events were introduced for the first time.

Use **Component / Install Packages / Add** IDE menu to install **Build Events** IDE extension:
* `Tools\BuildEvents\BuildEventsD5.bpl` for **Delphi 5**
* `Tools\BuildEvents\BuildEventsD6.bpl` for **Delphi 6**
* `Tools\BuildEvents\BuildEventsD7.bpl` for **Delphi 7**
* `Tools\BuildEvents\BuildEventsD2005.bpl` for **Delphi 2005**
* `Tools\BuildEvents\BuildEventsD2006.bpl` for **Delphi 2006**

With this build events and special `.bat` file you can emulate `DEBUG` and `RELEASE` configurations. 
Please see the Build Events [readme][build-events-readme] for details.
              
## Recommended `DEBUG` configuration

Due to 80 times slower compression nature of Zopfli algorithm it is not reasonable to use it during project development and debug.
So for all debug configurations you can use fast and light level 1 compression with `-GZ1 -B1` options of **assetslz** tool:
  * `"..\Tools\assetslz" -GZ1 -B1 "$(PROJECTDIR)\Assets" "$(PROJECTDIR)\assets.tmp"`
  * `"..\Tools\resedit" -D "$(PROJECTDIR)\Assets.res" rcdata ASSETS "$(PROJECTDIR)\assets.tmp"`

## Recommended `RELEASE` configuration

For release configuration it is recommended to turn on `bpoForceHTTPS`, and set `.StrictSSL` property to `strictSSLOn` or 
even `strictSSLIncludeSubDomains`. Setup `.ContentSecurityPolicy` property and validate it 
with [Security Headers][security-headers] service (see `CSP.pas` unit for details).

### Disable `Server` HTTP header on production

For security reasons you can fully disable `Server` and `X-Powered-By` HTTP Headers on production.
To do this add `NOXPOWEREDNAME` define to **Project / Options / Conditional defines** and rebuild all.

If you use `HTTP.sys` API on Windows Server add or modify the next registry key to disable `Server` HTTP header embedding (admin rights required):

Section: `SYSTEM\CurrentControlSet\Services\HTTP\Parameters`

Key: `DisableServerHeader: DWORD = 2`

## Advanced `TAssets` usage

You can embed any directories or files into your **single** project executable file. 
This gives you an ability to distribute, scale and run only one file on yours production environments.
Load from resource and deploy any assets on your production when it started. `TAssets` also checks files for modification timestamp and size changes before save to optimize disk IO operations.

For example you can compress and pack all you static assets into `Assets.res` and additionally pack mustache view templates into separate `Views.res` like this:

  * `"..\Tools\assetslz" "$(PROJECTDIR)\Assets" "$(PROJECTDIR)\assets.tmp"`
  * `"..\Tools\resedit" -D "$(PROJECTDIR)\Assets.res" rcdata ASSETS "$(PROJECTDIR)\assets.tmp"`
  * `"..\Tools\assetslz" -E "$(PROJECTDIR)\Views" "$(PROJECTDIR)\views.tmp"`
  * `"..\Tools\resedit" -D "$(PROJECTDIR)\Views.res" rcdata VIEWS "$(PROJECTDIR)\views.tmp"`

The `-E` option for views means skip any compression because we needn't to compress mustache views.
Now you can embed both resources files into executable.
Add the next lines to you project file near `{$R *.res}` or add both files to project:

```delphi
{$R Assets.res}
{$R Views.res}
```

Then on production, you can extract views from executable like this:

```delphi

procedure SaveViews;
var
  Assets: TAssets;
begin
  Assets.Init;
  Assets.LoadFromResource('Views');
  Assets.SaveAllIdentities('Views');
end;
```

## Custom options

With `RegisterCustomOptions` method you can tweak different options for different HTTP URL paths.
For example, you can disable cache usage for you API JSON calls or some special pages like this:

```delphi
  HTTPServer.RegisterCustomOptions(
    ['/api/json', '/login', '/settings*'],
    HTTPServer.Options - [bpoSetCachePublic] + [bpoSetCachePrivate,
      bpoSetCacheNoCache, bpoSetCacheNoStore, bpoSetCacheMustRevalidate]);
```

## Test Suite

The `TBoilerplateHTTPServer` is fully test covered with **mORMot Test Suite** framework. Instead of classical **TDD** approach the **Behavior-Driven Development (BDD)** scenarios are used. Please see [`Tests\BoilerplateTests.pas`][tests] for details.

## Change Log
This project adheres to [Semantic Versioning][semver].
Every release, along with the migration instructions, is documented on the GitHub [Releases][releases] page.

## License

The code is available under the [MIT license][license].

## Contacts

Feel free to contact me at **@gmail.com**: **eugene.ilyin**

[marmot]: /Tests/Assets/img/marmot.jpg
[boilerplate]: https://html5boilerplate.com
[synopse-mormot]: https://synopse.info/fossil/wiki?name=SQLite3+Framework
[releases]: https://github.com/eugeneilyin/mORMotBP/releases
[dist]: /Dist
[security-headers]: https://securityheaders.com
[kiran-kurapaty]: https://kurapaty.wordpress.com/about-2
[build-events-readme]: /Tools/BuildEvents/README
[tests]: /Tests/BoilerplateTests.pas
[license]: /License.txt
[semver]: http://semver.org
