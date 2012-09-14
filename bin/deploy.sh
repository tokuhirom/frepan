#!/usr/bin/zsh
DOMAIN=frepan.org

if [ ! -f /etc/nginx/sites-enabled/$DOMAIN.conf ]; then
    sudo ln -s `pwd`/etc/httpd/$DOMAIN.conf /etc/nginx/sites-enabled/$DOMAIN.conf
fi

sudo /etc/init.d/nginx reload

echo "--------------------------"
echo "Deployment finished"
sudo tail /var/log/upstart/$DOMAIN.log

