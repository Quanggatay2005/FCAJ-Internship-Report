---
title : "Build the recommendation engine"
date : 2026-07-28
weight : 6
chapter : false
pre : " <b> 5.6 </b> "
---

This is the core of the workshop. You will train a recommendation model and put it into real-time service.

#### Understand the data before you start

Amazon Personalize learns from **behaviour**, not from product attributes. It needs a table recording who interacted with which item, and when.

The required format has these columns, in uppercase:

```
USER_ID,ITEM_ID,EVENT_TYPE,TIMESTAMP
user-133,prod-080,view,1779328787
user-133,prod-008,view,1779328979
user-133,prod-008,add_to_cart,1779329120
user-133,prod-008,purchase,1779329340
```

`TIMESTAMP` must be a Unix integer, not a date string.

{{% notice warning %}}
**The most valuable lesson from this workshop.** Our first dataset had 4,491 interactions generated **uniformly at random**. The trained model performed terribly, and on reflection the reason was obvious: collaborative filtering works by finding groups of users who behave alike. If everyone interacts at random, no such groups exist.

Switching algorithms would not have fixed that. The data had to change.
{{% /notice %}}

The second dataset simulated realistic behaviour with five properties: grouping into browsing sessions, a conversion funnel from view to add-to-cart to purchase, a power-law distribution so a small set of products attracts most views, time-of-day rhythms, and users split into segments with different tastes.

Results on the same recipe:

| Metric | Random data | Behaviour-simulated data |
|---|---|---|
| Precision@5 | 0.0889 | 0.4348 |
| NDCG@10 | 0.1799 | 0.6512 |
| MRR@25 | 0.1216 | 0.7130 |
| Coverage | 0.8218 | 0.9505 |

#### Step 1. Create a bucket and upload the data

```bash
aws s3 mb s3://fcj-recsys-data-<your-name>
aws s3 cp interactions.csv s3://fcj-recsys-data-<your-name>/personalize/
aws s3 cp items.csv s3://fcj-recsys-data-<your-name>/personalize/
```

#### Step 2. Let Personalize read the bucket

Personalize is a separate service and needs explicit permission to read your bucket.

Create the role:

1. Go to the [IAM console](https://console.aws.amazon.com/iam/home#/roles) and choose **Create role**
2. **Trusted entity type**: AWS service. Under **Use case**, find and select **Personalize**
3. Attach the `AmazonS3ReadOnlyAccess` policy
4. Name it `PersonalizeS3Role` and choose **Create role**

Add a bucket policy allowing Personalize to read. Create `bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "personalize.amazonaws.com" },
    "Action": ["s3:GetObject", "s3:ListBucket"],
    "Resource": [
      "arn:aws:s3:::fcj-recsys-data-<your-name>",
      "arn:aws:s3:::fcj-recsys-data-<your-name>/*"
    ]
  }]
}
```

```bash
aws s3api put-bucket-policy --bucket fcj-recsys-data-<your-name> --policy file://bucket-policy.json
```

#### Step 3. Create a dataset group

1. Open the [Amazon Personalize console](https://ap-southeast-1.console.aws.amazon.com/personalize/home?region=ap-southeast-1)
2. Choose **Create dataset group**
3. **Name**: `fcj-recsys-dsg`, **Domain**: choose **Custom**
4. Choose **Create dataset group and continue**

![Create dataset group](/images/5-Workshop/5.6/create-dsg.png)

#### Step 4. Import the interactions data

1. At the **Create interactions dataset** step, choose **Create dataset**
2. **Dataset name**: `interactions`
3. Choose **Create new schema**, name it `interactions-schema`, and paste:

```json
{
  "type": "record",
  "name": "Interactions",
  "namespace": "com.amazonaws.personalize.schema",
  "fields": [
    { "name": "USER_ID", "type": "string" },
    { "name": "ITEM_ID", "type": "string" },
    { "name": "EVENT_TYPE", "type": "string" },
    { "name": "TIMESTAMP", "type": "long" }
  ],
  "version": "1.0"
}
```

4. Choose **Next**, then **Import data directly into datasets**
5. Fill in:
   - **Import job name**: `import-interactions`
   - **IAM role**: select `PersonalizeS3Role`
   - **Data location**: `s3://fcj-recsys-data-<your-name>/personalize/interactions.csv`
6. Choose **Start import**

The import takes roughly 10 to 20 minutes. The status must reach **Active**.

{{% notice tip %}}
While waiting, take screenshots of the steps you have completed for your report.
{{% /notice %}}

#### Step 5. Train a solution

1. In the left menu, choose **Custom resources** then **Solutions and recipes**
2. Choose **Create solution**
3. Fill in:
   - **Solution name**: `fcj-user-personalization`
   - **Solution type**: **Item recommendation**
   - **Recipe**: `aws-user-personalization-v2`
4. Choose **Create and train solution**

Training takes roughly 40 to 90 minutes depending on data volume.

#### Step 6. Review the evaluation metrics

Once the solution version becomes **Active**, open it to see the metrics:

- **Precision@K**: share of correct items among the first K recommendations
- **NDCG@K**: like Precision but position-aware; a correct item at the top counts more than one at the bottom
- **MRR@K**: average position of the first correct recommendation
- **Coverage**: share of the catalogue that ever gets recommended

![Model metrics](/images/5-Workshop/5.6/metrics.png)

#### Step 7. Create a campaign

A campaign is the endpoint that serves real-time inference.

1. Choose **Campaigns** then **Create campaign**
2. Fill in:
   - **Campaign name**: `fcj-recsys-campaign`
   - **Solution**: pick the solution you just trained
   - **Minimum provisioned TPS**: `1`
3. Choose **Create campaign**

{{% notice warning %}}
A campaign starts **billing per hour** the moment it is created, even with zero queries. It is the most expensive resource in this workshop. Remember to delete it during clean-up.
{{% /notice %}}

#### Step 8. Wire the campaign into Lambda

Copy the Campaign ARN, then add an environment variable to Lambda:

1. Open the `fcj-recsys-api` function, **Configuration** tab, **Environment variables**
2. Choose **Edit** and add:
   - **Key**: `CAMPAIGN_ARN`
   - **Value**: the ARN you copied
3. Choose **Save**

#### Verify

```bash
aws personalize-runtime get-recommendations \
  --campaign-arn <CAMPAIGN-ARN> \
  --user-id user-001 \
  --num-results 5
```

A list of `itemId` values means the model is working. Try a few different `user-id` values --- the results should differ, which is your proof that recommendations are genuinely personalised.
