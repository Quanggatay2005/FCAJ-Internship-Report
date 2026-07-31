---
title : "Clean up"
date : 2026-07-28
weight : 9
chapter : false
pre : " <b> 5.9 </b> "
---

{{% notice warning %}}
Do this **immediately after finishing the workshop**. A Personalize campaign bills per hour it exists; forgetting to delete it means your bill quietly grows every day.
{{% /notice %}}

#### Deletion order

Order matters because resources depend on each other. Follow the list below, starting with the most expensive.

#### Step 1. Delete the campaign --- highest priority

```bash
aws personalize delete-campaign --campaign-arn <CAMPAIGN-ARN>
```

Or in the console: **Personalize** → **Campaigns** → select the campaign → **Delete**.

Wait for the status to become **Delete pending** and then disappear from the list.

#### Step 2. Delete the solution and dataset group

These must be deleted in this exact order, otherwise you get dependency errors:

```bash
# Delete the solution first
aws personalize delete-solution --solution-arn <SOLUTION-ARN>

# Wait for it to disappear, then delete the dataset
aws personalize delete-dataset --dataset-arn <DATASET-ARN>

# Finally delete the dataset group
aws personalize delete-dataset-group --dataset-group-arn <DSG-ARN>
```

{{% notice note %}}
If the solution has **automatic retraining** enabled, turn it off before deleting, otherwise it may kick off a new training run and incur cost.
{{% /notice %}}

#### Step 3. Delete the CloudFront distribution

CloudFront will not delete an enabled distribution, so disable it first.

1. Open the [CloudFront console](https://console.aws.amazon.com/cloudfront/v4/home)
2. Select the distribution and choose **Disable**
3. Wait roughly 15 minutes for the status to return to **Deployed**
4. Select the distribution again and choose **Delete**

#### Step 4. Delete the S3 buckets

A bucket must be empty before it can be deleted:

```bash
aws s3 rm s3://fcj-recsys-frontend-<your-name> --recursive
aws s3 rb s3://fcj-recsys-frontend-<your-name>

aws s3 rm s3://fcj-recsys-data-<your-name> --recursive
aws s3 rb s3://fcj-recsys-data-<your-name>
```

#### Step 5. Delete API Gateway and Lambda

```bash
aws apigatewayv2 delete-api --api-id <API-ID>
aws lambda delete-function --function-name fcj-recsys-api
```

#### Step 6. Delete the DynamoDB tables

```bash
for T in Products Categories Users Sessions Carts Vouchers Reviews Orders; do
  aws dynamodb delete-table --table-name $T
done
```

#### Step 7. Delete the IAM role and alarms

```bash
aws iam delete-role-policy --role-name fcj-recsys-lambda-role --policy-name fcj-recsys-lambda-policy
aws iam detach-role-policy --role-name fcj-recsys-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name fcj-recsys-lambda-role

aws cloudwatch delete-alarms --alarm-names fcj-lambda-errors fcj-lambda-latency
```

#### Step 8. Final sweep

Do not rely on memory. Verify through the Billing console:

1. Open the [Billing console](https://console.aws.amazon.com/billing/home)
2. Choose **Bills** and check whether any service is still accruing cost
3. Cross-check with [Resource Groups](https://console.aws.amazon.com/resource-groups/) to find leftovers

{{% notice tip %}}
Keeping the **CloudWatch log group** is fine; logs are cheap and can be useful later. If you want a completely clean account, delete it from the CloudWatch console too.
{{% /notice %}}

#### Clean-up checklist

| Resource | Deleted |
|---|---|
| Personalize campaign | ☐ |
| Personalize solution and dataset group | ☐ |
| CloudFront distribution | ☐ |
| Both S3 buckets | ☐ |
| API Gateway | ☐ |
| Lambda function | ☐ |
| Eight DynamoDB tables | ☐ |
| IAM role | ☐ |
| CloudWatch alarms | ☐ |
