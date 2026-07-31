---
title : "Xây dựng hệ gợi ý"
date : 2026-07-28
weight : 6
chapter : false
pre : " <b> 5.6 </b> "
---

Đây là phần trung tâm của workshop. Bạn sẽ huấn luyện một mô hình gợi ý và đưa vào phục vụ thời gian thực.

#### Hiểu về dữ liệu trước khi bắt tay

Amazon Personalize học từ **hành vi**, không phải từ thuộc tính sản phẩm. Nó cần một bảng ghi lại ai đã tương tác với sản phẩm nào, vào lúc nào.

Định dạng bắt buộc gồm ba cột, tên viết hoa:

```
USER_ID,ITEM_ID,EVENT_TYPE,TIMESTAMP
user-133,prod-080,view,1779328787
user-133,prod-008,view,1779328979
user-133,prod-008,add_to_cart,1779329120
user-133,prod-008,purchase,1779329340
```

`TIMESTAMP` phải là số nguyên Unix, không phải chuỗi ngày tháng.

{{% notice warning %}}
**Bài học đắt giá nhất của workshop này.** Bộ dữ liệu đầu tiên chúng tôi dùng gồm 4.491 lượt tương tác sinh **ngẫu nhiên đều**. Mô hình huấn luyện xong cho kết quả rất tệ, và khi phân tích lại thì lý do hiển nhiên: thuật toán lọc cộng tác hoạt động bằng cách tìm các nhóm người dùng có hành vi giống nhau. Nếu ai cũng tương tác ngẫu nhiên thì không tồn tại nhóm nào để tìm.

Đổi thuật toán không cứu được điều đó. Phải sửa dữ liệu.
{{% /notice %}}

Bộ dữ liệu thứ hai mô phỏng hành vi thật với năm đặc điểm: gom theo phiên truy cập, có phễu chuyển đổi xem rồi mới thêm giỏ rồi mới mua, phân phối power-law để một nhóm nhỏ sản phẩm hút phần lớn lượt xem, có nhịp theo giờ trong ngày, và chia người dùng thành các phân khúc sở thích khác nhau.

Kết quả trên cùng một recipe:

| Chỉ số | Dữ liệu ngẫu nhiên | Dữ liệu mô phỏng hành vi |
|---|---|---|
| Precision@5 | 0,0889 | 0,4348 |
| NDCG@10 | 0,1799 | 0,6512 |
| MRR@25 | 0,1216 | 0,7130 |
| Coverage | 0,8218 | 0,9505 |

#### Bước 1. Tạo bucket và tải dữ liệu

```bash
aws s3 mb s3://fcj-recsys-data-<tên-bạn>
aws s3 cp interactions.csv s3://fcj-recsys-data-<tên-bạn>/personalize/
aws s3 cp items.csv s3://fcj-recsys-data-<tên-bạn>/personalize/
```

#### Bước 2. Cho phép Personalize đọc bucket

Personalize là một dịch vụ riêng, nó cần được cấp quyền mới đọc được bucket của bạn.

Tạo role:

