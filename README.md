# Turbo Setup WordPress

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)  

## Giới thiệu

Script này là một công cụ tự động hóa được viết bằng Bash, giúp thiết lập môi trường WordPress trên GitHub Codespace một cách nhanh chóng và dễ dàng. Với giao diện menu tương tác, script cung cấp ba tính năng chính:

- **Thiết lập WordPress**: Cài đặt và cấu hình WordPress cùng các thành phần cần thiết như Apache, PHP, và MySQL (sử dụng Docker).
- **Tạo tệp dữ liệu**: Sao lưu dữ liệu MySQL và các tệp WordPress thành các tệp nén zip.
- **Đăng nhập vào nhà cung cấp tên miền (serveo.net)**: Thiết lập khóa SSH và kết nối tới serveo.net để công khai máy chủ cục bộ ra internet.

Script này phù hợp cho các nhà phát triển muốn nhanh chóng triển khai WordPress trong môi trường Codespace mà không cần thực hiện các bước thủ công phức tạp.

### Tính năng chính

- **Thiết lập WordPress**: Tự động cài đặt Apache, PHP 8.0, MySQL qua Docker, tải và cấu hình WordPress, đồng thời thiết lập tunnel SSH để truy cập từ xa.
- **Tạo tệp dữ liệu**: Tạo bản sao lưu của dữ liệu MySQL và tệp WordPress dưới dạng zip để dễ dàng khôi phục hoặc di chuyển.
- **Đăng nhập vào serveo.net**: Tạo khóa SSH và cài đặt autossh để kết nối với serveo.net, cho phép truy cập WordPress qua internet.

### Yêu cầu trước khi sử dụng

- Một môi trường GitHub Codespace đã được thiết lập.
- Quyền truy cập internet để tải các gói phần mềm và kết nối tới serveo.net.
- Docker đã được cài đặt trong Codespace (script sẽ báo lỗi nếu thiếu Docker).

## Hướng dẫn sử dụng

### 1. Tải script về Codespace

Sao chép script vào môi trường Codespace của bạn bằng cách:

```bash
mkdir -p /workspaces/codespaces-blank
cd /workspaces/codespaces-blank
# Sau đó, dán script vào tệp `setup.sh` bằng trình chỉnh sửa hoặc lệnh sau:
cat > setup.sh << 'EOF'
# Dán toàn bộ nội dung script ở đây
EOF
chmod +x setup.sh
```

### 2. Chạy script

Khởi động script bằng lệnh sau:

```bash
bash setup.sh
```

### 3. Điều hướng menu

Khi script chạy, bạn sẽ thấy một menu với ba tùy chọn:

- **Set up WordPress** (Thiết lập WordPress)
- **Create data files** (Tạo tệp dữ liệu)
- **Log in to domain provider (serveo.net)** (Đăng nhập vào nhà cung cấp tên miền)

#### Cách sử dụng menu:
- Sử dụng **phím mũi tên lên/xuống** để di chuyển giữa các tùy chọn.
- Nhấn **Enter** để chọn tùy chọn đang được tô sáng.
- Một số tùy chọn có thể bị vô hiệu hóa (hiển thị màu xám) tùy thuộc vào trạng thái hệ thống:
  - Nếu thư mục `$HOME/.ssh` chưa tồn tại, chỉ tùy chọn "Log in to domain provider (serveo.net)" khả dụng.
  - Sau khi đăng nhập vào serveo.net, các tùy chọn khác sẽ được kích hoạt.

### 4. Chi tiết các tùy chọn

#### **Tùy chọn 1: Thiết lập WordPress**
- **Điều kiện**: Yêu cầu đã đăng nhập vào serveo.net (có thư mục `$HOME/.ssh`).
- **Quy trình**:
  1. **Nhập tên miền**: Nhập tên miền tùy chỉnh hoặc để mặc định (dạng `domain<ngày giờ>`). Tên miền đầy đủ sẽ là `<tên miền>.serveo.net`.
  2. **Gỡ PHP mặc định**: Xóa PHP mặc định để tránh xung đột.
  3. **Cài Apache2**: Cập nhật gói và cài đặt Apache2, khởi động dịch vụ.
  4. **Cài PHP 8.0**: Thêm repository và cài các tiện ích mở rộng cần thiết cho WordPress.
  5. **Đặt mật khẩu MySQL**: Nhập mật khẩu hoặc sử dụng mặc định (`1234567@@!`).
  6. **Cài WordPress**: Tải WordPress từ trang chính thức hoặc giải nén từ `wordpress.zip` nếu có sẵn, cấu hình `wp-config.php`.
  7. **Cấu hình MySQL**: Sử dụng Docker để chạy MySQL, khôi phục dữ liệu nếu có `mysql_data.zip`.
  8. **Cấu hình Virtual Host**: Thiết lập Apache để phục vụ WordPress.
  9. **Tạo script khởi động lại**: Tạo tệp `rerun_server.sh` để tái khởi động tunnel SSH khi cần.
  10. **Kết nối serveo.net**: Mở tunnel SSH để truy cập WordPress qua internet.
