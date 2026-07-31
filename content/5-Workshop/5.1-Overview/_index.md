---
title : "Overview and architecture"
date : 2026-07-28
weight : 1
chapter : false
pre : " <b> 5.1 </b> "
---

#### The problem

An online store may carry thousands of products, while a typical shopper only has the patience to browse a few dozen. Ranking products by sales volume or upload date means most of the catalogue is never seen, and users have to hunt for what they want on their own.

The system in this workshop addresses that by learning from actual user behaviour to suggest products tailored to each person.

#### Architecture

![Overall architecture](/images/5-Workshop/architecture.png)

The system splits into two independent paths:

**The content delivery path.** Users hit the CloudFront domain, and CloudFront serves the pre-built HTML, CSS and JavaScript files stored in an S3 bucket. Because this is static content, it can be cached at edge locations close to users, cutting latency and incurring almost no compute cost.

**The data path.** The frontend calls API Gateway, which invokes a Lambda function. Depending on the route, Lambda queries DynamoDB for business data or calls Amazon Personalize for a recommendation list.

#### Why these services

**Serverless instead of traditional servers.** Traffic for an internship project is low and uneven. With EC2 or ECS you pay by the hour even when nobody visits. With Lambda, no requests means no cost.

**DynamoDB instead of RDS.** RDS bills per instance-hour even when idle. DynamoDB in on-demand mode bills only for actual reads and writes. For key-based data with simple access patterns, DynamoDB is the better fit.

**Amazon Personalize instead of training on SageMaker.** Implementing a recommendation algorithm from scratch requires deep expertise and a lot of tuning time. Personalize packages the same algorithms Amazon uses in its own products, letting you focus on data quality rather than model implementation.

**CloudFront in front of S3.** Beyond speed, CloudFront lets you keep the bucket fully private and provides HTTPS at no extra cost.

#### Design principles applied throughout

- **Never trust data from the browser.** The server always looks up prices and recalculates totals itself, rather than using figures sent by the frontend.
- **Least privilege.** Each component receives only the permissions it needs, on only the resources it needs.
- **No hard-coded credentials.** Lambda uses an execution role; no access keys are embedded in source code.
