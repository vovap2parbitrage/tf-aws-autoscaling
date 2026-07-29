#!/bin/bash
apt-get -y update
apt-get install -y nginx

systemctl enable nginx

cat << 'EOF' > /etc/nginx/sites-available/default
${NGINX_CONF}
EOF

systemctl restart nginx