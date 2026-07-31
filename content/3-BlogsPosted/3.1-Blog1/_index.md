---
title: "From Static Recommendations to Real-time Personalization: A Journey with Amazon Personalize"
date: 2024-01-01
weight: 1
chapter: false
pre: " <b> 3.1. </b> "
---

### From Static Recommendations to Real-time Personalization: A Journey with Amazon Personalize

When first building the "Recommended Products" section for an e-commerce site, I thought it was simple: just take the Top Selling or Trending items of the week and display them to all users. But as I tracked conversion metrics, I realized a truth: static recommendations do not understand the individual behavior of each customer. A user who just viewed running shoes would still be recommended... the best-selling rice cooker of the week.

The challenge was: how do we transition from "one-size-fits-all recommendations" to real-time personalized recommendations, when the team doesn't have an in-house Data Science crew to train Collaborative Filtering or Deep Learning models? The answer I chose was **Amazon Personalize** - a managed ML service from AWS that uses the exact same technology behind Amazon.com's recommendation system.

Below is what I learned after implementing it in production.

#### 1. Data Preparation: The Three Pillars - Interactions, Users, Items

**Reality:** Many teams rush into creating a Dataset Group, forgetting that input data quality determines 80% of the model's quality. Amazon Personalize requires data across three types of datasets, but only one is mandatory:
- **Item interactions (mandatory):** records user behaviors - clicks, add-to-carts, purchases. Requires at least three fields: `USER_ID`, `ITEM_ID`, `TIMESTAMP`, and should include `EVENT_TYPE` to distinguish between different types of behaviors.
- **Users (optional):** only requires the `USER_ID` field, can include up to 5 metadata fields such as age, region, gender.
- **Items (optional):** only requires `ITEM_ID`, can include metadata like category, price, brand - this helps the model handle new products better (cold-start).

**Lesson:** Regarding the minimum data threshold for meaningful training, AWS recommends having at least 1,000 users and 1,000 interactions, and significantly more data per product to achieve better results. For the User-Personalization recipe, official AWS documentation also explicitly states a minimum requirement of 1,000 interaction records.

Another important point: if your Interactions dataset has multiple event types (click, purchase, watch...), you can specify a particular event type to train on, or - with v2 recipes - assign different weights to each event type (e.g., prioritizing purchases over clicks). This is a detail I overlooked initially, causing the model to "learn" too much from random click behaviors instead of truly valuable purchasing behaviors.

#### 2. Dataset Group, Schema & Import: The Foundation Before Training

**Reality:** Amazon Personalize organizes everything around the concept of a Dataset Group - a container holding a maximum of three dataset types (Interactions, Items, Users, and for more advanced use cases, Actions/Action interactions). You can choose between:
- **Domain dataset group** (ECOMMERCE, VIDEO_ON_DEMAND...): uses pre-configured recommenders, suitable for rapid deployment.
- **Custom dataset group:** lets you choose recipes and configure Solutions yourself — more flexible for specific use cases.

**Lesson:** Define the schema (Avro-based) for each dataset clearly from the start. If the team is familiar with IaC, you can declare everything using AWS CDK instead of clicking manually on the Console — this allows for easily reproducing Staging/Production environments and auditing when issues occur. A practical CDK structure example:

```text
DatasetGroup (domain: ECOMMERCE)
 └── InteractionsDataset (schema: USER_ID, ITEM_ID, TIMESTAMP, EVENT_TYPE)
 └── ItemsDataset (schema: ITEM_ID, CATEGORY, PRICE...)
 └── UsersDataset (schema: USER_ID, AGE, REGION...)
```

After creating the datasets, data import can be done via Batch import (from S3, suitable for historical data) or Streaming ingestion via PutEvents API (suitable for real-time behaviors like clicks on the site).

#### 3. Solution & Recipe: Choosing the Right "Brain" for the Problem

**Reality:** This is the step where newcomers get most confused — Amazon Personalize provides multiple recipes (pre-packaged algorithms) divided into three groups:
- **USER_PERSONALIZATION** — predicts the products a user is most likely to interact with next (used for homepages, recommendation emails).
- **PERSONALIZED_RANKING** — re-ranks an existing list of products based on relevance to each user (used for category/search pages).
- **RELATED_ITEMS** — recommends "similar products" (used for product detail pages).

**Lesson:** AWS currently recommends using v2 recipes (e.g., `User-Personalization-v2`) instead of the original versions, as these recipes can handle up to 5 million products with faster training times and lower latency. In addition, the User-Personalization recipe features an Exploration mechanism - proactively inserting new or sparsely interacted products into recommendations to avoid the "filter bubble", which is highly useful when the catalog changes rapidly (new products arriving constantly).

If you need a "no model training required" option for scenarios like hourly top trending items, Amazon Personalize also offers the `Trending-Now` recipe. This helps identify products with the fastest-growing interactions over a recent period - a great supplement for a "Trending Now" section alongside the main personalized recommendations.

#### 4. Campaign: Serving the Model in Real-time

**Reality:** Having a solution version (a trained model) is not enough - you need a Campaign to create an actual endpoint that returns real-time results when the application calls the `GetRecommendations` or `GetPersonalizedRanking` API.

**Most important lesson in this step:** real-time personalization doesn't stop at deploying the Campaign. With the User-Personalization recipe, Amazon Personalize automatically updates the latest model every two hours to consider new products - meaning you don't have to write a manual retraining pipeline just to add new products to the catalog. Furthermore, when there are filters (e.g., removing out-of-stock products from recommendations), these filters are also updated within 15 minutes of the latest data import or incremental record, fast enough for most e-commerce needs.

### Overall Architecture I Applied

```text
Clickstream / Purchase Events (Frontend, Backend)
 │ (PutEvents API - real-time)
 ▼
Amazon Personalize — Interactions Dataset
 │
 ├── Dataset Group (ECOMMERCE domain)
 ├── Solution (recipe: User-Personalization-v2)
 └── Campaign (real-time endpoint)
 │
 ▼
GetRecommendations API
 │
 ▼
Homepage / Product Pages / Email marketing
```

**Result:** After switching from static Top Selling to personalized recommendations, the "You might also like" sections on the homepage and product detail pages display correctly according to each user's behavior. We no longer need a Data Science team on standby to fine-tune the model manually - the entire train/deploy/update lifecycle is managed by Amazon Personalize.

### Biggest Takeaway

The tool is only half the story. The other half lies in preparing behavioral data correctly and choosing the right recipe for the right display location (the homepage is different from a category page, which is different from a product detail page). A good personalized recommendation system isn't the most complex model, but a model fed with clean interaction data, continuously updated, and placed in the right spot in the customer journey.

### References (Official AWS Docs)

For those who want to dive deeper into technical details:

#### Dataset & Schema:
- [Amazon Personalize Developer Guide — Choosing item interaction data for training](https://docs.aws.amazon.com/personalize/latest/dg/event-values-types.html)
- [CreateDatasetGroup API Reference](https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetGroup.html)

#### Recipe & Solution:
- [User-Personalization Recipe Guide](https://docs.aws.amazon.com/personalize/latest/dg/native-recipe-new-item-USER_PERSONALIZATION.html)
- [Trending-Now Recipe (AWS ML Blog)](https://aws.amazon.com/blogs/machine-learning/recommend-top-trending-items-to-your-users-using-the-new-amazon-personalize-recipe/)

#### Operations & Data Updates:
- [Simplify Data Management with New APIs in Amazon Personalize (AWS ML Blog)](https://aws.amazon.com/blogs/machine-learning/simplify-data-management-with-new-apis-in-amazon-personalize)