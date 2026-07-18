# Gold Game 🪙

Tarayıcıda çalışan, tek dosyalık (`index.html`) HTML5 canvas oyunu. Keseyi hareket
ettirip altınları topla, bombalardan kaç!

**Canlı adres:** https://goldgame.sinsoft.com.tr/ (Turhost DNS'te A kaydı ile
droplet IP'sine yönlendirilmiştir; SSL sertifikası Caddy + Let's Encrypt ile
otomatik alınır ve yenilenir.)

## Yerelde Docker ile çalıştırma

```bash
docker compose up -d --build
# Oyun: http://localhost/
```

## Otomatik Deploy (DigitalOcean Droplet + Docker)

`main` dalına yapılan her push, GitHub Actions ile droplet'e otomatik deploy
edilir (`.github/workflows/deploy.yml`): dosyalar `rsync` ile sunucuya kopyalanır,
ardından sunucuda `docker compose up -d --build` çalıştırılarak Caddy tabanlı
container güncellenir. Caddy, Let's Encrypt sertifikasını otomatik alır,
yeniler ve HTTP isteklerini HTTPS'e yönlendirir. Kurulum iki adımdan oluşur:

### 1. Sunucuyu hazırla (bir kereye mahsus)

Droplet'e root olarak bağlanıp kurulum script'ini çalıştırın:

```bash
scp deploy/setup-server.sh root@<droplet-ip>:/tmp/
ssh root@<droplet-ip> "bash /tmp/setup-server.sh"
```

Bu script Docker'ı kurar, `/opt/goldgame` dizinini oluşturur ve docker grubuna
üye `deploy` adlı bir kullanıcı ekler.

Sonra kendi bilgisayarınızda deploy için bir SSH anahtarı üretin ve açık
anahtarı sunucuya ekleyin:

```bash
ssh-keygen -t ed25519 -f goldgame_deploy -N '' -C 'goldgame-github-actions'
ssh root@<droplet-ip> "cat >> /home/deploy/.ssh/authorized_keys" < goldgame_deploy.pub
```

### 2. GitHub secret'larını ekle

GitHub'da **Settings → Secrets and variables → Actions → New repository secret**
yolundan şu secret'ları ekleyin:

| Secret               | Değer                                             | Zorunlu |
|----------------------|---------------------------------------------------|---------|
| `DO_HOST`            | Droplet'in IP adresi (SSH için IP önerilir)       | Evet    |
| `DO_USER`            | `deploy`                                          | Evet    |
| `DO_SSH_PRIVATE_KEY` | `goldgame_deploy` dosyasının **tüm içeriği**      | Evet    |
| `DO_PORT`            | SSH portu (varsayılan: `22`)                      | Hayır   |
| `DO_TARGET_DIR`      | Hedef dizin (varsayılan: `/opt/goldgame`)         | Hayır   |

Hepsi bu kadar. Artık `main` veya `claude/gold-game-index-page-h80dgz` dalına
her push'ta oyun **https://goldgame.sinsoft.com.tr/** adresinde otomatik
güncellenir. Deploy'u elle
tetiklemek isterseniz GitHub'da **Actions → DigitalOcean Droplet'e Deploy
(Docker) → Run workflow** kullanabilirsiniz.

