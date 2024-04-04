# NGINX Template :computer:

Welcome to `nginx-template`! This repository serves as a starting point for NGINX configuration, providing basic templates and scripts to streamline your web server setup.

## Purpose :dart:
`nginx-template` aims to eliminate the hassle of writing NGINX configuration files from scratch. It provides a basic, yet essential, template to kickstart your NGINX setup, ensuring a quicker and more efficient deployment.

## Getting Started :rocket:

### Prerequisites
- NGINX installed on your machine.
- Sudo privileges for script execution.

### Usage
To use the `nginx-template`, you have two main options:

1. **Manual Configuration:**
   - Copy the `example.com` file to your `/etc/nginx/sites-available` directory to use as a starting point for your site configuration.

2. **Using the `newsite` Script:**
   - Execute the `newsite` script to automatically configure a new site. This script requires sudo privileges:
     ```
     sudo ./newsite
     ```

## Contributing :handshake:
Contributions to `nginx-template` are welcome! If you have suggestions or improvements, feel free to fork the repo and submit a pull request.

## License :page_facing_up:
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.