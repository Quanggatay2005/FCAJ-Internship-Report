---
title : "Tạo cơ sở dữ liệu"
date : 2026-07-28
weight : 4
chapter : false
pre : " <b> 5.4 </b> "
---

Hệ thống dùng 8 bảng DynamoDB. Trước khi tạo, cần hiểu một điểm khác biệt căn bản so với cơ sở dữ liệu quan hệ.

#### Thiết kế theo mẫu truy vấn

Với cơ sở dữ liệu quan hệ, bạn chuẩn hoá dữ liệu trước rồi viết câu truy vấn sau. Với DynamoDB thì ngược lại: bạn xác định trước sẽ truy vấn thế nào, rồi thiết kế bảng phục vụ đúng những truy vấn đó.

Cụ thể ở đây, sáu bảng đầu chỉ cần tra theo một khoá duy nhất. Nhưng hai bảng cuối thì khác:

- **Reviews**: cần lấy *tất cả đánh giá của một sản phẩm*
- **Orders**: cần lấy *tất cả đơn hàng của một người dùng*

Nếu chỉ dùng khoá đơn, muốn lấy các bản ghi đó phải chạy **Scan** đọc toàn bộ bảng rồi lọc. Tốn thời gian và tốn tiền vì DynamoDB tính phí theo lượng dữ liệu đọc.

Giải pháp là dùng **khoá tổ hợp** gồm khoá phân vùng và khoá sắp xếp. Khi đó chỉ cần **Query** đọc đúng phân vùng cần thiết.

| Bảng | Khoá phân vùng | Khoá sắp xếp | Nội dung |
|---|---|---|---|
| Products | `id` | --- | Thông tin sản phẩm |
| Categories | `id` | --- | Danh mục |
| Users | `id` | --- | Tài khoản, mật khẩu đã băm |
| Sessions | `token` | --- | Phiên đăng nhập |
| Carts | `userId` | --- | Giỏ hàng |
| Vouchers | `code` | --- | Mã giảm giá |
| Reviews | `productId` | `id` | Đánh giá sản phẩm |
| Orders | `userId` | `id` | Đơn hàng |

{{% notice info %}}
**Lưu ý cho Production:** DynamoDB rất phù hợp cho các luồng giao dịch tốc độ cao (như giỏ hàng, đơn hàng). Tuy nhiên, đối với các truy vấn tìm kiếm và lọc sản phẩm phức tạp (như tìm theo khoảng giá, màu sắc, từ khóa tự do), bạn nên cân nhắc đồng bộ dữ liệu sang **Amazon OpenSearch** để xử lý thay vì phụ thuộc hoàn toàn vào DynamoDB.
{{% /notice %}}

#### Bước 1. Tạo bảng bằng console

Làm thử một bảng trên console để hiểu giao diện:

1. Mở [DynamoDB console](https://ap-southeast-1.console.aws.amazon.com/dynamodbv2/home?region=ap-southeast-1)
2. Chọn **Create table**
3. Điền:
   - **Table name**: `Products`
   - **Partition key**: `id`, kiểu **String**
   - Bỏ trống Sort key
   - **Table settings**: chọn **Customize settings**
   - **Table class**: DynamoDB Standard
   - **Capacity mode**: **On-demand**
4. Chọn **Create table**

![Tạo bảng](/images/5-Workshop/5.4/create-table.png)

{{% notice note %}}
**On-demand** nghĩa là bạn trả tiền theo số lần đọc ghi thực tế, không phải theo dung lượng đặt trước. Với dự án chưa biết lưu lượng thì đây là lựa chọn an toàn, không sợ vừa thừa tiền vừa nghẽn.
{{% /notice %}}

#### Bước 2. Tạo bảy bảng còn lại bằng CLI

Tạo bảy bảng bằng tay khá mất thời gian. Dùng lệnh sau cho nhanh:

```bash
for T in Categories Users Sessions Carts Vouchers; do
  case $T in
    Sessions) K=token ;;
    Carts)    K=userId ;;
    Vouchers) K=code ;;
    *)        K=id ;;
  esac
  aws dynamodb create-table --table-name $T \
    --attribute-definitions AttributeName=$K,AttributeType=S \
    --key-schema AttributeName=$K,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
done
```

Hai bảng có khoá tổ hợp tạo riêng:

```bash
aws dynamodb create-table --table-name Reviews \
  --attribute-definitions AttributeName=productId,AttributeType=S AttributeName=id,AttributeType=S \
  --key-schema AttributeName=productId,KeyType=HASH AttributeName=id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

aws dynamodb create-table --table-name Orders \
  --attribute-definitions AttributeName=userId,AttributeType=S AttributeName=id,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH AttributeName=id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
```

#### Bước 3. Kiểm tra

```bash
aws dynamodb list-tables
```

Kết quả phải liệt kê đủ 8 bảng.

#### Bước 4. Nạp dữ liệu mẫu

Nạp danh mục và sản phẩm mẫu để hệ thống có thứ hiển thị:

```bash
cd backend
node scripts/seed-data.mjs
```

Kiểm tra lại số bản ghi trong bảng Products:

```bash
aws dynamodb scan --table-name Products --select COUNT
```
