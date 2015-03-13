###*
 * Test files:
 * - http://h.hiphotos.baidu.com/image/pic/item/d788d43f8794a4c22a6aaa2a0cf41bd5ad6e3961.jpg
 * - https://education.github.com/assets/sdp-backpack-0c38cf04554c7f4d019e62abf3a0bffd.png
###
path = require 'path'
fs = require 'fs'
util = require './util'
utilLib = require 'util'
urlLib = require 'url'
http = require 'http'
https = require 'https'
redisStore = require './store'

camo = (options = {}) ->

  _options = utilLib._extend
    tmpDir: path.join __dirname, '../tmp'   # Save files to the tmp directory, this will also be the nginx alias property
    expire: 86400000                        # Save the file for the expire milliseconds
    urlPrefix: '/camo'                      # The url prefix in nginx location block
    getUrl: (req) -> req.query.url          # Get url param by your way
  , options

  # Initialize mime store
  store = _options.store or redisStore(require('redis').createClient())(_options)

  {tmpDir, expire, urlPrefix} = _options

  basePath = "#{Math.floor(Date.now() / expire)}"
  tmpDir = path.join tmpDir, basePath

  fs.mkdirSync tmpDir unless fs.existsSync tmpDir

  _camo = (req, res, next) ->

    url = _options.getUrl(req)

    return next(new Error('invalid url')) unless /^(http|https):\/\//.test url

    baseName = "#{util.md5(url)}#{path.extname(url)}"
    filePath = path.join tmpDir, baseName
    redirectPath = path.join urlPrefix, basePath, baseName

    fs.exists filePath, (exists) ->
      if exists
        store.getMime baseName, (err, mime) ->
          res.set 'Content-Type', mime if mime
          res.set 'X-Accel-Redirect', redirectPath
          res.end()
      else
        file = fs.createWriteStream filePath
        mime = null

        switch
          when url.indexOf('https://') is 0 then httpLib = https
          else httpLib = http

        _errHandler = (err) ->
          file.close()
          fs.unlink filePath
          next err

        httpLib
        .get url, (_res) ->
          if _res.statusCode is 200 and _res.headers?['content-type']
            mime = _res.headers['content-type']
            store.setMime baseName, mime, ->

            _res.pipe file

            file.on 'finish', ->
              file.close()
              res.set 'Content-Type', mime if mime
              res.set 'X-Accel-Redirect', redirectPath
              res.end()
          else
            _errHandler(new Error('request failed'))

        .on 'error', _errHandler

        .end()

camo.util = util
camo.redisStore = redisStore

module.exports = camo
