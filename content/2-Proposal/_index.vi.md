---
title: "Bản đề xuất"
date: 2024-01-01
weight: 2
chapter: false
pre: " <b> 2. </b> "
---

# Hệ gợi ý sản phẩm thương mại điện tử trên AWS

## Website Thương mại điện tử Tích hợp Gợi ý Cá nhân hóa và Tìm kiếm bằng Hình ảnh trên AWS

### 1. Tóm tắt điều hành

Dự án **Hệ gợi ý sản phẩm thương mại điện tử trên AWS** được thực hiện trong khuôn khổ đồ án môn **Machine Learning trên AWS**. Mục tiêu của dự án là xây dựng và triển khai một trang web thương mại điện tử hoàn chỉnh, tích hợp hệ thống gợi ý sản phẩm cá nhân hóa và tính năng tìm kiếm bằng hình ảnh. Nền tảng tận dụng các dịch vụ AWS Serverless (API Gateway, AWS Lambda, DynamoDB, S3, CloudFront) kết hợp với Amazon Personalize và mô hình CLIP để mang lại trải nghiệm mua sắm tối ưu và hiện đại.

### 2. Tuyên bố vấn đề

_Vấn đề hiện tại_  
Các website thương mại điện tử truyền thống thường thiếu khả năng cá nhân hóa trải nghiệm theo thời gian thực, dẫn đến tỷ lệ chuyển đổi và độ tương tác của người dùng chưa cao. Bên cạnh đó, việc tìm kiếm sản phẩm bằng từ khóa văn bản bị hạn chế khi người dùng chỉ có hình ảnh sản phẩm. Chi phí vận hành hạ tầng máy chủ truyền thống cũng là một rào cản lớn khi hệ thống cần mở rộng quy mô.

_Giải pháp_  
Hệ thống giải quyết các vấn đề trên bằng cách triển khai giải pháp e-commerce hoàn chỉnh trên hạ tầng Serverless của AWS:

- **Gợi ý cá nhân hóa:** Tận dụng Amazon Personalize (recipe `aws-user-personalization`) để hiển thị khối "Gợi ý riêng cho bạn" ngay tại trang chủ.
- **Tìm kiếm bằng hình ảnh:** Sử dụng mô hình CLIP (`@xenova/transformers`) kết hợp đo độ tương đồng Cosine (Cosine Similarity).
- **Nghiệp vụ Mua sắm Toàn diện:** Duyệt/tìm kiếm/lọc sản phẩm, quản lý tài khoản/phiên làm việc, giỏ hàng, mã giảm giá, đặt hàng (COD / Chuyển khoản) và đánh giá sản phẩm.
- **Kiến trúc Serverless:** Giao diện React (Vite) lưu trữ trên S3 và phân phối qua CloudFront, API Node.js 20 chạy trên AWS Lambda qua API Gateway, cơ sở dữ liệu DynamoDB (8 bảng) hoạt động theo chế độ On-demand.

_Lợi ích và hoàn vốn đầu tư (ROI)_

- **Tăng tỷ lệ chuyển đổi:** Gợi ý sản phẩm chính xác dựa trên hành vi giúp tăng giá trị đơn hàng và độ hài lòng của khách hàng.
- **Tối ưu chi phí hạ tầng:** Mô hình Serverless giúp chỉ trả tiền theo lượng truy cập thực tế, loại bỏ chi phí duy trì máy chủ rảnh rỗi.
- **Khả năng mở rộng cao:** DynamoDB On-demand và Lambda tự động co giãn theo tải mà không cần quản trị hạ tầng thủ công.

### 3. Kiến trúc giải pháp

Nền tảng sử dụng kiến trúc Serverless trên AWS để xử lý toàn bộ luồng nghiệp vụ và gợi ý AI:

![Mô tả hình ảnh](/images/5-Workshop/architecture.png)

_Dịch vụ AWS & Công nghệ sử dụng_

- **AWS CloudFront & Amazon S3:** Lưu trữ giao diện tĩnh React 18 (Vite, Redux Toolkit, Tailwind) và phân phối tại biên.
- **Amazon API Gateway:** HTTP API quản lý 22 routes chuyển tiếp tới AWS Lambda.
- **AWS Lambda:** Hàm `fcj-api` (Node.js 20) xử lý toàn bộ logic API và kết nối cơ sở dữ liệu.
- **Amazon DynamoDB:** 8 bảng dữ liệu (`Products`, `Categories`, `Users`, `Sessions`, `Carts`, `Vouchers`, `Reviews`, `Orders`) ở chế độ On-demand.
- **Amazon Personalize:** Sử dụng recipe `aws-user-personalization` cung cấp danh sách gợi ý theo Campaign ARN.
- **Tìm kiếm bằng hình ảnh:** CLIP (`@xenova/transformers`) + Cosine Similarity (chạy ở máy local).

