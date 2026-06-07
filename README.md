# UnknownForums

A community discussion forum built with Ruby on Rails.

- **Domain:** unknownforums.fun
- **Database:** Neon (serverless PostgreSQL)
- **File Storage:** Cloudflare R2
- **Reverse Proxy:** Caddy (automatic HTTPS)
- **App Port:** 4251

---

## Local Development

```bash
bundle install
bin/rails db:setup
bin/rails server
```

Runs at `http://localhost:4251`.

---

## Production Deployment (VPS + Caddy + Neon + Docker)

### 1. DNS

Point your domain at your VPS IP in your registrar:

```
A    @    → YOUR_VPS_IP
A    www  → YOUR_VPS_IP
```

### 2. VPS Setup

```bash
# Update
sudo apt update && sudo apt upgrade -y

# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in

# Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy

# Firewall
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### 3. Neon Database

1. Go to [neon.tech](https://neon.tech) and create a project
2. Create a database (e.g. `unknownforums`)
3. Copy the connection string:
   ```
   postgresql://user:pass@ep-xxxxx.us-east-2.aws.neon.tech/unknownforums?sslmode=require
   ```

### 4. Caddyfile

```bash
sudo nano /etc/caddy/Caddyfile
```

```
unknownforums.fun, www.unknownforums.fun {
    reverse_proxy 127.0.0.1:4251 {
        health_uri /up
        health_interval 15s
        transport http {
            read_timeout 24h
            write_timeout 24h
        }
    }

    header {
        -Server
        X-Robots-Tag "index, follow"
    }

    encode gzip

    request_body {
        max_size 100MB
    }
}
```

Forum uploads go **directly to Cloudflare R2** from the browser (not through Caddy). Files over 5 GB use R2 multipart upload automatically. The `request_body` limit only applies to normal form posts (thread text, signed upload IDs, etc.).

For a **100 GB** upload on a 100 Mbps connection, expect roughly 2–3 hours of upload time — keep the tab open until it finishes.

Configure R2 CORS on your bucket:

```json
[
  {
    "AllowedOrigins": ["https://unknownforums.fun", "https://www.unknownforums.fun"],
    "AllowedMethods": ["GET", "PUT", "POST", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

```bash
sudo systemctl restart caddy
```

Caddy automatically provisions and renews SSL certificates.

### 5. App Directory

```bash
mkdir -p ~/unknownforums && cd ~/unknownforums
```

### 6. docker-compose.yml

```yaml
x-app: &app
  build: .
  restart: always
  env_file:
    - .env
  environment:
    RAILS_ENV: production
    PORT: "4251"
    RAILS_SERVE_STATIC_FILES: "true"
    FORUM_NAME: "UnknownForums"

services:
  web:
    <<: *app
    command: ./bin/rails server -p 4251 -b 0.0.0.0
    ports:
      - "127.0.0.1:4251:4251"

  worker:
    <<: *app
    command: ./bin/jobs start
    depends_on:
      - web
```

### 7. .env

```bash
nano ~/unknownforums/.env
```

```env
# Run `cat config/master.key` locally to get this value
RAILS_MASTER_KEY=your_master_key_here

# Neon connection string
DATABASE_URL=postgresql://user:pass@ep-xxxxx.us-east-2.aws.neon.tech/unknownforums?sslmode=require

# Site host and Resend API email delivery
APP_HOST=unknownforums.fun
RESEND_API_KEY=re_your_resend_api_key_here
MAIL_FROM="UnknownForums <noreply@unknownforums.fun>"

# Cloudflare R2
R2_ACCESS_KEY_ID=your_r2_key
R2_SECRET_ACCESS_KEY=your_r2_secret
R2_BUCKET=your_bucket_name
R2_ENDPOINT=https://your-account-id.r2.cloudflarestorage.com

# VirusTotal (optional — file scanning)
VIRUSTOTAL_API_KEY=your_vt_api_key_here

# Background job worker
JOB_CONCURRENCY=1
```

### 8. Deploy Code

From your local machine:

```bash
# Option A: Git
git remote add vps ssh://user@YOUR_VPS_IP:~/unknownforums
git push vps main

# Option B: rsync
rsync -avz --exclude='.git' --exclude='tmp' --exclude='log' \
  ./ user@YOUR_VPS_IP:~/unknownforums/
```

### 9. Build & Start

```bash
cd ~/unknownforums
docker compose build
docker compose up -d
docker compose exec web bin/rails db:migrate
```

Uploads are scanned by the `worker` service through Solid Queue. Keep both containers running:

```bash
docker compose ps
docker compose logs -f worker
```

If files stay stuck as `pending`, confirm:

```bash
docker compose exec web bin/rails runner 'puts ActiveJob::Base.queue_adapter.class'
docker compose exec web bin/rails runner 'p Attachment.order(created_at: :desc).limit(5).pluck(:id, :filename, :vt_status, :vt_scanned_at)'
docker compose logs --tail=100 worker
```

### 10. Verify

```bash
curl https://unknownforums.fun/up
curl https://unknownforums.fun/sitemap.xml
curl -I https://unknownforums.fun/
```

---

## Common Commands

```bash
# Logs
docker compose logs -f web
docker compose logs -f worker

# Migrations
docker compose exec web bin/rails db:migrate

# Rails console
docker compose exec web bin/rails console

# Rebuild after code changes
docker compose build && docker compose up -d

# Create admin user
docker compose exec web bin/rails console
# > User.create!(username: "admin", password: "YourPass", password_confirmation: "YourPass", role: "admin")
```

---

## Environment Variables

| Variable | Description |
|---|---|
| `RAILS_MASTER_KEY` | From `config/master.key` |
| `DATABASE_URL` | Neon PostgreSQL connection string |
| `APP_HOST` | Production host used for URLs and Action Cable (default: unknownforums.fun) |
| `RESEND_API_KEY` | Resend API key used to send OTP verification and login emails |
| `MAIL_FROM` | Verified Resend sender address, e.g. `UnknownForums <noreply@unknownforums.fun>` |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 access key |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 secret key |
| `R2_BUCKET` | R2 bucket name |
| `R2_ENDPOINT` | R2 endpoint URL |
| `FORUM_NAME` | Site name (default: UnknownForums) |
| `FORUM_DESCRIPTION` | Site description for SEO |
| `WEB_CONCURRENCY` | Puma workers (default: 2) |
| `RAILS_MAX_THREADS` | Puma threads (default: 3) |
| `BLOCKED_IPS` | Comma-separated IPs to block |
| `VIRUSTOTAL_API_KEY` | VirusTotal API key for automatic file scanning (optional) |

Email delivery uses the Resend API directly. SMTP variables such as `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, and `SMTP_PASSWORD` are not used for OTP emails.
