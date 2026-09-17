# SERP Hawk CRM V2 - DevOps & Cloud Engineering Architecture

AI-Powered CRM for SEO Agencies | Next.js 16 + FastAPI + PostgreSQL + Docker + Terraform + GitHub Actions + AWS Free Tier

---

## 📋 Table of Contents
1. [Overview & Tech Stack](#-overview--tech-stack)
2. [DevOps Architecture & Service Rationale](#-devops-architecture--service-rationale)
3. [AWS Free Tier Architecture Diagram](#%EF%B8%8F-aws-free-tier-architecture-diagram)
4. [Enterprise Evolution (IaaS vs. PaaS)](#-enterprise-evolution-iaas-vs-paas)
5. [Local Docker Deployment (Low-Resource Mode)](#-local-docker-deployment-low-resource-mode)
6. [Infrastructure as Code (Terraform)](#-infrastructure-as-code-terraform)
7. [CI/CD Pipeline (GitHub Actions)](#-cicd-pipeline-github-actions)
8. [Manual AWS Deployment Walkthrough](#-manual-aws-deployment-walkthrough)
9. [Candidate Submission Checklist](#-candidate-submission-checklist)

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
    User["👤 Browser Client"] -->|HTTP / HTTPS Port 80/443| IGW["AWS Internet Gateway"]
    
    subgraph VPC["AWS Virtual Private Cloud (VPC)"]
        subgraph PublicSubnet["Public Subnet"]
            subgraph EC2["EC2 t2.micro / t3.micro (1 vCPU, 1 GB RAM)"]
                Nginx["Nginx Reverse Proxy (Port 80)"]
                
                Nginx -->|/ (Frontend)| Frontend["Next.js Container (Port 3000)"]
                Nginx -->|/api, /docs, /ws| Backend["FastAPI Container (Port 8000)"]
                
                Backend -->|TCP 5432| DB["PostgreSQL 16 Alpine Container (Port 5432)"]
            end
        end
    end
    
    Backend -->|Outbound HTTPS| OpenAI["OpenAI API"]
    Backend -->|Outbound HTTPS| Gemini["Google Gemini API"]
```

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

## ⚙️ Infrastructure as Code (Terraform)

The [`terraform/`](file:///c:/Users/abhishek.cs/OneDrive%20-%20Trinity%20Mobility%20Pvt%20Ltd/Downloads/CRM-V2-SerpHawk-main/CRM-V2-SerpHawk-main/terraform) directory contains IaC manifests to automatically provision the AWS environment:

```bash
cd terraform

# Initialize providers
terraform init

# Review execution plan
terraform plan

# Provision AWS resources (EC2, Security Group, Docker)
terraform apply -auto-approve
```

Outputs will display:
- `instance_public_ip`
- `application_url`
- `api_docs_url`
- `ssh_command`

---

## 🔄 CI/CD Pipeline (GitHub Actions)

The workflow defined in [`.github/workflows/deploy.yml`](file:///c:/Users/abhishek.cs/OneDrive%20-%20Trinity%20Mobility%20Pvt%20Ltd/Downloads/CRM-V2-SerpHawk-main/CRM-V2-SerpHawk-main/.github/workflows/deploy.yml) provides automated CI/CD:

1. **Continuous Integration (CI)**:
   - Validates Next.js standalone multi-stage Docker build.
   - Validates Python FastAPI multi-stage wheel build.
2. **Continuous Deployment (CD)**:
   - On merge/push to `main`, connects to EC2 via SSH.
   - Pulls latest commit, runs `docker compose up --build -d`, runs database migrations, and prunes unused images to protect storage.

### Setting Up GitHub Secrets:
In your GitHub repository under **Settings > Secrets and variables > Actions**, add:
- `EC2_HOST`: Your EC2 Public IPv4 address
- `EC2_USER`: `ubuntu`
- `EC2_SSH_KEY`: Private Key (`.pem`) contents

---

## ☁️ Manual AWS Deployment Walkthrough

1. **Launch EC2 Instance**:
   - Ubuntu 24.04 LTS (`t2.micro` or `t3.micro`, Free Tier).
   - Inbound Security Rules: Port 80 (HTTP), 443 (HTTPS), 22 (SSH).
   - Storage: 20 GB `gp3`.

2. **Server Setup**:
   ```bash
   ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>
   sudo apt-get update && sudo apt-get install -y docker.io docker-compose-v2 git
   sudo usermod -aG docker ubuntu
   ```

3. **Deploy Application**:
   ```bash
   git clone <YOUR-REPO-URL> app
   cd app
   cp .env.example .env
   # Update NEXT_PUBLIC_API_BASE_URL to http://<EC2-PUBLIC-IP> in .env
   docker compose up --build -d
   docker exec serphawk_backend python create_tables.py
   docker exec serphawk_backend python seed_db.py
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