---
title : "Triển khai lớp giao diện"
date : 2026-07-28
weight : 3
chapter : false
pre : " <b> 5.3 </b> "
---

Trong phần này bạn tạo nơi lưu và nơi phân phối giao diện web. Bucket S3 giữ file, CloudFront đưa file đó tới người dùng.

Điểm cần chú ý: bucket sẽ được để **riêng tư hoàn toàn**. Người dùng không truy cập thẳng vào S3 mà chỉ đi qua CloudFront. Cơ chế cho phép điều này gọi là **Origin Access Control**.

#### Bước 1. Tạo bucket lưu giao diện

1. Mở [Amazon S3 console](https://s3.console.aws.amazon.com/s3/home?region=ap-southeast-1)
2. Chọn **Create bucket**
3. Điền thông tin:
   - **Bucket name**: `fcj-recsys-frontend-<tên-bạn>` (tên bucket là duy nhất toàn cầu, thêm hậu tố để tránh trùng)
   - **AWS Region**: Asia Pacific (Singapore) `ap-southeast-1`
   - **Block Public Access**: **giữ nguyên bật tất cả**
4. Chọn **Create bucket**

![Tạo bucket](/images/5-Workshop/5.3/create-bucket.png)

{{% notice note %}}
Nhiều hướng dẫn cũ bảo bật Static website hosting và mở public cho bucket. Cách đó không còn được khuyến nghị vì lộ bucket ra Internet. Ở workshop này ta giữ bucket kín và để CloudFront làm cửa duy nhất.
{{% /notice %}}

#### Bước 2. Build giao diện

Tại máy của bạn, vào thư mục `frontend` và build:

```bash
cd frontend
npm install
npm run build
```

Lệnh này tạo ra thư mục `dist` chứa toàn bộ file tĩnh.

{{% notice tip %}}
Chưa cần lo địa chỉ API lúc này. Sau khi tạo xong API Gateway ở mục 5.5, bạn sẽ quay lại đặt biến `VITE_API_BASE_URL` rồi build lại.
{{% /notice %}}

#### Bước 3. Tải file lên S3

```bash
aws s3 sync dist/ s3://fcj-recsys-frontend-<tên-bạn>/ --delete
```

Tham số `--delete` xoá những file cũ không còn trong bản build mới, tránh để lại rác qua nhiều lần deploy.

Kiểm tra lại trên console, bucket phải có `index.html` cùng thư mục `assets`.

#### Bước 4. Tạo CloudFront distribution

1. Mở [CloudFront console](https://console.aws.amazon.com/cloudfront/v4/home)
2. Chọn **Create distribution**
3. Ở phần **Origin**:
   - **Origin domain**: chọn bucket vừa tạo từ danh sách
   - **Origin access**: chọn **Origin access control settings (recommended)**
   - Chọn **Create new OAC**, giữ nguyên tuỳ chọn mặc định, bấm **Create**
4. Ở phần **Default cache behavior**:
   - **Viewer protocol policy**: **Redirect HTTP to HTTPS**
   - **Allowed HTTP methods**: `GET, HEAD`
5. Ở phần **Settings**:
   - **Default root object**: `index.html`
6. Chọn **Create distribution**

![Tạo distribution](/images/5-Workshop/5.3/create-distribution.png)

{{% notice tip %}}
**Bảo mật nâng cao:** Ở bước tạo CloudFront này, bạn có thể áp dụng thêm **AWS WAF** (Web Application Firewall) để chặn Botnet và các cuộc tấn công DDoS vào giao diện web của bạn.
{{% /notice %}}

#### Bước 5. Cấp quyền cho CloudFront đọc bucket

Sau khi tạo xong, CloudFront hiện một banner nhắc cập nhật bucket policy. Chọn **Copy policy**, rồi:

1. Sang [S3 console](https://s3.console.aws.amazon.com/s3/home?region=ap-southeast-1), mở bucket
2. Vào tab **Permissions**
3. Ở mục **Bucket policy**, chọn **Edit**, dán policy vừa copy, chọn **Save changes**

Policy này chỉ cho phép đúng distribution vừa tạo đọc bucket, không mở cho ai khác.

#### Bước 6. Xử lý lỗi 403 với ứng dụng một trang

Giao diện React dùng định tuyến phía client. Khi người dùng mở thẳng `/cart`, CloudFront đi tìm file tên `cart` trong S3, không thấy nên trả về lỗi. Cần chuyển các lỗi đó về `index.html`.

1. Trong distribution, mở tab **Error pages**
2. Chọn **Create custom error response**, khai báo:
   - **HTTP error code**: `403 Forbidden`
   - **Customize error response**: Yes
   - **Response page path**: `/index.html`
   - **HTTP Response code**: `200 OK`
3. Lặp lại một lần nữa cho mã lỗi `404 Not Found`

#### Kiểm tra

Chờ khoảng 5 phút cho distribution chuyển sang trạng thái **Deployed**, sau đó mở địa chỉ ở cột **Distribution domain name**, dạng `dxxxxxxxxx.cloudfront.net`.

Giao diện phải hiển thị được. Phần dữ liệu sản phẩm chưa có vì API chưa tạo, điều đó bình thường.

{{% notice warning %}}
**Ghi nhớ điều này, nó sẽ tiết kiệm cho bạn hàng giờ.** Mỗi lần tải bản build mới lên S3, bạn **bắt buộc** phải tạo invalidation, nếu không CloudFront vẫn phục vụ bản cũ trong bộ nhớ đệm và bạn sẽ tưởng mã nguồn bị lỗi.

```bash
aws cloudfront create-invalidation --distribution-id <ID-CUA-BAN> --paths "/*"
```
{{% /notice %}}