_Thiết kế thành phần_

- **Frontend:** Code build được tải lên S3 bucket riêng tư, chỉ CloudFront được phép truy cập qua OAC.
- **Backend API:** Lambda tiếp nhận 22 endpoint nghiệp vụ, băm mật khẩu người dùng bằng `scrypt` và so sánh an toàn bằng `timingSafeEqual`.
- **Hệ gợi ý:** Lambda gọi API tới Personalize Campaign để lấy danh sách gợi ý riêng cho từng người dùng đã đăng nhập.
- **Tìm kiếm hình ảnh:** Tạo vector từ ảnh sản phẩm lưu tại `vector-cache.json`, so sánh vector đường dẫn ảnh đầu vào để trả về sản phẩm tương đồng.

### 4. Triển khai kỹ thuật

_Các giai đoạn triển khai_

1. **Khởi tạo Hạ tầng & Database:** Thiết kế schema cho 8 bảng DynamoDB, cấu hình IAM Role, S3, CloudFront và API Gateway.
2. **Phát triển Backend & Frontend:** Viết 22 route API trong `backend/index.mjs`, dựng giao diện React và kết nối Redux Toolkit với API thật.
3. **Tích hợp ML & AI:** Xây dựng pipeline dữ liệu (`ml_recommendation_dataset.csv`), huấn luyện mô hình Amazon Personalize và cài đặt CLIP visual search.
4. **Kiểm thử & Triển khai:** Viết kịch bản kiểm thử tự động Playwright (luồng đặt hàng), deploy Lambda & CloudFront, đánh giá chỉ số mô hình.

_Yêu cầu kỹ thuật_

- **Môi trường:** Node.js 20 trở lên, AWS CLI / IAM User được cấp đúng quyền trên 8 bảng DynamoDB và Personalize Campaign.
- **Bảo mật:** Không commit file `.env` chứa Access Key lên Git; phân quyền IAM theo nguyên tắc tối thiểu; băm mật khẩu người dùng bằng `scrypt`.

### 5. Lộ trình & Mốc triển khai

- **Giai đoạn 1: Lập kế hoạch & Xây dựng dữ liệu**
  - Thiết kế kiến trúc AWS và bảng cơ sở dữ liệu.
  - Sinh bộ dữ liệu tương tác mô phỏng hành vi mua sắm (phễu chuyển đổi, quy luật power-law).
- **Giai đoạn 2: Phát triển Core E-Commerce**
  - Hoàn thiện 22 route API trên Lambda.
  - Xây dựng giao diện frontend (Trang chủ, Chi tiết sản phẩm, Giỏ hàng, Thanh toán, Tài khoản).
- **Giai đoạn 3: Tích hợp Machine Learning**
  - Huấn luyện và tạo Campaign trên Amazon Personalize.
  - Tích hợp tính năng tìm kiếm bằng hình ảnh CLIP.
- **Giai đoạn 4: Kiểm thử & Triển khai**
  - Viết kịch bản Playwright test tự động luồng checkout.
  - Deploy backend lên Lambda và frontend lên S3/CloudFront.

### 6. Ước tính ngân sách & Chỉ số Mô hình

**Ước tính chi phí AWS hàng tháng (Quy mô lưu lượng thấp / Đồ án môn học)**

| Dịch vụ AWS                                  | Giả định mức sử dụng                            | Chi phí ước tính (USD/tháng) |
| -------------------------------------------- | ----------------------------------------------- | ---------------------------- |
| **AWS Lambda** (`fcj-api`)                   | ~1 triệu lượt gọi, 512MB, ~200ms trung bình     | $0.20 – $1.00                |
| **API Gateway (HTTP API)**                   | ~1 triệu request                                | ~$1.00                       |
| **Amazon DynamoDB** (8 bảng, On-demand)      | ~1 triệu request unit đọc/ghi                   | $5 – $10                     |
| **Amazon S3** (lưu trữ frontend)             | ~5 GB dung lượng + request PUT/GET              | ~$0.15                       |
| **Amazon CloudFront**                        | ~50 GB dữ liệu truyền tải ra                    | ~$4.25                       |
| **Amazon Personalize (Campaign)**            | 1 campaign, TPS tối thiểu, chạy 24/7 (~730 giờ) | **$150 – $220**              |
| **Amazon Personalize (Huấn luyện Solution)** | Huấn luyện lại định kỳ (~2–4 giờ/lần)           | ~$0.50 – $1.00 mỗi lần       |
| **CloudWatch Logs & Monitoring**             | Gói ghi log cơ bản                              | ~$1.00                       |
| **Tổng cộng (ổn định, hàng tháng)**          |                                                 | **≈ $160 – $240 / tháng**    |

