#!/bin/bash

mkdir -p /workspaces/codespaces-blank || exit 1
cd /workspaces/codespaces-blank || exit 1

center_text() {
    local text="$*"
    local width=$(tput cols)
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s\n" "$padding" "" "$text"
}

error_exit() {
    echo -e "\e[31mError: $1\e[0m" >&2
    exit 1
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
        if [[ " ${valid_options[*]} " =~ " $i " ]]; then
            if [ "$i" -eq "$selected" ]; then
                echo -e "\e[34m$(center_text "> ${options[$i]}")\e[0m"
            else
                echo "$(center_text "  ${options[$i]}")"
            fi
        else
            echo -e "\e[90m$(center_text "  ${options[$i]} (disabled)")\e[0m"
        fi
    done
    
    read -rsn1 input
    case "$input" in
        $'\x1b')
            read -rsn1 -t 0.1 input
            if [[ "$input" == '[' ]]; then
                read -rsn1 input
                case "$input" in
                    'A')
                        ((selected--))
                        while [[ ! " ${valid_options[*]} " =~ " $selected " ]] && [ "$selected" -ge 0 ]; do
                            ((selected--))
                        done
                        [ "$selected" -lt 0 ] && selected="${valid_options[-1]}"
                        ;;
                    'B')
                        ((selected++))
                        while [[ ! " ${valid_options[*]} " =~ " $selected " ]] && [ "$selected" -lt "${#options[@]}" ]; do
                            ((selected++))
                        done
                        [ "$selected" -ge "${#options[@]}" ] && selected="${valid_options[0]}"
                        ;;
                esac
            fi
            ;;
        '')
            [[ " ${valid_options[*]} " =~ " $selected " ]] && break
            ;;
    esac
done