1. Vào [IAM console](https://console.aws.amazon.com/iam/home#/roles), chọn **Create role**
2. **Trusted entity type**: AWS service. Ở **Use case**, tìm và chọn **Personalize**
3. Gán policy `AmazonS3ReadOnlyAccess`
4. Đặt tên `PersonalizeS3Role`, chọn **Create role**

Thêm bucket policy cho phép Personalize đọc. Tạo file `bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "personalize.amazonaws.com" },
    "Action": ["s3:GetObject", "s3:ListBucket"],
    "Resource": [
      "arn:aws:s3:::fcj-recsys-data-<tên-bạn>",
      "arn:aws:s3:::fcj-recsys-data-<tên-bạn>/*"
    ]
  }]
}
```

```bash
aws s3api put-bucket-policy --bucket fcj-recsys-data-<tên-bạn> --policy file://bucket-policy.json
```

#### Bước 3. Tạo dataset group

1. Mở [Amazon Personalize console](https://ap-southeast-1.console.aws.amazon.com/personalize/home?region=ap-southeast-1)
2. Chọn **Create dataset group**
3. **Name**: `fcj-recsys-dsg`, **Domain**: chọn **Custom**
4. Chọn **Create dataset group and continue**

![Tạo dataset group](/images/5-Workshop/5.6/create-dsg.png)

#### Bước 4. Nạp dữ liệu tương tác

1. Ở bước **Create interactions dataset**, chọn **Create dataset**
2. **Dataset name**: `interactions`
3. Chọn **Create new schema**, đặt tên `interactions-schema`, dán nội dung:

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

4. Chọn **Next**, rồi **Import data directly into datasets**
5. Điền:
   - **Import job name**: `import-interactions`
   - **IAM role**: chọn `PersonalizeS3Role`
   - **Data location**: `s3://fcj-recsys-data-<tên-bạn>/personalize/interactions.csv`
6. Chọn **Start import**

Quá trình nạp mất khoảng 10 đến 20 phút. Trạng thái phải chuyển sang **Active**.

{{% notice tip %}}
Trong lúc chờ, tranh thủ chụp màn hình các bước đã làm cho phần báo cáo.
{{% /notice %}}

#### Bước 5. Huấn luyện solution

1. Ở menu trái, chọn **Custom resources** rồi **Solutions and recipes**
2. Chọn **Create solution**
3. Điền:
   - **Solution name**: `fcj-user-personalization`
   - **Solution type**: **Item recommendation**
   - **Recipe**: `aws-user-personalization-v2`
4. Chọn **Create and train solution**

Huấn luyện mất khoảng 40 đến 90 phút tuỳ lượng dữ liệu.

#### Bước 6. Xem chỉ số đánh giá

Khi solution version chuyển sang **Active**, mở nó ra để xem các chỉ số:

- **Precision@K**: tỉ lệ sản phẩm đúng trong K gợi ý đầu tiên
- **NDCG@K**: giống Precision nhưng có tính vị trí, gợi ý đúng nằm đầu danh sách có giá trị cao hơn nằm cuối
- **MRR@K**: vị trí trung bình của gợi ý đúng đầu tiên
- **Coverage**: tỉ lệ sản phẩm trong kho từng được gợi ý

![Chỉ số mô hình](/images/5-Workshop/5.6/metrics.png)

#### Bước 7. Tạo campaign

Campaign là điểm cuối phục vụ suy luận thời gian thực.

1. Chọn **Campaigns** rồi **Create campaign**
2. Điền:
   - **Campaign name**: `fcj-recsys-campaign`
   - **Solution**: chọn solution vừa huấn luyện
   - **Minimum provisioned TPS**: `1`
3. Chọn **Create campaign**

{{% notice warning %}}
Campaign bắt đầu **tính phí theo giờ** ngay khi tạo, kể cả khi không có truy vấn nào. Đây là tài nguyên tốn tiền nhất trong workshop. Ghi nhớ để xoá ở phần dọn dẹp.
{{% /notice %}}

#### Bước 8. Nối campaign vào Lambda

Copy Campaign ARN, rồi thêm biến môi trường cho Lambda:

1. Mở hàm `fcj-recsys-api`, tab **Configuration**, mục **Environment variables**
2. Chọn **Edit**, thêm biến:
   - **Key**: `CAMPAIGN_ARN`
   - **Value**: ARN vừa copy
3. Chọn **Save**

#### Kiểm tra

```bash
aws personalize-runtime get-recommendations \
  --campaign-arn <CAMPAIGN-ARN> \
  --user-id user-001 \
  --num-results 5
```

Trả về danh sách `itemId` là mô hình đã hoạt động. Thử với vài `user-id` khác nhau, kết quả phải khác nhau --- đó là bằng chứng gợi ý thực sự được cá nhân hoá.
