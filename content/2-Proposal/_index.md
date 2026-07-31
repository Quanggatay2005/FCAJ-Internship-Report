---
title: "Proposal"
date: 2024-01-01
weight: 2
chapter: false
pre: " <b> 2. </b> "
---

# E-Commerce Product Recommendation System on AWS

## A Personalised Recommendation and Visual Search E-Commerce Platform Built on AWS

### 1. Executive Summary

This project aims to build and deploy a full-stack e-commerce platform equipped with a personalised recommendation engine and visual search capabilities. Designed as part of the **Machine Learning on AWS** course, the platform utilizes AWS Serverless architecture (API Gateway, AWS Lambda, DynamoDB, S3, CloudFront) alongside Amazon Personalize and CLIP-based vector embeddings to deliver tailored shopping experiences and robust e-commerce features.

### 2. Problem Statement

### What’s the Problem?

Traditional e-commerce platforms often lack real-time personalisation, resulting in lower customer engagement and conversion rates. Furthermore, searching for products using text keywords can be limiting when users only have visual references. High operational overhead and infrastructure management also pose challenges for scaling traditional monolithic e-commerce applications.

### The Solution

The platform addresses these challenges by deploying a complete e-commerce solution on AWS Serverless infrastructure:

- **Personalised Recommendations:** Powered by Amazon Personalize (`aws-user-personalization` recipe) to show a "Recommended for You" section on the homepage.
- **Visual Search:** Implemented using a CLIP model (`@xenova/transformers`) with cosine similarity for image-based product discovery.
- **Core E-Commerce Suite:** Full support for browsing, filtering, account management, cart operations, vouchers, checkout (COD / Bank Transfer), and product reviews.
- **Serverless Architecture:** Utilizes React (Vite) hosted on S3 and distributed via CloudFront, Node.js 20 Lambda functions via HTTP API Gateway, and DynamoDB (8 tables) for on-demand database operations.

### Benefits and Return on Investment

- **Enhanced Customer Engagement:** Personalised recommendations improve product discovery and conversion rates.
- **Cost Efficiency:** Serverless pay-per-use architecture eliminates idle server costs; static assets are cached at the edge via CloudFront.
- **Scalability & Maintenance:** DynamoDB on-demand capacity and AWS Lambda handle variable traffic seamlessly without manual server provisioning.

### 3. Solution Architecture

The platform is built on a serverless microservices-like architecture on AWS:
![Picture discription](/images/5-Workshop/architecture.jpg)

### AWS Services & Technologies Used

- **Frontend:** React 18, Vite, Redux Toolkit, Tailwind CSS hosted on Amazon S3 and distributed via CloudFront.
- **API Gateway:** HTTP API routing 22 routes to a single AWS Lambda function.
- **AWS Lambda:** `fcj-api` (Node.js 20) handling business logic, authentication, and database operations.
- **Amazon DynamoDB:** On-demand capacity mode with 8 tables: `Products`, `Categories`, `Users`, `Sessions`, `Carts`, `Vouchers`, `Reviews`, `Orders`.
- **Amazon Personalize:** Campaign utilizing `aws-user-personalization` recipe to serve personalized product lists.
- **Visual Search Engine:** CLIP model (`@xenova/transformers`) + cosine similarity running locally due to Lambda package size constraints.

### Component Design

- **Frontend Hosting:** S3 bucket stores compiled static assets; CloudFront provides CDN caching and secure HTTPS access.
- **Business API:** Lambda processes request payloads, handles password hashing via `scrypt`, manages token sessions, and interacts with DynamoDB.
- **Recommendation Pipeline:** Lambda queries the Amazon Personalize Campaign endpoint to retrieve tailored product IDs for logged-in users.
- **Image Search Pipeline:** Vectors generated from product images are cached in `vector-cache.json` and matched against user input image URLs via cosine similarity.

### 4. Technical Implementation

**Implementation Phases**

1. **Infrastructure & Database Setup:** DDL/Schema design for 8 DynamoDB tables; configuring S3, CloudFront, API Gateway, and IAM execution roles.
2. **Backend & Frontend Development:** Writing 22 API routes in `backend/index.mjs`, creating React components, and integrating state management with Redux Toolkit.
3. **ML & AI Integration:** Preparing interaction datasets (`ml_recommendation_dataset.csv`), training Amazon Personalize models, and embedding CLIP visual search.
4. **Testing, Deployment & Evaluation:** Running Playwright end-to-end automated tests, deploying code to Lambda & S3/CloudFront, and evaluating model metrics (v1 vs. v2 dataset iterations).

**Technical Requirements**

- **Node.js Environment:** Node.js 20+ required for development and runtime execution.
- **AWS Credentials & Permissions:** IAM user/role with read/write access to 8 DynamoDB tables and invoke access to Amazon Personalize campaign.
- **Security:** Strict separation of environment variables (`.env`), passwords hashed with `scrypt` and compared via `timingSafeEqual`, S3 bucket kept private with CloudFront OAC.

### 5. Timeline & Milestones

- **Phase 1: Architecture & Data Engineering**
  - Design AWS architecture and IAM roles.
  - Build synthetic interaction data generation pipelines (handling power-law distribution, conversion funnels).
