# Evilginx 3 — Production Configuration & Deployment Guide

## 1. Required Configuration (`.env`)

```bash
# REQUIRED - Must change for production
EVILGINX_DOMAIN=yourdomain.com           # Your registered domain
EVILGINX_EXTERNAL_IPV4=1.2.3.4           # Your VPS public IP
EVILGINX_ENABLE_PHISHLETS=github,linkedin,facebook  # Enable only needed phishlets
```

## 2. Production Changes Required

| Setting | Dev Value | Production Value |
|---------|-----------|------------------|
| EVILGINX_DEVELOPER | true | **false** (uses Let's Encrypt) |
| EVILGINX_DEBUG | true | **false** |
| EVILGINX_UNAUTH_URL | rickroll | **https://yourdomain.com/404** |
| EVILGINX_BIND_IPV4 | 0.0.0.0 | Keep 0.0.0.0 or specific IP |

## 3. DNS Setup (Required for Let's Encrypt)

```bash
# Add A records pointing to your VPS IP:
github.yourdomain.com     A   1.2.3.4
linkedin.yourdomain.com   A   1.2.3.4
facebook.yourdomain.com   A   1.2.3.4
yourdomain.com            A   1.2.3.4
```

## 4. Port Requirements

| Port | Protocol | Purpose |
|------|----------|---------|
| 80   | TCP      | HTTP + Let's Encrypt ACME challenge |
| 443  | TCP      | HTTPS (phishing pages) |
| 53   | UDP      | DNS (optional, for custom domains) |

## 5. Firewall / Security

```bash
# Allow only required ports
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 53/udp    # Only if using DNS
ufw enable

# In cloud provider (AWS/GCP/Azure): open Security Groups for 80, 443, 53
```

## 6. TLS Certificates

- **Dev mode** (EVILGINX_DEVELOPER=true): Self-signed certs (browser warnings)
- **Production** (EVILGINX_DEVELOPER=false): Let's Encrypt auto-certs (requires valid DNS + port 80)

## 7. Phishlet Selection

```bash
# Only enable what you need (reduces attack surface)
EVILGINX_ENABLE_PHISHLETS=github,linkedin
# Available: amazon, citrix, facebook, github, instagram, linkedin, o365, okta, onelogin, outlook, protonmail, reddit, twitter, twitter-mobile, wordpress.org
```

## 8. Deployment Commands

```bash
# Build
docker compose build

# Deploy
docker compose up -d

# Monitor
docker compose logs -f evilginx

# Health check
docker compose ps

# Update
docker compose pull && docker compose build && docker compose up -d

# Backup config
tar -czf evilginx-backup-$(date +%Y%m%d).tar.gz config/ logs/
```

## 9. Production Hardening Checklist

- [ ] Change EVILGINX_DOMAIN to your real domain
- [ ] Set EVILGINX_EXTERNAL_IPV4 to your VPS IP
- [ ] Set EVILGINX_DEVELOPER=false
- [ ] Set EVILGINX_DEBUG=false
- [ ] Configure DNS A records for all phishlet subdomains
- [ ] Open ports 80/443 on firewall
- [ ] Enable only needed phishlets
- [ ] Set up log rotation for logs/evilginx/
- [ ] Monitor disk space (certs + logs grow)
- [ ] Set up automated backups of /config/certs (Let's Encrypt certs)

## 10. Common Issues

| Issue | Fix |
|-------|-----|
| "no certificate available" | DNS not propagated, port 80 blocked, or EVILGINX_DEVELOPER=true |
| Port 53 conflict | Comment out DNS port in docker-compose.yml |
| Phishlet not loading | Check config/evilginx/phishlets/ has .yaml files |
| Blacklist blocking you | Set "blacklist": {"mode": "none"} in config.json |

## 11. Legal/Operational Warning

**Evilginx is a phishing framework.** Only deploy in authorized penetration tests on systems you own or have explicit written permission to test. Unauthorized use is illegal in most jurisdictions.