- **Kết quả**: Truy cập WordPress tại `http://<tên miền>.serveo.net`.

#### **Tùy chọn 2: Tạo tệp dữ liệu**
- **Chức năng**: Sao lưu dữ liệu MySQL và tệp WordPress.
- **Quy trình**:
  1. Sao chép dữ liệu MySQL từ Docker volume và nén thành `mysql_data.zip`.
  2. Sao chép thư mục `/var/www/html/` và nén thành `wordpress.zip`.
- **Kết quả**: Tạo hai tệp `mysql_data.zip` và `wordpress.zip` trong thư mục hiện tại.

#### **Tùy chọn 3: Đăng nhập vào serveo.net**
- **Chức năng**: Thiết lập kết nối tới serveo.net để công khai máy chủ.
- **Quy trình**:
  1. Tạo khóa SSH nếu chưa có (`$HOME/.ssh/id_rsa`).
  2. Cài đặt autossh.
  3. Kết nối tới serveo.net, hiển thị thông báo yêu cầu đăng nhập qua Google/GitHub.
  4. Nhấn **Ctrl+C** hai lần để thoát sau khi đăng nhập.
- **Kết quả**: Kết nối SSH được thiết lập, mở đường cho các tùy chọn khác.

### 5. Khởi động lại máy chủ (nếu cần)

Sau khi thiết lập WordPress, bạn có thể sử dụng script `rerun_server.sh` để khởi động lại tunnel SSH:

```bash
bash rerun_server.sh
```

## Giải thích chi tiết script

### **Hệ thống menu**
- Menu được hiển thị với các tùy chọn được tô màu:
  - **Xanh dương**: Tùy chọn được chọn.
  - **Xám**: Tùy chọn bị vô hiệu hóa.
- Logic kiểm tra điều kiện: Nếu thư mục `$HOME/.ssh` tồn tại, tùy chọn 0 và 1 khả dụng; nếu không, chỉ tùy chọn 2 hoạt động.

### **Thiết lập WordPress**
- **Cấu hình domain**: Tạo tên miền duy nhất dựa trên thời gian nếu không nhập.
- **Cài đặt phụ thuộc**: Xóa PHP mặc định, cài Apache2 và PHP 8.0 với các tiện ích mở rộng cần thiết.
- **WordPress**: Tải từ wordpress.org hoặc dùng tệp zip có sẵn, tự động cấu hình cơ sở dữ liệu và khóa bảo mật.
- **MySQL**: Chạy qua Docker với volume lưu trữ dữ liệu lâu dài.
- **Apache**: Thiết lập Virtual Host và bật module rewrite để hỗ trợ URL thân thiện.

### **Tạo tệp dữ liệu**
- Sử dụng lệnh `zip` để nén dữ liệu từ Docker và thư mục WordPress.

### **Đăng nhập serveo.net**
- Tạo khóa SSH và dùng autossh để duy trì tunnel ổn định.

## Xử lý sự cố

- **Lỗi SSH**: Kiểm tra xem khóa SSH đã được tạo chưa (`ls -la $HOME/.ssh`) và đảm bảo đã đăng nhập serveo.net.
- **Lỗi Docker**: Xác nhận Docker đang chạy (`docker ps`) và kiểm tra log nếu MySQL không khởi động (`docker logs mysql_server`).
- **Lỗi Apache**: Xem log lỗi tại `/var/log/apache2/error.log` để tìm nguyên nhân.
- **WordPress không hoạt động**: Kiểm tra `wp-config.php` và đảm bảo MySQL đang chạy.

## Bản quyền

Script này được phát triển bởi **OpenFXT** và **NULLCommand1**.  
- **Website**: [https://openfxt.vercel.app](https://openfxt.vercel.app)  