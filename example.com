upstream backend-name {
  server 127.0.0.1:8080;
}

# HTTP - configuration
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

    # Auth
    # Basic auth
    # auth_basic "";
    # auth_basic_user_file /etc/apache2/.htpasswd;
    # Client cert auth
    # ssl_client_certificate /path/to/root/cert;
    # ssl_verify_client on;

    # SSL configuration added by Certbot
    ssl_certificate      /path/to/cert; 
    ssl_certificate_key  /path/to/key;

    # Logs
    access_log   /var/log/nginx/example.com.access.log;
    error_log    /var/log/nginx/example.com.error.log;

    # Reverse proxy configuration
    location / {
        proxy_pass http://backend-name;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
    }

    # Custom error pages
    # 40x errors
    error_page 400 401 403 404 405 406 407 408 409 /40x.html;
    location = /40x.html {
        root /usr/share/nginx/error;
        internal;
    }
    # 50x errors
    error_page 500 501 502 503 504 505 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/error;
        internal;
    }
}
