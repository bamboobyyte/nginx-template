#!/bin/bash

# Check if the script is running in sudo mode
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Ask for the host name of the website
read -p "Enter the host name of the website [_]: " hostname
hostname=${hostname:-_}

# Determine the configuration file name
if [ "$hostname" = "_" ]; then
    config_file_name="default"
else
    config_file_name="$hostname"
fi

# Check if the configuration file already exists and ask for override
config_file_path="/etc/nginx/sites-available/$config_file_name"
if [ -f "$config_file_path" ]; then
    read -p "Configuration file $config_file_path already exists. Override? [Y/n]: " override
    override=${override:-y}
    if [ "$override" = "n" ]; then
        echo "Exiting without overriding the existing configuration file."
        exit 0
    fi
fi

# Continue with the rest of the configuration
read -p "Enter the upstream pool name [backend-name]: " pool_name
pool_name=${pool_name:-backend-name}
read -p "Enter the upstream host [127.0.0.1]: " upstream_host
upstream_host=${upstream_host:-127.0.0.1}
read -p "Enter the upstream port [8080]: " upstream_port
upstream_port=${upstream_port:-8080}

# Ask for authentication method
echo "Select authentication method:
    1. None, 
    2. Basic Auth, 
    3. Client Cert Auth)"
read -p "Choice [1]: " auth_choice
auth_choice=${auth_choice:-1}

# Basic auth
if [ "$auth_choice" -eq 2 ]; then
    read -p "Enter the user file location [/etc/apache2/]: " user_file_location
    user_file_location=${user_file_location:-/etc/apache2/}
    read -p "Enter the user file name [.htpasswd]: " user_file_name
    user_file_name=${user_file_name:-.htpasswd}
fi

# Client cert auth
if [ "$auth_choice" -eq 3 ]; then
    read -p "Enter the client root cert location [/etc/nginx/certs/]: " client_cert_path
    client_cert_path=${client_cert_path:-/etc/nginx/certs/}
    ls -l "$client_cert_path"
    read -p "Enter the index of the cert file: " client_cert_index
    client_cert_file=$(ls "$client_cert_path" | sed -n "${client_cert_index}p")
fi

# Ask for if enable HTTPS
read -p "Enable HTTPS [Y/n]: " enable_https
enable_https=${enable_https:-y}

if [ "$enable_https" = "y" ]; then
    # Ask for SSL certificate and key
    read -p "Enter the SSL cert location [/etc/nginx/certs/]: " server_cert_path
    server_cert_path=${server_cert_path:-/etc/nginx/certs/}
    ls -l "$server_cert_path"
    read -p "Enter the index of the cert file: " server_cert_index
    server_cert_file=$(ls "$server_cert_path" | sed -n "${server_cert_index}p")

    read -p "Enter the SSL key location [/etc/nginx/certs/]: " server_key_path
    server_key_path=${server_key_path:-/etc/nginx/certs/}
    ls -l "$server_key_path"
    read -p "Enter the index of the cert file: " server_key_index
    server_key_file=$(ls "$server_key_path" | sed -n "${server_key_index}p")
fi

# Ask for log file paths and names
access_log_file="/var/log/nginx/$config_file_name.access.log"
error_log_file="/var/log/nginx/$config_file_name.error.log"

# Ask for HTTP to HTTPS redirect
if [ "$enable_https" = "y" ]; then
    read -p "Enable HTTP to HTTPS redirect? [Y/n]: " redirect_http
    redirect_http=${redirect_http:-y}
else
    redirect_http="n"
fi

# Create config file
echo "Creating NGINX config file at $config_file_path"

{
    echo "upstream $pool_name {"
    echo "    server $upstream_host:$upstream_port;"
    echo "}"
    echo ""

    echo "# HTTP - configuration"
    echo "server {"
    echo "    listen 80;"
    echo "    server_name $hostname;"
    echo ""
    if [ "$redirect_http" = "y" ]; then
        echo "    # Redirect all HTTP requests to HTTPS"
        echo "    return 301 https://\$host\$request_uri;"
    else
        # Repeat configuration for HTTP when not redirecting
        if [ "$auth_choice" -eq 2 ]; then
            echo "    # Basic auth"
            echo "    auth_basic \"Restricted\";"
            echo "    auth_basic_user_file $user_file_location$user_file_name;"
            echo ""
        elif [ "$auth_choice" -eq 3 ]; then
            echo "    # Client cert auth"
            echo "    ssl_client_certificate $client_cert_path$client_cert_file;"
            echo "    ssl_verify_client on;"
            echo ""
        fi
        echo "    # Logs"
        echo "    access_log $access_log_file;"
        echo "    error_log $error_log_file;"
        echo ""
        echo "    # Reverse proxy configuration"
        echo "    location / {"
        echo "        proxy_pass http://$pool_name;"
        echo "        proxy_buffering off;"
        echo "        proxy_http_version 1.1;"
        echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
        echo "        proxy_set_header Upgrade \$http_upgrade;"
        echo "        proxy_set_header Connection \"upgrade\";"
        echo "    }"
    fi
    echo "}"
    if [ "$enable_https" = "y" ]; then
        echo ""
        echo "# HTTPS - configuration"
        echo "server {"
        echo "    listen 443 ssl;"
        echo "    server_name $hostname;"
        echo ""
        if [ "$auth_choice" -eq 2 ]; then
            echo "    # Basic auth"
            echo "    auth_basic \"Restricted\";"
            echo "    auth_basic_user_file $user_file_location$user_file_name;"
            echo ""
        elif [ "$auth_choice" -eq 3 ]; then
            echo "    # Client cert auth"
            echo "    ssl_client_certificate $client_cert_path$client_cert_file;"
            echo "    ssl_verify_client on;"
            echo ""
        fi
        echo "    # SSL configuration"
        echo "    ssl_certificate $server_cert_path$server_cert_file;"
        echo "    ssl_certificate_key $server_key_path$server_key_file;"
        echo ""
        echo "    # Logs"
        echo "    access_log $access_log_file;"
        echo "    error_log $error_log_file;"
        echo ""
        echo "    # Reverse proxy configuration"
        echo "    location / {"
        echo "        proxy_pass http://$pool_name;"
        echo "        proxy_buffering off;"
        echo "        proxy_http_version 1.1;"
        echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
        echo "        proxy_set_header Upgrade \$http_upgrade;"
        echo "        proxy_set_header Connection \"upgrade\";"
        echo "    }"
    echo "}"
    fi
} > "$config_file_path"

# Ask if need to enable the config by creating a soft link
read -p "Enable this site? [Y/n]: " enable_site
enable_site=${enable_site:-y}

if [ "$enable_site" = "y" ]; then
    ln -s "$config_file_path" "/etc/nginx/sites-enabled/$config_file_name"
    echo "Site enabled."
fi

echo "Configuration completed."
