# Turbo Setup WordPress on Codespace Script
This repository contains a Bash script to automate the setup, configuration, and deployment of a WordPress environment in a Codespace environment. This script helps to streamline the installation of WordPress along with Apache2, PHP, MySQL, and Docker, providing an easy setup for a local or cloud-based development environment. Additionally, it offers options for data backup and domain provisioning through serveo.net.
## Features
- **Automated WordPress Setup**: Installs and configures WordPress, Apache2, PHP 8.0, and MySQL on your development environment.
- **Domain Provisioning**: Uses SSH tunneling with Serveo for public domain access.
- **Docker Integration**: Sets up MySQL in a Docker container to isolate the database environment.
- **Data Backup**: Creates and compresses WordPress and MySQL data files for easy backup.
- **Interactive Command-Line Interface**: Presents an intuitive selection menu for setup, data creation, and domain login actions.
## Requirements
- **Codespace or Local Development Environment** with:
  - **Bash** (Shell environment)
  - **Docker** (for MySQL container)
  - **Serveo.net account** for domain tunneling (optional)
- **Packages**: `apache2`, `php8.0`, `autossh`, `wget`, `unzip`, `zip`
## Installation
To install and run the script, execute the following command:
```bash
curl -O https://tbwp.vercel.app/script.sh && chmod +x script.sh && ./script.sh
```
## Usage
The script provides the following options through a command-line interface:
1. **Set up WordPress**: Installs and configures WordPress with Apache2, PHP, and MySQL Docker container.
2. **Create Data Files**: Backs up MySQL and WordPress data into compressed files (`mysql_data.zip` and `wordpress.zip`).
3. **Log in to Domain Provider (serveo.net)**: Establishes an SSH tunnel with serveo.net, providing public access to your WordPress site.
### Details of Each Option
#### 1. Set up WordPress
   - **Domain Setup**: Configures a domain with serveo.net if SSH keys are available.
   - **Apache2 and PHP Configuration**: Sets up Apache2 as the web server and installs PHP 8 with necessary modules.
   - **Database Setup**: Uses Docker to run MySQL with specified database and user credentials.
   - **WordPress Installation**: Downloads WordPress files, updates configuration settings in `wp-config.php`, and transfers files to `/var/www/html`.
#### 2. Create Data Files
   - **WordPress Backup**: Compresses the WordPress files and configuration into `wordpress.zip`.
   - **MySQL Backup**: Compresses the MySQL data files in `mysql_data.zip` for easy backup and restoration.
#### 3. Log in to Domain Provider (serveo.net)
   - **SSH Key Generation**: Generates an SSH key if not already present.
   - **SSH Tunnel**: Establishes an SSH tunnel with serveo.net to make the WordPress site publicly accessible.
## Script Structure
- **Functions**:
  - `center_text`: Centers text for display in the terminal.
  - `setup_wordpress`: Manages the installation and configuration of WordPress and its dependencies.
  - `create_data_files`: Backs up WordPress and MySQL data.
  - `login_domain_provider`: Sets up the SSH tunnel with serveo.net.
- **Options Menu**: Presents users with an interactive menu to choose from the available options based on environment conditions (e.g., SSH key availability).
## Troubleshooting
- **Permission Errors**: Ensure you have the necessary permissions to execute the script (`chmod +x script.sh`) and to write to `/var/www/html`.
- **Docker Issues**: Verify Docker is installed and running.
- **SSH Tunnel Errors**: Check that autossh and the SSH keys are correctly set up for tunneling with serveo.net.
## Contributing
Contributions are welcome! Please fork this repository, create a feature branch, and submit a pull request.