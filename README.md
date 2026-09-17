# SERP Hawk CRM V2 - DevOps & Cloud Engineering Architecture

AI-Powered CRM for SEO Agencies | Next.js 16 + FastAPI + PostgreSQL + Docker + Terraform + GitHub Actions + AWS Free Tier

---

## 📋 Table of Contents
1. [Overview & Tech Stack](#-overview--tech-stack)
2. [DevOps Architecture & Service Rationale](#-devops-architecture--service-rationale)
3. [AWS Free Tier Architecture Diagram](#-aws-free-tier-architecture-diagram)
4. [Enterprise Evolution (IaaS vs. PaaS)](#-enterprise-evolution-iaas-vs-paas)
5. [Local Docker Deployment (Low-Resource Mode)](#-local-docker-deployment-low-resource-mode)
6. [Automated Deployment (Terraform & GitHub Actions CI/CD)](#-automated-deployment-terraform--github-actions-cicd)
   - [Provisioning Infrastructure with Terraform](#provisioning-infrastructure-with-terraform)
   - [Automated CI/CD Pipeline with GitHub Actions](#automated-cicd-pipeline-with-github-actions)
7. [Manual AWS Resource Creation & Deployment Walkthrough](#-manual-aws-resource-creation--deployment-walkthrough)
   - [Part A: Manual AWS Console Infrastructure Creation](#part-a-manual-aws-console-infrastructure-creation)
   - [Part B: Manual Server Setup & Application Deployment](#part-b-manual-server-setup--application-deployment)
8. [Candidate Submission Checklist](#-candidate-submission-checklist)

---

## 📌 Overview & Tech Stack

SERP Hawk CRM V2 is an enterprise-grade relationship management system for digital marketing and SEO agencies.

- **Frontend**: Next.js 16 (React 19, TypeScript, Tailwind CSS 4)
- **Backend**: FastAPI (Python 3.13, SQLModel ORM, Uvicorn, WebSockets)
- **Database**: PostgreSQL 16 (Alpine in Docker / Neon Serverless)
- **Reverse Proxy**: Nginx (Unified entry on Port 80, Gzip compression, WebSocket upgrade)
- **Containerization**: Multi-stage standalone Docker builds (~160MB actual RAM footprint)
- **IaC**: Terraform (VPC, Security Groups, EC2 auto-provisioning)
- **CI/CD**: GitHub Actions (Build validation & automated EC2 SSH deployment)
- **Cloud Infrastructure**: AWS Free Tier (EC2 `t2.micro` / `t3.micro`)

---

## 🧠 DevOps Architecture & Service Rationale

When deploying on AWS within strict **Free Tier / Zero-Cost** limits, architectural decision-making requires balancing cost, operational overhead, and resource efficiency:

| AWS Service | Selected For | Rationale & Free Tier Safety |
| :--- | :--- | :--- |
| **AWS EC2 (`t2.micro`/`t3.micro`)** | Compute & Container Host | **750 hours/month free** (12-month tier). Running our multi-stage optimized container stack requires only **~160MB RAM**, comfortably fitting in the 1GB RAM quota. |
| **AWS VPC & Security Group** | Isolated Networking | 100% Free. Enforces least-privilege: Port 80 (HTTP), Port 443 (HTTPS), Port 22 (restricted to admin IP). |
| **AWS EBS (20 GB gp3)** | Persistent Storage | **30 GB free SSD storage** per month under Free Tier. Accommodates OS, container layers, and PostgreSQL volume data. |
| **AWS Elastic IP** | Fixed Public IP | Free when associated with a running instance. Ensures DNS and API URLs remain constant. |

### Why EC2 + Docker Compose over AWS PaaS (App Runner / ECS Fargate / RDS)?
1. **PaaS Free Tier Pitfalls**:
   - **AWS App Runner**: Free tier lasts only 30 days (max 300 vCPU-hours), after which it bills for provisioned container memory ($0.007/GB-hour).
   - **AWS RDS (db.t3.micro)**: Reserves 1GB RAM exclusively for PostgreSQL and starts billing after 12 months. Our containerized Postgres Alpine uses only **~35MB RAM**.
   - **AWS ECS Fargate**: Does not have a permanent 12-month free tier and bills continuously per vCPU/RAM-hour.
2. **Resource Throttling**: A single IaaS instance running Docker Compose allows fine-grained container memory/CPU reservations (`deploy.resources.limits`) to guarantee zero OOM crashes.

---

## 🏗️ AWS Free Tier Architecture Diagram

```mermaid
graph TD
    User["👤 Browser Client / Admin"] -->|"Inbound HTTP (80) / HTTPS (443) / SSH (22)"| IGW["AWS Internet Gateway"]

    subgraph VPC["AWS Virtual Private Cloud (VPC)"]
        subgraph PublicSubnet["Public Subnet"]
            subgraph SG["Security Group (serphawk-sg: Inbound 80, 443, 22)"]
                subgraph EC2["EC2 t2.micro / t3.micro (1 vCPU, 1 GB RAM)"]
                    Nginx["Nginx Reverse Proxy (Port 80)"]
                    
                    subgraph DockerNetwork["Isolated Docker Bridge Network"]
                        Frontend["Next.js Container (Port 3000)"]
                        Backend["FastAPI Container (Port 8000)"]
                        DB[("PostgreSQL 16 Alpine (Port 5432)")]
                    end
                end
            end
        end
    end

    %% Inbound Traffic Flow
    IGW -->|"Inbound Traffic Allowed by SG"| Nginx
    Nginx -->|"/ (Frontend UI)"| Frontend
    Nginx -->|"/api, /docs, /ws"| Backend
    Backend -->|"Internal TCP 5432"| DB

    %% Outbound Traffic (External AI APIs)
    subgraph External["External Cloud APIs (Third-Party SaaS)"]
        OpenAI["OpenAI API (GPT-4o-mini)"]
        Gemini["Google Gemini API (Vision OCR)"]
    end

    Backend -.->|"Outbound HTTPS (Egress Port 443)"| OpenAI
    Backend -.->|"Outbound HTTPS (Egress Port 443)"| Gemini
```

### 🔍 Traffic Flow Breakdown:
- **Inbound Traffic (Ingress)**:
  - Users send HTTP (`80`) and HTTPS (`443`) requests via the **AWS Internet Gateway (IGW)**.
  - The **Security Group (`serphawk-sg`)** inspects and permits inbound traffic on ports `80`, `443`, and `22` (SSH admin access).
  - Traffic enters **Nginx**, which acts as a reverse proxy, SSL termination, and single point of entry, routing `/` to Next.js and `/api`, `/docs`, `/ws` to FastAPI.
  - PostgreSQL is completely isolated inside the internal Docker bridge network (not exposed to the public internet).
- **Outbound Traffic (Egress)**:
  - **Why does FastAPI make outbound calls?** SERP Hawk CRM integrates with **OpenAI** (for AI email drafting & insights) and **Google Gemini** (for business card OCR scanning).
  - Because these are external third-party SaaS services outside AWS, FastAPI makes outbound client HTTPS requests (`Port 443` egress) to their public API endpoints.


---

## 🚀 Enterprise Evolution (IaaS vs. PaaS)

If project requirements scale beyond the Free Tier and require enterprise multi-region redundancy, the architecture can evolve:

```
[Free Tier Dev/Stage: EC2 + Compose] 
               │
               ▼
[Enterprise Production PaaS]
├── Frontend: AWS CloudFront CDN + S3 / Vercel (Edge SSR)
├── Backend:  AWS ECS Fargate (Auto-scaled tasks behind Application Load Balancer)
├── Database: AWS Aurora Serverless v2 PostgreSQL (Multi-AZ with automatic failover)
└── Security: AWS WAF + Secrets Manager + ACM Managed SSL
```

---

## 🐳 Local Docker Deployment (Low-Resource Mode)

### Measured Resource Consumption

| Container Name | Service | Memory Usage / Limit | CPU % |
| :--- | :--- | :--- | :--- |
| **`serphawk_backend`** | FastAPI (Python 3.13) | **94.85 MiB** / 256 MiB | 0.20% |
| **`serphawk_frontend`** | Next.js 16 Standalone | **27.32 MiB** / 256 MiB | 0.00% |
| **`serphawk_db`** | PostgreSQL 16 Alpine | **34.77 MiB** / 128 MiB | 0.07% |
| **`serphawk_nginx`** | Nginx Reverse Proxy | **2.71 MiB** / 64 MiB | 0.00% |
| **TOTAL STACK RAM** | — | **~160 MiB** | **< 0.3%** |

### Running Locally with Docker:
```bash
# 1. Copy environment template
cp .env.example .env

# 2. Build and start containers
docker compose up --build -d

# 3. Initialize database tables & seed initial data
docker exec serphawk_backend python create_tables.py
docker exec serphawk_backend python seed_db.py

# 4. Inspect container status
docker ps
docker stats --no-stream
```
- **Web App**: `http://localhost`
- **Swagger Docs**: `http://localhost/docs`

---

## ⚡ Automated Deployment (Terraform & GitHub Actions CI/CD)

The primary cloud deployment strategy utilizes **Terraform** for automated AWS infrastructure provisioning and **GitHub Actions** for continuous integration and automated continuous deployment (CI/CD).

### Provisioning Infrastructure with Terraform

The [`terraform/`](file:///c:/Users/abhishek.cs/OneDrive%20-%20Trinity%20Mobility%20Pvt%20Ltd/Downloads/CRM-V2-SerpHawk-main/CRM-V2-SerpHawk-main/terraform) directory contains complete Infrastructure as Code (IaC) manifests to automatically provision the AWS cloud environment:

```bash
cd terraform

# 1. Initialize Terraform providers and backend
terraform init

# 2. Review resources to be provisioned (VPC, Security Group, EC2)
terraform plan

# 3. Provision AWS infrastructure automatically
terraform apply -auto-approve
```

**Terraform Outputs Provided:**
- `instance_public_ip`: EC2 IPv4 address
- `application_url`: Frontend & API URL (`http://<EC2_IP>`)
- `api_docs_url`: Swagger API docs (`http://<EC2_IP>/docs`)
- `ssh_command`: Ready-to-use SSH connection string

---

### Automated CI/CD Pipeline with GitHub Actions

The workflow defined in [`.github/workflows/deploy.yml`](file:///c:/Users/abhishek.cs/OneDrive%20-%20Trinity%20Mobility%20Pvt%20Ltd/Downloads/CRM-V2-SerpHawk-main/CRM-V2-SerpHawk-main/.github/workflows/deploy.yml) provides an automated pipeline triggered on code pushes to `main`:

1. **Continuous Integration (CI Stage)**:
   - Validates multi-stage standalone Next.js Docker build.
   - Validates multi-stage FastAPI Python wheel Docker build.
2. **Continuous Deployment (CD Stage)**:
   - Connects securely to the AWS EC2 instance via SSH.
   - Pulls latest commit from GitHub (`git pull origin main`).
   - Rebuilds and restarts containers (`docker compose up --build -d`).
   - Executes automatic database schema migration and seeding.
   - Prunes dangling Docker images to preserve EBS disk space.

#### Setting Up GitHub Secrets:
In your GitHub Repository under **Settings > Secrets and variables > Actions**, add:
- `EC2_HOST`: EC2 Public IPv4 address (from Terraform output)
- `EC2_USER`: `ubuntu`
- `EC2_SSH_KEY`: Contents of your SSH private key (`.pem`)

---

## 🛠️ Manual AWS Resource Creation & Deployment Walkthrough

If you prefer to manually set up resources via the AWS Console instead of using Terraform, follow this step-by-step walkthrough.

### Part A: Manual AWS Console Infrastructure Creation

1. **Log in to AWS Console**:
   - Select your target region (e.g., `us-east-1`).

2. **Create Security Group**:
   - Navigate to **EC2 > Security Groups > Create security group**.
   - **Name**: `serphawk-sg`
   - **Description**: Security group for SERP Hawk CRM V2
   - **Inbound Rules**:
     - `HTTP` | Port `80` | Source: `0.0.0.0/0` (Anywhere IPv4)
     - `HTTPS` | Port `443` | Source: `0.0.0.0/0` (Anywhere IPv4)
     - `SSH` | Port `22` | Source: `0.0.0.0/0` (or your specific IP)

3. **Launch EC2 Instance**:
   - Navigate to **EC2 Dashboard > Launch instance**.
   - **Name**: `SERP-Hawk-CRM-Server`
   - **Application and OS Image**: Ubuntu Server 24.04 LTS (64-bit x86, Free Tier eligible).
   - **Instance Type**: `t2.micro` or `t3.micro` (1 vCPU, 1 GiB RAM - Free Tier eligible).
   - **Key Pair**: Select an existing key pair or click **Create new key pair** (`RSA`, `.pem`).
   - **Network Settings**: Select your default VPC & Public Subnet. Select existing security group `serphawk-sg`. Ensure **Auto-assign Public IP** is set to **Enable**.
   - **Configure Storage**: `20 GiB` `gp3` SSD (Free Tier allows up to 30 GB).
   - Click **Launch Instance**.

4. **Elastic IP Allocation (Optional)**:
   - Go to **EC2 > Elastic IPs > Allocate Elastic IP address**.
   - Associate it with your newly launched `SERP-Hawk-CRM-Server` instance to ensure the public IP remains static across restarts.

---

### Part B: Manual Server Setup & Application Deployment

1. **SSH into the EC2 Instance**:
   ```bash
   chmod 400 your-key.pem
   ssh -i "your-key.pem" ubuntu@<YOUR-EC2-PUBLIC-IP>
   ```

2. **Install Required System Packages (Docker & Git)**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose-v2 git
   sudo usermod -aG docker ubuntu
   newgrp docker
   ```

3. **Clone Repository & Configure Environment**:
   ```bash
   git clone https://github.com/abhishekcsshetty/SERP-Hawk-CRM-V2.git app
   cd app
   cp .env.example .env
   ```
   *Edit `.env` if necessary to update `NEXT_PUBLIC_API_BASE_URL` to `http://<YOUR-EC2-PUBLIC-IP>`.*

4. **Launch Docker Stack**:
   ```bash
   docker compose up --build -d
   ```

5. **Run Database Migrations & Seed Initial Data**:
   ```bash
   docker exec serphawk_backend python create_tables.py
   docker exec serphawk_backend python seed_db.py
   ```

6. **Verify Running Containers**:
   ```bash
   docker ps
   docker stats --no-stream
   ```

---

## 📑 Candidate Submission Checklist

- [x] **Local Execution Verified**: Stack running locally, verified with `docker stats` at ~160MB RAM.
- [x] **Multi-Stage Optimization**: Next.js standalone mode + Python slim wheel compilation.
- [x] **Strict Free Tier Compliance**: No chargeable AWS services used ($0.00/month).
- [x] **Infrastructure as Code**: Terraform module provided in `terraform/`.
- [x] **CI/CD Automation**: GitHub Actions pipeline provided in `.github/workflows/deploy.yml`.
- [x] **Security Guardrails**: `.env` strictly ignored by `.gitignore` and `.dockerignore`.
- [x] **Architecture Diagram & Rationale**: Mermaid diagram and service comparison documented.