> **Lưu ý:** Amazon Personalize Campaign chạy liên tục là yếu tố chi phí lớn nhất, do tính phí theo TPS tối thiểu mỗi giờ bất kể lưu lượng truy cập thực tế. Đối với đồ án môn học/demo, có thể giảm đáng kể chi phí này bằng cách xóa Campaign khi không sử dụng để demo, hoặc chỉ tạo lại trong giai đoạn đánh giá/kiểm thử. Chi phí Lambda, API Gateway, DynamoDB, S3 và CloudFront ở mức tối thiểu tại quy mô lưu lượng này nhờ mô hình tính phí Serverless theo mức sử dụng thực tế.

_Đánh giá Bộ dữ liệu Huấn luyện (v1 vs v2)_
Bộ dữ liệu tương tác được sinh mô phỏng theo hành vi mua sắm thực tế mang lại kết quả cải thiện vượt trội:

| Chỉ số          | Dữ liệu v1 | Dữ liệu v2 |
| --------------- | ---------- | ---------- |
| **Precision@5** | 0.0889     | 0.4348     |
| **NDCG@10**     | 0.1799     | 0.6512     |
| **MRR@25**      | 0.1216     | 0.7130     |
| **Coverage**    | 0.8218     | 0.9505     |

_Kết luận:_ Chất lượng dữ liệu đầu vào đóng vai trò quyết định đến hiệu năng mô hình hơn việc thay đổi thuật toán.

### 7. Đánh giá rủi ro

_Ma trận rủi ro_

- **Vòng lặp dữ liệu chưa khép kín:** Ảnh hưởng cao, xác suất trung bình (Tương tác thực của người dùng chưa được ghi ngược lại tự động để retraining định kỳ).
- **Giới hạn kích thước Lambda:** Ảnh hưởng trung bình, xác suất cao (Model CLIP nặng vài trăm MB không thể deploy trực tiếp lên Lambda, phải chạy local).
- **Cache CloudFront bị cũ:** Ảnh hưởng thấp, xác suất cao (Cần invalidate cache `/*` sau mỗi lần upload frontend mới lên S3).
- **Truy vấn dữ liệu phức tạp (Database Bottleneck):** Ảnh hưởng trung bình, xác suất cao (DynamoDB không tối ưu cho việc tìm kiếm văn bản tự do (full-text search) và lọc sản phẩm theo nhiều tiêu chí).

_Chiến lược giảm thiểu_

- **Dữ liệu:** Nghiên cứu tích hợp AWS EventBridge / Kinesis để ghi log tương tác phục vụ retrain tự động.
- **Model nặng:** Hướng tới sử dụng AWS Fargate hoặc Amazon SageMaker Endpoint cho mô hình tìm kiếm hình ảnh.
- **Deploy:** Tự động hóa lệnh invalidate CloudFront trong script deploy.
- **Truy vấn:** Kết hợp Amazon OpenSearch để xử lý các truy vấn tìm kiếm và lọc sản phẩm phức tạp.

### 8. Kết quả kỳ vọng

_Cải tiến kỹ thuật:_ Hệ thống thương mại điện tử hoàn chỉnh chạy trên Serverless AWS, tích hợp kiểm thử tự động Playwright, phản hồi gợi ý cá nhân hóa dưới 1 giây.
_Giá trị dài hạn:_ Làm mô hình tham chiếu chuẩn cho việc triển khai các ứng dụng Machine Learning thực tế lên nền tảng đám mây AWS.

### 9. Một số hướng cải thiện

Dựa trên thực tế vận hành và yêu cầu mở rộng, một số dịch vụ AWS có thể được thêm vào hệ thống nhằm tối ưu hóa bảo mật, hiệu năng và khả năng mở rộng:

- **Bảo mật nhiều lớp:** Bổ sung AWS WAF trước CloudFront/API Gateway để chống Botnet/DDoS. Chuyển đổi quản lý người dùng sang Amazon Cognito.
- **Microservices:** Tách nhỏ Lambda hiện tại thành các dịch vụ độc lập (User, Product, Order) để tránh rủi ro hệ thống và cải thiện thời gian khởi động (Cold Start).
- **Tối ưu Truy vấn & Tìm kiếm:** Tích hợp Amazon OpenSearch cùng với DynamoDB để đáp ứng các truy vấn lọc sản phẩm và text-search phức tạp. Đưa mô hình CLIP lên Amazon ECS hoặc SageMaker.
- **Real-time Feedback Loop:** Sử dụng Kinesis Data Streams kết hợp với Amazon Personalize Event Tracker để cập nhật dữ liệu hành vi người dùng theo thời gian thực.
