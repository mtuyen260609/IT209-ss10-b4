#!/bin/bash
# ==============================================================================
# BÀI 4: THIẾT LẬP CUSTOM NETWORK & NAMED VOLUME BẰNG DOCKER CLI
# Repository: https://github.com/mtuyen260609/IT209-ss10-b4
# Đường dẫn: homework/session_10/ex4/commands.sh
# 
# Mục tiêu:
# 1. Tạo Custom Bridge Network (app-net) để các container giao tiếp qua DNS tên service.
# 2. Tạo Named Volume (db-data) để lưu trữ dữ liệu bền vững (Data Persistence).
# 3. Kết nối Database container (db-server) và Backend container (app-container).
# 4. Xác minh giao tiếp qua DNS và bảo toàn dữ liệu sau khi xóa cứng container DB.
# ==============================================================================

set -e

echo "======================================================================"
echo "BƯỚC 0: DỌN DẸP CÁC CONTAINER CŨ (NẾU ĐÃ TỒN TẠI TỪ TRƯỚC)"
echo "======================================================================"
docker rm -f db-server app-container 2>/dev/null || true
echo ">> Đã dọn dẹp môi trường sẵn sàng."

echo ""
echo "======================================================================"
echo "BƯỚC 1: TẠO CUSTOM BRIDGE NETWORK (app-net)"
echo "======================================================================"
# Kiểm tra nếu network chưa có thì tạo mới
if ! docker network ls | grep -w "app-net" >/dev/null 2>&1; then
    echo ">> Đang tạo custom bridge network 'app-net'..."
    docker network create --driver bridge app-net
else
    echo ">> Network 'app-net' đã tồn tại."
fi

echo ""
echo "======================================================================"
echo "BƯỚC 2: TẠO NAMED VOLUME (db-data)"
echo "======================================================================"
# Kiểm tra nếu volume chưa có thì tạo mới
if ! docker volume ls | grep -w "db-data" >/dev/null 2>&1; then
    echo ">> Đang tạo named volume 'db-data'..."
    docker volume create db-data
else
    echo ">> Volume 'db-data' đã tồn tại."
fi

echo ""
echo "======================================================================"
echo "BƯỚC 3: KHỞI CHẠY DATABASE CONTAINER (postgres:15-alpine)"
echo "======================================================================"
# Container db-server tham gia network app-net và mount volume db-data vào /var/lib/postgresql/data
echo ">> Khởi chạy db-server..."
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=appdb \
  postgres:15-alpine

echo ">> Đang chờ PostgreSQL db-server sẵn sàng nhận kết nối..."
until docker exec db-server pg_isready -U postgres -d appdb >/dev/null 2>&1; do
    echo "   ...đang khởi động database, vui lòng chờ..."
    sleep 2
done
echo ">> PostgreSQL db-server đã sẵn sàng!"

echo ""
echo "======================================================================"
echo "BƯỚC 4: KHỞI CHẠY BACKEND CONTAINER (app-container)"
echo "======================================================================"
# Khởi chạy backend container tham gia app-net, truyền biến kết nối DB bằng hostname db-server
# Sử dụng image alpine (hoặc node:18-alpine) có sẵn công cụ mạng (ping)
echo ">> Khởi chạy app-container..."
docker run -d \
  --name app-container \
  --network app-net \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e DB_NAME=appdb \
  alpine tail -f /dev/null

echo ">> app-container đã khởi chạy thành công!"

echo ""
echo "======================================================================"
echo "BƯỚC 5: KIỂM TRA THEO YÊU CẦU ĐỀ BÀI"
echo "======================================================================"

echo "--- 1. docker network ls | grep app-net ---"
docker network ls | grep app-net

echo ""
echo "--- 2. docker volume ls | grep db-data ---"
docker volume ls | grep db-data

echo ""
echo "--- 3. docker network inspect app-net ---"
docker network inspect app-net

echo ""
echo "--- 4. docker exec -it app-container ping -c 2 db-server ---"
# Chạy ping từ app-container sang db-server bằng hostname
docker exec app-container ping -c 2 db-server

echo ""
echo "======================================================================"
echo "BƯỚC 6: THỰC HIỆN TEST DATA PERSISTENCE"
echo "======================================================================"

echo ">> 6.1. Thêm dữ liệu vào Database qua db-server..."
docker exec -i db-server psql -U postgres -d appdb << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES 
('Nguyen Van A', 'nguyenvana@example.com'),
('Tran Thi B', 'tranthib@example.com');
EOF

echo ">> Kiểm tra dữ liệu trong DB trước khi xóa container:"
docker exec -i db-server psql -U postgres -d appdb -c "SELECT * FROM users;"

echo ""
echo ">> 6.2. Xóa cứng container DB: docker rm -f db-server"
docker rm -f db-server

echo ">> Kiểm tra trạng thái db-server (không còn tồn tại):"
docker ps -a --filter "name=db-server"

echo ""
echo ">> 6.3. Khởi chạy lại container DB mới gắn cùng Volume db-data..."
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=appdb \
  postgres:15-alpine

echo ">> Đang chờ container DB mới sẵn sàng..."
until docker exec db-server pg_isready -U postgres -d appdb >/dev/null 2>&1; do
    echo "   ...đang khởi tạo database, vui lòng chờ..."
    sleep 2
done

echo ""
echo ">> 6.4. Xác minh dữ liệu không bị mất sau khi tái tạo container:"
docker exec -i db-server psql -U postgres -d appdb -c "SELECT * FROM users;"

echo ""
echo "======================================================================"
echo "KẾT LUẬN: BÀI THỰC HÀNH THÀNH CÔNG!"
echo "- DNS Resolution: app-container đã phân giải và ping thành công tới db-server."
echo "- Data Persistence: Dữ liệu vẫn được bảo toàn trọn vẹn nhờ Named Volume db-data."
echo "======================================================================"
