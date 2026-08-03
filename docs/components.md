# Component Analysis

Dựa vào cấu trúc thư mục và các file cấu hình, đây là một dự án Hugo (một framework tạo trang web tĩnh - Static Site Generator rất phổ biến). Dự án này đang được sử dụng để tạo một trang web dạng tài liệu/báo cáo, cụ thể là "Báo cáo thực tập" (Internship Report) cho sự kiện/chương trình của AWS Study Group (First Cloud Journey - FCJ).

Dưới đây là review chi tiết về các thành phần và vai trò của từng thư mục/file trong dự án của bạn:

## 1. File cấu hình chính
- **config.toml**: Đây là file quan trọng nhất của dự án Hugo. Nó chứa các cài đặt tổng thể cho trang web như:
    - baseURL: Địa chỉ URL gốc của trang web (https://workshop-sample.awsfcaj.com/).
    - theme: Giao diện đang sử dụng là hugo-theme-learn (một theme rất phổ biến cho các trang tài liệu/workshop).
    - Cấu hình đa ngôn ngữ (Multi-language): Hỗ trợ tiếng Anh ([Languages.en]) và tiếng Việt ([Languages.vi]).
    - Menu sidebar bên trái (các shortcut liên kết tới blog và Facebook group của AWS Study Group).
- **.hugo_build.lock**: File lock được sinh ra tự động khi chạy Hugo build để ngăn chặn các tiến trình build chạy đồng thời gây xung đột.
- **.gitmodules**: Cho thấy dự án này có sử dụng Git Submodules, khả năng cao là để pull mã nguồn của theme hugo-theme-learn vào thư mục themes/.

## 2. Các thư mục chính
- **content/**: Thư mục quan trọng nhất đối với người viết nội dung. Tất cả các bài viết, báo cáo của bạn dưới dạng file Markdown (.md) sẽ nằm ở đây.
    - Dự án hiện tại đã chia sẵn các thư mục theo luồng báo cáo thực tập như: 1-Worklog, 2-Proposal, 3-BlogsPosted, 4-EventParticipated, 5-Workshop, 6-Self-evaluation, 7-Feedback.
    - Hugo sẽ dựa vào cấu trúc thư mục này để tạo menu điều hướng ở thanh bên trái trang web.
    - Các file _index.md và _index.vi.md là trang chủ (Homepage) của website cho từng ngôn ngữ.
- **themes/**: Chứa mã nguồn của giao diện. Trong trường hợp này, nó sẽ chứa thư mục của theme hugo-theme-learn. Bạn thường không nên chỉnh sửa code trực tiếp trong này vì nó được quản lý qua git submodule.
- **static/**: Chứa các tệp tĩnh (static assets) như hình ảnh, file CSS tùy chỉnh, JavaScript, logo,... Bất cứ thứ gì bạn đặt vào đây sẽ được copy nguyên vẹn sang thư mục gốc khi build trang web. Ví dụ: Nếu bạn để file image.png vào thư mục này, bạn có thể gọi nó trên web với đường dẫn /image.png.
- **layouts/**: Chứa các file HTML template tùy chỉnh. Nếu bạn muốn thay đổi cấu trúc mã HTML của theme mặc định (ví dụ: muốn sửa footer, header), bạn sẽ copy file tương ứng từ theme sang thư mục layouts này và chỉnh sửa. Hugo sẽ ưu tiên dùng file trong layouts/ của bạn hơn là file trong themes/.
- **archetypes/**: Chứa các file template gốc định dạng sẵn (front matter) cho các bài viết mới. Khi bạn chạy lệnh hugo new content/bai-viet.md, Hugo sẽ lấy mẫu từ thư mục này để tạo file với các thông số mặc định (tiêu đề, ngày tháng, trạng thái draft...).
- **public/**: Đây là thư mục đầu ra. Khi bạn chạy lệnh hugo để build website, toàn bộ mã HTML/CSS/JS cuối cùng đã được xử lý sẽ được xuất ra thư mục này. Thư mục này dùng để upload lên server/hosting (như GitHub Pages, AWS S3, Vercel...). Lưu ý: Không bao giờ viết code trực tiếp vào thư mục này vì nó sẽ bị ghi đè mỗi khi build lại.

## 3. Các thành phần khác
- **.git/, .gitignore, .github/**: Các thư mục và file liên quan đến Git để quản lý version code và thiết lập CI/CD (GitHub Actions) để tự động deploy trang web khi có code mới.
.vscode/: Chứa các cấu hình (settings, snippets, hoặc recommended extensions) dành riêng cho editor Visual Studio Code để hỗ trợ bạn viết code dự án này tốt hơn.

**Tóm lại**: Nếu bạn chỉ cần viết báo cáo, bạn chỉ cần quan tâm và thao tác chủ yếu trong thư mục content/ (viết file markdown) và static/ (để chứa hình ảnh chèn vào báo cáo).