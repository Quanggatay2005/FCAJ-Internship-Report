---
title : "Prerequisites"
date : 2026-07-28
weight : 2
chapter : false
pre : " <b> 5.2 </b> "
---

#### Requirements

| Item | Details |
|---|---|
| AWS account | With permissions to create S3, CloudFront, Lambda, API Gateway, DynamoDB, IAM and Personalize resources |
| Region | `ap-southeast-1` (Singapore) --- this workshop uses a single region throughout |
| Node.js | Version 20 or later, for building the frontend |
| AWS CLI | Version 2, already configured with `aws configure`. Alternatively use AWS CloudShell in the console |
| Background | Comfortable with a terminal, familiar with HTTP requests and JSON |

{{% notice warning %}}
An Amazon Personalize campaign is **billed per hour it exists**, regardless of how many queries it serves. It is the most expensive resource in this workshop. Work through it in one sitting and delete the campaign as soon as you are done. See [Clean up](../5.9-Cleanup/).
{{% /notice %}}

#### Cost estimate

If you complete the workshop in a single day and clean up immediately, the cost stays very low. Most of it falls within the free tier:

- S3, CloudFront, Lambda, API Gateway, on-demand DynamoDB: effectively free at this scale
- Personalize: billed for training time and for how long the campaign exists

#### Verify your environment

Open a terminal and run the following to confirm your tooling is ready:

```bash
aws --version
node --version
aws sts get-caller-identity
```

The last command returns the Account ID and ARN of your current identity. If it fails, run `aws configure` again.

Set a default region so you do not have to specify it on every command:

```bash
export AWS_DEFAULT_REGION=ap-southeast-1
```

#### Prepare the source code

Download the project source. It contains two main folders:

```
backend/    API logic, to be deployed to Lambda
frontend/   React frontend, to be built into static files
```
