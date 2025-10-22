# 🚀 Automated Docker + NGINX Deployment Script (`deploy.sh`)

### **Author:** *John Durodola*

### **Language:** Bash

---

## 🧭 Overview

This project provides a **robust, production-grade Bash script** (`deploy.sh`) that automates the **setup, deployment, and configuration** of a **Dockerized web application** on a **remote Linux server**, complete with **NGINX reverse proxy**, **error handling**, **validation**, and **logging**.

It is designed for **repeatable, idempotent deployments**, suitable for **real-world DevOps workflows** or **infrastructure automation tasks**.

---

## 🎯 Objectives

By the end of this project, you should be able to:

* Automate the **deployment of a Dockerized app** onto a remote Linux server.
* Handle **SSH-based communication** and **file transfer** securely.
* Configure **NGINX** as a reverse proxy to expose the app publicly.
* Implement **logging, validation, and error handling** best practices in Bash.
* Understand the foundations of **server provisioning**, **container orchestration**, and **infrastructure automation**.

---

## 🧩 Features

✅ Collects user input interactively and validates all parameters.
✅ Supports both **Dockerfile** and **docker-compose.yml**-based projects.
✅ Automatically installs **Docker**, **Docker Compose**, and **NGINX** if missing.
✅ Configures **NGINX reverse proxy** dynamically for your app.
✅ **Idempotent:** Safe to re-run without breaking existing setups.
✅ Logs every action with timestamps and clear success/failure indicators.
✅ Supports `--cleanup` flag to remove all deployed resources gracefully.
✅ Fully self-contained — no dependencies beyond `bash`, `git`, `rsync`, and `ssh`.

---

## ⚙️ Requirements

| Component         | Purpose                      | Example                            |
| ----------------- | ---------------------------- | ---------------------------------- |
| **Local machine** | Runs the script              | macOS / Linux                      |
| **Remote server** | Target deployment host       | Ubuntu 20.04+                      |
| **SSH access**    | Required for remote commands | Key-based (recommended)            |
| **Docker**        | Application runtime          | Installed automatically if missing |
| **NGINX**         | Reverse proxy                | Installed automatically            |
| **Git**           | To clone project repo        | Must be installed locally          |

---

## 🧰 Installation

### 1️⃣ Clone this script repository

```bash
git clone https://github.com/<your-username>/deploy-script.git
cd deploy-script
```

### 2️⃣ Make the script executable

```bash
chmod +x deploy.sh
```

---

## 🚀 Usage

### ✅ **To deploy your app:**

Run the script interactively:

```bash
./deploy.sh
```

You’ll be prompted for:

| Prompt              | Description                                        |
| ------------------- | -------------------------------------------------- |
| **Git repo URL**    | URL of your app’s repository                       |
| **Branch**          | Optional (defaults to `main`)                      |
| **Remote username** | SSH username on target server                      |
| **Server IP**       | Public IP or domain of remote host                 |
| **SSH key path**    | Path to private SSH key (default: `~/.ssh/id_rsa`) |
| **App port**        | Internal container port (default: `80`)            |

Once complete, your app will be accessible at:

```
http://<your-server-ip>
```

---

### 🧹 **Cleanup Mode**

To remove deployed containers, files, and NGINX configs:

```bash
./deploy.sh --cleanup
```

This will:

* Stop and remove Docker containers.
* Delete project files from the remote server.
* Remove NGINX site configurations.
* Reload NGINX cleanly.

---

## 📦 What the Script Does (Step-by-Step)

| **Step**                    | **Description**                                                       |
| --------------------------- | --------------------------------------------------------------------- |
| **1. Parameter Collection** | Prompts user for repo, branch, server, key, and port with validation. |
| **2. Repository Setup**     | Clones or updates the repository using `git`.                         |
| **3. Docker Validation**    | Ensures presence of `Dockerfile` or `docker-compose.yml`.             |
| **4. SSH Validation**       | Tests remote connection using `ssh` dry-run.                          |
| **5. Environment Setup**    | Installs `docker`, `docker-compose`, and `nginx` remotely.            |
| **6. File Sync**            | Transfers project files securely with `rsync`.                        |
| **7. Docker Deployment**    | Builds and runs containers using `docker` or `docker-compose`.        |
| **8. NGINX Proxy Config**   | Creates reverse proxy config and reloads NGINX.                       |
| **9. Verification**         | Checks Docker containers and logs final status.                       |
| **10. Logging**             | Saves all actions to `deploy_YYYYMMDD_HHMMSS.log`.                    |
| **11. Cleanup (optional)**  | Removes containers, files, and configs when `--cleanup` is used.      |

---

## 🧾 Logging

* Every run generates a timestamped log file:

  ```
  deploy_20251022_143501.log
  ```
* All actions are logged with `[INFO]`, `[WARN]`, and `[ERROR]` tags.
* You can review logs to debug or audit your deployments.

---

## ⚠️ Error Handling

The script uses:

* `set -Eeuo pipefail` → catches all unhandled errors.
* `trap` → logs the failing line and exits gracefully.
* Validation checks for:

  * Missing or invalid SSH keys
  * Missing required binaries (`git`, `ssh`, `rsync`)
  * Unreachable hosts
  * Missing Docker configuration files

Each stage exits with a clear error message and a distinct exit code.

---

## 🔁 Idempotency

The script is safe to re-run.
It will:

* Pull latest repo updates if the folder already exists.
* Stop and remove old containers before rebuilding.
* Avoid duplicating NGINX configs.
* Only re-deploy changed files.

This ensures **consistent, repeatable deployments** every time.

---

## 🌐 Example Walkthrough

```bash
$ ./deploy.sh
=== Automated Docker + NGINX Deployment ===
Git repo URL: https://github.com/example/myapp.git
Branch (default: main): main
Remote username: ubuntu
Remote server IP: 18.223.45.67
SSH key path (default: ~/.ssh/id_rsa):
Application port (default: 80): 5000
[INFO]  Validating inputs...
[INFO]  SSH connection successful.
[INFO]  Preparing remote environment...
[INFO]  Deploying application...
[INFO]  Configuring NGINX...
[INFO]  Verifying Docker container status...
[INFO]  Deployment completed successfully!
App accessible at: http://18.223.45.67
Full log saved in: deploy_20251022_143501.log
```

---

## 🧩 Directory Structure

```
deploy-script/
│
├── deploy.sh             # Main Bash script
├── README.md             # Documentation
└── deploy_YYYYMMDD.log   # Auto-generated logs
```

---

## 🔒 Security Notes

* SSH keys are never copied or exposed — only used locally.
* PATs (Personal Access Tokens) are not stored; if added, use them cautiously.
* Always prefer **key-based SSH authentication** over passwords.
* For production, integrate **Certbot** or real SSL instead of HTTP-only NGINX.

---
