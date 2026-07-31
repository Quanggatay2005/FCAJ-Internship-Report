---
title : "Giám sát và cảnh báo"
date : 2026-07-28
weight : 7
chapter : false
pre : " <b> 5.7 </b> "
---

Hệ thống chạy được không có nghĩa là xong. Nếu Lambda bắt đầu lỗi lúc 2 giờ sáng, bạn cần biết trước khi người dùng phàn nàn.

#### Bước 1. Xem log

Lambda tự động ghi log vào CloudWatch nhờ policy `AWSLambdaBasicExecutionRole` đã gán ở mục 5.5.

1. Mở [CloudWatch console](https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1)
2. Chọn **Log groups**, tìm `/aws/lambda/fcj-recsys-api`
3. Mở log stream mới nhất

Đây là nơi đầu tiên cần nhìn mỗi khi API trả về lỗi 500. Thông báo lỗi trả về cho người dùng thường bị rút gọn, còn stack trace đầy đủ nằm ở đây.

#### Bước 2. Tạo SNS topic nhận thông báo

```bash
aws sns create-topic --name fcj-recsys-alerts
```

Đăng ký email nhận cảnh báo:

```bash
aws sns subscribe \
  --topic-arn <TOPIC-ARN> \
  --protocol email \
  --notification-endpoint email-cua-ban@example.com
```

Mở hộp thư và bấm xác nhận đăng ký.

#### Bước 3. Tạo alarm cho tỉ lệ lỗi

1. Mở [CloudWatch console](https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1), chọn **Alarms** rồi **Create alarm**
2. Chọn **Select metric**, vào **Lambda** rồi **By Function Name**
3. Tìm hàm `fcj-recsys-api`, chọn metric **Errors**, chọn **Select metric**
4. Ở phần **Conditions**:
   - **Statistic**: Sum
   - **Period**: 5 minutes
   - **Threshold type**: Static
   - **Whenever Errors is**: Greater than `5`
5. Chọn **Next**, ở phần thông báo chọn topic `fcj-recsys-alerts`
6. Đặt tên alarm `fcj-lambda-errors`, chọn **Create alarm**

![Tạo alarm](/images/5-Workshop/5.7/create-alarm.png)

#### Bước 4. Tạo alarm cho độ trễ

Lặp lại các bước trên nhưng chọn metric **Duration**, thống kê **Average**, ngưỡng lớn hơn `3000` mili giây. Đặt tên `fcj-lambda-latency`.

Độ trễ tăng thường là dấu hiệu sớm hơn lỗi. Khi Lambda chạy chậm dần, thường là do truy vấn DynamoDB không hiệu quả hoặc Personalize phản hồi chậm.

#### Bước 5. Đặt cảnh báo chi phí

Đây là thứ nhiều người bỏ qua và phải trả giá.

1. Mở [Billing console](https://console.aws.amazon.com/billing/home#/budgets)
2. Chọn **Budgets** rồi **Create budget**
3. Chọn **Cost budget**, đặt ngưỡng phù hợp, ví dụ 10 USD mỗi tháng
4. Thêm cảnh báo khi đạt 80 phần trăm ngưỡng, điền email của bạn

{{% notice tip %}}
Personalize campaign tính phí theo giờ tồn tại. Nếu quên xoá sau khi hoàn thành, chi phí tích luỹ âm thầm. Cảnh báo ngân sách là lưới an toàn cho tình huống đó.
{{% /notice %}}

#### Kiểm tra alarm hoạt động

Gọi thử một đường dẫn không tồn tại nhiều lần để sinh lỗi:

```bash
for i in {1..10}; do
  curl -s https://xxxxx.execute-api.ap-southeast-1.amazonaws.com/khong-ton-tai > /dev/null
done
```

Sau vài phút, alarm phải chuyển sang trạng thái **In alarm** và bạn nhận được email.
