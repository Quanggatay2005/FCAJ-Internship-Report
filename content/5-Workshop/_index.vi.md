---
title : "Workshop"
date : 2026-07-28
weight : 5
chapter : false
pre : " <b> 5. </b> "
---

# Xây dựng hệ gợi ý sản phẩm thương mại điện tử không máy chủ trên AWS

#### Tổng quan

Trong workshop này, bạn sẽ xây dựng một website thương mại điện tử hoàn chỉnh có tích hợp hệ thống gợi ý sản phẩm cá nhân hoá, triển khai toàn bộ theo kiến trúc **serverless** trên AWS.

Điểm khác biệt của hệ thống này so với một website bán hàng thông thường là mỗi người dùng đăng nhập sẽ nhìn thấy một danh sách sản phẩm gợi ý khác nhau, sinh ra từ mô hình học máy của **Amazon Personalize** dựa trên hành vi duyệt và mua hàng, thay vì sắp xếp cứng theo lượt bán.

Sau khi hoàn thành, bạn sẽ có một hệ thống chạy thật trên Internet với chi phí gần như bằng không khi không có lưu lượng truy cập.

#### Bạn sẽ học được gì

- Thiết kế kiến trúc serverless tách biệt luồng nội dung tĩnh và luồng dữ liệu động
- Cấu hình CloudFront với Origin Access Control để bảo vệ bucket S3 khỏi truy cập trực tiếp
- Thiết kế bảng DynamoDB theo mẫu truy vấn, dùng khoá tổ hợp để tránh Scan toàn bảng
- Áp dụng nguyên tắc quyền tối thiểu khi tạo IAM role
- Huấn luyện và triển khai mô hình gợi ý bằng Amazon Personalize
- Thiết lập cảnh báo bằng CloudWatch Alarm
- Dọn dẹp tài nguyên đúng cách để tránh phát sinh chi phí

#### Dịch vụ AWS sử dụng

| Dịch vụ | Vai trò trong hệ thống |
|---|---|
| Amazon S3 | Lưu file tĩnh của giao diện và bộ dữ liệu huấn luyện |
| Amazon CloudFront | Phân phối giao diện từ điểm biên, cung cấp HTTPS |
| Amazon API Gateway | Cổng vào cho toàn bộ lời gọi API |
| AWS Lambda | Xử lý logic nghiệp vụ |
| Amazon DynamoDB | Lưu dữ liệu sản phẩm, người dùng, đơn hàng |
| Amazon Personalize | Huấn luyện và phục vụ mô hình gợi ý |
| AWS IAM | Phân quyền giữa các dịch vụ |
| Amazon CloudWatch | Ghi log và cảnh báo |

#### Nội dung

1. [Tổng quan và kiến trúc](5.1-Overview/)
2. [Chuẩn bị](5.2-Prerequisite/)
3. [Triển khai lớp giao diện](5.3-Frontend/)
4. [Tạo cơ sở dữ liệu](5.4-Database/)
5. [Triển khai lớp API](5.5-Backend/)
6. [Xây dựng hệ gợi ý](5.6-Personalize/)
7. [Giám sát và cảnh báo](5.7-Monitoring/)
8. [Kiểm thử toàn luồng](5.8-Testing/)
9. [Dọn dẹp tài nguyên](5.9-Cleanup/)
