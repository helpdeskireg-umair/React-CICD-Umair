# Complete CI/CD Pipeline Documentation

## Project: React-CICD-Umair

### Overview
This document provides a complete, step-by-step guide to implementing a fully automated **CI/CD (Continuous Integration / Continuous Deployment)** pipeline for a React application. The pipeline uses **GitHub Actions** to automatically run tests on every code change and deploy the production build to a live production server (VPS) served by **Nginx**.

---

## Table of Contents
1. [What is CI/CD?](#1-what-is-cicd)
2. [Architecture Overview](#2-architecture-overview)
3. [Tools & Technologies Used](#3-tools--technologies-used)
4. [Step-by-Step Implementation](#4-step-by-step-implementation)
   - [Step 1: Create the React App](#step-1-create-the-react-app)
   - [Step 2: Set Up GitHub Repository](#step-2-set-up-github-repository)
   - [Step 3: Write the CI/CD Workflow](#step-3-write-the-cicd-workflow)
   - [Step 4: Purchase a VPS](#step-4-purchase-a-vps)
   - [Step 5: Set Up the VPS](#step-5-set-up-the-vps)
   - [Step 6: Generate SSH Deploy Key](#step-6-generate-ssh-deploy-key)
   - [Step 7: Configure Nginx](#step-7-configure-nginx)
   - [Step 8: Add GitHub Secrets](#step-8-add-github-secrets)
   - [Step 9: Trigger the Pipeline](#step-9-trigger-the-pipeline)
   - [Step 10: Verify Deployment](#step-10-verify-deployment)
5. [The Workflow File Explained](#5-the-workflow-file-explained)
6. [How Deployments Work](#6-how-deployments-work)
7. [Troubleshooting](#7-troubleshooting)
8. [Security Best Practices](#8-security-best-practices)
9. [Cost Breakdown](#9-cost-breakdown)

---

## 1. What is CI/CD?

**CI (Continuous Integration):**
- Every push to the code repository automatically triggers tests
- Catches bugs early before they reach production
- Ensures code quality through automated testing

**CD (Continuous Deployment):**
- After tests pass, the code is automatically deployed to a production server
- No manual steps required between code push and live deployment
- Faster release cycles and reduced human error

---

## 2. Architecture Overview

```
Developer pushes code to GitHub (main branch)
                    │
                    ▼
        ┌─────────────────────────┐
        │    GitHub Actions       │
        │   (Automated Pipeline)  │
        └────────────┬────────────┘
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
   ┌─────────────┐       ┌─────────────┐
   │  JOB 1: CI  │       │  JOB 2: CD  │
   │ Run Tests   │──────▶│  Deploy     │
   └─────────────┘       └──────┬──────┘
                                │ (SSH)
                                ▼
                        ┌─────────────┐
                        │  Linux VPS  │
                        │  + Nginx    │
                        └─────────────┘
                                │
                                ▼
                     http://145.223.79.115
```

---

## 3. Tools & Technologies Used

| Tool | Purpose |
|------|---------|
| **React 18** | Frontend framework |
| **Create React App** | Build tooling and dev server |
| **Jest + React Testing Library** | Unit testing framework |
| **GitHub Actions** | CI/CD automation (free for public repos) |
| **Ubuntu 22.04 VPS** | Production hosting environment |
| **Nginx** | Web server to serve the static build |
| **GitHub Deploy Keys** | Secure SSH access for deployment |
| **GitHub Secrets** | Store sensitive credentials (encrypted) |

---

## 4. Step-by-Step Implementation

### Step 1: Create the React App

```bash
npx create-react-app my-react-app
cd my-react-app
```

Modify `src/App.js` to display the application content:

```jsx
function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>Hello, Umair Rao!</h1>
        <p className="pipeline-message">
          This app was deployed with a CI/CD pipeline.
        </p>
      </header>
    </div>
  );
}
```

Create tests in `src/App.test.js`:

```jsx
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders without crashing', () => {
  render(<App />);
});

test('displays the greeting message', () => {
  render(<App />);
  const heading = screen.getByText(/Hello, Umair Rao!/i);
  expect(heading).toBeInTheDocument();
});

test('displays the pipeline message', () => {
  render(<App />);
  const message = screen.getByText(/This app was deployed with a CI\/CD pipeline\./i);
  expect(message).toBeInTheDocument();
});
```

**Test locally:**
```bash
npm test
```

**Expected output:**
```
Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
```

---

### Step 2: Set Up GitHub Repository

1. Create a new repository on GitHub: `React-CICD-Umair`
2. Push the local code:
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/helpdeskireg-umair/React-CICD-Umair.git
git push origin main
```

---

### Step 3: Write the CI/CD Workflow

Create the file `.github/workflows/ci.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  # ────────────────────────────────────
  # JOB 1: Run tests (CI)
  # ────────────────────────────────────
  test:
    name: Run Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Node.js 18
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

  # ────────────────────────────────────
  # JOB 2: Deploy to VPS (CD)
  # Runs only after tests pass on main
  # ────────────────────────────────────
  deploy:
    name: Deploy to VPS
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

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
            echo "✅ Deployment complete!"
```

---

### Step 4: Purchase a VPS

1. Choose a provider (examples):
   - **DigitalOcean** — $4/month droplet
   - **AWS EC2** — free tier
   - **Vultr** — $5/month
   - **CloudPanel** — used in this project

2. Create an **Ubuntu 22.04** server
3. Note the **IP address**: `145.223.79.115`
4. SSH into the server:
```bash
ssh root@145.223.79.115
```

---

### Step 5: Set Up the VPS

Run these commands on the VPS:

```bash
# 1. Update the system
apt update && apt upgrade -y

# 2. Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 3. Install Git and Nginx
apt install -y git nginx

# 4. Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# 5. Create deployment directory
mkdir -p /var/www/my-react-app
cd /var/www/my-react-app

# 6. Clone the repository
git clone git@github.com:helpdeskireg-umair/React-CICD-Umair.git .

# 7. Install dependencies and build
npm install
npm run build
```

> **Note:** If Apache2 is already running (common with CloudPanel), stop it first:
> ```bash
> systemctl stop apache2
> systemctl disable apache2
> systemctl start nginx
> ```

---

### Step 6: Generate SSH Deploy Key

The pipeline needs SSH access to the VPS without a password prompt.

```bash
# 1. Generate a key pair
ssh-keygen -t ed25519 -C "deploy-key" -f ~/.ssh/deploy_key -N ""

# 2. Add the public key to authorized_keys
cat ~/.ssh/deploy_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 3. Configure git to use the deploy key
git config --global core.sshCommand "ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no"

# 4. Test the key works
ssh -i ~/.ssh/deploy_key root@localhost "echo ok"
```

**Alternative (RSA key for GitHub Actions compatibility):**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/deploy_key_rsa -N "" -C "deploy-key-rsa"
cat ~/.ssh/deploy_key_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/deploy_key_rsa
```

---

### Step 7: Configure Nginx

Create the site configuration:

```bash
cat > /etc/nginx/sites-available/my-react-app.conf << 'EOF'
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
EOF
```

**Important:** The file MUST end with `.conf` so Nginx loads it:

```bash
# Enable the site
ln -sf /etc/nginx/sites-available/my-react-app.conf /etc/nginx/sites-enabled/

# Remove any default sites
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/default.conf

# Test and reload Nginx
nginx -t
systemctl reload nginx
```

**Verify:**
```bash
curl -s http://localhost | head -20
```

---

### Step 8: Add GitHub Secrets

Go to **GitHub → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Value |
|-------------|-------------|-------|
| `VPS_HOST` | VPS IP address | `145.223.79.115` |
| `VPS_USER` | SSH username | `root` |
| `VPS_SSH_KEY` | SSH private key (RSA recommended) | Full output of `cat ~/.ssh/deploy_key_rsa` |

**To get the private key (on VPS):**
```bash
cat ~/.ssh/deploy_key_rsa
```

Copy the **entire output** including the `-----BEGIN` and `-----END` lines, with **no extra spaces or blank lines**.

Secrets are:
- **Encrypted** at rest
- **Never exposed** in logs
- Referenced as `${{ secrets.NAME }}` in the workflow

---

### Step 9: Trigger the Pipeline

Make any code change and push to `main`:

```bash
git add .
git commit -m "Update deployment"
git push origin main
```

GitHub Actions automatically triggers:
1. **Run Tests** job
2. **Deploy to VPS** job (only after tests pass, only on `main`)

---

### Step 10: Verify Deployment

1. Open **GitHub → Actions tab** — watch both jobs complete
2. Open your browser at **http://145.223.79.115**
3. You should see the React app displaying **"Hello, Umair Rao!"**

**To verify a change deploys automatically:**
```bash
# Local: change the greeting
# git add, commit, push
# Wait 2-3 minutes
# Refresh the browser — change is live!
```

---

## 5. The Workflow File Explained

| Section | Purpose |
|---------|---------|
| `on: push` | Runs on every push to any branch |
| `on: pull_request` | Also runs on pull requests (for review) |
| `jobs.test` | CI job — installs deps and runs tests |
| `actions/checkout@v4` | Clones the repo code |
| `actions/setup-node@v4` | Installs Node.js 18 |
| `npm ci` | Clean install (hard fail if lock is out of sync) |
| `npm test` | Runs Jest tests; fails the job if any test fails |
| `jobs.deploy` | CD job — deploys to production VPS |
| `needs: test` | Only runs after test job succeeds |
| `if: github.ref == 'refs/heads/main'` | Only on main branch |
| `if: github.event_name == 'push'` | Only on push (not PRs) |
| `appleboy/ssh-action@v1.0.3` | SSHes into the VPS and runs commands |

---

## 6. How Deployments Work

**The complete automated flow:**

1. Developer edits code locally
2. Runs `git push origin main`
3. GitHub Actions detects the push
4. **CI Job:** 
   - Clones the repo
   - Installs dependencies
   - Runs all tests
5. **If tests fail** → pipeline stops, developer gets an error
6. **If tests pass:**
   - **CD Job** SSHes into the VPS
   - Then on the VPS:
     a. `git pull origin main` — fetches latest code
     b. `npm install` — installs dependencies
     c. `npm run build` — creates optimized production build
     d. `sudo systemctl reload nginx` — serves the new build
7. Website updates automatically — no manual intervention

**Time to full deployment:** ~2–3 minutes

---

## 7. Troubleshooting

### Test fails in CI but passes locally
- Ensure Node version matches (`node -v`)
- CI uses Node 18; update locally if needed

### Permission denied on git push
- Clear cached credentials: `git credential reject` (host=github.com)
- Re-authenticate with the correct GitHub account

### SSH: unable to authenticate
- The `VPS_SSH_KEY` secret may have wrong/malformed key
- Ensure you used the **RSA key** (`deploy_key_rsa`) not the ed25519 key
- Check no extra blank lines around the key
- Verify key is in `~/.ssh/authorized_keys` on VPS

### Nginx returns empty reply
- Ensure site config ends with `.conf`
- Nginx only auto-loads `*.conf` files from `sites-enabled`

### Nginx fails to start (Address already in use)
- Apache2 or another service is using port 80
- Stop the other service: `systemctl stop apache2`

### npm ci fails (lock file out of sync)
- Use `npm install` instead, or regenerate lock file

### Deploy passes but site not updated
- Verify build folder updated: `ls /var/www/my-react-app/build`

---

## 8. Security Best Practices

| Practice | Implementation |
|----------|----------------|
| **No plaintext passwords** | All credentials stored as GitHub Secrets (encrypted at rest) |
| **Restricted SSH key** | Separate deploy key with no passphrase, specific to this server |
| **Never commit secrets** | `.gitignore` excludes `.env` and secret files |
| **Branch protection** | Tests run on every PR before merging to `main` |
| **Limited sudo** | Only Nginx reload allowed without password |
| **Read-only deploy key** | The GitHub deploy key used for `git pull` has write access only where needed |

---

## 9. Cost Breakdown

| Resource | Cost |
|----------|------|
| GitHub Actions | **Free** (2000 minutes/month for private repos, unlimited for public) |
| GitHub Repository | Free |
| Ubuntu VPS | ~$4–6/month |
| Domain (optional) | ~$10/year |
| **Total** | **~$4–6/month** |

---

## Summary

This project demonstrates a production-grade CI/CD pipeline where:
- **Code quality** is enforced through automated testing
- **Deployments are fully automated** — push to `main`, and the app updates itself
- **No manual steps** required between commit and production
- **Rollback** is easy (revert the git commit and push again)

The pipeline is reusable — swap the React build for any static site, Node.js, or Dockerized app to deploy other projects with the same automation.
