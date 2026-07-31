---
title : "Deploy the API layer"
date : 2026-07-28
weight : 5
chapter : false
pre : " <b> 5.5 </b> "
---

This section creates the brain of the system: one Lambda function handling all business logic, and an API Gateway as the entry point.

{{% notice info %}}
**Security Note (Auth):** In the scope of this workshop, password hashing and user management logic are coded directly within the API so you can easily visualize the data flow. In a real-world Production environment, you should delegate this entire functionality to **Amazon Cognito** to meet security standards.
{{% /notice %}}

Order matters: **IAM role first, then Lambda, then API Gateway**. Because Lambda needs the role at creation time, and API Gateway needs the Lambda to already exist.

#### Step 1. Create an IAM role with least privilege

Lambda needs read/write access to DynamoDB and permission to call Personalize. The quickest option would be attaching `AdministratorAccess`, but that is a bad habit: if your code has a vulnerability, an attacker gains the whole account.

We grant only what is needed.

1. Open the [IAM console](https://console.aws.amazon.com/iam/home#/roles), choose **Roles** then **Create role**
2. **Trusted entity type**: AWS service. **Use case**: Lambda. Choose **Next**
3. Search for and select `AWSLambdaBasicExecutionRole` --- permission to write CloudWatch logs
4. Choose **Next**, name it `fcj-recsys-lambda-role`, choose **Create role**

Now add the specific permissions for DynamoDB and Personalize:

5. Open the new role, choose **Add permissions** then **Create inline policy**
6. Switch to the **JSON** tab and paste the following (replace `<ACCOUNT-ID>` with your account number):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
        "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan",
        "dynamodb:BatchGetItem", "dynamodb:BatchWriteItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-southeast-1:<ACCOUNT-ID>:table/*"
    },
    {
      "Effect": "Allow",
      "Action": "personalize:GetRecommendations",
      "Resource": "*"
    }
  ]
}
```

7. Name the policy `fcj-recsys-lambda-policy` and choose **Create policy**

{{% notice tip %}}
Get your Account ID with `aws sts get-caller-identity --query Account --output text`
{{% /notice %}}

#### Step 2. Package the source code

Lambda needs a zip file containing your code and its dependencies:

```bash
cd backend
npm install --production
zip -r ../function.zip index.mjs node_modules
```

#### Step 3. Create the Lambda function

1. Open the [Lambda console](https://ap-southeast-1.console.aws.amazon.com/lambda/home?region=ap-southeast-1)
2. Choose **Create function**
3. Fill in:
   - **Function name**: `fcj-recsys-api`
   - **Runtime**: **Node.js 20.x**
   - **Architecture**: x86_64
   - **Execution role**: choose **Use an existing role**, select `fcj-recsys-lambda-role`
4. Choose **Create function**
5. On the **Code** tab, choose **Upload from** then **.zip file**, and upload `function.zip`
6. Go to **Runtime settings**, choose **Edit**, set **Handler** to `index.handler`

![Create Lambda](/images/5-Workshop/5.5/create-lambda.png)

#### Step 4. Increase the timeout

By default Lambda stops after 3 seconds, which is not enough when calling Personalize.

1. Open the **Configuration** tab, choose **General configuration**, choose **Edit**
2. Set **Timeout** to `30` seconds and **Memory** to `512` MB
3. Choose **Save**

#### Step 5. Create the HTTP API

1. Open the [API Gateway console](https://ap-southeast-1.console.aws.amazon.com/apigateway/main/apis?region=ap-southeast-1)
2. In the **HTTP API** box, choose **Build**
3. Choose **Add integration**, type **Lambda**, and select the `fcj-recsys-api` function
4. **API name**: `fcj-recsys-api`, choose **Next**
5. Under **Configure routes**, define a catch-all route:
   - **Method**: `ANY`
   - **Resource path**: `/{proxy+}`
   - **Integration target**: the Lambda function you selected
6. Choose **Next**, keep the `$default` stage with **Auto-deploy** enabled, choose **Create**

{{% notice note %}}
The `/{proxy+}` route sends every path to the same Lambda, letting the code route internally. This keeps API Gateway configuration simple, at the cost of moving routing into the code. With 22 routes, that is a reasonable trade-off.
{{% /notice %}}

#### Step 6. Enable CORS

The frontend runs on a CloudFront domain while the API sits on a different one. Browsers will block the calls unless CORS is declared.

1. In your API, choose **CORS** in the left menu, then **Configure**
2. Set:
   - **Access-Control-Allow-Origin**: `*`
   - **Access-Control-Allow-Headers**: `content-type, authorization`
   - **Access-Control-Allow-Methods**: `GET, POST, PUT, DELETE, OPTIONS`
3. Choose **Save**

{{% notice warning %}}
CORS errors only appear in the browser console; testing with `curl` still works fine. If the interface reports it cannot reach the server while `curl` succeeds, press F12 and check the Console tab first.
{{% /notice %}}

#### Step 7. Connect the frontend to the API

Copy the **Invoke URL** from the API detail page, then go back to the frontend folder:

```bash
cd frontend
echo "VITE_API_BASE_URL=https://xxxxx.execute-api.ap-southeast-1.amazonaws.com" > .env
npm run build
aws s3 sync dist/ s3://fcj-recsys-frontend-<your-name>/ --delete
aws cloudfront create-invalidation --distribution-id <YOUR-ID> --paths "/*"
```

#### Verify

```bash
curl https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/products
```

A JSON list of products means success. Reload the CloudFront page and products should now appear.
