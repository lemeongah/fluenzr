FROM wordpress:latest

# Install dependencies for GD and image processing
RUN apt-get update && apt-get install -y \
    libgd-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libfreetype6-dev \
    libzip-dev \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install zip

# Increase PHP upload limits
RUN printf 'upload_max_filesize = 64M\npost_max_size = 64M\nmemory_limit = 256M\n' > /usr/local/etc/php/conf.d/uploads.ini

# Enable necessary Apache modules
RUN a2enmod rewrite headers

# Allow .htaccess
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# HTTPS proxy configuration
RUN echo 'SetEnvIf X-Forwarded-Proto "^https$" HTTPS=on\n\
RemoteIPHeader X-Forwarded-For\n\
RemoteIPInternalProxy 10.0.0.0/8\n\
RemoteIPInternalProxy 172.16.0.0/12\n\
RemoteIPInternalProxy 192.168.0.0/16\n\
ServerTokens Prod\n\
ServerSignature Off' > /etc/apache2/conf-available/proxy-https.conf \
    && a2enconf proxy-https
