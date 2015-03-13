express = require 'express'
camo = require '../'

app = express()
app.use camo()

app.listen 3000, -> console.log 'server listen on 3000'
