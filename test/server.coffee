camo = require '../src/camo'
express = require 'express'
app = express()

app.use camo()

module.exports = app
