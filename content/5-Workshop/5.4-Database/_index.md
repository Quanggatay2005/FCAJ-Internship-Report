---
title : "Create the database"
date : 2026-07-28
weight : 4
chapter : false
pre : " <b> 5.4 </b> "
---

The system uses 8 DynamoDB tables. Before creating them, there is one fundamental difference from relational databases worth understanding.

#### Design around access patterns

With a relational database you normalise the data first and write queries later. With DynamoDB it is the other way round: you decide how you will query first, then design tables to serve exactly those queries.

Here, the first six tables only ever need a lookup by a single key. The last two are different:

- **Reviews**: needs *all reviews for one product*
- **Orders**: needs *all orders for one user*

With a single key, fetching those records would require a **Scan** that reads the entire table and filters. That is slow and expensive, since DynamoDB bills by the volume of data read.

The solution is a **composite key** made of a partition key and a sort key. That lets you use **Query**, which reads only the partition you need.

| Table | Partition key | Sort key | Contents |
|---|---|---|---|
| Products | `id` | --- | Product information |
| Categories | `id` | --- | Categories |
| Users | `id` | --- | Accounts, hashed passwords |
| Sessions | `token` | --- | Login sessions |
| Carts | `userId` | --- | Shopping carts |
| Vouchers | `code` | --- | Discount codes |
| Reviews | `productId` | `id` | Product reviews |
| Orders | `userId` | `id` | Orders |

{{% notice info %}}
**Production Note:** DynamoDB is highly suitable for high-speed transactional workflows (like shopping carts and orders). However, for complex product search and filtering queries (such as searching by price range, color, or free-text keywords), you should consider syncing data to **Amazon OpenSearch** to process them rather than relying solely on DynamoDB.
{{% /notice %}}

#### Step 1. Create a table in the console

Do one by hand first to get familiar with the interface:

1. Open the [DynamoDB console](https://ap-southeast-1.console.aws.amazon.com/dynamodbv2/home?region=ap-southeast-1)
2. Choose **Create table**
3. Fill in:
   - **Table name**: `Products`
   - **Partition key**: `id`, type **String**
   - Leave Sort key empty
   - **Table settings**: choose **Customize settings**
   - **Table class**: DynamoDB Standard
   - **Capacity mode**: **On-demand**
4. Choose **Create table**

![Create table](/images/5-Workshop/5.4/create-table.png)

{{% notice note %}}
**On-demand** means you pay for actual reads and writes rather than pre-provisioned capacity. For a project with unknown traffic this is the safe choice: you neither overpay nor get throttled.
{{% /notice %}}

#### Step 2. Create the remaining seven tables via CLI

Creating seven tables by hand is tedious. Use this instead:

```bash
for T in Categories Users Sessions Carts Vouchers; do
  case $T in
    Sessions) K=token ;;
    Carts)    K=userId ;;
    Vouchers) K=code ;;
    *)        K=id ;;
  esac
  aws dynamodb create-table --table-name $T \
    --attribute-definitions AttributeName=$K,AttributeType=S \
    --key-schema AttributeName=$K,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
done
```

The two composite-key tables are created separately:

```bash
aws dynamodb create-table --table-name Reviews \
  --attribute-definitions AttributeName=productId,AttributeType=S AttributeName=id,AttributeType=S \
  --key-schema AttributeName=productId,KeyType=HASH AttributeName=id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

aws dynamodb create-table --table-name Orders \
  --attribute-definitions AttributeName=userId,AttributeType=S AttributeName=id,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH AttributeName=id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
```

#### Step 3. Verify

```bash
aws dynamodb list-tables
```

The output should list all 8 tables.

#### Step 4. Seed sample data

Load sample categories and products so the system has something to display:

```bash
cd backend
node scripts/seed-data.mjs
```

Check the record count in the Products table:

```bash
aws dynamodb scan --table-name Products --select COUNT
```