- **Phase 2: Core Development**
  - Implement 22 API routes in Lambda (`backend/index.mjs`).
  - Build React frontend components (Catalog, Product Details, Cart, Checkout, User Account).
- **Phase 3: Machine Learning & Personalization**
  - Train and deploy Amazon Personalize campaign (`aws-user-personalization`).
  - Implement CLIP model visual search and vector caching.
- **Phase 4: Integration, Testing & Deployment**
  - End-to-end Playwright automated test scripts for checkout flows.
  - Deploy frontend to S3/CloudFront and backend to AWS Lambda.

### 6. Budget Estimation & Model Metrics

**Estimated Monthly AWS Cost (Low-Traffic / Course Project Scale)**

| AWS Service                                | Usage Assumption                                 | Estimated Cost (USD/month) |
| ------------------------------------------ | ------------------------------------------------ | -------------------------- |
| **AWS Lambda** (`fcj-api`)                 | ~1M invocations, 512MB, ~200ms avg               | $0.20 – $1.00              |
| **API Gateway (HTTP API)**                 | ~1M requests                                     | ~$1.00                     |
| **Amazon DynamoDB** (8 tables, On-demand)  | ~1M read/write request units                     | $5 – $10                   |
| **Amazon S3** (frontend hosting)           | ~5 GB storage + PUT/GET requests                 | ~$0.15                     |
| **Amazon CloudFront**                      | ~50 GB data transfer out                         | ~$4.25                     |
| **Amazon Personalize (Campaign)**          | 1 campaign, minimum TPS, running 24/7 (~730 hrs) | **$150 – $220**            |
| **Amazon Personalize (Solution Training)** | One-time/periodic retraining (~2–4 hrs/session)  | ~$0.50 – $1.00 per run     |
| **CloudWatch Logs & Monitoring**           | Basic logging tier                               | ~$1.00                     |
| **Total (steady-state, monthly)**          |                                                  | **≈ $160 – $240 / month**  |

> **Note:** Amazon Personalize's always-on Campaign is by far the dominant cost driver, since it charges an hourly minimum TPS rate regardless of actual traffic. For a course/demo project, this cost can be significantly reduced by deleting the Campaign when not actively demoing, or by only re-creating it during evaluation/testing windows. Lambda, API Gateway, DynamoDB, S3, and CloudFront costs remain minimal at this traffic scale thanks to the serverless pay-per-use pricing model.

**Training & Dataset Iteration Results**
The interaction dataset was engineered to simulate realistic shopping behavior (conversion funnels, time-of-day dynamics, power-law distribution):

| Metric          | Dataset v1 | Dataset v2 |
| --------------- | ---------- | ---------- |
| **Precision@5** | 0.0889     | 0.4348     |
| **NDCG@10**     | 0.1799     | 0.6512     |
| **MRR@25**      | 0.1216     | 0.7130     |
| **Coverage**    | 0.8218     | 0.9505     |

_Conclusion:_ Input data quality significantly impacts model performance over algorithm selection.

### 7. Risk Assessment

#### Risk Matrix

- **Data Feedback Loop Gap:** High impact, medium probability (User interactions on web are not currently fed back automatically to retrain the model).
- **Package Size Limits:** Medium impact, high probability (CLIP model exceeds Lambda limits, restricting image search to local environments).
- **CloudFront Cache Stale Content:** Low impact, high probability (Requires mandatory invalidations `/*` upon new deployments).
- **Database Bottleneck (Complex Queries):** Medium impact, high probability (DynamoDB is not optimized for full-text search or complex product filtering).

#### Mitigation Strategies

- **Data Loop:** Plan automated data logging pipelines from DynamoDB/S3 back into Amazon Personalize.
- **Model Deployment:** Explore AWS ECS/Fargate or Sagemaker Endpoints for hosting heavy machine learning models like CLIP.
- **Deployment Automation:** Script deployment processes to include automatic CloudFront cache invalidation.
- **Search Optimization:** Integrate Amazon OpenSearch to handle complex filtering and text search queries.

### 8. Expected Outcomes

- **Technical Improvements:** A fully operational, serverless e-commerce platform with automated E2E testing (Playwright) and sub-second personal recommendations.
- **Long-term Value:** A scalable foundation for machine learning deployment on AWS that can be extended with closed-loop real-time retraining and server-side visual search.

### 9. Improvements and Next Steps

Based on operational reality and scaling requirements, several AWS services can be added to the system to optimize security, performance, and scalability:

- **Multi-layered Security:** Add AWS WAF in front of CloudFront/API Gateway to mitigate Botnet/DDoS attacks. Delegate user identity and authentication to Amazon Cognito.
- **Microservices Architecture:** Deconstruct the current monolithic Lambda into domain-specific independent services (User, Product, Order) to reduce blast radius and cold start times.
- **Query & Search Optimization:** Integrate Amazon OpenSearch alongside DynamoDB to fulfill complex product filtering and text-search queries. Host the CLIP model on Amazon ECS or SageMaker.
- **Real-time Feedback Loop:** Utilize Amazon Kinesis Data Streams with Amazon Personalize Event Tracker to capture and ingest user interaction data in real time.
