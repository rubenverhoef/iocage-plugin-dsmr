#!/bin/sh

# 1. Database backend (PostgreSQL)
# Enable and start Postgresql
sysrc 'postgresql_enable=YES'
# Initialize Postgresql
/usr/local/etc/rc.d/postgresql initdb
# Start Postgresql
service postgresql start
# Create database user:
sudo sudo -u postgres createuser -DSR dsmrreader
# Create database, owned by the database user we just created:
sudo sudo -u postgres createdb -O dsmrreader dsmrreader
# Set password for database user:
sudo sudo -u postgres psql -c "alter user dsmrreader with password 'dsmrreader';"

# 2. Dependencies
# Already installed by plugin

# 3. Application user
pw group add dsmr
pw user add -n dsmr -d /home/dsmr -G dsmr -m -s /usr/local/bin/bash

# 4. Webserver/Nginx (part 1)
sudo mkdir -p /var/www/dsmrreader/static
sudo chown -R dsmr:dsmr /var/www/dsmrreader/

# 5. Clone project code from Github
sudo git clone https://github.com/dennissiemensma/dsmr-reader.git /home/dsmr/dsmr-reader
sudo chown -R dsmr:dsmr /home/dsmr/

# 6. Virtualenv
sudo sudo -u dsmr mkdir /home/dsmr/.virtualenvs
sudo sudo -u dsmr virtualenv /home/dsmr/.virtualenvs/dsmrreader --no-site-packages --python python3.7

# 7. Application configuration & setup
sudo sudo -u dsmr cp /home/dsmr/dsmr-reader/dsmrreader/provisioning/django/postgresql.py /home/dsmr/dsmr-reader/dsmrreader/settings.py
sudo sudo -u dsmr /home/dsmr/.virtualenvs/dsmrreader/bin/pip3 install -r /home/dsmr/dsmr-reader/dsmrreader/provisioning/requirements/base.txt -r /home/dsmr/dsmr-reader/dsmrreader/provisioning/requirements/postgresql.txt

# 8. Bootstrapping
# Not nessasary, Skipping

# 9. Webserver/Nginx (part 2)
sysrc 'nginx_enable=YES'
service nginx start

sed -i '' '/^    server {/i\\
    include \/home\/dsmr\/dsmr-reader\/dsmrreader\/provisioning\/nginx\/dsmr-webinterface;\
' /usr/local/etc/nginx/nginx.conf

service nginx restart

# 10. Supervisor
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
