#!/bin/bash

echo "=== VPS Deployment for Faktulove ==="
echo "Domain: faktulowe.ooxo.pl"
echo "IP: 13.49.169.63"
echo ""

# Step 1: Install system dependencies
echo "Step 1: Installing system dependencies..."
sudo apt install -y libpango1.0-dev libcairo2-dev libgdk-pixbuf2.0-dev libffi-dev shared-mime-info

# Step 2: Create production settings
echo "Step 2: Creating production settings..."
cd /home/ubuntu/faktulove

cat > faktulove/settings_prod.py << 'EOF'
import os
from pathlib import Path
from .settings import *

DEBUG = False
ALLOWED_HOSTS = ['faktulowe.ooxo.pl', '13.49.169.63', 'localhost', '127.0.0.1']

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

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
EOF

# Step 3: Install Gunicorn
echo "Step 3: Installing Gunicorn..."
source venv/bin/activate
pip install gunicorn

# Step 4: Run migrations
echo "Step 4: Running migrations..."
python manage.py migrate --settings=faktulove.settings_prod

# Step 5: Collect static files
echo "Step 5: Collecting static files..."
python manage.py collectstatic --noinput --settings=faktulove.settings_prod

# Step 6: Create superuser
echo "Step 6: Creating superuser..."
python manage.py createsuperuser --settings=faktulove.settings_prod --username admin --email admin@faktulowe.ooxo.pl --noinput
echo "admin:admin123" | sudo chpasswd

# Step 7: Configure Nginx
echo "Step 7: Configuring Nginx..."
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

sudo ln -sf /etc/nginx/sites-available/faktulove /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Step 8: Configure Gunicorn service
echo "Step 8: Configuring Gunicorn service..."
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

# Step 9: Start services
echo "Step 9: Starting services..."
sudo systemctl daemon-reload
sudo systemctl start faktulove
sudo systemctl enable faktulove
sudo systemctl restart nginx

# Step 10: Set permissions
echo "Step 10: Setting permissions..."
sudo chown -R ubuntu:www-data /home/ubuntu/faktulove
sudo chmod -R 755 /home/ubuntu/faktulove

echo ""
echo "=== Deployment completed! ==="
echo "Application: http://faktulowe.ooxo.pl"
echo "Admin panel: http://faktulowe.ooxo.pl/admin"
echo "Username: admin"
echo "Password: admin123"
echo ""
echo "To check status:"
echo "sudo systemctl status faktulove"
echo "sudo systemctl status nginx"
