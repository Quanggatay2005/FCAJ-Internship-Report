---
title : "Dọn dẹp tài nguyên"
date : 2026-07-28
weight : 9
chapter : false
pre : " <b> 5.9 </b> "
---

{{% notice warning %}}
Làm phần này **ngay sau khi hoàn thành workshop**. Personalize campaign tính phí theo giờ tồn tại, quên xoá là hoá đơn tăng âm thầm từng ngày.
{{% /notice %}}

#### Thứ tự xoá

Thứ tự quan trọng vì các tài nguyên phụ thuộc lẫn nhau. Xoá theo đúng danh sách dưới, từ tốn tiền nhất tới ít tốn nhất.

#### Bước 1. Xoá campaign --- ưu tiên cao nhất

```bash
aws personalize delete-campaign --campaign-arn <CAMPAIGN-ARN>
```

Hoặc trên console: **Personalize** → **Campaigns** → chọn campaign → **Delete**.

Chờ trạng thái chuyển sang **Delete pending** rồi biến mất khỏi danh sách.

#### Bước 2. Xoá solution và dataset group

Phải xoá theo đúng thứ tự này, nếu không sẽ báo lỗi phụ thuộc:

```bash
# Xoá solution trước
aws personalize delete-solution --solution-arn <SOLUTION-ARN>

# Đợi solution biến mất rồi xoá dataset
aws personalize delete-dataset --dataset-arn <DATASET-ARN>

# Cuối cùng xoá dataset group
aws personalize delete-dataset-group --dataset-group-arn <DSG-ARN>
```

{{% notice note %}}
Nếu solution có bật **automatic retraining**, hãy tắt trước khi xoá, nếu không nó có thể khởi động một lần huấn luyện mới và phát sinh chi phí.
{{% /notice %}}

#### Bước 3. Xoá CloudFront distribution

CloudFront không cho xoá distribution đang bật, phải vô hiệu hoá trước.

1. Mở [CloudFront console](https://console.aws.amazon.com/cloudfront/v4/home)
2. Chọn distribution, chọn **Disable**
3. Chờ khoảng 15 phút cho trạng thái chuyển sang **Deployed**
4. Chọn lại distribution, chọn **Delete**

#### Bước 4. Xoá bucket S3

Bucket phải rỗng mới xoá được:

```bash
aws s3 rm s3://fcj-recsys-frontend-<tên-bạn> --recursive
aws s3 rb s3://fcj-recsys-frontend-<tên-bạn>

aws s3 rm s3://fcj-recsys-data-<tên-bạn> --recursive
aws s3 rb s3://fcj-recsys-data-<tên-bạn>
```

#### Bước 5. Xoá API Gateway và Lambda

```bash
aws apigatewayv2 delete-api --api-id <API-ID>
aws lambda delete-function --function-name fcj-recsys-api
```

#### Bước 6. Xoá bảng DynamoDB

```bash
for T in Products Categories Users Sessions Carts Vouchers Reviews Orders; do
  aws dynamodb delete-table --table-name $T
done
```

#### Bước 7. Xoá IAM role và alarm

```bash
aws iam delete-role-policy --role-name fcj-recsys-lambda-role --policy-name fcj-recsys-lambda-policy
aws iam detach-role-policy --role-name fcj-recsys-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name fcj-recsys-lambda-role

aws cloudwatch delete-alarms --alarm-names fcj-lambda-errors fcj-lambda-latency
```

#### Bước 8. Rà soát lần cuối

Đừng tin vào trí nhớ. Kiểm tra lại bằng Billing console:

1. Mở [Billing console](https://console.aws.amazon.com/billing/home)
2. Chọn **Bills**, xem có dịch vụ nào còn phát sinh chi phí không
3. Kiểm tra thêm bằng [Resource Groups](https://console.aws.amazon.com/resource-groups/) để tìm tài nguyên còn sót

{{% notice tip %}}
Giữ lại **CloudWatch log group** cũng được, log rất rẻ và có thể hữu ích khi bạn cần xem lại. Nhưng nếu muốn sạch hoàn toàn thì xoá luôn ở CloudWatch console.
{{% /notice %}}

#### Bảng kiểm dọn dẹp

| Tài nguyên | Đã xoá |
|---|---|
| Personalize campaign | ☐ |
| Personalize solution và dataset group | ☐ |
| CloudFront distribution | ☐ |
| Hai bucket S3 | ☐ |
| API Gateway | ☐ |
| Hàm Lambda | ☐ |
| Tám bảng DynamoDB | ☐ |
| IAM role | ☐ |
| CloudWatch alarm | ☐ |
