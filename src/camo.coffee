path = require 'path'
fs = require 'fs'
utilLib = require 'util'
request = require 'request'

util = require './util'
redisStore = require './store'

camo = (options = {}) ->

  _options = utilLib._extend
    tmpDir: path.join __dirname, '../tmp'   # Save files to the tmp directory, this will also be the nginx alias property
    expire: 86400000                        # Save the file for the expire milliseconds
    urlPrefix: '/camo'                      # The url prefix in nginx location block
    getUrl: (req) -> req.query.url          # Get url param by your way
    onError: false                          # Error handler when fire an error
  , options

  # Initialize mime store
  store = _options.store or redisStore(require('redis').createClient())(_options)

  {tmpDir, expire, urlPrefix, onError} = _options

  _camo = (req, res, next) ->

    url = _options.getUrl(req)

    return next(new Error('invalid url')) unless /^(http|https):\/\//.test url

    basePath = "#{Math.floor(Date.now() / expire)}"
    _tmpDir = path.join tmpDir, basePath

    fs.mkdirSync _tmpDir unless fs.existsSync _tmpDir

    # Base name should only contain letters
    baseName = "#{util.md5(url)}#{path.extname(url).match(/^\.[0-9a-z]+/i)?[0] or ''}"
    filePath = path.join _tmpDir, baseName
    redirectPath = path.join urlPrefix, basePath, baseName
    responsed = false

    fs.exists filePath, (exists) ->
      if exists
        store.getMime baseName, (err, mime) ->
          return if responsed
          res.set 'Content-Type', mime if mime
          res.set 'X-Accel-Redirect', redirectPath
          responsed = true
          res.end()
      else
        file = fs.createWriteStream filePath
        mime = null

        _errHandler = (err) ->
          return if responsed
          file.close()
          fs.unlink filePath
          if toString.call(onError) is '[object Function]'
            return onError err, req, res, next
          next err

        request.get
          url: url
          headers: 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36'

        .on 'response', (_res) ->

          if _res.statusCode >= 200 and _res.statusCode < 300

            if _res.headers?['content-type']
              mime = _res.headers['content-type']
              store.setMime baseName, mime, ->

            file.on 'finish', ->
              file.close()
              return if responsed
              res.set 'Content-Type', mime if mime
              res.set 'X-Accel-Redirect', redirectPath
              responsed = true
              res.end()
            _res.pipe file

          else _errHandler(new Error('request failed'))

        .on 'error', _errHandler

camo.util = util
camo.redisStore = redisStore

module.exports = camo
