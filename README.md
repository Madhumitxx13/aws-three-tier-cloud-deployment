# 3-Tier AWS Architecture using Terraform

![Terraform](https://img.shields.io/badge/IaC-Terraform-blueviolet?logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws)
![Flask](https://img.shields.io/badge/Web%20Framework-Flask-black?logo=flask)
![Python](https://img.shields.io/badge/Language-Python-blue?logo=python)
![EC2](https://img.shields.io/badge/Compute-EC2-success?logo=amazon-ec2)
![RDS](https://img.shields.io/badge/Database-RDS-lightblue?logo=amazon-rds)
![ALB](https://img.shields.io/badge/LoadBalancer-ALB-yellow?logo=elastic-load-balancing)

---

## Project Overview

**Problem Addressed:** Modern web applications require high availability, scalability, and security. Deploying all application components on a single server creates a single point of failure and makes scaling inefficient. Furthermore, manually provisioning cloud infrastructure is error-prone and difficult to reproduce.

**Objectives:** This project demonstrates a robust, automated deployment of a **3-Tier Web Application Architecture** on AWS using **Terraform**. By separating the Presentation, Application, and Database tiers, the infrastructure is inherently scalable and secure. This project serves as a showcase of Infrastructure as Code (IaC) principles for an internship presentation and professional portfolio.

---

## AWS Architecture and Request Flow

The architecture follows a strict 3-tier design deployed within a custom VPC spanning two Availability Zones:

**Request Flow:**
`User -> Application Load Balancer -> EC2 Flask application instances -> RDS MySQL`

1. **Presentation Tier (Public Subnets):** An Internet Gateway allows traffic in. An Application Load Balancer (ALB) receives HTTP requests and securely distributes them.
2. **Application Tier (Private Subnets):** EC2 instances host a Python Flask web application. These instances do not have public IP addresses and are only accessible via the ALB.
3. **Database Tier (Private Subnets):** A Multi-AZ Amazon RDS (MySQL) instance serves as the data layer. It is fully isolated from the internet and only accepts traffic from the Application tier where database integration is configured.

---

## Technologies Used

| Technology | Purpose |
|------------|---------|
| **AWS VPC** | Virtual Private Cloud providing a logically isolated network for the infrastructure, securing resources across public and private subnets. |
| **AWS EC2** | Elastic Compute Cloud providing virtual servers acting as the Application Tier to run the web application. |
| **AWS ALB** | Application Load Balancer routing incoming web traffic safely across multiple EC2 instances to ensure high availability. |
| **Amazon RDS (MySQL)** | Managed relational database service providing the Database Tier with Multi-AZ redundancy and automated backups. |
| **Terraform** | Infrastructure as Code (IaC) tool used to define, provision, and manage the AWS resources predictably and consistently. |
| **Python** | High-level programming language used to build the application logic. |
| **Flask** | Lightweight Python web framework used to serve the application and handle HTTP requests. |

---

## Project Structure

```text
aws-three-tier-cloud-deployment/
│
├── Terraform/
│   ├── main.tf              # Defines the core infrastructure (VPC, EC2, RDS, ALB)
│   ├── variables.tf         # Input variables allowing dynamic configuration
│   ├── outputs.tf           # Terraform outputs (e.g., ALB DNS endpoint)
│   └── provider.tf          # AWS provider and region configuration
│
├── Architecture.txt         # Detailed ASCII diagram of the system's architecture
├── Screenshots/             # Directory containing reference and verified deployment images
├── .gitignore               # Excludes sensitive files, credentials, and state from source control
└── README.md                # Project documentation and setup guide
```

---

## Security Best Practices

Security is a primary focus of this project. The following practices have been strictly enforced:
- **No Hard-coded Secrets:** Database passwords and AWS credentials are not stored in source code.
- **`.gitignore` Enforced:** Terraform state files (`*.tfstate`), variable files (`*.tfvars`), environment files (`.env`), and AWS credentials/private keys must never be committed to GitHub. 
- **Network Isolation:** Only the ALB is exposed to the internet. EC2 and RDS instances sit in private subnets with restricted Security Groups.

---

## Setup and Deployment Instructions

### Prerequisites
1. **AWS CLI:** Installed and configured with appropriate IAM permissions. Do **not** place AWS credentials inside the project folder.
2. **Terraform:** Installed on your local machine.
3. **Secure Variables:** Set your database password as an environment variable to inject it safely:
   
   **Linux/macOS:**
   ```bash
   export TF_VAR_db_password="YourSecurePasswordHere!"
   ```
   **Windows (PowerShell):**
   ```powershell
   $env:TF_VAR_db_password="YourSecurePasswordHere!"
   ```

### Deployment Steps
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/Madhumitxx13/aws-three-tier-cloud-deployment.git
   cd aws-three-tier-cloud-deployment/Terraform
   ```

2. **Initialize Terraform:**
   Downloads required providers and initializes the working directory.
   ```bash
   terraform init
   ```

3. **Validate Configuration:**
   Checks the syntax and validity of the Terraform files.
   ```bash
   terraform validate
   ```

4. **Review the Execution Plan:**
   Generates a plan showing what resources will be created.
   ```bash
   terraform plan -out plan.out
   ```

5. **Deploy the Infrastructure:**
   Provisions the infrastructure on AWS.
   ```bash
   terraform apply plan.out
   ```

### Cleanup
To avoid incurring unnecessary AWS charges, destroy the infrastructure when you are done testing:
```bash
terraform destroy -auto-approve
```

---

## Results and Evidence

*Note: The deployment and database connection tests for my specific implementation are currently **PENDING VERIFICATION**.* 

### Reference Screenshots
The following image is a reference screenshot provided by the original author to illustrate the expected application output once deployed.
> ![Reference: Flask App Output](Screenshots/flask-Output.png)

### Verified Implementation (Pending)
*[PLACEHOLDER: Insert screenshot of the AWS Console showing the deployed VPC, EC2, and RDS instances here]*
> Evidence of successful infrastructure provisioning.

*[PLACEHOLDER: Insert screenshot of the browser accessing the Application Load Balancer DNS endpoint here]*
> Evidence that the ALB successfully routes traffic to the Flask application.

*[PLACEHOLDER: Insert screenshot/log of the application successfully reading/writing to the RDS MySQL database here]*
> Evidence of successful database integration between the Application Tier and Database Tier.

---

## Acknowledgements

- **Reference Project:** This project is based on a reference implementation by **Jothi Krishna M**. 
- **Original Repository:** [https://github.com/KrishnaaCloud/3-Tier-AWS-Infra-Using-Terraform](https://github.com/KrishnaaCloud/3-Tier-AWS-Infra-Using-Terraform)
- **Modifications:** I have adapted this repository for my internship portfolio. My contributions include securing the Terraform code by removing hard-coded credentials, updating the `.gitignore` to prevent secret leakage, restructuring the documentation, and validating the architectural security. 
