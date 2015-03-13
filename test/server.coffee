# Fake express server

path = require 'path'
fs = require 'fs'
http = require 'http'
https = require 'https'
express = require 'express'

app = express()

mimeTypes =
  '.jpg': 'image/jpeg'
  '.png': 'image/png'

app.get '/:file', (req, res) ->
  filePath = path.join __dirname, 'assets', req.params.file
  res.set 'Content-Type', mimeTypes[path.extname(req.params.file)]
  res.sendFile filePath

http.createServer(app).listen 3001

httpOptions =
  key: fs.readFileSync(__dirname + '/assets/camo.pem', 'utf8')
  cert: fs.readFileSync(__dirname + '/assets/camo.crt', 'utf8')

https.createServer(httpOptions, app).listen 3002

module.exports = app
