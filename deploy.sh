#!/usr/bin/env bash
# deploy.sh — Automated NGINX & Docker Deployment Script

set -Eeuo pipefail

LOGFILE="deploy_$(date +%Y%m%d_%H%M%S).log"
trap 'echo "[ERROR] Script failed at line $LINENO. Check $LOGFILE for details." | tee -a "$LOGFILE"; exit 1' ERR

log()   { echo "[$(date +'%F %T')] [INFO]  $*" | tee -a "$LOGFILE"; }
warn()  { echo "[$(date +'%F %T')] [WARN]  $*" | tee -a "$LOGFILE"; }
error() { echo "[$(date +'%F %T')] [ERROR] $*" | tee -a "$LOGFILE"; }

# --- Check for Cleanup Mode ---
if [[ "${1:-}" == "--cleanup" ]]; then
  echo "Cleanup mode activated."
  read -p "Enter remote username: " USER
  read -p "Enter remote server IP: " HOST
  read -p "SSH key path (default: ~/.ssh/id_rsa): " SSH_KEY
  SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}

  [[ -z "$USER" || -z "$HOST" ]] && { error "Missing cleanup credentials."; exit 1; }

  log "Performing remote cleanup..."
  ssh -i "$SSH_KEY" "$USER@$HOST" "bash -s" <<'EOF' | tee -a "$LOGFILE"
    set -e
    echo "Stopping and removing Docker containers..."
    sudo docker ps -aq | xargs -r sudo docker rm -f
    echo "Removing app files..."
    rm -rf ~/app_repo
    echo "Removing Nginx config..."
    sudo rm -f /etc/nginx/sites-available/app_repo /etc/nginx/sites-enabled/app_repo
    sudo nginx -t && sudo systemctl reload nginx
    echo "Cleanup completed."
EOF
  exit 0
fi

# --- Deployment Mode ---
echo "=== Automated Docker + NGINX Deployment ==="
read -p "Git repo URL: " GIT_URL
read -p "Branch (default: main): " BRANCH
BRANCH=${BRANCH:-main}
read -p "Remote username: " USER
read -p "Remote server IP: " HOST
read -p "SSH key path (default: ~/.ssh/id_rsa): " SSH_KEY
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
read -p "Application port (default: 80): " APP_PORT
APP_PORT=${APP_PORT:-80}

# --- Validation ---
log "Validating inputs..."
[[ -z "$GIT_URL" || -z "$USER" || -z "$HOST" ]] && { error "Required fields missing."; exit 1; }
[[ ! -f "$SSH_KEY" ]] && { error "SSH key not found: $SSH_KEY"; exit 1; }
for cmd in git ssh rsync; do
  command -v $cmd >/dev/null || { error "$cmd not installed."; exit 1; }
done

# --- Clone or Update Repo ---
log "Fetching repository..."
if [[ -d "app_repo/.git" ]]; then
  cd app_repo
  git fetch origin "$BRANCH"
  git reset --hard "origin/$BRANCH"
else
  git clone -b "$BRANCH" "$GIT_URL" app_repo
  cd app_repo
fi

# --- Docker Validation ---
if [[ ! -f Dockerfile && ! -f docker-compose.yml ]]; then
  error "No Dockerfile or docker-compose.yml found in repository."
  exit 1
fi
log "Docker configuration validated."

# --- SSH Connectivity Test ---
log "Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 "$USER@$HOST" "echo ok" &>/dev/null; then
  error "SSH connection failed for $USER@$HOST"
  exit 1
fi
log "SSH connection successful."

# --- Remote Environment Setup ---
log "Preparing remote environment..."
ssh -i "$SSH_KEY" "$USER@$HOST" "bash -s" <<'EOF' | tee -a "$LOGFILE"
  set -e
  sudo apt-get update -y
  sudo apt-get install -y docker.io docker-compose nginx
  sudo systemctl enable --now docker nginx
EOF

# --- File Transfer ---
log "Syncing files to remote server..."
rsync -az --exclude .git -e "ssh -i $SSH_KEY" ./ "$USER@$HOST:/home/$USER/app_repo" | tee -a "$LOGFILE"

# --- Deploy Application ---
log "Deploying application on remote server..."
ssh -i "$SSH_KEY" "$USER@$HOST" "bash -s" <<EOF | tee -a "$LOGFILE"
  set -e
  cd /home/$USER/app_repo
  if [ -f docker-compose.yml ]; then
    sudo docker compose down || true
    sudo docker compose up -d --build
  else
    sudo docker rm -f simple_app || true
    sudo docker build -t simple_app .
    sudo docker run -d --name simple_app -p ${APP_PORT}:${APP_PORT} --restart unless-stopped simple_app
  fi
EOF

# --- Configure NGINX ---
log "Configuring NGINX reverse proxy..."
ssh -i "$SSH_KEY" "$USER@$HOST" "bash -s" <<EOF | tee -a "$LOGFILE"
  set -e
  sudo bash -c 'cat > /etc/nginx/sites-available/app_repo' <<CONF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
CONF
  sudo ln -sf /etc/nginx/sites-available/app_repo /etc/nginx/sites-enabled/app_repo
  sudo nginx -t
  sudo systemctl reload nginx
EOF

# --- Verify Deployment ---
log "Verifying Docker container status..."
ssh -i "$SSH_KEY" "$USER@$HOST" "sudo docker ps --format 'table {{.Names}}\t{{.Status}}'" | tee -a "$LOGFILE"

log "Deployment completed successfully!"
echo "App accessible at: http://$HOST"
echo "Full log saved in: $LOGFILE"
