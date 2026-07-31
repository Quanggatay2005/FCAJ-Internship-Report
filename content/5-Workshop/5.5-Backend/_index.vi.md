---
title : "Triển khai lớp API"
date : 2026-07-28
weight : 5
chapter : false
pre : " <b> 5.5 </b> "
---

Phần này tạo bộ não của hệ thống: một hàm Lambda xử lý toàn bộ nghiệp vụ, và một API Gateway làm cửa vào.

{{% notice info %}}
**Lưu ý bảo mật (Auth):** Trong phạm vi workshop này, logic băm mật khẩu và quản lý người dùng được lập trình trực tiếp trong API để bạn dễ hình dung luồng dữ liệu. Trên môi trường Production thực tế, bạn nên ủy quyền toàn bộ chức năng này cho **Amazon Cognito** để đảm bảo tiêu chuẩn bảo mật.
{{% /notice %}}

Thứ tự làm quan trọng: **IAM role trước, Lambda sau, API Gateway cuối**. Vì Lambda cần role lúc tạo, và API Gateway cần Lambda đã tồn tại.

#### Bước 1. Tạo IAM role theo nguyên tắc quyền tối thiểu

Lambda cần quyền đọc ghi DynamoDB và gọi Personalize. Cách nhanh nhất là gán `AdministratorAccess`, nhưng đó là thói quen xấu: nếu mã nguồn có lỗ hổng, kẻ tấn công chiếm được toàn bộ tài khoản.

Ta chỉ cấp đúng thứ cần.

1. Mở [IAM console](https://console.aws.amazon.com/iam/home#/roles), chọn **Roles** rồi **Create role**
2. **Trusted entity type**: AWS service. **Use case**: Lambda. Chọn **Next**
3. Tìm và chọn `AWSLambdaBasicExecutionRole` --- quyền ghi log vào CloudWatch
4. Chọn **Next**, đặt tên `fcj-recsys-lambda-role`, chọn **Create role**

Giờ thêm quyền riêng cho DynamoDB và Personalize:

5. Mở role vừa tạo, chọn **Add permissions** rồi **Create inline policy**
6. Chuyển sang tab **JSON**, dán nội dung sau (thay `<ACCOUNT-ID>` bằng số tài khoản của bạn):

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

7. Đặt tên policy `fcj-recsys-lambda-policy`, chọn **Create policy**

{{% notice tip %}}
Lấy Account ID bằng lệnh `aws sts get-caller-identity --query Account --output text`
{{% /notice %}}

#### Bước 2. Đóng gói mã nguồn

Lambda cần một file zip chứa mã nguồn và thư viện phụ thuộc:

```bash
cd backend
npm install --production
zip -r ../function.zip index.mjs node_modules
```

#### Bước 3. Tạo hàm Lambda

1. Mở [Lambda console](https://ap-southeast-1.console.aws.amazon.com/lambda/home?region=ap-southeast-1)
2. Chọn **Create function**
3. Điền:
   - **Function name**: `fcj-recsys-api`
   - **Runtime**: **Node.js 20.x**
   - **Architecture**: x86_64
   - **Execution role**: chọn **Use an existing role**, chọn `fcj-recsys-lambda-role`
4. Chọn **Create function**
5. Ở tab **Code**, chọn **Upload from** rồi **.zip file**, tải `function.zip` lên
6. Vào **Runtime settings**, chọn **Edit**, đặt **Handler** thành `index.handler`

![Tạo Lambda](/images/5-Workshop/5.5/create-lambda.png)

#### Bước 4. Tăng timeout

Mặc định Lambda dừng sau 3 giây, không đủ khi phải gọi Personalize.

1. Mở tab **Configuration**, chọn **General configuration**, chọn **Edit**
2. Đặt **Timeout** là `30` giây, **Memory** là `512` MB
3. Chọn **Save**

#### Bước 5. Tạo HTTP API

1. Mở [API Gateway console](https://ap-southeast-1.console.aws.amazon.com/apigateway/main/apis?region=ap-southeast-1)
2. Ở ô **HTTP API**, chọn **Build**
3. Chọn **Add integration**, kiểu **Lambda**, chọn hàm `fcj-recsys-api`
4. **API name**: `fcj-recsys-api`, chọn **Next**
5. Ở phần **Configure routes**, khai báo một route bắt tất cả:
   - **Method**: `ANY`
   - **Resource path**: `/{proxy+}`
   - **Integration target**: hàm Lambda vừa chọn
6. Chọn **Next**, giữ stage `$default` với **Auto-deploy** bật, chọn **Create**

{{% notice note %}}
Route `/{proxy+}` chuyển mọi đường dẫn về cùng một Lambda, để mã nguồn tự định tuyến bên trong. Cách này giữ cấu hình API Gateway đơn giản, đổi lại việc định tuyến nằm trong mã. Với 22 route thì đây là đánh đổi hợp lý.
{{% /notice %}}

#### Bước 6. Bật CORS

Giao diện chạy trên tên miền CloudFront, API nằm ở tên miền khác. Trình duyệt sẽ chặn nếu không khai báo CORS.

1. Trong API vừa tạo, chọn **CORS** ở menu bên trái, chọn **Configure**
2. Khai báo:
   - **Access-Control-Allow-Origin**: `*`
   - **Access-Control-Allow-Headers**: `content-type, authorization`
   - **Access-Control-Allow-Methods**: `GET, POST, PUT, DELETE, OPTIONS`
3. Chọn **Save**

{{% notice warning %}}
Lỗi CORS chỉ hiện trong console trình duyệt, còn thử bằng `curl` thì vẫn chạy bình thường. Nếu giao diện báo không kết nối được máy chủ trong khi `curl` vẫn ổn, hãy bấm F12 xem tab Console trước tiên.
{{% /notice %}}

#### Bước 7. Nối giao diện với API

Copy **Invoke URL** ở trang chi tiết API, rồi quay lại thư mục giao diện:

```bash
cd frontend
echo "VITE_API_BASE_URL=https://xxxxx.execute-api.ap-southeast-1.amazonaws.com" > .env
npm run build
aws s3 sync dist/ s3://fcj-recsys-frontend-<tên-bạn>/ --delete
aws cloudfront create-invalidation --distribution-id <ID-CUA-BAN> --paths "/*"
```

#### Kiểm tra

```bash
curl https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/products
```

Trả về danh sách sản phẩm dạng JSON là thành công. Mở lại trang CloudFront, sản phẩm phải hiển thị.