setup_wordpress() {
    clear
    [ ! -d "$HOME/.ssh" ] && error_exit "Please login to domain provider (serveo.net) first!"
    
    echo -e "\e[32mStarting WordPress setup...\e[0m"
    
    echo -e "\e[32mStep 1: Setting up domain.\e[0m"
    read -p "Input domain name (default: domain$(date +'%d%m%H%M%Y')): " domain
    domain="${domain:-domain$(date +'%d%m%H%M%Y')}"
    echo -e "\e[33mDomain name used: $domain.serveo.net\e[0m"
    
    echo -e "\e[32mStep 2: Removing default PHP.\e[0m"
    sudo rm -rf /usr/local/php || error_exit "Failed to remove default PHP"
    
    echo -e "\e[32mStep 3: Installing Apache2.\e[0m"
    sudo apt update -y && sudo apt install apache2 -y && sudo a2dissite 000-default.conf \
        && sudo a2dissite default-ssl.conf && sudo service apache2 start || error_exit "Failed to install Apache2"
    
    echo -e "\e[32mStep 4: Installing PHP 8.\e[0m"
    sudo apt install software-properties-common -y && sudo add-apt-repository ppa:ondrej/php -y \
        && sudo apt update -y && sudo apt install php8.0 php8.0-mysql php8.0-xml php8.0-curl \
        php8.0-gd php8.0-mbstring php8.0-zip libapache2-mod-php8.0 -y && sudo a2enmod php8.0 \
        && sudo service apache2 restart || error_exit "Failed to install PHP 8"
    
    echo -e "\e[32mStep 5: Setting MySQL password.\e[0m"
    read -p "Input password for MySQL (default: 1234567@@!): " mysql_password
    mysql_password="${mysql_password:-1234567@@!}"
    echo -e "\e[33mMySQL password used: $mysql_password\e[0m"
    
    echo -e "\e[32mStep 6: Removing index.html if it exists.\e[0m"
    [ -f /var/www/html/index.html ] && sudo rm -f /var/www/html/index.html || echo "index.html not found"
    echo -e "\e[32mStep 7: Installing WordPress resources.\e[0m"
    if [ -f "wordpress.zip" ]; then
        unzip wordpress.zip && rm -rf wordpress.zip || error_exit "Failed to unzip wordpress.zip"
    else
        wget -q "https://wordpress.org/latest.tar.gz" -O wordpress.tar.gz || error_exit "Failed to download WordPress"
        tar -xzf wordpress.tar.gz && rm -rf wordpress.tar.gz || error_exit "Failed to extract WordPress"
        cp wordpress/wp-config-sample.php wordpress/wp-config.php || error_exit "Failed to copy wp-config-sample.php"
        sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', 'wordpressdb' );/" wordpress/wp-config.php || error_exit "Failed to set DB_NAME"
        sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', 'wordpressuser' );/" wordpress/wp-config.php || error_exit "Failed to set DB_USER"
        sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '$mysql_password' );/" wordpress/wp-config.php || error_exit "Failed to set DB_PASSWORD"
        sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', '127.0.0.1:3306' );/" wordpress/wp-config.php || error_exit "Failed to set DB_HOST"
        curl -s https://api.wordpress.org/secret-key/1.1/salt/ > temp_salt.txt || error_exit "Failed to download secret keys"
        sed -i '/#@-/r temp_salt.txt' wordpress/wp-config.php && rm temp_salt.txt || error_exit "Failed to insert secret keys"
    fi
    sudo mv wordpress/* /var/www/html/ && sudo rm -rf wordpress || error_exit "Failed to move WordPress files"
    sudo bash -c 'cat > /var/www/html/.htaccess <<EOT
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
EOT' || error_exit "Failed to create .htaccess"
    sudo chown -R www-data:www-data /var/www/html/ && sudo chmod -R 755 /var/www/html/ || error_exit "Failed to set permissions"
    
    echo -e "\e[32mStep 8: Setting up MySQL with Docker.\e[0m"
    command -v docker >/dev/null || error_exit "Docker is not installed"
    cat > docker-compose.yml <<EOF || error_exit "Failed to create docker-compose.yml"
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
    docker volume create mysql-data || error_exit "Failed to create Docker volume"
    if [ -f "mysql_data.zip" ]; then
        unzip mysql_data.zip && sudo mv _data /var/lib/docker/volumes/mysql-data || error_exit "Failed to restore MySQL data"
        rm -rf mysql_data.zip
    fi
    docker compose up -d || error_exit "Failed to start Docker containers"
    
    echo -e "\e[32mStep 9: Configuring Virtual Host.\e[0m"
    sudo bash -c 'cat > /etc/apache2/sites-available/wordpress.conf <<EOT
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
EOT' || error_exit "Failed to create Virtual Host"
    sudo a2ensite wordpress.conf && sudo a2enmod rewrite && sudo service apache2 restart || error_exit "Failed to enable Virtual Host"
    
    echo -e "\e[33mCreating rerun_server.sh...\e[0m"
    echo "#!/bin/bash" > rerun_server.sh
    echo "autossh -M 0 -R $domain:80:localhost:80 serveo.net" >> rerun_server.sh
    chmod +x rerun_server.sh
    echo -e "\e[32mSetup completed! Access your site at http://$domain.serveo.net\e[0m"
    autossh -M 0 -R "$domain:80:localhost:80" serveo.net || error_exit "Failed to start SSH tunnel"
    echo -e "\e[31mServer has been shut down.\e[0m"
}

create_data_files() {
    echo -e "\e[32mBacking up data...\e[0m"
    sudo cp -r /var/lib/docker/volumes/mysql-data/_data ./ && sudo zip -r mysql_data.zip ./_data \
        && sudo rm -rf ./_data || error_exit "Failed to back up MySQL data"
    sudo cp -r /var/www/html/ ./wordpress/ && sudo zip -r wordpress.zip ./wordpress \
        && sudo rm -rf ./wordpress || error_exit "Failed to back up WordPress data"
    echo -e "\e[32mBackup completed successfully!\e[0m"
}

login_domain_provider() {
    ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa" -N "" || error_exit "Failed to generate SSH key"
    sudo apt update -y && sudo apt install autossh -y || error_exit "Failed to install autossh"
    echo -e "\e[33mChoose a link (Google/Github) to login to serveo.net, then press Ctrl+C twice to exit...\e[0m"
    autossh -M 0 -R simple000default:80:localhost:80 serveo.net || error_exit "Failed to connect to serveo.net"
}

case "$selected" in
    0) setup_wordpress ;;
    1) create_data_files ;;
    2) login_domain_provider ;;
esac