#!/usr/bin/env bash
#
# DigitalOcean droplet'ini goldgame'in Docker ile deploy'u için
# bir kereliğine hazırlar. Droplet'te root olarak çalıştırın:
#
#   bash setup-server.sh
#
# Yaptıkları:
#   1. Docker ve docker compose eklentisini kurar
#   2. /opt/goldgame dizinini oluşturur
#   3. "deploy" adında bir kullanıcı oluşturup docker grubuna ekler
#      (GitHub Actions bu kullanıcıyla bağlanıp container'ı günceller)
#
set -euo pipefail

SITE_DIR="/opt/goldgame"
DEPLOY_USER="deploy"

echo "==> Docker kuruluyor..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
else
  echo "    Docker zaten kurulu, atlanıyor."
fi
systemctl enable --now docker

echo "==> Host üzerindeki nginx kontrol ediliyor (80 portu Docker container'ına kalmalı)"
if systemctl is-active --quiet nginx 2>/dev/null; then
  echo "    Host'ta nginx çalışıyor; 80 portunu boşaltmak için durdurulup devre dışı bırakılıyor."
  systemctl disable --now nginx
fi

echo "==> Güvenlik duvarı kontrol ediliyor (80 ve 443 açık olmalı)"
if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp
  ufw allow 443/tcp
fi

echo "==> Uygulama dizini oluşturuluyor: ${SITE_DIR}"
mkdir -p "${SITE_DIR}"

echo "==> Deploy kullanıcısı oluşturuluyor: ${DEPLOY_USER}"
if ! id "${DEPLOY_USER}" &>/dev/null; then
  useradd --create-home --shell /bin/bash "${DEPLOY_USER}"
fi
usermod -aG docker "${DEPLOY_USER}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${SITE_DIR}"

echo "==> Deploy kullanıcısı için SSH dizini hazırlanıyor"
DEPLOY_HOME="$(eval echo ~${DEPLOY_USER})"
mkdir -p "${DEPLOY_HOME}/.ssh"
touch "${DEPLOY_HOME}/.ssh/authorized_keys"
chmod 700 "${DEPLOY_HOME}/.ssh"
chmod 600 "${DEPLOY_HOME}/.ssh/authorized_keys"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_HOME}/.ssh"

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
echo "İlk deploy'dan sonra oyun http://<droplet-ip>/ adresinde yayında olacak."
