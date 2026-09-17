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
   - [Part A: Manual AWS Console Infrastructure Creation (VPC, IGW, Subnet, RT, SG, EC2)](#part-a-manual-aws-console-infrastructure-creation-vpc-igw-subnet-rt-sg-ec2)
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

The [`terraform/`](terraform/) directory contains complete Infrastructure as Code (IaC) manifests to provision an isolated AWS networking stack and compute instance from scratch:

- **Custom VPC (`aws_vpc`)**: Dedicated CIDR block (`10.0.0.0/16`) with DNS support and DNS hostnames enabled.
- **Internet Gateway (`aws_internet_gateway`)**: Attached to the custom VPC for inbound and outbound internet traffic.
- **Public Subnet (`aws_subnet`)**: Subnet CIDR (`10.0.1.0/24`) with automatic public IP assignment.
- **Route Table & Association (`aws_route_table`)**: Defines default route `0.0.0.0/0` directed to the Internet Gateway.
- **Security Group (`aws_security_group`)**: Enforces least-privilege access on ports 80 (HTTP), 443 (HTTPS), 22 (SSH), and all egress.
- **EC2 Instance (`aws_instance`)**: Ubuntu 24.04 LTS (`t2.micro` or `t3.micro`, Free Tier eligible) with automated Docker Engine install via `user_data`.

```bash
cd terraform

# 1. Initialize Terraform providers and backend
terraform init

# 2. Preview resources to be provisioned (VPC, IGW, Subnet, RT, SG, EC2)
terraform plan

# 3. Provision AWS infrastructure automatically
terraform apply -auto-approve
```

**Terraform Outputs Provided:**
- `vpc_id`: Custom VPC ID
- `public_subnet_id`: Public Subnet ID
- `security_group_id`: Security Group ID
- `instance_public_ip`: EC2 IPv4 address
- `application_url`: Frontend & API URL (`http://<EC2_IP>`)
- `api_docs_url`: Swagger API docs (`http://<EC2_IP>/docs`)
- `ssh_command`: Ready-to-use SSH connection string

---

### Automated CI/CD Pipeline with GitHub Actions

The workflow defined in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) provides an automated pipeline triggered on code pushes to `main`:

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

If you prefer to manually set up resources via the **AWS Management Console** instead of using Terraform, follow this complete step-by-step walkthrough covering custom VPC, Internet Gateway, Subnet, Route Table, Security Group, EC2 instance, and Docker stack deployment.

### Part A: Manual AWS Console Infrastructure Creation (VPC, IGW, Subnet, RT, SG, EC2)

#### Step 1: Create Custom VPC
1. Open the **AWS Management Console** and navigate to **VPC Dashboard** (ensure your region is selected, e.g., `us-east-1`).
2. Click **Create VPC**.
3. Under **Resources to create**, select **VPC only**.
4. Configure:
   - **Name tag**: `serphawk-vpc`
   - **IPv4 CIDR block**: `10.0.0.0/16`
   - **Tenancy**: Default
5. Click **Create VPC**.
6. Select `serphawk-vpc`, click **Actions > Edit VPC settings**, check both **Enable DNS resolution** and **Enable DNS hostnames**, and click **Save**.

#### Step 2: Create Internet Gateway (IGW) & Attach to VPC
1. In the VPC left navigation, click **Internet gateways**.
2. Click **Create internet gateway**.
3. **Name tag**: `serphawk-igw`
4. Click **Create internet gateway**.
5. In the banner or under **Actions**, click **Attach to VPC**.
6. Select `serphawk-vpc` and click **Attach internet gateway**.

#### Step 3: Create Public Subnet
1. In the VPC left navigation, click **Subnets**.
2. Click **Create subnet**.
3. Configure:
   - **VPC ID**: Select `serphawk-vpc`
   - **Subnet name**: `serphawk-public-subnet`
   - **Availability Zone**: Select any AZ (e.g., `us-east-1a`)
   - **IPv4 subnet CIDR block**: `10.0.1.0/24`
