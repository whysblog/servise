#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/var/www/maintenance-page"
NGINX_SITE="/etc/nginx/sites-available/maintenance-page"
NGINX_LINK="/etc/nginx/sites-enabled/maintenance-page"

if [[ $EUID -ne 0 ]]; then
  echo "请使用 sudo 或 root 运行该脚本。"
  exit 1
fi

echo "[1/6] 安装 Nginx..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y nginx

echo "[2/6] 创建网页目录..."
mkdir -p "$APP_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/index.html" "$APP_DIR/index.html"

echo "[3/6] 写入 Nginx 站点配置..."
cat > "$NGINX_SITE" <<CONF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    root $APP_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    add_header Cache-Control "no-store, no-cache, must-revalidate" always;
}
CONF

echo "[4/6] 启用站点配置..."
rm -f /etc/nginx/sites-enabled/default
ln -sf "$NGINX_SITE" "$NGINX_LINK"

echo "[5/6] 校验并重载 Nginx..."
nginx -t
systemctl enable nginx
systemctl restart nginx

echo "[6/6] 部署完成。"
echo "页面目录: $APP_DIR"
echo "你可以访问服务器 IP 检查维护页面是否生效。"
