#!/bin/bash
set -e

echo "=== Step 1: Updating system ==="
apt update && apt upgrade -y

echo "=== Step 2: Installing Node.js 18 ==="
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "=== Step 3: Installing Git and Nginx ==="
apt install -y git nginx

echo "=== Step 4: Starting and enabling Nginx ==="
systemctl start nginx
systemctl enable nginx

echo "=== Step 5: Creating app directory ==="
mkdir -p /var/www/my-react-app
cd /var/www/my-react-app

echo "=== Step 6: Cloning your repo ==="
# Replace YOUR_GITHUB_USERNAME with your actual GitHub username
git clone https://github.com/AWAIS-ALI-DOTCOM/my-react-app.git .

echo "=== Step 7: Installing dependencies and building ==="
npm ci
npm run build

echo "=== Step 8: Configuring Nginx ==="
VPS_IP=$(curl -s ifconfig.me)
cat > /etc/nginx/sites-available/my-react-app <<EOF
server {
    listen 80;
    server_name $VPS_IP;

    root /var/www/my-react-app/build;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }

    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

ln -sf /etc/nginx/sites-available/my-react-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "=== Step 9: Allowing Nginx reload without password ==="
echo "root ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx" > /etc/sudoers.d/nginx-reload

echo "=== Step 10: Generating deploy SSH key ==="
ssh-keygen -t ed25519 -C "deploy-key" -f ~/.ssh/deploy_key -N ""
cat ~/.ssh/deploy_key.pub

echo ""
echo "================================================"
echo "  SETUP COMPLETE!"
echo ""
echo "  Your app should now be live at: http://$VPS_IP"
echo ""
echo "  NEXT STEPS:"
echo "  1. Copy the public key above (starts with ssh-ed25519)"
echo "  2. Go to GitHub repo -> Settings -> Deploy keys -> Add deploy key"
echo "  3. Paste the public key and check 'Allow write access'"
echo "  4. Run this command on VPS to use the deploy key:"
echo "     git config --global core.sshCommand 'ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no'"
echo "  5. Add GitHub Secrets (VPS_HOST, VPS_USER, VPS_SSH_KEY)"
echo "  6. Push a change to main to test the pipeline"
echo "================================================"
