---
title : "Tổng quan và kiến trúc"
date : 2026-07-28
weight : 1
chapter : false
pre : " <b> 5.1 </b> "
---

#### Bài toán

Một sàn thương mại điện tử có hàng nghìn sản phẩm, trong khi mỗi người dùng chỉ đủ kiên nhẫn duyệt vài chục. Sắp xếp sản phẩm theo lượt bán hay ngày đăng khiến phần lớn kho hàng không bao giờ được nhìn thấy, đồng thời người dùng phải tự tìm thứ mình cần.

Hệ thống trong workshop này giải quyết bằng cách học từ hành vi thực tế của người dùng để đề xuất sản phẩm riêng cho từng người.

#### Kiến trúc

![Kiến trúc tổng thể](/images/5-Workshop/architecture.png)

Hệ thống chia thành hai nhánh xử lý độc lập:

**Nhánh phục vụ giao diện.** Người dùng truy cập tên miền CloudFront, CloudFront trả về các file HTML, CSS, JavaScript đã build sẵn và lưu trong bucket S3. Vì là nội dung tĩnh nên có thể lưu đệm tại các điểm biên gần người dùng, giảm độ trễ và gần như không phát sinh chi phí tính toán.

**Nhánh xử lý dữ liệu.** Giao diện gọi tới API Gateway, API Gateway kích hoạt hàm Lambda. Tuỳ theo đường dẫn, Lambda truy vấn DynamoDB để lấy dữ liệu nghiệp vụ, hoặc gọi Amazon Personalize để lấy danh sách gợi ý.

#### Vì sao chọn những dịch vụ này

**Serverless thay vì máy chủ truyền thống.** Lưu lượng của một dự án thực tập thấp và không đều. Với EC2 hoặc ECS, bạn trả tiền theo giờ kể cả khi không ai truy cập. Với Lambda, khi không có request thì chi phí bằng không.

**DynamoDB thay vì RDS.** RDS tính phí theo giờ instance ngay cả lúc nhàn rỗi. DynamoDB ở chế độ on-demand chỉ tính theo số lần đọc ghi thực tế. Với dữ liệu dạng khoá và mẫu truy vấn đơn giản, DynamoDB là lựa chọn hợp lý hơn.

**Amazon Personalize thay vì tự huấn luyện trên SageMaker.** Tự cài đặt thuật toán gợi ý đòi hỏi kiến thức sâu và nhiều thời gian tinh chỉnh. Personalize đóng gói sẵn các thuật toán mà Amazon dùng trong sản phẩm của chính họ, cho phép tập trung vào chất lượng dữ liệu thay vì cài đặt mô hình.

**CloudFront trước S3.** Ngoài việc tăng tốc, CloudFront cho phép giữ bucket ở chế độ riêng tư hoàn toàn và cung cấp HTTPS miễn phí.

#### Nguyên tắc thiết kế xuyên suốt

- **Không tin dữ liệu từ trình duyệt.** Máy chủ luôn tự truy vấn giá và tính lại tổng tiền, không dùng số liệu do giao diện gửi lên.
- **Quyền tối thiểu.** Mỗi thành phần chỉ được cấp đúng quyền cần thiết trên đúng tài nguyên cần thiết.
- **Không hard-code khoá truy cập.** Lambda dùng execution role, không nhúng access key vào mã nguồn.
