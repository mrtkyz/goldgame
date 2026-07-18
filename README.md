# Talha'nın Altın Oyunu 🪙

Tarayıcıda çalışan, tek dosyalık (`index.html`) HTML5 canvas oyunu. Keseyi hareket
ettirip altınları topla, bombalardan kaç!

## Otomatik Deploy (DigitalOcean Droplet)

`main` dalına yapılan her push, GitHub Actions ile droplet'e otomatik olarak
deploy edilir (`.github/workflows/deploy.yml`). Kurulum iki adımdan oluşur:

### 1. Sunucuyu hazırla (bir kereye mahsus)

Droplet'e root olarak bağlanıp kurulum script'ini çalıştırın:

```bash
scp deploy/setup-server.sh root@<droplet-ip>:/tmp/
ssh root@<droplet-ip> "bash /tmp/setup-server.sh"
```

Bu script nginx'i kurar, `/var/www/goldgame` dizinini oluşturur ve sadece bu
dizine yazabilen `deploy` adlı bir kullanıcı ekler.

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
| `DO_HOST`            | Droplet'in IP adresi                              | Evet    |
| `DO_USER`            | `deploy`                                          | Evet    |
| `DO_SSH_PRIVATE_KEY` | `goldgame_deploy` dosyasının **tüm içeriği**      | Evet    |
| `DO_PORT`            | SSH portu (varsayılan: `22`)                      | Hayır   |
| `DO_TARGET_DIR`      | Hedef dizin (varsayılan: `/var/www/goldgame`)     | Hayır   |

Hepsi bu kadar. Artık `main`'e her push'ta oyun `http://<droplet-ip>/`
adresinde otomatik güncellenir. Deploy'u elle tetiklemek isterseniz GitHub'da
**Actions → DigitalOcean Droplet'e Deploy → Run workflow** kullanabilirsiniz.
