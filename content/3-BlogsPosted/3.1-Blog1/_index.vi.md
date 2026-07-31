---
title: "Blog 1"
date: 2024-01-01
weight: 1
chapter: false
pre: " <b> 3.1. </b> "
---

# Từ Gợi Ý Tĩnh Đến Real-time Personalization: Hành Trình Với Amazon Personalize
Khi mới xây dựng phần "Sản phẩm gợi ý" cho một trang thương mại điện tử, mình từng nghĩ đơn giản: cứ lấy Top Selling hoặc Trending theo tuần, hiển thị cho tất cả người dùng là xong. Nhưng càng theo dõi số liệu conversion, mình càng nhận ra một sự thật: gợi ý tĩnh không hiểu hành vi cá nhân của từng khách hàng. Người vừa xem giày chạy bộ vẫn bị đề xuất... nồi cơm điện đang bán chạy nhất tuần.

Vấn đề đặt ra là: làm sao chuyển từ "gợi ý giống nhau cho tất cả mọi người" sang gợi ý cá nhân hoá theo thời gian thực, mà team không có sẵn đội ngũ Data Science để tự huấn luyện mô hình Collaborative Filtering hay Deep Learning? Câu trả lời mình chọn là **Amazon Personalize** - dịch vụ managed ML của AWS, vốn dùng chính công nghệ đứng sau hệ thống gợi ý của Amazon.com.

Dưới đây là những gì mình rút ra được sau khi triển khai thực tế.

#### 1. Chuẩn Bị Dữ Liệu: Ba "Chân Kiềng" Interactions – Users – Items

**Thực tế:** Nhiều team lao vào tạo Dataset Group ngay mà quên rằng chất lượng dữ liệu đầu vào quyết định 80% chất lượng mô hình. Amazon Personalize yêu cầu dữ liệu theo ba loại dataset, nhưng chỉ một loại là bắt buộc:
- **Item interactions (bắt buộc):** ghi lại hành vi người dùng - click, add-to-cart, purchase. Tối thiểu cần ba trường `USER_ID`, `ITEM_ID`, `TIMESTAMP`, và nên có thêm `EVENT_TYPE` để phân biệt các loại hành vi.
- **Users (tuỳ chọn):** chỉ bắt buộc trường `USER_ID`, có thể thêm tối đa 5 trường metadata như độ tuổi, khu vực, giới tính.
- **Items (tuỳ chọn):** chỉ bắt buộc `ITEM_ID`, có thể thêm metadata như danh mục, giá, thương hiệu - giúp mô hình xử lý tốt hơn với sản phẩm mới (cold-start).

**Bài học:** Về ngưỡng dữ liệu tối thiểu để training có ý nghĩa, AWS khuyến nghị nên có ít nhất 1.000 người dùng và 1.000 lượt tương tác, còn để đạt kết quả tốt hơn thì cần nhiều dữ liệu hơn đáng kể trên mỗi sản phẩm. Với recipe User-Personalization, tài liệu chính thức của AWS cũng nêu rõ yêu cầu import tối thiểu khoảng 1.000 bản ghi tương tác.

Một điểm quan trọng khác: nếu dataset Interactions của bạn có nhiều loại sự kiện (click, purchase, watch...), bạn hoàn toàn có thể chỉ định loại sự kiện cụ thể để huấn luyện, hoặc - với các recipe v2 - gán trọng số khác nhau cho từng loại sự kiện, ví dụ ưu tiên purchase cao hơn click. Đây là chi tiết mình từng bỏ qua ở lần đầu, khiến mô hình "học" quá nhiều từ hành vi click ngẫu nhiên thay vì hành vi mua hàng thật sự có giá trị.

#### 2. Dataset Group, Schema & Import: Nền Móng Trước Khi Train

**Thực tế:** Amazon Personalize tổ chức mọi thứ quanh khái niệm Dataset Group - một container chứa tối đa các loại dataset (Interactions, Items, Users, và với các use-case nâng cao hơn là Actions/Action interactions). Bạn có thể chọn:
- **Domain dataset group** (ECOMMERCE, VIDEO_ON_DEMAND...): dùng sẵn các recommender được cấu hình trước, phù hợp nếu muốn triển khai nhanh.
- **Custom dataset group:** tự chọn recipe, tự cấu hình Solution — linh hoạt hơn cho use-case đặc thù.

**Bài học:** Định nghĩa schema (Avro-based) cho từng dataset rõ ràng ngay từ đầu, và nếu team đã quen với IaC, có thể khai báo toàn bộ bằng AWS CDK thay vì click tay trên Console — vừa tái lập được môi trường Staging/Production, vừa dễ audit khi có sự cố. Một ví dụ cấu trúc CDK thực tế:

```text
DatasetGroup (domain: ECOMMERCE)
 └── InteractionsDataset (schema: USER_ID, ITEM_ID, TIMESTAMP, EVENT_TYPE)
 └── ItemsDataset (schema: ITEM_ID, CATEGORY, PRICE...)
 └── UsersDataset (schema: USER_ID, AGE, REGION...)
```

Sau khi tạo dataset, việc import dữ liệu có thể thực hiện qua Batch import (từ S3, phù hợp dữ liệu lịch sử) hoặc Streaming ingestion qua PutEvents API (phù hợp hành vi real-time như click ngay trên trang).

