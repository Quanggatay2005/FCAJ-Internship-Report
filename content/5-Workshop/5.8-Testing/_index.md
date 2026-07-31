---
title : "End-to-end testing"
date : 2026-07-28
weight : 8
chapter : false
pre : " <b> 5.8 </b> "
---

Individual components working does not mean the system works. This section verifies the whole path from browser to model.

#### Step 1. Test each layer via CLI

Work from the inside out; stop and fix at whichever layer fails.

```bash
# Data layer
aws dynamodb scan --table-name Products --select COUNT

# API layer
curl https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/products

# ML layer
aws personalize-runtime get-recommendations \
  --campaign-arn <CAMPAIGN-ARN> --user-id user-001 --num-results 5

# Recommendations through the API
curl "https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/recommendations?userId=user-001"
```

#### Step 2. Verify recommendations are actually personalised

This is the single most important check in the system. Call it with two different users:

```bash
curl "https://.../recommendations?userId=user-001"
curl "https://.../recommendations?userId=user-150"
```

The two results **must differ**. If they are identical, the model is not personalising and is only returning a general popularity list.

#### Step 3. Verify recommendation order is preserved

This is a subtle bug that produces no error message at all.

Personalize returns a ranked list. Lambda then queries DynamoDB to fetch full details for each product. The catch: **DynamoDB does not guarantee results come back in the order the keys were passed in**.

If the code does not re-sort, the ranking the model computed is lost, and the best-matching product can end up at the bottom of the list.

How to check: compare the order of `itemId` values from `get-recommendations` with the order of products returned by the API. They must match.

#### Step 4. Test in the browser

1. Open the CloudFront address
2. Register a new account
3. Browse a few products and add them to the cart
4. Place an order
5. Go to the account page and check the order appears
6. Return to the home page and check the recommendation block renders

Press **F12** to open Developer Tools and check the **Network** tab to confirm API calls return 200. If you see CORS errors in the Console tab, go back to section 5.5 and check the configuration.

#### Step 5. Test order price security

The server must recalculate totals itself rather than trusting the browser. Try submitting an order with a tampered price:

```bash
curl -X POST https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: <YOUR-TOKEN>" \
  -d '{"items":[{"productId":"prod-001","quantity":1,"price":1}]}'
```

The created order must carry the **real price** from DynamoDB, not the price of 1 that was submitted. If the order records a price of 1, you have a serious vulnerability.

#### Final checklist

| Item | Expected result |
|---|---|
| Home page loads over CloudFront | Full interface renders |
| Direct access to the S3 bucket | Denied, 403 |
| API returns the product list | JSON with 100 products |
| Recommendations for two different users | Two different lists |
| Recommendation order | Matches what Personalize returned |
| Order with tampered price | Server uses the real price |
| Opening a sub-path like `/cart` directly | Page loads, no 403 |
| CloudWatch logs | An entry for every invocation |
