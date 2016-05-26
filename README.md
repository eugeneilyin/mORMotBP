# mORMotBP
Boilerplate HTTP Server for Synopse mORMot Framework

This project is embedding of **HTML5 Boilerplate** apache server settings into **Synopse mORMot Framework**
  * http://synopse.info
  * https://html5boilerplate.com
  
###Project goals
  1. Provide memcached HTTP static access for Web projects based on **Synopse mORMot Framework**
  2. Eliminate **disk IO** operations for faster in-memory assets access (for example on cloud hosting)
  3. Predefine `content type` for known assets with all **HTML5 Boilerplate** recomendations
  4. Precalculate `content hash` for HTTP ETag cache management
  5. Embed `.zynlz` archive as single `RT_RCDATA` resource during project pre-build event
  6. Apply `ETag/Last-Modified` or more user-friendly `Last-Modified/If-Modified-Since` cache strategies
  8. Apply `Cache-Control` or `Expires`  browsers cache strategies on the client side
  7. Apply all HTTP headers corrections following **HTML5 Boilerplate** apache settings
  9. Decomress all assets into any production server directory with pattern filtering (for example 
  this feature allows to delegate content transferring from server code to `http.sys` windows kernel mode.
  All you need is preliminary decompress asset somewhere on server and told mORMot Framework that content
  is a `!STATIC` file. You can even transfer gzipped files on a kernel `http.sys` windows level).
  
Fill free to contact me at **@gmail.com**: **eugene.ilyin**

(c) 2016 Yevgeny Iliyn
