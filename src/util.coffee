crypto = require 'crypto'

module.exports =
  md5: (str = '') ->
    crypto.createHash('md5').update(str).digest('hex')
