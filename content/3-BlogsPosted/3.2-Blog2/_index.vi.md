---
title: "Blog 2"
date: 2024-01-01
weight: 1
chapter: false
pre: " <b> 3.2. </b> "
---

# TỪ ZERO ĐẾN ZERO-DOWNTIME: DEVOPS & CI/CD TRÊN AWS

Khi bắt đầu DevOps trên AWS, mình từng nghĩ CI/CD chỉ là viết script tự động đẩy code lên máy chủ. Nhưng các hệ thống Production thực tế đã dạy rằng DevOps thực chất là về **Độ tin cậy**, **Bảo mật** và **Tốc độ**.

## 3 Bài Học Quan Trọng

### 1. Infrastructure as Code (IaC): Nói Không Với ClickOps

- Bấm tay trên console lúc đầu nhanh nhưng là ác mộng khi tái lập môi trường hoặc audit lỗi.
- **Dùng Terraform hoặc AWS CDK**. Coi hạ tầng như code. Mọi thay đổi qua Pull Request → Plan → Code Review.

### 2. Shift-Left Security Trong CI/CD Pipeline

- Đừng đợi lên Production mới quét lỗ hổng.
- **Tích hợp bảo mật sớm:**
  - Quét file IaC với Checkov/TFLint
  - Quét container image với Amazon ECR Image Scanning
  - Quản lý secrets tập trung với AWS Secrets Manager (không hardcode)

### 3. Blue/Green & Canary Deployments Cho Zero-Downtime

- Deploy kiểu in-place dễ gây gián đoạn và lỗi 502.
- **Dùng AWS CodeDeploy:**
  - **Blue/Green**: Dựng môi trường song song, test rồi chuyển traffic
  - **Canary**: Chuyển 10% traffic sang bản mới, theo dõi CloudWatch Metrics rồi rollout 100%

## Kiến Trúc Pipeline Chi Tiết

Dưới đây là luồng CI/CD đã được áp dụng trong thực tế:

**Bước 1: Developer commit code lên GitHub**

Khi lập trình viên đẩy code lên repository, đây là điểm khởi đầu của toàn bộ pipeline.

**Bước 2: AWS CodePipeline phát hiện thay đổi và kích hoạt pipeline**

CodePipeline liên tục theo dõi repository. Khi có commit mới, pipeline tự động được kích hoạt mà không cần can thiệp thủ công.

**Bước 3: AWS CodeBuild chạy Unit Tests**

Kiểm tra chất lượng code bằng các bài test tự động. Nếu test thất bại, pipeline dừng lại ngay để tránh deploy code lỗi.

**Bước 4: CodeBuild chạy Security Scan**

Quét mã nguồn và các dependency để phát hiện lỗ hổng bảo mật. Phát hiện sớm giúp giảm chi phí sửa lỗi so với khi đã lên Production.

**Bước 5: Build container image và push lên Amazon ECR**

Tạo Docker image từ source code, sau đó đẩy lên Amazon Elastic Container Registry để lưu trữ và quản lý các phiên bản image.

**Bước 6: ECR tự động quét image**

Ngay khi image được push lên, ECR tự động quét để phát hiện CVE trong các layer của image. Kết quả quét được ghi lại để đánh giá trước khi triển khai.

**Bước 7: CodeDeploy (hoặc Helm) triển khai lên Amazon EKS**

Image được triển khai lên Kubernetes cluster. Tùy vào cách thiết lập, có thể dùng CodeDeploy tích hợp sẵn với EKS hoặc dùng Helm để quản lý ứng dụng dạng charts.

**Bước 8: Áp dụng chiến lược Blue/Green hoặc Canary**

Thay vì deploy trực tiếp lên production, pipeline sử dụng một trong hai chiến lược:

- Blue/Green: Tạo bản Green (mới) song song với bản Blue (hiện tại). Sau khi test kỹ trên bản Green, traffic được chuyển từ Blue sang Green.
- Canary: Chuyển một phần nhỏ traffic (ví dụ 10%) sang bản mới, theo dõi các chỉ số trước khi chuyển toàn bộ.

**Bước 9: Theo dõi metrics trên CloudWatch và tự động rollback**

Trong suốt quá trình deploy, CloudWatch theo dõi các chỉ số quan trọng như tỷ lệ lỗi, thời gian phản hồi. Nếu phát hiện bất thường, pipeline tự động rollback về bản cũ để giảm thiểu tác động.

### Giải thích từng thành phần:

**GitHub:** Nơi lưu trữ source code, tích hợp sẵn với CodePipeline.

**AWS CodePipeline:** Dịch vụ orchestration CI/CD, điều phối toàn bộ luồng từ build đến deploy.

**AWS CodeBuild:** Dịch vụ build serverless, thực hiện test, security scan và build image.

**Amazon ECR:** Registry container image, tích hợp quét CVE tự động.

**AWS CodeDeploy / Helm:** Công cụ triển khai với các chiến lược Zero-Downtime.

**Amazon EKS:** Kubernetes cluster nơi ứng dụng chạy.

### Kết quả đạt được:

- Thời gian deploy giảm từ 30 phút xuống dưới 4 phút
- Phát hiện sớm lỗ hổng bảo mật ngay từ khâu build
- Triển khai không downtime nhờ Blue/Green và Canary
- Tự động rollback nếu có vấn đề sau deploy

## Điểm Quan Trọng

Công cụ chỉ chiếm 20%. 80% còn lại là **Thiết kế Pipeline** và văn hóa **Release nhỏ, liên tục**.

**Bài viết gốc:** [Facebook AWS Study Group FCJ](https://www.facebook.com/groups/awsstudygroupfcj/permalink/2229176364513990/?rdid=aT7nNGRCmytCuj4K#)
