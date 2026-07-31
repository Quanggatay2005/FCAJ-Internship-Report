---
title: "Blog 3"
date: 2024-01-01
weight: 1
chapter: false
pre: " <b> 3.3. </b> "
---

# RECOMMENDATION SYSTEMS FAIL: DATA, NOT ALGORITHM

When building a product recommendation system with Amazon Personalize during an internship at FCAJ, we discovered that poor performance usually comes from data quality, not algorithm choice.

## 3 Key Lessons

### 1. Understand Your Algorithm's Core Mechanism

- Amazon Personalize uses **collaborative filtering** — it finds users with similar behavior and recommends based on those patterns.
- **Key insight:** If user interactions are random, no patterns exist for the algorithm to learn.

### 2. Data Quality > Algorithm Selection

- Changing recipes without fixing underlying data issues wastes time and money.
- **Focus on data structure:**
  - Create realistic user segments (e.g., electronics lovers, fashion fans, bookworms)
  - Simulate real behavior patterns (sessions, conversion funnels, power-law distribution)
  - The algorithm can only learn what your data reveals

### 3. Synthetic Data Must Reflect Reality

- `random.choice()` is fast but useless for meaningful testing.
- **Design synthetic data carefully:**
  - Model user sessions with related product views
  - Apply conversion rates (view→cart, cart→purchase)
  - Build distinct user segments with clear preferences

## Results Comparison: Same Algorithm, Better Data

| Metric          | Random Data | Structured Data | Improvement |
| --------------- | ----------- | --------------- | ----------- |
| **Precision@5** | 0.0889      | 0.4348          | **4.9x**    |
| **NDCG@10**     | 0.1799      | 0.6512          | **3.6x**    |
| **MRR@25**      | 0.1216      | 0.7130          | **5.9x**    |
| **Coverage**    | 0.8218      | 0.9505          | **+15.7%**  |

### Key Takeaways:

- MRR increased nearly 6x — recommendations now appear at the top of the list where users actually see them
- Coverage improved by 15.7% — the system recommends more products, not just best-sellers
- A well-structured dataset can multiply performance 5-6 times without changing any algorithm

## Component Breakdown

**Data Preparation:** The critical foundation — includes user segmentation, behavior modeling, and realistic interaction patterns.

**Amazon Personalize:** Managed service with pre-built recipes (AWS provides the algorithms, you provide the data).

**Evaluation Metrics:** Precision@5, NDCG@10, MRR@25, Coverage — measure recommendation quality and diversity.

**Structured Data:** Requires user segments (electronics, fashion, books), session-based interactions, conversion funnels, and power-law distributions.

## Key Takeaway

Tools and algorithms are only 20%. The remaining 80% is **Data Quality** and **Understanding Your Problem Domain**.

When metrics are abnormally low, **examine your data before changing the algorithm**.

---

**Original post:** [Facebook AWS Study Group FCJ](https://www.facebook.com/groups/awsstudygroupfcj/permalink/2229279517837008/?rdid=7zgI0zX0X33fQod5#)