4. Click **Create subnet**.
5. Select `serphawk-public-subnet`, click **Actions > Edit subnet settings**, check **Enable auto-assign public IPv4 address**, and click **Save**.

#### Step 4: Create Route Table (RT) & Associate Subnet
1. In the VPC left navigation, click **Route tables**.
2. Click **Create route table**.
3. Configure:
   - **Name**: `serphawk-public-rt`
   - **VPC**: Select `serphawk-vpc`
4. Click **Create route table**.
5. Select `serphawk-public-rt`, open the **Routes** tab, and click **Edit routes**:
   - Click **Add route**
   - **Destination**: `0.0.0.0/0`
   - **Target**: Select **Internet Gateway** > `serphawk-igw`
   - Click **Save changes**.
6. Open the **Subnet associations** tab, click **Edit subnet associations**:
   - Select `serphawk-public-subnet`
   - Click **Save associations**.

#### Step 5: Create Security Group (SG)
1. In the VPC left navigation (or EC2 Dashboard), click **Security groups**.
2. Click **Create security group**.
3. Configure:
   - **Security group name**: `serphawk-crm-sg`
   - **Description**: Security group for SERP Hawk CRM V2
   - **VPC**: Select `serphawk-vpc` *(do not select the default VPC)*
4. Under **Inbound rules**, add:
   - `HTTP` | Port `80` | Source: `Anywhere-IPv4` (`0.0.0.0/0`)
   - `HTTPS` | Port `443` | Source: `Anywhere-IPv4` (`0.0.0.0/0`)
   - `SSH` | Port `22` | Source: `My IP` (or `0.0.0.0/0`)
5. Under **Outbound rules**:
   - Ensure `All traffic` | `0.0.0.0/0` is present.
6. Click **Create security group**.

#### Step 6: Launch EC2 Instance in Custom VPC
1. Navigate to **EC2 Dashboard > Instances** and click **Launch instances**.
2. Configure:
   - **Name**: `SERP-Hawk-CRM-Server`
   - **Application and OS Image**: Ubuntu Server 24.04 LTS (64-bit x86, Free Tier eligible)
   - **Instance Type**: `t2.micro` or `t3.micro` (1 vCPU, 1 GiB RAM - Free Tier eligible)
   - **Key Pair**: Select your existing `.pem` key pair (or create a new one)
3. Under **Network settings**, click **Edit**:
   - **VPC**: Select `serphawk-vpc`
   - **Subnet**: Select `serphawk-public-subnet`
   - **Auto-assign Public IP**: `Enable`
   - **Firewall (security groups)**: Choose **Select existing security group** and pick `serphawk-crm-sg`
4. Under **Configure Storage**:
   - `20 GiB` `gp3` SSD (Free Tier allows up to 30 GB)
5. Click **Launch Instance**.

#### Step 7: Allocate & Associate Elastic IP (Optional / Recommended)
1. Go to **EC2 > Network & Security > Elastic IPs**.
2. Click **Allocate Elastic IP address** > **Allocate**.
3. Select the allocated Elastic IP, click **Actions > Associate Elastic IP address**.
4. Choose **Instance**: `SERP-Hawk-CRM-Server`, and click **Associate**.

---

### Part B: Manual Server Setup & Application Deployment

1. **SSH into the EC2 Instance**:
   ```bash
   chmod 400 your-key.pem
   ssh -i "your-key.pem" ubuntu@<YOUR-EC2-PUBLIC-IP>
   ```

2. **Install Required Packages & Configure Swap**:
   ```bash
   # System updates and Docker installation
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose-v2 git
   sudo usermod -aG docker ubuntu
   newgrp docker

   # Optional 2GB swap space on EBS SSD (prevents memory spikes during Next.js builds on 1GB RAM)
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
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