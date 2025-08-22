# VPS Deployment Guide for Faktulove

## Server Information
- **Domain**: faktulowe.ooxo.pl
- **IP Address**: 13.49.169.63
- **SSH Key**: klucz1.pem
- **SSH Command**: `ssh -i "klucz1.pem" ubuntu@ec2-13-49-169-63.eu-north-1.compute.amazonaws.com`

## Prerequisites
- DNS records for `faktulowe.ooxo.pl` pointing to `13.49.169.63`
- SSH access to the VPS
- Git repository access

## Step-by-Step Deployment

### 1. Connect to VPS
```bash
ssh -i "klucz1.pem" ubuntu@ec2-13-49-169-63.eu-north-1.compute.amazonaws.com
```

### 2. Update System and Install Dependencies
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential \
    libpq-dev postgresql postgresql-contrib nginx git curl \
    libpango1.0-dev libcairo2-dev libgdk-pixbuf2.0-dev libffi-dev shared-mime-info
```

### 3. Clean Up Disk Space
```bash
sudo apt autoremove -y
sudo apt clean
sudo rm -rf /var/cache/apt/archives/*
sudo rm -rf /tmp/*
```

### 4. Set Up PostgreSQL Database
```bash
# Create database user
sudo -u postgres createuser --interactive --pwprompt faktulove_user
# Enter password: CAnabis123#$
# Make superuser: y

# Create database
sudo -u postgres createdb faktulove_db
```

### 5. Clone and Set Up Application
```bash
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
pip install gunicorn
```

### 6. Create Production Settings
Create file `/home/ubuntu/faktulove/faktulove/settings_prod.py`:

```python
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
```

### 7. Run Django Commands
```bash
cd /home/ubuntu/faktulove
source venv/bin/activate

# Run migrations
python manage.py migrate --settings=faktulove.settings_prod

# Collect static files
python manage.py collectstatic --noinput --settings=faktulove.settings_prod

# Create superuser
python manage.py createsuperuser --settings=faktulove.settings_prod
# Username: admin
# Email: admin@faktulowe.ooxo.pl
# Password: admin123
```

### 8. Configure Nginx
Create file `/etc/nginx/sites-available/faktulove`:

```nginx
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
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/faktulove /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### 9. Configure Gunicorn Service
Create file `/etc/systemd/system/faktulove.service`:

```ini
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
```

### 10. Start Services
```bash
# Reload systemd and start services
sudo systemctl daemon-reload
sudo systemctl start faktulove
sudo systemctl enable faktulove
sudo systemctl restart nginx

# Set permissions
sudo chown -R ubuntu:www-data /home/ubuntu/faktulove
sudo chmod -R 755 /home/ubuntu/faktulove
```

### 11. Verify Deployment
```bash
# Check service status
sudo systemctl status faktulove
sudo systemctl status nginx

# Check logs
sudo journalctl -u faktulove -f
tail -f /home/ubuntu/faktulove/django.log
```

## Access Information
- **Application URL**: http://faktulowe.ooxo.pl
- **Admin Panel**: http://faktulowe.ooxo.pl/admin
- **Admin Username**: admin
- **Admin Password**: admin123

## Troubleshooting

### Check Disk Space
```bash
df -h
```

### Check Service Logs
```bash
sudo journalctl -u faktulove -f
sudo tail -f /var/log/nginx/error.log
```

### Restart Services
```bash
sudo systemctl restart faktulove
sudo systemctl restart nginx
```

### Check Database Connection
```bash
cd /home/ubuntu/faktulove
source venv/bin/activate
python manage.py dbshell --settings=faktulove.settings_prod
```

## Security Notes
- Change default admin password after first login
- Consider setting up SSL/HTTPS with Let's Encrypt
- Configure firewall rules
- Regular system updates
- Database backups

## Backup Strategy
```bash
# Database backup
pg_dump -U faktulove_user -h localhost faktulove_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Application backup
tar -czf faktulove_backup_$(date +%Y%m%d_%H%M%S).tar.gz /home/ubuntu/faktulove/
```
