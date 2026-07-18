#!/usr/bin/env bash
#
# DigitalOcean droplet'ini goldgame için bir kereliğine hazırlar.
# Droplet'te root (veya sudo yetkili bir kullanıcı) olarak çalıştırın:
#
#   bash setup-server.sh
#
# Yaptıkları:
#   1. nginx kurar
#   2. /var/www/goldgame dizinini oluşturur
#   3. nginx'i bu dizini sunacak şekilde ayarlar
#   4. "deploy" adında, sadece bu dizine yazabilen bir kullanıcı oluşturur
#
set -euo pipefail

SITE_DIR="/var/www/goldgame"
DEPLOY_USER="deploy"

echo "==> nginx kuruluyor..."
apt-get update -qq
apt-get install -y -qq nginx

echo "==> Site dizini oluşturuluyor: ${SITE_DIR}"
mkdir -p "${SITE_DIR}"

echo "==> Deploy kullanıcısı oluşturuluyor: ${DEPLOY_USER}"
if ! id "${DEPLOY_USER}" &>/dev/null; then
  useradd --create-home --shell /bin/bash "${DEPLOY_USER}"
fi
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${SITE_DIR}"

echo "==> Deploy kullanıcısı için SSH dizini hazırlanıyor"
DEPLOY_HOME="$(eval echo ~${DEPLOY_USER})"
mkdir -p "${DEPLOY_HOME}/.ssh"
touch "${DEPLOY_HOME}/.ssh/authorized_keys"
chmod 700 "${DEPLOY_HOME}/.ssh"
chmod 600 "${DEPLOY_HOME}/.ssh/authorized_keys"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_HOME}/.ssh"

echo "==> nginx site ayarı yazılıyor"
cat > /etc/nginx/sites-available/goldgame <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/goldgame;
    index index.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Oyun tek dosya; statik içerik için basit önbellek başlıkları
    location ~* \.(html)$ {
        add_header Cache-Control "no-cache";
    }
}
NGINX

ln -sf /etc/nginx/sites-available/goldgame /etc/nginx/sites-enabled/goldgame
rm -f /etc/nginx/sites-enabled/default

echo "==> nginx test edilip yeniden yükleniyor"
nginx -t
systemctl reload nginx
systemctl enable nginx

echo
echo "Kurulum tamam! Şimdi yapmanız gerekenler:"
echo "  1. GitHub Actions için bir SSH anahtar çifti üretin (kendi bilgisayarınızda):"
echo "       ssh-keygen -t ed25519 -f goldgame_deploy -N '' -C 'goldgame-github-actions'"
echo "  2. Açık anahtarı (goldgame_deploy.pub) bu sunucuda şu dosyaya ekleyin:"
echo "       ${DEPLOY_HOME}/.ssh/authorized_keys"
echo "  3. Özel anahtarı (goldgame_deploy) GitHub repo ayarlarında"
echo "     DO_SSH_PRIVATE_KEY adlı secret olarak kaydedin."
echo "     Diğer secret'lar: DO_HOST (droplet IP), DO_USER (${DEPLOY_USER})"
echo
echo "Site şu an http://<droplet-ip>/ adresinde yayında (deploy sonrası oyun görünür)."
