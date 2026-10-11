# IT209 - Session 10: Docker Networking & Storage Management

## Bài 4: Thiết lập Custom Network & Named Volume bằng Docker CLI

Bài làm được đặt tại thư mục: [homework/session_10/ex4/](homework/session_10/ex4/)

### Danh mục bài nộp:
- Script thực thi tự động: [`commands.sh`](homework/session_10/ex4/commands.sh)
- Báo cáo chi tiết & hướng dẫn: [`README.md`](homework/session_10/ex4/README.md)

### Tóm tắt nội dung thực hiện:
1. Tạo Custom Bridge Network `app-net`.
2. Tạo Named Volume `db-data`.
3. Khởi chạy Database container `db-server` (`postgres:15-alpine`) gắn volume `db-data` và mạng `app-net`.
4. Khởi chạy Backend container `app-container` giao tiếp với DB qua hostname `db-server`.
5. Kiểm tra DNS Resolution qua lệnh: `docker exec -it app-container ping -c 2 db-server`.
6. Thực hiện test Data Persistence: Thêm dữ liệu ➔ Xóa cứng `db-server` ➔ Khởi chạy container mới gắn lại volume `db-data` ➔ Xác minh toàn vẹn dữ liệu.
