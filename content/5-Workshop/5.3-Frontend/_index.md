---
title : "Deploy the frontend layer"
date : 2026-07-28
weight : 3
chapter : false
pre : " <b> 5.3 </b> "
---

In this section you create the storage and delivery layer for the web interface. An S3 bucket holds the files; CloudFront delivers them to users.

One thing to note: the bucket will stay **completely private**. Users never reach S3 directly, only through CloudFront. The mechanism that makes this work is called **Origin Access Control**.

#### Step 1. Create the frontend bucket

1. Open the [Amazon S3 console](https://s3.console.aws.amazon.com/s3/home?region=ap-southeast-1)
2. Choose **Create bucket**
3. Fill in:
   - **Bucket name**: `fcj-recsys-frontend-<your-name>` (bucket names are globally unique, so add a suffix)
   - **AWS Region**: Asia Pacific (Singapore) `ap-southeast-1`
   - **Block Public Access**: **leave everything enabled**
4. Choose **Create bucket**

![Create bucket](/images/5-Workshop/5.3/create-bucket.png)

{{% notice note %}}
Older guides tell you to enable Static website hosting and make the bucket public. That approach is no longer recommended because it exposes the bucket to the Internet. Here we keep the bucket closed and let CloudFront be the only door.
{{% /notice %}}

#### Step 2. Build the frontend

On your machine, go into the `frontend` folder and build:

```bash
cd frontend
npm install
npm run build
```

This produces a `dist` folder containing all static files.

{{% notice tip %}}
Do not worry about the API address yet. After you create API Gateway in section 5.5, you will come back, set `VITE_API_BASE_URL` and rebuild.
{{% /notice %}}

#### Step 3. Upload to S3

```bash
aws s3 sync dist/ s3://fcj-recsys-frontend-<your-name>/ --delete
```

The `--delete` flag removes old files no longer present in the new build, so leftovers do not pile up across deployments.

Check the console: the bucket should now contain `index.html` and an `assets` folder.

#### Step 4. Create the CloudFront distribution

1. Open the [CloudFront console](https://console.aws.amazon.com/cloudfront/v4/home)
2. Choose **Create distribution**
3. Under **Origin**:
   - **Origin domain**: pick the bucket you just created
   - **Origin access**: choose **Origin access control settings (recommended)**
   - Choose **Create new OAC**, keep the defaults, click **Create**
4. Under **Default cache behavior**:
   - **Viewer protocol policy**: **Redirect HTTP to HTTPS**
   - **Allowed HTTP methods**: `GET, HEAD`
5. Under **Settings**:
   - **Default root object**: `index.html`
6. Choose **Create distribution**

![Create distribution](/images/5-Workshop/5.3/create-distribution.png)

{{% notice tip %}}
**Advanced Security:** At this CloudFront creation step, you could also apply **AWS WAF** (Web Application Firewall) to block Botnets and DDoS attacks directed at your web interface.
{{% /notice %}}

#### Step 5. Grant CloudFront read access to the bucket

After creation, CloudFront shows a banner prompting you to update the bucket policy. Choose **Copy policy**, then:

1. Go to the [S3 console](https://s3.console.aws.amazon.com/s3/home?region=ap-southeast-1) and open the bucket
2. Open the **Permissions** tab
3. Under **Bucket policy**, choose **Edit**, paste the copied policy, then **Save changes**

This policy allows only that one distribution to read the bucket, nobody else.

#### Step 6. Handle 403 errors for the single-page app

The React frontend uses client-side routing. When a user opens `/cart` directly, CloudFront looks for a file named `cart` in S3, does not find it and returns an error. Those errors need to be redirected to `index.html`.

1. In the distribution, open the **Error pages** tab
2. Choose **Create custom error response** and set:
   - **HTTP error code**: `403 Forbidden`
   - **Customize error response**: Yes
   - **Response page path**: `/index.html`
   - **HTTP Response code**: `200 OK`
3. Repeat once more for error code `404 Not Found`

#### Verify

Wait around 5 minutes for the distribution status to become **Deployed**, then open the address shown under **Distribution domain name**, in the form `dxxxxxxxxx.cloudfront.net`.

The interface should render. Product data will be missing because the API does not exist yet, which is expected.

{{% notice warning %}}
**Remember this one, it will save you hours.** Every time you upload a new build to S3 you **must** create an invalidation, otherwise CloudFront keeps serving the cached old version and you will think your code is broken.

```bash
aws cloudfront create-invalidation --distribution-id <YOUR-ID> --paths "/*"
```
{{% /notice %}}
