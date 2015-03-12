express-camo
===
Save remote files to local directory, send it to clients

[![NPM version][npm-image]][npm-url] [![Build Status][travis-image]][travis-url]

# Serve file with nginx internal request with X-Accel-Redirect header

```conf
server {
    listen 80;
    server_name file.localhost;
    location / {
        proxy_pass http://127.0.0.1:3000;
    }
    location /camo {
        internal;
        alias /you/path/to/express-camo/tmp;
        break;
    }
}
```

# Options
```
tmpDir: path.join __dirname, '../tmp'   # Save files to the tmp directory, this will also be the nginx alias property
expire: 86400000                        # Save the file for the expire milliseconds
urlPrefix: '/camo'                      # The url prefix in nginx location block
getUrl: (req) -> req.query.url          # Get url param by your way
store:                                  # Define your store or use the default redis store (every store should have  getMime/setMime function)
```

[npm-url]: https://npmjs.org/package/express-camo
[npm-image]: http://img.shields.io/npm/v/express-camo.svg

[travis-url]: https://travis-ci.org/sailxjx/express-camo
[travis-image]: http://img.shields.io/travis/sailxjx/express-camo.svg
