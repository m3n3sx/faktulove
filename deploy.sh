#!/bin/bash

# VPS Deployment Script for Faktulove
# Domain: faktulowe.ooxo.pl
# IP: 13.49.169.63

echo "Starting VPS deployment for Faktulove..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential \
    libpq-dev postgresql postgresql-contrib nginx git curl \
    libpango1.0-dev libcairo2-dev libgdk-pixbuf2.0-dev libffi-dev shared-mime-info

# Clean up disk space
sudo apt autoremove -y
sudo apt clean
sudo rm -rf /var/cache/apt/archives/*
sudo rm -rf /tmp/*

# Create database user and database
sudo -u postgres createuser --interactive --pwprompt faktulove_user << EOF
CAnabis123#$
CAnabis123#$
y
EOF

sudo -u postgres createdb faktulove_db

# Create application directory
mkdir -p /home/ubuntu/faktulove
cd /home/ubuntu/faktulove

# Clone repository
git clone https://github.com/m3n3sx/faktulove.git .

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Create production requirements
cp requirements.txt requirements.txt.backup
sed 's/mysqlclient==2.2.7/psycopg2-binary==2.9.9/' requirements.txt > requirements_prod.txt

# Install Python packages
pip install --upgrade pip
pip install --no-cache-dir -r requirements_prod.txt

# Create production settings
cat > faktulove/settings_prod.py << 'EOF'
import os
from pathlib import Path
from .settings import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

ALLOWED_HOSTS = ['faktulowe.ooxo.pl', '13.49.169.63', 'localhost', '127.0.0.1']

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'faktulove_db',
        'USER': 'faktulove_user',
        'PASSWORD': 'CAnabis123#$',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Security settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/home/ubuntu/faktulove/django.log',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
EOF

# Run migrations
python manage.py migrate --settings=faktulove.settings_prod

# Collect static files
python manage.py collectstatic --noinput --settings=faktulove.settings_prod

# Create superuser (optional)
echo "Creating superuser..."
python manage.py createsuperuser --settings=faktulove.settings_prod << EOF
admin
admin@faktulowe.ooxo.pl
admin123
admin123
EOF

# Configure Nginx
sudo tee /etc/nginx/sites-available/faktulove << 'EOF'
server {
    listen 80;
    server_name faktulowe.ooxo.pl www.faktulowe.ooxo.pl;

    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root /home/ubuntu/faktulove;
    }

    location /media/ {
        root /home/ubuntu/faktulove;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/faktulove/faktulove.sock;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/faktulove /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Configure Gunicorn
sudo tee /etc/systemd/system/faktulove.service << 'EOF'
[Unit]
Description=Faktulove Django Application
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/faktulove
Environment="PATH=/home/ubuntu/faktulove/venv/bin"
ExecStart=/home/ubuntu/faktulove/venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/faktulove/faktulove.sock faktulove.wsgi:application --settings=faktulove.settings_prod
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Install Gunicorn
source venv/bin/activate
pip install gunicorn

# Start services
sudo systemctl daemon-reload
sudo systemctl start faktulove
sudo systemctl enable faktulove
sudo systemctl restart nginx

# Set permissions
sudo chown -R ubuntu:www-data /home/ubuntu/faktulove
sudo chmod -R 755 /home/ubuntu/faktulove

echo "Deployment completed successfully!"
echo "Application should be available at: http://faktulowe.ooxo.pl"
echo "Admin panel: http://faktulowe.ooxo.pl/admin"
echo "Username: admin"
echo "Password: admin123"
