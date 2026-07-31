---
title : "Monitoring and alerting"
date : 2026-07-28
weight : 7
chapter : false
pre : " <b> 5.7 </b> "
---

A system that runs is not a finished system. If Lambda starts failing at 2 a.m., you want to know before your users complain.

#### Step 1. Read the logs

Lambda writes logs to CloudWatch automatically thanks to the `AWSLambdaBasicExecutionRole` policy attached in section 5.5.

1. Open the [CloudWatch console](https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1)
2. Choose **Log groups** and find `/aws/lambda/fcj-recsys-api`
3. Open the most recent log stream

This is the first place to look whenever the API returns a 500. The error message sent to users is usually trimmed; the full stack trace lives here.

#### Step 2. Create an SNS topic for notifications

```bash
aws sns create-topic --name fcj-recsys-alerts
```

Subscribe your email:

```bash
aws sns subscribe \
  --topic-arn <TOPIC-ARN> \
  --protocol email \
  --notification-endpoint your-email@example.com
```

Open your inbox and confirm the subscription.

#### Step 3. Create an error-rate alarm

1. Open the [CloudWatch console](https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1), choose **Alarms** then **Create alarm**
2. Choose **Select metric**, go to **Lambda** then **By Function Name**
3. Find `fcj-recsys-api`, select the **Errors** metric, choose **Select metric**
4. Under **Conditions**:
   - **Statistic**: Sum
   - **Period**: 5 minutes
   - **Threshold type**: Static
   - **Whenever Errors is**: Greater than `5`
5. Choose **Next**, and for notifications select the `fcj-recsys-alerts` topic
6. Name the alarm `fcj-lambda-errors` and choose **Create alarm**

![Create alarm](/images/5-Workshop/5.7/create-alarm.png)

#### Step 4. Create a latency alarm

Repeat the steps above but select the **Duration** metric, statistic **Average**, threshold greater than `3000` milliseconds. Name it `fcj-lambda-latency`.

Rising latency is often an earlier signal than outright errors. When Lambda gradually slows down, the cause is usually an inefficient DynamoDB query or a slow Personalize response.

#### Step 5. Set a cost alert

This is the one people skip and later regret.

1. Open the [Billing console](https://console.aws.amazon.com/billing/home#/budgets)
2. Choose **Budgets** then **Create budget**
3. Choose **Cost budget** and set a sensible threshold, for example 10 USD per month
4. Add an alert at 80 percent of the threshold and enter your email

{{% notice tip %}}
A Personalize campaign bills per hour it exists. If you forget to delete it after finishing, the cost accumulates silently. A budget alert is your safety net for exactly that.
{{% /notice %}}

#### Verify the alarm works

Hit a non-existent path several times to generate errors:

```bash
for i in {1..10}; do
  curl -s https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/does-not-exist > /dev/null
done
```

After a few minutes the alarm should switch to **In alarm** and you should receive an email.
