express-camo
===
Save remote files to local directory, send it to clients

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
