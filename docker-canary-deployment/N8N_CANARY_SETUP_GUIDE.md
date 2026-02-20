# N8N CANARY DEPLOYMENT SETUP GUIDE

## 🎯 Overview

Bu setup CTO'nun "PR'da deploy patlıyor mu?" isteğini gerçek deployment testi ile karşılar:

**PR açıldığında:**
- `/opt/n8n-pr` → port **5679** → Test → Sil ❌

**Merge sonrası (dev branch):**
- `/opt/n8n` → port **5678** → Production (kalıcı) ✅

---

## 📁 Repo Yapısı

```
repository/
├── docker-canary-deployment/
│   ├── docker-compose.yml       # Production (port 5678)
│   └── docker-compose.pr.yml    # PR override (port 5679)
│
└── .github/
    └── workflows/
        ├── n8n-deploy-plan-pr.yml    # PR canary test
        └── n8n-deploy-apply-merge.yml  # Production deploy
```

---


## 🔄 Workflow Nasıl Çalışır?

### Senaryo 1: Developer PR Açar

```
1. Developer yeni feature branch oluşturur
   git checkout -b feature/new-workflow

2. docker/docker-compose.yml değiştirir

3. PR açar: feature/new-workflow → dev

4. ⚡ n8n PR Canary workflow otomatik başlar:
   - docker-compose.yml + docker-compose.pr.yml birleştirir
   - /opt/n8n-pr klasörüne yazar
   - Port 5679'da container başlatır
   - curl localhost:5679 health check
   - Container'ı siler (down -v)

5a. ✅ Test başarılı → PR'ye yorum yazar:
    "✅ n8n Canary Test Passed - Safe to merge!"
    
5b. ❌ Test başarısız → PR'ye yorum yazar:
    "❌ n8n Canary Test Failed - Cannot merge"
    
6. CTO merge yapar (sadece test pass ise)
```

### Senaryo 2: Merge Sonrası Production Deploy

```
1. CTO merge yapar: feature/new-workflow → dev

2. ⚡ n8n Deploy to Production workflow otomatik başlar:
   - docker-compose.yml'yi /opt/n8n altına yazar
   - Port 5678'de production container'ı günceller
   - Health check yapar
   - Container çalışır durumda kalır ✅

3. n8n production güncellenmiş olur!
```

---

## 🧪 Test

### PR Canary Test:

```bash
# PR aç
git checkout -b test/canary-deployment
# docker-compose.yml'de küçük değişiklik yap
git commit -am "Test canary deployment"
git push origin test/canary-deployment

# PR aç GitHub'da
# Workflow otomatik çalışacak

# Sonuç:
# - Actions tab'de workflow'u izle
# - PR'de comment gelecek (success/failure)
```

### Production Deploy Test:

```bash
# PR merge et (canary test pass ise)
# Otomatik production deploy başlar

# Verify:
curl https://n8n.bensonpaca.com
# n8n login page görünmeli
```

---

## 📊 Port Mapping

| Environment | Directory | Port | Container Name | Lifecycle |
|-------------|-----------|------|----------------|-----------|
| **Production** | `/opt/n8n` | 5678 | `n8n` | Persistent |
| **PR Canary** | `/opt/n8n-pr` | 5679 | `pr-n8n` | Temporary (deleted after test) |

**Önemli:** İki container **aynı imajı** (`n8nio/n8n:next`) kullanır ama:
- Farklı port'larda çalışır (izolasyon)
- Farklı project name (`-p pr`) ile ayrılır
- PR canary test sonrası **silinir** (`down -v`)

---

## 🔍 Monitoring

### PR Canary Logs:

```bash
# Workflow running sırasında
aws ssm start-session --target <instance-id>

# Canary container logs
sudo docker logs pr-n8n --tail 100

# Canary çalışıyor mu kontrol
sudo docker ps --filter name=pr-n8n
```

### Production Logs:

```bash
# Production container logs
sudo docker logs n8n --tail 100 -f

# Container status
sudo docker ps --filter name=n8n
```

---

## 🐛 Troubleshooting

### Issue: PR Canary Test Fails

**Check:**
```bash
# GitHub Actions logs
# Actions → PR Canary workflow → Logs

# EC2'de manuel test
aws ssm start-session --target <instance-id>
cd /opt/n8n-pr
sudo docker compose -p pr -f docker-compose.yml -f docker-compose.pr.yml --env-file .env config
sudo docker compose -p pr -f docker-compose.yml -f docker-compose.pr.yml --env-file .env up -d
sudo docker logs pr-n8n
```

**Common causes:**
1. Database connection failed → Check DB_POSTGRESDB_* secrets
2. Port 5679 already in use → Check: `netstat -tlnp | grep 5679`
3. Compose syntax error → Validate locally
4. Docker not installed → Check user_data.sh

### Issue: Production Deploy Fails

**Check:**
```bash
# EC2'de manuel deploy
cd /opt/n8n
sudo docker compose --env-file .env up -d
sudo docker logs n8n
```

**Rollback:**
```bash
# Önceki image'a dön
sudo docker compose --env-file .env down
sudo docker pull n8nio/n8n:1.xx.x  # Önceki versiyon
# docker-compose.yml'de image tag'i değiştir
sudo docker compose --env-file .env up -d
```

### Issue: Secrets Not Found

**Verify secrets:**
```bash
# Repository secrets listele (GitHub UI)
Settings → Secrets → Actions

# Required:
# - AWS_ROLE_ARN
# - EC2_INSTANCE_ID
# - N8N_HOST
# - N8N_ENCRYPTION_KEY
# - DB_POSTGRESDB_*
```

---

## 🎉 Success Checklist

Deployment setup tamamlandıktan sonra:

- [ ] `docker/docker-compose.yml` eklendi
- [ ] `docker/docker-compose.pr.yml` eklendi
- [ ] `.github/workflows/n8n-pr-canary.yml` eklendi
- [ ] `.github/workflows/n8n-deploy-prod.yml` eklendi
- [ ] GitHub Secrets eklendi (11 adet)
- [ ] Branch protection rule eklendi (dev branch)
- [ ] Production environment oluşturuldu (optional)
- [ ] Test PR açıldı
- [ ] PR canary test passed ✅
- [ ] PR merged
- [ ] Production deploy successful ✅
- [ ] n8n accessible: https://n8n.bensonpaca.com ✅

---

## 💡 Benefits

**CTO için:**
- ✅ Her PR gerçek deployment testi ile doğrulanır
- ✅ Hatalı PR'ler merge edilemez (branch protection)
- ✅ Production güvenli kalır

**Developer için:**
- ✅ Lokalde test etmeden önce EC2'de test
- ✅ Database connection test
- ✅ Container başlatma testi
- ✅ Otomatik cleanup (manuel temizlik gerekmez)

**DevOps için:**
- ✅ Fully automated (manuel adım yok)
- ✅ Reproducible (her PR aynı test)
- ✅ No manual cleanup needed
- ✅ Version controlled (workflow as code)

---

## 🔄 Update Workflow

### Güncelleme Yapmak İsterseniz:

1. **docker/docker-compose.yml** dosyasını değiştir
2. PR aç
3. Canary test otomatik çalışır
4. Test pass ise merge et
5. Production otomatik güncellenir

**Tek adım:** PR aç → Merge et → Done! 🚀

---

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [n8n Self-Hosting Guide](https://docs.n8n.io/hosting/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS SSM Run Command](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html)

---

## 🎯 Next Steps

1. Setup tamamla (yukarıdaki adımlar)
2. Test PR aç
3. Canary test'i izle
4. Merge et
5. Production deploy'u izle
6. Enjoy automated n8n deployments! 🎉
