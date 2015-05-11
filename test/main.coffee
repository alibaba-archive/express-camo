path = require 'path'
should = require 'should'
request = require 'supertest'
express = require 'express'
camo = require '../src/camo'
server = require './server'

# Support for self-signed certificate
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

getBaseName = (url) -> "#{camo.util.md5(url)}#{path.extname(url).match(/^\.[0-9a-z]+/i)?[0] or ''}"

assert = (baseName) ->

fakeStore =
  getMime: -> assert.apply this, arguments
  setMime: -> assert.apply this, arguments

describe 'Basic proxy', ->

  app = express()

  app.use camo
    store: fakeStore

  it 'should get the image from http url and set the correct content-type', (done) ->

    url = "http://localhost:3001/http.jpg"

    _baseName = getBaseName url

    # The file is not exist, check baseName and mime from store.setMime
    assert = (baseName, mime, callback) ->
      baseName.should.eql "#{camo.util.md5(url)}#{path.extname(url)}"
      mime.should.eql 'image/jpeg'
      callback null, mime

    request(app)
    .get "?url=#{url}"
    .end (err, res) ->
      res.headers['content-type'].should.eql 'image/jpeg'
      res.headers['x-accel-redirect'].should.containEql _baseName
      res.statusCode.should.eql 200
      done err

  it 'should get the image from https url and set the correct content-type', (done) ->

    url = "https://localhost:3002/https.png"

    _baseName = getBaseName url

    # The file is not exist, check baseName and mime from store.setMime
    assert = (baseName, mime, callback) ->
      baseName.should.eql _baseName
      mime.should.eql 'image/png'
      callback null, mime

    request(app)
    .get "?url=#{url}"
    .end (err, res) ->
      res.headers['content-type'].should.eql 'image/png'
      res.headers['x-accel-redirect'].should.containEql _baseName
      res.statusCode.should.eql 200
      done err

  it 'should get the image from local file system when the file exists', (done) ->

    url = "http://localhost:3001/http.jpg"

    _baseName = getBaseName url

    # The file is exist, should call the store.getMime function
    assert = (baseName, callback) ->
      baseName.should.eql _baseName
      callback null, 'image/jpeg'

    request(app)
    .get "?url=#{url}"
    .end (err, res) ->
      res.headers['content-type'].should.eql 'image/jpeg'
      res.headers['x-accel-redirect'].should.containEql _baseName
      res.statusCode.should.eql 200
      done err

  it 'should get the correct image when the server generate a 302 redirect', (done) ->

    url = 'http://localhost:3001/rdr/302.jpg'

    _baseName = getBaseName url

    assert = (baseName, mime, callback) ->
      baseName.should.eql _baseName
      mime.should.eql 'image/jpeg'
      callback null, mime

    request(app)
    .get "?url=#{url}"
    .end (err, res) ->
      res.headers['content-type'].should.eql 'image/jpeg'
      res.headers['x-accel-redirect'].should.containEql _baseName
      res.statusCode.should.eql 200
      done err

  it 'should get the image when url contains question mark', (done) ->

    url = 'http://localhost:3001/rdr/302.jpg?v1'

    _baseName = getBaseName url

    assert = (baseName, mime, callback) ->
      baseName.should.not.containEql '?'
      baseName.should.eql _baseName
      mime.should.eql 'image/jpeg'
      callback null, mime

    request(app)
    .get "?url=#{url}"
    .end (err, res) ->
      res.headers['content-type'].should.eql 'image/jpeg'
      res.headers['x-accel-redirect'].should.containEql _baseName
      res.statusCode.should.eql 200
      done err

describe 'Option expire', ->

  app = express()

  app.use camo
    store: fakeStore
    expire: 200

  it 'should expire after 200 milliseconds', (done) ->

    url = 'http://localhost:3001/expire.jpg'
    _baseName = getBaseName url

    # Reset assert function
    assert = ->

    request(app).get "?url=#{url}"

    .end (err, res) ->
      should(err).eql null

      # Should set the new mime type of the old file
      assert = (baseName, mime, callback) ->
        baseName.should.eql _baseName
        mime.should.eql 'image/jpeg'
        callback null, mime

      setTimeout ->
        request(app)
        .get "?url=#{url}"
        .end (err, res) ->
          res.headers['content-type'].should.eql 'image/jpeg'
          res.headers['x-accel-redirect'].should.containEql _baseName
          res.statusCode.should.eql 200
          done err
      , 200

describe 'Option getUrl', ->

  app = express()

  app.use '/camo/:file', camo
    store: fakeStore
    getUrl: (req) -> new Buffer(req.params.file, 'base64').toString()

  it 'should parse the base64ed url from getUrl option', (done) ->

    url = 'http://localhost:3001/base64.jpg'

    _baseName = getBaseName url

    assert = (baseName, mime, callback) ->
      baseName.should.eql _baseName
      mime.should.eql 'image/jpeg'
      callback null, mime

    request(app)
    .get "/camo/#{new Buffer(url).toString('base64')}"
    .end (err, res) ->
      res.headers['content-type'].should.eql 'image/jpeg'
      res.headers['x-accel-redirect'].should.containEql _baseName
      res.statusCode.should.eql 200
      done err
