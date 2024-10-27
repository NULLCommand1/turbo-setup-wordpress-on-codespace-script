#!/bin/bash
mkdir -p /workspaces/codespaces-blank
cd /workspaces/codespaces-blank
center_text() {
    local text="$*"
    local width=$(tput cols)
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}
options=("Set up WordPress" "Create data files" "Log in to domain provider (serveo.net)")
selected=0
if [ -d "$HOME/.ssh" ]; then
    valid_options=(0 1)
else
    valid_options=(2)
fi
while true; do
    clear
    echo -e "\e[32m$(center_text 'Turbo Setup WordPress on Codespace Script - Version 0.1.0')\e[0m"
    for i in "${!options[@]}"; do
        if [ -d "$HOME/.ssh" ]; then
            if [ $i -eq 2 ]; then
                echo -e "\e[90m$(center_text "  ${options[$i]} (disabled)")\e[0m"
            elif [ $i -eq $selected ]; then
                echo -e "\e[34m$(center_text "> ${options[$i]}") \e[0m"
            else
                echo "$(center_text "  ${options[$i]}")"
            fi
        else
            if [ $i -eq 0 ] || [ $i -eq 1 ]; then
                echo -e "\e[90m$(center_text "  ${options[$i]} (disabled)")\e[0m"
            elif [ $i -eq $selected ]; then
                echo -e "\e[34m$(center_text "> ${options[$i]}") \e[0m"
            else
                echo "$(center_text "  ${options[$i]}")"
            fi
        fi
    done
    read -rsn1 input 
    case $input in
        $'\x1b') 
            read -rsn1 -t 0.1 input  
            if [[ $input == '[' ]]; then
                read -rsn1 input
                case $input in
                    'A')
                        ((selected--))
                        while [[ ! " ${valid_options[@]} " =~ " $selected " ]] && [ $selected -ge 0 ]; do
                            ((selected--))
                        done
                        if [ $selected -lt 0 ]; then
                            selected=${valid_options[${#valid_options[@]}-1]}
                        fi
                        ;;
                    'B')
                        ((selected++))
                        while [[ ! " ${valid_options[@]} " =~ " $selected " ]] && [ $selected -lt ${#options[@]} ]; do
                            ((selected++))
                        done
                        if [ $selected -ge ${#options[@]} ]; then
                            selected=${valid_options[0]}
                        fi
                        ;;
                esac
            fi
            ;;
        '')  
            if [[ " ${valid_options[@]} " =~ " $selected " ]]; then
                break
            fi
            ;;
    esac
done
setup_wordpress() {
    clear
    if [ ! -d "$HOME/.ssh" ]; then
        echo -e "\e[31mError: Please login to domain provider (serveo.net) before continuing!\e[0m"
        exit 1
    fi
    echo -e "\e[32mStarting WordPress setup...\e[0m"
    echo -e "\e[32mStep 1: Setting up domain.\e[0m"
    read -p "Input domain name (default: domain$(date +'%d%m%H%M%Y')): " domain
    domain="${domain:-domain$(date +'%d%m%H%M%Y')}"
    echo -e "\e[33mDomain name used: $domain.serveo.net\e[0m"
    echo -e "\e[32mDomain setup completed successfully!\e[0m"
    echo -e "\e[32mStep 2: Removing default PHP.\e[0m"
    if sudo rm -rf /usr/local/php; then
        echo -e "\e[32mDefault PHP removed successfully!\e[0m"
    else
        echo -e "\e[31mError: Failed to remove default PHP!\e[0m"
        exit 1
    fi
    echo -e "\e[32mStep 3: Installing and configuring Apache2 for the first time.\e[0m"
    if sudo apt update -y && sudo apt upgrade -y && sudo apt install apache2 -y && sudo a2dissite 000-default.conf && sudo a2dissite default-ssl.conf && sudo service apache2 start; then
        echo -e "\e[32mApache2 installed and configured successfully!\e[0m"
    else
        echo -e "\e[31mError: Failed to install and configure Apache2!\e[0m"
        exit 1
    fi
    echo -e "\e[32mStep 4: Installing PHP 8.\e[0m"
    if sudo apt install software-properties-common -y && \
       sudo add-apt-repository ppa:ondrej/php -y && \
       sudo apt update -y && \
       sudo apt install php8.0 php8.0-mysql php8.0-xml php8.0-curl php8.0-gd php8.0-mbstring php8.0-zip libapache2-mod-php8.0 -y && \
       sudo a2enmod php8.0 && \
       sudo service apache2 restart; then
        echo -e "\e[32mPHP 8 and required modules installed successfully!\e[0m"
    else
        echo -e "\e[31mError: Failed to install PHP 8 and required modules!\e[0m"
        exit 1
    fi
    echo -e "\e[32mStep 5: Setting password for MySQL database.\e[0m"
    read -p "Input password for MySQL database (default: 1234567@@!): " mysql_password
    mysql_password="${mysql_password:-1234567@@!}"
    echo -e "\e[33mMySQL password used: $mysql_password\e[0m"
    echo -e "\e[32mMySQL database password set successfully!\e[0m"
    echo -e "\e[32mStep 6: Installing WordPress resources.\e[0m"
    if [ -f "wordpress.zip" ]; then
        echo -e "\e[33mFile wordpress.zip exists, unzipping...\e[0m"
        unzip wordpress.zip && rm -rf wordpress.zip || { echo -e "\e[31mError: Failed to unzip wordpress.zip.\e[0m"; exit 1; }
    else
        echo -e "\e[33mFile wordpress.zip does not exist, downloading wordpress.tar.gz...\e[0m"
        wordpress_url="https://wordpress.org/latest.tar.gz"
        wget -q $wordpress_url -O wordpress.tar.gz || { echo -e "\e[31mError: Failed to download WordPress resources.\e[0m" >&2; exit 1; }
        tar -xzf wordpress.tar.gz && rm -rf wordpress.tar.gz || { echo -e "\e[31mError: Failed to extract WordPress resources.\e[0m"; exit 1; }
        cp /workspaces/codespaces-blank/wordpress/wp-config-sample.php /workspaces/codespaces-blank/wordpress/wp-config.php || { echo -e "\e[31mError: Failed to copy wp-config-sample.php.\e[0m"; exit 1; }
        sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', 'wordpressdb' );/" /workspaces/codespaces-blank/wordpress/wp-config.php || { echo -e "\e[31mError: Failed to set DB_NAME in wp-config.php.\e[0m"; exit 1; }
        sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', 'wordpressuser' );/" /workspaces/codespaces-blank/wordpress/wp-config.php || { echo -e "\e[31mError: Failed to set DB_USER in wp-config.php.\e[0m"; exit 1; }
        sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '$mysql_password' );/" /workspaces/codespaces-blank/wordpress/wp-config.php || { echo -e "\e[31mError: Failed to set DB_PASSWORD in wp-config.php.\e[0m"; exit 1; }
        sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', '127.0.0.1:3306' );/" /workspaces/codespaces-blank/wordpress/wp-config.php || { echo -e "\e[31mError: Failed to set DB_HOST in wp-config.php.\e[0m"; exit 1; }
        curl -s https://api.wordpress.org/secret-key/1.1/salt/ > temp_salt.txt || { echo -e "\e[31mError: Failed to download secret keys.\e[0m"; exit 1; }
        sed -i '/AUTH_KEY/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/SECURE_AUTH_KEY/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/LOGGED_IN_KEY/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/NONCE_KEY/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/AUTH_SALT/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/SECURE_AUTH_SALT/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/LOGGED_IN_SALT/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/NONCE_SALT/d' /workspaces/codespaces-blank/wordpress/wp-config.php
        sed -i '/#@-/r temp_salt.txt' /workspaces/codespaces-blank/wordpress/wp-config.php || { echo -e "\e[31mError: Failed to insert secret keys into wp-config.php.\e[0m"; exit 1; }
        rm temp_salt.txt || { echo -e "\e[31mError: Failed to remove temporary salt file.\e[0m"; exit 1; }
    fi
    echo -e "\e[33mMoving WordPress resources to /var/www/html/...\e[0m"
    echo -e "\e[33mCreating .htaccess file...\e[0m"
    cat <<EOT > /var/www/html/.htaccess
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
EOT
    sudo mv /workspaces/codespaces-blank/wordpress/* /var/www/html/ || { echo -e "\e[31mError: Failed to move WordPress resources to /var/www/html/.\e[0m"; exit 1; }
    sudo rm -rf /workspaces/codespaces-blank/wordpress || { echo -e "\e[31mError: Failed to remove temporary WordPress directory.\e[0m"; exit 1; }
    sudo rm -rf /var/www/html/index.html || { echo -e "\e[31mError: Failed to remove default index.html.\e[0m"; exit 1; }
    sudo chown -R www-data:www-data /var/www/html/ || { echo -e "\e[31mError: Failed to change ownership of /var/www/html/.\e[0m"; exit 1; }
    sudo chmod -R 755 /var/www/html/ || { echo -e "\e[31mError: Failed to set permissions for /var/www/html/.\e[0m"; exit 1; }
    echo -e "\e[32mWordPress resources installed successfully!\e[0m"
    echo -e "\e[32mStep 7: Setting up MySQL server with Docker.\e[0m"
    if ! command -v docker &> /dev/null; then
        echo -e "\e[31mError: Docker is not installed. Please install Docker before continuing!\e[0m"
        exit 1
    fi
    echo -e "\e[33mCreating a Docker Compose file for the MySQL server...\e[0m"
    rm -rf docker-compose.yml || { echo -e "\e[31mError: Failed to remove existing docker-compose.yml.\e[0m"; exit 1; }
    cat <<EOF > docker-compose.yml
services:
  mysql:
    image: mysql:latest
    container_name: mysql_server
    environment:
      MYSQL_ROOT_PASSWORD: $mysql_password
      MYSQL_DATABASE: wordpressdb
      MYSQL_USER: wordpressuser
      MYSQL_PASSWORD: $mysql_password
    volumes:
      - mysql-data:/var/lib/mysql
    ports:
      - "3306:3306"
volumes:
  mysql-data:
    external: true
EOF
    echo -e "\e[33mSetting up volume mysql-data for container mysql_server...\e[0m"
    docker volume create mysql-data || { echo -e "\e[31mError: Failed to create Docker volume mysql-data.\e[0m"; exit 1; }
    if [ -f "mysql_data.zip" ]; then
        echo -e "\e[33mRestoring MySQL data volume...\e[0m"
        unzip mysql_data.zip || { echo -e "\e[31mError: Failed to unzip mysql_data.zip.\e[0m"; exit 1; }
        rm -rf mysql_data.zip || { echo -e "\e[31mError: Failed to remove mysql_data.zip.\e[0m"; exit 1; }
        sudo rm -rf /var/lib/docker/volumes/mysql-data/_data || { echo -e "\e[31mError: Failed to remove existing MySQL data.\e[0m"; exit 1; }
        sudo mv _data /var/lib/docker/volumes/mysql-data/_data || { echo -e "\e[31mError: Failed to move MySQL data.\e[0m"; exit 1; }
    else
        echo -e "\e[33mNo mysql_data.zip found in the current directory, creating a new one...\e[0m"
    fi
    docker compose up -d || { echo -e "\e[31mError: Failed to start Docker containers.\e[0m"; exit 1; }
    echo -e "\e[32mMySQL server setup with Docker completed successfully!\e[0m"
    echo -e "\e[32mStep 8: Configuring the Virtual Host and activating it for Apache2.\e[0m"
    sudo bash -c 'cat <<EOT > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot "/var/www/html"
    <Directory "/var/www/html">
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT' || { echo -e "\e[31mError: Failed to create Virtual Host configuration.\e[0m"; exit 1; }
    sudo a2ensite wordpress.conf && sudo a2enmod rewrite || { echo -e "\e[31mError: Failed to enable Virtual Host or mod_rewrite.\e[0m"; exit 1; }
    sudo chown -R www-data:www-data /var/www/html/ || { echo -e "\e[31mError: Failed to change ownership of /var/www/html/.\e[0m"; exit 1; }
    sudo chmod -R 755 /var/www/html/ || { echo -e "\e[31mError: Failed to set permissions for /var/www/html/.\e[0m"; exit 1; }
    sudo service apache2 restart || { echo -e "\e[31mError: Failed to restart Apache2.\e[0m"; exit 1; }
    echo -e "\e[32mVirtual Host configured and activated for Apache2 successfully!\e[0m"
    echo -e "\e[32mWordPress setup completed successfully!\e[0m"
    echo -e "\e[33mCreating rerun_server.sh script to restart server...\e[0m"
    cat > rerun_server.sh << EOF
#!/bin/bash
autossh -M 0 -R $domain:80:localhost:80 serveo.net
EOF
    chmod +x rerun_server.sh
    echo -e "\e[32mCreated rerun_server.sh script to restart the server.\e[0m"
    echo -e "\e[33mYou can restart the server by running: ./rerun_server.sh\e[0m"
    echo -e "\e[32mYou can now access your WordPress site at http://$domain.serveo.net\e[0m"
    autossh -M 0 -R $domain:80:localhost:80 serveo.net || { echo -e "\e[31mError: Failed to establish SSH tunnel with serveo.net.\e[0m"; exit 1; }
    echo -e "\e[31mServer has been shut down.\e[0m"
}
create_data_files() {
    echo -e "\e[32mBacking up data...\e[0m"
    sudo cp -r /var/lib/docker/volumes/mysql-data/_data ./ && sudo zip -r mysql_data.zip ./_data && sudo rm -rf ./_data || { echo -e "\e[31mError: Failed to back up MySQL data.\e[0m"; exit 1; }
    echo -e "\e[32mMySQL server container data backed up successfully!\e[0m"
    sudo cp -r /var/www/html/ ./wordpress/ || { echo -e "\e[31mError: Failed to copy WordPress data!\e[0m"; exit 1; }
    sudo zip -r wordpress.zip ./wordpress || { echo -e "\e[31mError: Failed to zip WordPress data!\e[0m"; exit 1; }
    sudo rm -rf ./wordpress || { echo -e "\e[31mError: Failed to remove temporary WordPress directory.\e[0m"; exit 1; }
    echo -e "\e[32mWordPress data backed up successfully!\e[0m"
}
login_domain_provider() {
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" || { echo -e "\e[31mError: Failed to generate SSH key.\e[0m"; exit 1; }
    sudo apt update -y && sudo apt upgrade -y && sudo apt install autossh -y || { echo -e "\e[31mError: Failed to install autossh.\e[0m"; exit 1; }
    echo -e "\e[33mWhen 2 links appear on the terminal (Google or Github), choose one to log in to the domain provider, then press Ctrl + C 2 times to exit...\e[0m"
    autossh -M 0 -R simple000default:80:localhost:80 serveo.net || { echo -e "\e[31mError: Failed to establish SSH tunnel with serveo.net.\e[0m"; exit 1; }
}
case $selected in
    0) setup_wordpress ;;
    1) create_data_files ;;
    2) login_domain_provider ;;
esac