---
title : "Kiểm thử toàn luồng"
date : 2026-07-28
weight : 8
chapter : false
pre : " <b> 5.8 </b> "
---

Từng thành phần chạy được không đảm bảo cả hệ thống chạy được. Phần này kiểm tra toàn luồng từ trình duyệt tới mô hình.

#### Bước 1. Kiểm tra từng lớp bằng CLI

Đi từ trong ra ngoài, lớp nào lỗi thì dừng ở đó mà sửa.

```bash
# Lớp dữ liệu
aws dynamodb scan --table-name Products --select COUNT

# Lớp API
curl https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/products

# Lớp học máy
aws personalize-runtime get-recommendations \
  --campaign-arn <CAMPAIGN-ARN> --user-id user-001 --num-results 5

# Lớp gợi ý qua API
curl "https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/recommendations?userId=user-001"
```

#### Bước 2. Kiểm tra gợi ý thực sự cá nhân hoá

Đây là phép thử quan trọng nhất của cả hệ thống. Gọi với hai người dùng khác nhau:

```bash
curl "https://.../recommendations?userId=user-001"
curl "https://.../recommendations?userId=user-150"
```

Hai kết quả **phải khác nhau**. Nếu giống hệt, nghĩa là mô hình không cá nhân hoá mà chỉ trả về danh sách phổ biến chung.

#### Bước 3. Kiểm tra thứ tự gợi ý được giữ nguyên

Đây là lỗi tinh vi, không sinh ra thông báo lỗi nào.

Personalize trả về danh sách đã xếp hạng. Lambda sau đó truy vấn DynamoDB để lấy thông tin đầy đủ của từng sản phẩm. Vấn đề: **DynamoDB không đảm bảo trả về theo đúng thứ tự khoá được truyền vào**.

Nếu mã nguồn không sắp xếp lại, thứ hạng do mô hình tính toán sẽ bị mất, và sản phẩm phù hợp nhất có thể rơi xuống cuối danh sách.

Cách kiểm tra: so sánh thứ tự `itemId` từ lệnh `get-recommendations` với thứ tự sản phẩm mà API trả về. Hai thứ tự phải trùng khớp.

#### Bước 4. Kiểm tra trên trình duyệt

1. Mở địa chỉ CloudFront
2. Đăng ký một tài khoản mới
3. Duyệt vài sản phẩm, thêm vào giỏ
4. Đặt hàng
5. Vào trang tài khoản xem đơn vừa đặt
6. Về trang chủ, kiểm tra khối gợi ý có hiển thị không

Bấm **F12** mở Developer Tools, xem tab **Network** để chắc chắn các lời gọi API trả về mã 200. Nếu thấy lỗi CORS ở tab Console, quay lại mục 5.5 kiểm tra cấu hình.

#### Bước 5. Kiểm tra bảo mật giá đặt hàng

Máy chủ phải tự tính lại tổng tiền, không tin số liệu do trình duyệt gửi lên. Thử gửi một đơn hàng với giá bị sửa:

```bash
curl -X POST https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: <TOKEN-CUA-BAN>" \
  -d '{"items":[{"productId":"prod-001","quantity":1,"price":1}]}'
```

Đơn tạo ra phải mang **giá thật** lấy từ DynamoDB, không phải giá 1 đồng gửi lên. Nếu đơn ghi nhận giá 1 đồng thì hệ thống có lỗ hổng nghiêm trọng.

#### Bảng kiểm cuối

| Hạng mục | Kết quả mong đợi |
|---|---|
| Trang chủ tải được qua CloudFront | Hiển thị đầy đủ giao diện |
| Truy cập thẳng bucket S3 | Bị từ chối, mã 403 |
| API trả về danh sách sản phẩm | JSON có 100 sản phẩm |
| Gợi ý cho hai người dùng khác nhau | Hai danh sách khác nhau |
| Thứ tự gợi ý | Trùng với thứ tự Personalize trả về |
| Đặt hàng với giá bị sửa | Máy chủ dùng giá thật |
| Mở thẳng đường dẫn con như `/cart` | Trang tải được, không lỗi 403 |
| CloudWatch log | Có bản ghi cho mỗi lần gọi |
