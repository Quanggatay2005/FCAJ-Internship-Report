# Các bước đưa báo cáo lên GitHub Pages
Để hoàn thiện báo cáo và đưa lên GitHub Pages với đường link **"https://callmesen.github.io/FCAJ-Internship-Report/vi/"**, bạn cần thực hiện theo các bước chính sau đây:

## Bước 1: Viết nội dung báo cáo
- Mở các thư mục trong **content/** (như 1-Worklog, 2-Proposal,...).
- Mở hoặc tạo các file **.md** bên trong và điền nội dung báo cáo của bạn.
Vì bạn muốn đường link có đuôi **/vi/**, dự án của bạn đã cấu hình đa ngôn ngữ, hãy đảm bảo bạn viết nội dung vào các file có tên kết thúc bằng **.vi.md** (ví dụ: _index.vi.md, hoặc trong 1-Worklog bạn có thể tạo _index.vi.md).

## Bước 2: Chỉnh sửa file cấu hình config.toml
Để trang web nhận diện đúng đường link khi đẩy lên mạng, bạn cần mở file **config.toml** ra và sửa lại dòng đầu tiên:

Sửa từ: **`baseURL = "https://workshop-sample.awsfcaj.com/"`**

Thành: **`baseURL = "https://github.com/Quanggatay2005/FCAJ-Internship-Report"`**
(Hugo sẽ tự động thêm phần /vi/ vào cuối URL dựa trên cấu hình ngôn ngữ bên dưới file).

## Bước 3: Đưa mã nguồn lên GitHub (Tạo Repository)
- Đăng nhập vào GitHub với tài khoản callmesen.
- Tạo một Repository mới (**New repository**) với tên chính xác là: **FCAJ-Internship-Report**. Để chế độ Public.
- Không chọn thêm file README, .gitignore hay license gì cả lúc tạo.
- Mở Terminal (Command Prompt / PowerShell) tại thư mục **c:\Projects\fcj-workshop-template** và chạy các lệnh sau để đẩy code lên:
```bash
# Khởi tạo git (nếu chưa có) và đẩy code
git add .
git commit -m "Báo cáo thực tập AWS FCJ"
git branch -M main
git remote add origin https://github.com/Quanggatay2005/FCAJ-Internship-Report.git
git push -u origin main
```
(Lưu ý: Bạn thay đổi remote URL nếu trước đó project này đã link tới một repo khác bằng lệnh git remote set-url origin https://github.com/callmesen/FCAJ-Internship-Report.git)

## Bước 4: Cấp quyền cho GitHub Actions tự động Deploy
Dự án của bạn đã có sẵn thư mục .github/workflows/hugo.yml để tự động build và deploy trang web mỗi khi bạn có thay đổi code. Để nó hoạt động trơn tru:

- Vào trang Repository FCAJ-Internship-Report trên GitHub của bạn.
- Chuyển sang tab Settings > Kéo xuống chọn Actions > General.
- Cuộn xuống phần Workflow permissions, chọn "Read and write permissions" rồi nhấn Save.

## Bước 5: Kích hoạt GitHub Pages
Sau khi hoàn tất bước 3 và bước 4, GitHub Actions sẽ tự động chạy (bạn có thể kiểm tra ở tab Actions trên GitHub). Quá trình này sẽ tạo ra một nhánh (branch) mới tên là gh-pages chứa mã HTML tĩnh.

Cuối cùng, bạn cần kích hoạt website:

- Vẫn trong tab Settings của Repository trên GitHub, chọn Pages ở menu bên trái.
- Ở phần Build and deployment > Source, chọn Deploy from a branch.
- Ở phần Branch, chọn nhánh gh-pages và thư mục /(root), sau đó nhấn Save.
Đợi khoảng 1-2 phút, trang web của bạn sẽ chính thức hoạt động tại địa chỉ: https://callmesen.github.io/FCAJ-Internship-Report/vi/. Bất cứ khi nào bạn viết thêm báo cáo ở local và gõ lệnh git push, trang web sẽ tự động được cập nhật!