#### 3. Solution & Recipe: Chọn "Bộ Não" Phù Hợp Với Bài Toán

**Thực tế:** Đây là bước nhiều người mới dễ bối rối nhất — Amazon Personalize cung cấp nhiều recipe (thuật toán được đóng gói sẵn), chia theo ba nhóm:
- **USER_PERSONALIZATION** — dự đoán sản phẩm người dùng có khả năng tương tác tiếp theo (dùng cho trang chủ, email gợi ý).
- **PERSONALIZED_RANKING** — sắp xếp lại một danh sách sản phẩm có sẵn theo mức độ liên quan với từng user (dùng cho trang danh mục/search).
- **RELATED_ITEMS** — gợi ý "sản phẩm tương tự" (dùng cho trang chi tiết sản phẩm).

**Bài học:** AWS hiện khuyến nghị dùng thế hệ recipe v2 (ví dụ `User-Personalization-v2`) thay vì bản gốc, vì các recipe này có thể xử lý tới 5 triệu sản phẩm với thời gian huấn luyện nhanh hơn và độ trễ thấp hơn. Ngoài ra, recipe User-Personalization còn có cơ chế Exploration - chủ động chèn thêm sản phẩm mới hoặc ít dữ liệu tương tác vào danh sách gợi ý để tránh hiện tượng "filter bubble", rất hữu ích khi catalog thay đổi nhanh (sản phẩm mới về liên tục).

Nếu cần một lựa chọn "không cần train mô hình riêng" cho các trường hợp như top trending theo khung giờ, Amazon Personalize còn có recipe `Trending-Now`, giúp xác định các sản phẩm đang tăng trưởng tương tác nhanh nhất trong một khoảng thời gian gần đây - phù hợp bổ sung cho phần "Đang thịnh hành" bên cạnh phần cá nhân hoá chính.

#### 4. Campaign: Đưa Mô Hình Ra Phục Vụ Real-time

**Thực tế:** Có solution version (mô hình đã train) thôi chưa đủ - cần Campaign để tạo một endpoint thực sự trả kết quả theo thời gian thực khi ứng dụng gọi API `GetRecommendations` hoặc `GetPersonalizedRanking`.

**Bài học quan trọng nhất ở bước này:** real-time personalization không dừng lại ở lúc deploy Campaign. Với recipe User-Personalization, Amazon Personalize tự động cập nhật mô hình mới nhất mỗi hai giờ để cân nhắc thêm các sản phẩm mới - nghĩa là bạn không cần tự viết pipeline retraining thủ công cho việc thêm sản phẩm mới vào catalog. Bên cạnh đó, khi có filter (ví dụ loại bỏ sản phẩm hết hàng khỏi danh sách gợi ý), các filter này cũng được cập nhật trong vòng 15 phút kể từ lần import dữ liệu hoặc bản ghi gia tăng gần nhất, đủ nhanh cho hầu hết nhu cầu e-commerce.

### Kiến Trúc Tổng Thể Mình Đã Áp Dụng

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
Trang chủ / Trang sản phẩm / Email marketing
```

**Kết quả:** Sau khi chuyển từ Top Selling tĩnh sang gợi ý cá nhân hoá, phần "Có thể bạn cũng thích" trên trang chủ và trang chi tiết sản phẩm hiển thị đúng theo hành vi từng người dùng, không còn cần đội Data Science túc trực để tinh chỉnh mô hình thủ công - toàn bộ vòng đời train/deploy/update được Amazon Personalize quản lý.

### Takeaway Lớn Nhất

Công cụ chỉ là một nửa câu chuyện. Nửa còn lại nằm ở việc chuẩn bị dữ liệu hành vi đúng cách và chọn đúng recipe cho đúng vị trí hiển thị (trang chủ khác trang danh mục, khác trang chi tiết sản phẩm). Một hệ thống gợi ý cá nhân hoá tốt không phải là mô hình phức tạp nhất, mà là mô hình được nuôi bằng dữ liệu tương tác sạch, được cập nhật liên tục, và được đặt đúng chỗ trong customer journey.

### Tài Liệu Tham Khảo (Official AWS Docs)

Dành cho bạn nào muốn đào sâu chi tiết kỹ thuật:

#### Dataset & Schema:
- [Amazon Personalize Developer Guide — Choosing item interaction data for training](https://docs.aws.amazon.com/personalize/latest/dg/event-values-types.html)
- [CreateDatasetGroup API Reference](https://docs.aws.amazon.com/personalize/latest/dg/API_CreateDatasetGroup.html)

#### Recipe & Solution:
- [User-Personalization Recipe Guide](https://docs.aws.amazon.com/personalize/latest/dg/native-recipe-new-item-USER_PERSONALIZATION.html)
- [Trending-Now Recipe (AWS ML Blog)](https://aws.amazon.com/blogs/machine-learning/recommend-top-trending-items-to-your-users-using-the-new-amazon-personalize-recipe/)

#### Vận hành & Cập nhật dữ liệu:
- [Simplify Data Management with New APIs in Amazon Personalize (AWS ML Blog)](https://aws.amazon.com/blogs/machine-learning/simplify-data-management-with-new-apis-in-amazon-personalize)      


**Bài viết gốc**: [Facebook AWS Study Group FCJ](https://www.facebook.com/groups/awsstudygroupfcj/permalink/2229289067836053/?rdid=PGigWM6loaBLr4ZG#)