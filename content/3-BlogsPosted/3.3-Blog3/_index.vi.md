---
title: "Blog 3"
date: 2024-01-01
weight: 1
chapter: false
pre: " <b> 3.3. </b> "
---

# HỆ GỢI Ý THẤT BẠI: DỮ LIỆU, KHÔNG PHẢI THUẬT TOÁN

Khi xây dựng hệ thống gợi ý sản phẩm với Amazon Personalize trong kỳ thực tập tại FCAJ, chúng tôi phát hiện ra rằng hiệu suất kém thường xuất phát từ chất lượng dữ liệu, không phải do chọn sai thuật toán.

## 3 Bài Học Quan Trọng

### 1. Hiểu Cơ Chế Cốt Lõi Của Thuật Toán

- Amazon Personalize sử dụng **collaborative filtering** — tìm những người dùng có hành vi tương tự và gợi ý dựa trên các mẫu hành vi đó.
- **Điểm mấu chốt:** Nếu tương tác của người dùng là ngẫu nhiên, sẽ không có mẫu nào để thuật toán học.

### 2. Chất Lượng Dữ Liệu > Chọn Thuật Toán

- Đổi recipe mà không sửa lỗi dữ liệu nền chỉ gây lãng phí thời gian và tiền bạc.
- **Tập trung vào cấu trúc dữ liệu:**
  - Tạo các phân khúc người dùng thực tế (ví dụ: yêu thích điện tử, thời trang, sách)
  - Mô phỏng hành vi thực tế (phiên truy cập, phễu chuyển đổi, phân phối lũy thừa)
  - Thuật toán chỉ có thể học được những gì dữ liệu của bạn phản ánh

### 3. Dữ Liệu Mô Phỏng Phải Phản Ánh Thực Tế

- `random.choice()` tuy nhanh nhưng vô dụng cho việc kiểm thử có ý nghĩa.
- **Thiết kế dữ liệu mô phỏng cẩn thận:**
  - Mô hình hóa phiên người dùng với các sản phẩm liên quan
  - Áp dụng tỷ lệ chuyển đổi (xem→giỏ, giỏ→mua)
  - Xây dựng các phân khúc người dùng với sở thích rõ ràng

## So Sánh Kết Quả: Cùng Thuật Toán, Dữ Liệu Tốt Hơn

| Chỉ số          | Dữ liệu ngẫu nhiên | Dữ liệu có cấu trúc | Cải thiện       |
| --------------- | ------------------ | ------------------- | --------------- |
| **Precision@5** | 0.0889             | 0.4348              | **Gấp 4.9 lần** |
| **NDCG@10**     | 0.1799             | 0.6512              | **Gấp 3.6 lần** |
| **MRR@25**      | 0.1216             | 0.7130              | **Gấp 5.9 lần** |
| **Coverage**    | 0.8218             | 0.9505              | **+15.7%**      |

### Những Điểm Rút Ra:

- MRR tăng gần 6 lần — gợi ý phù hợp nay xuất hiện ở đầu danh sách nơi người dùng thực sự nhìn thấy
- Coverage cải thiện 15.7% — hệ thống gợi ý đa dạng hơn, không chỉ gợi ý đi gợi ý lại các sản phẩm bán chạy
- Một bộ dữ liệu có cấu trúc tốt có thể nhân hiệu suất lên 5-6 lần mà không cần thay đổi thuật toán

## Phân Tích Thành Phần

**Chuẩn Bị Dữ Liệu:** Nền tảng quan trọng nhất — bao gồm phân khúc người dùng, mô hình hành vi và các mẫu tương tác thực tế.

**Amazon Personalize:** Dịch vụ managed với các recipe có sẵn (AWS cung cấp thuật toán, bạn cung cấp dữ liệu).

**Chỉ Số Đánh Giá:** Precision@5, NDCG@10, MRR@25, Coverage — đo chất lượng và đa dạng của gợi ý.

**Dữ Liệu Có Cấu Trúc:** Yêu cầu các phân khúc người dùng (điện tử, thời trang, sách), tương tác theo phiên, phễu chuyển đổi và phân phối lũy thừa.

## Điểm Mấu Chốt

Công cụ và thuật toán chỉ chiếm 20%. 80% còn lại là **Chất Lượng Dữ Liệu** và **Hiểu Rõ Lĩnh Vực Bài Toán** của bạn.

Khi các chỉ số thấp bất thường, **hãy kiểm tra dữ liệu trước khi thay đổi thuật toán**.

---

**Bài viết gốc:** [Facebook AWS Study Group FCJ](https://www.facebook.com/groups/awsstudygroupfcj/permalink/2229279517837008/?rdid=7zgI0zX0X33fQod5#)
