upstream backend {
  server 127.0.0.1:8080
}

# HTTP - redirect all requests to HTTPS
server {
    listen 80;
    server_name example.com;

    # Redirect all HTTP requests to HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS - configuration
server {
    listen 443 ssl;
    server_name example.com;

    # SSL configuration added by Certbot
    ssl                  on;
    ssl_certificate      /path/to/cert; 
    ssl_certificate_key  /path/to/key;

    access_log   /var/log/nginx/example.com.access.log;
    error_log    /var/log/nginx/example.com.error.log;

    # Reverse proxy configuration
    location / {
        proxy_pass backend;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
    }
}
