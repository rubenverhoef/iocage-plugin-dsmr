#!/bin/sh

sysrc 'postgresql_enable=YES' 'nginx_enable=YES' 'supervisord_enable=YES'
sudo sudo -u postgres initdb -D /var/db/postgres/data12
service postgresql start

# Database
sudo sudo -u postgres createuser -DSR dsmrreader
sudo sudo -u postgres createdb -O dsmrreader dsmrreader
sudo sudo -u postgres psql -c "alter user dsmrreader with password 'dsmrreader';"

# Code checkout
mkdir -p /usr/local/www/dsmrreader/static
git clone https://github.com/dennissiemensma/dsmr-reader.git /root/dsmr-reader

# Config & requirements
cp /root/dsmr-reader/dsmrreader/provisioning/django/postgresql.py /root/dsmr-reader/dsmrreader/settings.py
pip install -r /root/dsmr-reader/dsmrreader/provisioning/requirements/base.txt -r /root/dsmr-reader/dsmrreader/provisioning/requirements/postgresql.txt

# Setup
python3.7 /root/dsmr-reader/manage.py migrate
python3.7 /root/dsmr-reader/manage.py collectstatic --noinput
mv /var/www/dsmrreader/* /usr/local/www/dsmrreader

# Nginx
service nginx start


# Supervisor

mkdir -p /var/log/supervisor
mkdir -p /usr/local/etc/supervisor/conf.d
cp /root/dsmr-reader/dsmrreader/provisioning/supervisor/dsmr-reader.conf /usr/local/etc/supervisor/conf.d/

#sed all dsmr-reader.conf settings

# ;[include] -> [include]
# ;files = * -> files = /usr/local/etc/supervisor/conf.d/*.conf
# sed -i 's/^# DAB Setup.*//' /boot/config.txt
# sudo sudo -u postgres echo "hoi" >> "/usr/local/etc/supervisord.conf"

service supervisord start
supervisorctl reread
supervisorctl update


python3.7 /root/dsmr-reader/manage.py createsuperuser --username admin --email root@localhost

http://192.168.0.16/
