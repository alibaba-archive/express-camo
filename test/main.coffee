path = require 'path'
should = require 'should'
request = require 'supertest'
express = require 'express'
camo = require '../src/camo'

assert = (baseName) ->

fakeStore =
  getMime: -> assert.apply this, arguments
  setMime: -> assert.apply this, arguments

describe 'Basic proxy', ->

  @timeout 5000

  app = express()

  app.use camo
    store: fakeStore

  it 'should get the image from http url and set the correct content-type', (done) ->

    url = "http://h.hiphotos.baidu.com/image/pic/item/d788d43f8794a4c22a6aaa2a0cf41bd5ad6e3961.jpg"

    _baseName = "#{camo.util.md5(url)}#{path.extname(url)}"

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

    url = "https://education.github.com/assets/sdp-backpack-0c38cf04554c7f4d019e62abf3a0bffd.png"

    _baseName = "#{camo.util.md5(url)}#{path.extname(url)}"

    # The file is not exist, check baseName and mime from store.setMime
    assert = (baseName, mime, callback) ->
      baseName.should.eql "#{camo.util.md5(url)}#{path.extname(url)}"
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

    url = "http://h.hiphotos.baidu.com/image/pic/item/d788d43f8794a4c22a6aaa2a0cf41bd5ad6e3961.jpg"

    _baseName = "#{camo.util.md5(url)}#{path.extname(url)}"

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
