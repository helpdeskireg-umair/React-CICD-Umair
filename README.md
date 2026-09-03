# my-react-app — CI/CD Demo

A minimal React app whose sole purpose is to prove that a CI/CD pipeline works end-to-end.  
Every push to `main` automatically runs tests and, if they pass, deploys the production build to a Linux VPS served by Nginx.

---

## What the App Does

- Displays **"Hello, Umair!"** on the screen.
- Displays **"This app was deployed with a CI/CD pipeline."**
- That's it — simple by design. The app is the proof, not the feature.

---

## Project Structure

```
my-react-app/
├── .github/
│   └── workflows/
│       └── ci.yml          # GitHub Actions CI/CD pipeline
├── public/
│   └── index.html          # HTML shell
├── src/
│   ├── App.js              # Main component
│   ├── App.css             # App styles
│   ├── App.test.js         # Jest + RTL tests
│   ├── index.js            # React entry point
│   └── index.css           # Global styles
├── package.json
└── README.md
```

---

## Run Locally

**Requirements:** Node.js 18+, npm

```bash
# 1. Clone the repo
git clone https://github.com/<your-username>/my-react-app.git
cd my-react-app

# 2. Install dependencies
npm install

# 3. Start the dev server
npm start
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Run Tests

```bash
npm test
```

You should see 3 tests pass:
- `renders without crashing`
- `displays the greeting message`
- `displays the pipeline message`

### Build for Production

```bash
npm run build
```

This creates a `build/` folder with optimized static files ready to be served by Nginx.

---

## CI/CD Pipeline (GitHub Actions)

The pipeline is defined in `.github/workflows/ci.yml`.

### Triggers

| Event | Branch | What happens |
|-------|--------|--------------|
| Push | `main` | Runs tests → deploys to VPS |
| Pull Request | `main` | Runs tests only (no deploy) |

### Pipeline Flow

```
Push to main
     │
     ▼
┌─────────────┐
│  JOB 1: CI  │  checkout → install deps → run tests
│  (test)     │
└──────┬──────┘
       │  tests pass?
       ▼
┌─────────────┐
│  JOB 2: CD  │  SSH into VPS → git pull → npm ci → npm build → reload nginx
│  (deploy)   │
└─────────────┘
```

### CI Steps (test job)

1. **Checkout code** — pulls your repository onto the runner.
2. **Set up Node.js 18** — installs the correct Node version.
3. **Install dependencies** — runs `npm ci` (clean, reproducible install).
4. **Run tests** — runs `npm test` (exits non-zero if any test fails, blocking deploy).

### CD Steps (deploy job)

1. Runs only when tests pass AND the push is to `main` (not pull requests).
2. SSHs into your VPS using secrets you configure in GitHub.
3. On the VPS: pulls latest code, installs deps, builds the app.
4. Reloads Nginx so the new build is live.

---

## GitHub Secrets

The deploy job reads three secrets from your GitHub repository. You must add these before the CD pipeline will work.

### Where to add them

1. Go to your GitHub repository.
2. Click **Settings** → **Secrets and variables** → **Actions**.
3. Click **New repository secret** for each one below.

### The three secrets

| Secret name | What to put in it | Example |
|-------------|-------------------|---------|
| `VPS_HOST` | The IP address of your VPS | `123.456.789.0` |
| `VPS_USER` | The SSH username on your VPS | `ubuntu` or `root` |
| `VPS_SSH_KEY` | Your **private** SSH key (the full contents of `~/.ssh/id_rsa`) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

> **VPS_SSH_KEY tip:** Run `cat ~/.ssh/id_rsa` on your local machine and paste the entire output — including the `-----BEGIN` and `-----END` lines.

---

## VPS Setup (Ubuntu 22.04 — Run Once)

These are the exact commands to run on a fresh Ubuntu 22.04 VPS to get it ready for deployments.

### Step 1 — SSH into your VPS

```bash
ssh ubuntu@YOUR_VPS_IP
```

### Step 2 — Update the system

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 3 — Install Node.js 18

```bash
# Install the NodeSource repository for Node 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js (npm comes with it)
sudo apt install -y nodejs

# Verify
node -v   # should print v18.x.x
npm -v
```

### Step 4 — Install Git

```bash
sudo apt install -y git
```

### Step 5 — Install Nginx

```bash
sudo apt install -y nginx

# Start Nginx and enable it on boot
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify it's running
sudo systemctl status nginx
```

### Step 6 — Create the app folder and clone your repo

```bash
# Create the deployment directory
sudo mkdir -p /var/www/my-react-app
sudo chown $USER:$USER /var/www/my-react-app

# Clone your GitHub repository into it
git clone https://github.com/<your-username>/my-react-app.git /var/www/my-react-app
```

### Step 7 — Add the VPS deploy key to GitHub (so git pull works)

On the VPS, generate an SSH key pair:

```bash
ssh-keygen -t ed25519 -C "vps-deploy-key" -f ~/.ssh/deploy_key -N ""
cat ~/.ssh/deploy_key.pub
```

Copy the output. In GitHub go to your repo → **Settings** → **Deploy keys** → **Add deploy key**.  
Paste the public key. Give it read access only.

Then tell git on the VPS to use this key:

```bash
git config --global core.sshCommand "ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no"
```

### Step 8 — Allow the deploy user to reload Nginx without a password

The deployment script runs `sudo systemctl reload nginx`. To allow this without a password prompt (required for non-interactive SSH):

```bash
# Open the sudoers file safely
sudo visudo
```

Add this line at the bottom (replace `ubuntu` with your actual username):

```
ubuntu ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx
```

### Step 9 — Configure Nginx to serve the React build

```bash
sudo nano /etc/nginx/sites-available/my-react-app
```

Paste this config:

```nginx
server {
    listen 80;
    server_name YOUR_VPS_IP;   # replace with your IP or domain name

    root /var/www/my-react-app/build;
    index index.html;

    # For React Router — serve index.html for all routes
    location / {
        try_files $uri /index.html;
    }

    # Cache static assets
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable the config:

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/my-react-app /etc/nginx/sites-enabled/

# Remove the default site
sudo rm /etc/nginx/sites-enabled/default

# Test the config for syntax errors
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 10 — Do the first manual build

```bash
cd /var/www/my-react-app
npm ci
npm run build
```

Open `http://YOUR_VPS_IP` in a browser — you should see the app.

---

## How Deployments Work After Setup

Once everything above is done:

1. You make a code change locally.
2. `git push origin main`
3. GitHub Actions picks it up automatically.
4. Tests run. If they pass, the deploy job SSHes into your VPS and runs the build.
5. Nginx serves the new build. Done.

The whole pipeline typically takes about 2–3 minutes.

---

## Troubleshooting

**Tests fail in CI but pass locally**  
Make sure you're on Node 18 locally (`node -v`). The CI runner uses Node 18 exactly.

**SSH permission denied in deploy job**  
- Double-check that `VPS_SSH_KEY` contains the full private key including the header/footer lines.
- Make sure the corresponding public key is in `~/.ssh/authorized_keys` on the VPS.

**Nginx shows 403 or 404**  
- Confirm the `build/` folder exists on the VPS: `ls /var/www/my-react-app/build`
- Check Nginx error logs: `sudo tail -f /var/log/nginx/error.log`

**git pull fails (permission denied)**  
- Make sure the deploy key is added to GitHub and configured on the VPS (Step 7).

---

## License

MIT
