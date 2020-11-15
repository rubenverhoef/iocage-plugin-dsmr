#!/bin/sh

# Enable and start Postgresql
sysrc 'postgresql_enable=YES'
/usr/local/etc/rc.d/postgresql initdb
service postgresql start

# Database
sudo sudo -u postgres createuser -DSR dsmrreader
sudo sudo -u postgres createdb -O dsmrreader dsmrreader
sudo sudo -u postgres psql -c "alter user dsmrreader with password 'dsmrreader';"

# System user
pw group add dsmr
pw user add -n dsmr -d /home/dsmr -G dsmr -m -s /usr/local/bin/bash

# Nginx
sudo mkdir -p /var/www/dsmrreader/static
sudo chown -R dsmr:dsmr /var/www/dsmrreader/

# Code checkout
sudo git clone https://github.com/dsmrreader/dsmr-reader.git /home/dsmr/dsmr-reader
sudo chown -R dsmr:dsmr /home/dsmr/

# Virtual env
sudo sudo -u dsmr mkdir /home/dsmr/.virtualenvs
sudo sudo -u dsmr virtualenv /home/dsmr/.virtualenvs/dsmrreader --no-site-packages --python python3.7

# Config
sudo sudo -u dsmr cp /home/dsmr/dsmr-reader/dsmrreader/provisioning/django/settings.py.template /home/dsmr/dsmr-reader/dsmrreader/settings.py
sudo sudo -u dsmr cp /home/dsmr/dsmr-reader/.env.template /home/dsmr/dsmr-reader/.env
sudo sudo -u dsmr /home/dsmr/dsmr-reader/tools/generate-secret-key.sh

# Requirements
sudo sudo -u dsmr /home/dsmr/.virtualenvs/dsmrreader/bin/pip3 install -r /home/dsmr/dsmr-reader/dsmrreader/provisioning/requirements/base.txt
sudo sudo -u dsmr /home/dsmr/.virtualenvs/dsmrreader/bin/pip3 install psycopg2

# Setup
sudo sudo -u dsmr /home/dsmr/.virtualenvs/dsmrreader/bin/python3 /home/dsmr/dsmr-reader/manage.py migrate
sudo sudo -u dsmr /home/dsmr/.virtualenvs/dsmrreader/bin/python3 /home/dsmr/dsmr-reader/manage.py collectstatic --noinput

# Create (super)user with the values in DSMR_USER and
# DSMR_PASSWORD as defined in one of the previous steps.
sudo sudo -u dsmr /home/dsmr/.virtualenvs/dsmrreader/bin/python3 /home/dsmr/dsmr-reader/manage.py dsmr_superuser

# Nginx
sysrc 'nginx_enable=YES'
service nginx start

cp /home/dsmr/dsmr-reader/dsmrreader/provisioning/nginx/dsmr-webinterface /usr/local/etc/nginx/dsmr-webinterface

sed -i '' '/^    server {/i\
    include dsmr-webinterface;\
\
' /usr/local/etc/nginx/nginx.conf

service nginx restart

# Supervisor
sysrc 'supervisord_enable=YES'

mkdir -p /var/log/supervisor
mkdir -p /usr/local/etc/supervisor/conf.d

#sed all dsmr-reader.conf settings
sed -i '' 's/;\[include\]/\[include\]/g' /usr/local/etc/supervisord.conf
sed -i '' 's/;files =.*/files = \/usr\/local\/etc\/supervisor\/conf.d\/*.conf/g' /usr/local/etc/supervisord.conf
# Copy the configuration files for Supervisor:
sudo cp /home/dsmr/dsmr-reader/dsmrreader/provisioning/supervisor/dsmr_datalogger.conf /usr/local/etc/supervisor/conf.d/
sudo cp /home/dsmr/dsmr-reader/dsmrreader/provisioning/supervisor/dsmr_backend.conf /usr/local/etc/supervisor/conf.d/
sudo cp /home/dsmr/dsmr-reader/dsmrreader/provisioning/supervisor/dsmr_webinterface.conf /usr/local/etc/supervisor/conf.d/

service supervisord start
sudo supervisorctl reread
sudo supervisorctl update
