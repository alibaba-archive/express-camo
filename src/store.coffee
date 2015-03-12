store = (redis) ->

  return (options) ->

    {expire} = options

    _store =
      getMime: (baseName, callback = ->) ->
        baseName = "camo:#{baseName}"
        redis.get baseName, callback

      setMime: (baseName, mime, callback = ->) ->
        baseName = "camo:#{baseName}"
        redis.setex baseName, expire/1000, mime, callback

module.exports = store
