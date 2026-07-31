---
title: "Blog 2"
date: 2024-01-01
weight: 1
chapter: false
pre: " <b> 3.2. </b> "
---

# FROM ZERO TO ZERO-DOWNTIME: DEVOPS & CI/CD ON AWS

When starting with DevOps on AWS, CI/CD seemed like just automating deployment scripts. But real Production systems taught that DevOps is about **Reliability**, **Security**, and **Velocity**.

## 3 Key Lessons

### 1. Infrastructure as Code (IaC): Say No to ClickOps

- Manual console clicks are fast initially but become a nightmare for environment replication and auditing.
- **Use Terraform or AWS CDK**. Treat infrastructure as code. All changes go through Pull Request → Plan → Code Review.

### 2. Shift-Left Security in CI/CD Pipeline

- Don't wait until Production to scan for vulnerabilities.
- **Integrate security early:**
  - Scan IaC files with Checkov/TFLint
  - Scan container images with Amazon ECR Image Scanning
  - Manage secrets centrally with AWS Secrets Manager (never hardcode)

### 3. Blue/Green & Canary Deployments for Zero-Downtime

- In-place deployments cause disruptions and 502 errors.
- **Use AWS CodeDeploy:**
  - **Blue/Green**: Deploy parallel environment, test, then switch traffic
  - **Canary**: Route 10% traffic to new version, monitor CloudWatch metrics, then rollout 100%

## Detailed Pipeline Architecture

Below is the CI/CD workflow applied in practice:

**Step 1: Developer commits code to GitHub**

When developers push code to the repository, this is the starting point of the entire pipeline.

**Step 2: AWS CodePipeline detects changes and triggers the pipeline**

CodePipeline continuously monitors the repository. When a new commit is detected, the pipeline is automatically triggered without manual intervention.

**Step 3: AWS CodeBuild runs Unit Tests**

Code quality is verified through automated tests. If tests fail, the pipeline stops immediately to prevent deploying broken code.

**Step 4: CodeBuild runs Security Scan**

Source code and dependencies are scanned to detect security vulnerabilities. Early detection significantly reduces the cost of fixing issues compared to finding them in Production.

**Step 5: Build container image and push to Amazon ECR**

A Docker image is built from the source code, then pushed to Amazon Elastic Container Registry for storage and version management.

**Step 6: ECR automatically scans the image**

Once the image is pushed, ECR automatically scans it to detect CVEs in the image layers. Scan results are recorded for evaluation before deployment.

**Step 7: CodeDeploy (or Helm) deploys to Amazon EKS**

The image is deployed to the Kubernetes cluster. Depending on the setup, either CodeDeploy (with native EKS integration) or Helm (for chart-based management) can be used.

**Step 8: Apply Blue/Green or Canary strategy**

Instead of deploying directly to production, the pipeline uses one of these strategies:

- Blue/Green: Creates a new Green version alongside the existing Blue version. After thorough testing on Green, traffic is switched from Blue to Green.
- Canary: Routes a small percentage of traffic (e.g., 10%) to the new version, monitors key metrics, then gradually rolls out to 100%.

**Step 9: Monitor CloudWatch metrics and auto-rollback**

Throughout the deployment, CloudWatch tracks critical metrics like error rates and response times. If anomalies are detected, the pipeline automatically rollbacks to the previous version to minimize impact.

### Component Breakdown:

**GitHub:** Source code repository with built-in CodePipeline integration.

**AWS CodePipeline:** CI/CD orchestration service that coordinates the entire workflow from build to deploy.

**AWS CodeBuild:** Serverless build service that runs tests, security scans, and builds images.

**Amazon ECR:** Container image registry with automated CVE scanning.

**AWS CodeDeploy / Helm:** Deployment tools with Zero-Downtime strategies.

**Amazon EKS:** Kubernetes cluster where applications run.

### Results Achieved:

- Deployment time reduced from 30 minutes to under 4 minutes
- Early detection of security vulnerabilities at the build stage
- Zero-downtime deployments through Blue/Green and Canary
- Automatic rollback if issues are detected after deployment

## Key Takeaway

Tools are only 20%. The remaining 80% is **Pipeline Design** and culture of **Small & Frequent Releases**.

**Original post:** [Facebook AWS Study Group FCJ](https://www.facebook.com/groups/awsstudygroupfcj/permalink/2229176364513990/?rdid=aT7nNGRCmytCuj4K#)
