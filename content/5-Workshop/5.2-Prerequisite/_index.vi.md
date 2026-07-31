---
title : "Chuẩn bị"
date : 2026-07-28
weight : 2
chapter : false
pre : " <b> 5.2 </b> "
---

#### Yêu cầu

| Mục | Chi tiết |
|---|---|
| Tài khoản AWS | Có quyền tạo tài nguyên S3, CloudFront, Lambda, API Gateway, DynamoDB, IAM, Personalize |
| Region | `ap-southeast-1` (Singapore) --- workshop này dùng xuyên suốt một region |
| Node.js | Phiên bản 20 trở lên, để build giao diện |
| AWS CLI | Phiên bản 2, đã chạy `aws configure`. Hoặc dùng AWS CloudShell ngay trên console |
| Kiến thức nền | Biết dùng terminal, hiểu khái niệm HTTP request và JSON |

{{% notice warning %}}
Amazon Personalize campaign **tính phí theo giờ hoạt động**, không phụ thuộc số lượng truy vấn. Đây là tài nguyên tốn tiền nhất trong workshop. Hãy làm liên tục và xoá campaign ngay sau khi hoàn thành. Xem mục [Dọn dẹp tài nguyên](../5.9-Cleanup/).
{{% /notice %}}

#### Ước tính chi phí

Nếu hoàn thành workshop trong một ngày rồi dọn dẹp ngay, chi phí phát sinh ở mức rất thấp. Phần lớn nằm trong hạn mức miễn phí:

- S3, CloudFront, Lambda, API Gateway, DynamoDB on-demand: gần như miễn phí ở quy mô này
- Personalize: tính phí cho thời gian huấn luyện và thời gian campaign tồn tại

#### Kiểm tra môi trường

Mở terminal và chạy các lệnh sau để xác nhận công cụ đã sẵn sàng:

```bash
aws --version
node --version
aws sts get-caller-identity
```

Lệnh cuối trả về Account ID và ARN của danh tính đang dùng. Nếu báo lỗi, chạy lại `aws configure`.

Đặt region mặc định để không phải khai báo lại ở mỗi lệnh:

```bash
export AWS_DEFAULT_REGION=ap-southeast-1
```

#### Chuẩn bị mã nguồn

Tải mã nguồn của dự án. Cấu trúc gồm hai thư mục chính:

```
backend/    Logic API, sẽ đưa lên Lambda
frontend/   Giao diện React, sẽ build ra file tĩnh
```
