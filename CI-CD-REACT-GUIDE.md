# CI/CD for React — GitHub Actions + VPS (Nginx)

## Flow

```
Push to main → GitHub Actions → Run Tests → Deploy → VPS (Nginx serves build/)
```

## 1. Push Code to GitHub

```bash
git init
git remote add origin https://<token>@github.com/helpdeskireg-umair/React-CICD-Umair.git
git add . && git commit -m "Initial commit"
git branch -M main && git push -u origin main
```

## 2. VPS Setup (once only)

```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs nginx git

# Stop Apache if using port 80 (e.g. CloudPanel)
sudo systemctl stop apache2 && sudo systemctl disable apache2
sudo systemctl start nginx
```

## 3. Clone + Build App on VPS

```bash
sudo mkdir -p /var/www/my-react-app
cd /var/www/my-react-app
git clone git@github.com:helpdeskireg-umair/React-CICD-Umair.git .
npm install
npm run build
```

## 4. Nginx Config

```bash
sudo nano /etc/nginx/sites-available/my-react-app.conf   # MUST end in .conf
```

```nginx
server {
    listen 80;
    server_name 145.223.79.115;

    root /var/www/my-react-app/build;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
sudo ln -sf /etc/nginx/sites-available/my-react-app.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default*
sudo nginx -t && sudo systemctl reload nginx
```

## 5. SSH Key for GitHub Actions

```bash
# On VPS
ssh-keygen -t rsa -b 4096 -f ~/.ssh/deploy_key_rsa -N "" -C "deploy"
cat ~/.ssh/deploy_key_rsa.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/deploy_key_rsa          # copy this → private key

# Passwordless nginx reload
echo "root ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx" > /etc/sudoers.d/nginx-reload

# Let git pull via deploy key
git config --global core.sshCommand "ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no"
```

## 6. GitHub Secrets (Settings → Secrets → Actions)

| Secret | Value |
|--------|-------|
| `VPS_HOST` | `145.223.79.115` |
| `VPS_USER` | `root` |
| `VPS_SSH_KEY` | private key from step 5 |

## 7. Workflow (`.github/workflows/ci.yml`)

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '18', cache: 'npm' }
      - run: npm ci
      - run: npm test

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /var/www/my-react-app
            git pull origin main
            npm install
            npm run build
            sudo systemctl reload nginx
```

## Done — Live at http://145.223.79.115

Push to `main` → tests run → code pulled → build regenerated → Nginx serves the new version automatically.