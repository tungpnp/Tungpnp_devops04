# ==========================================
# STAGE 1: Giai đoạn "Biên Dịch" (Builder)
# ==========================================
# 1. Khởi tạo một máy ảo Linux có cài sẵn Node.js (phiên bản 20 trên nền Alpine nhẹ).
# Đặt tên máy này là "builder".
FROM node:20-alpine AS builder

# 2. Tạo và di chuyển vào thư mục /app bên trong máy ảo.
WORKDIR /app

# 3. [Tối ưu hóa] Copy riêng file danh sách thư viện (package.json) vào trước.
# Mục đích: Để tận dụng Docker Cache, nếu không thêm thư viện mới thì Docker không phải tải lại.
COPY package.json package-lock.json ./

# 4. Chạy lệnh cài đặt toàn bộ thư viện cần thiết cho React.
# Dùng `npm ci` thay vì `npm install` để bám sát tuyệt đối vào phiên bản trong package-lock.json.
RUN npm ci

# 5. Copy toàn bộ mã nguồn React còn lại từ Windows vào máy ảo Linux.
COPY . .

# 6. Ra lệnh cho Node.js biên dịch toàn bộ React thành một bộ file tĩnh (HTML, CSS, JS gốc).
# Kết quả sẽ được đẻ ra ở thư mục /app/dist.
RUN npm run build


# ==========================================
# STAGE 2: Giai đoạn "Phục Vụ" (Nginx Runtime)
# ==========================================
# 7. Vứt bỏ hoàn toàn máy ảo Node.js cồng kềnh.
# Khởi tạo một máy ảo mới siêu nhẹ, chỉ chứa web server NGINX (khoảng 15MB).
FROM nginx:alpine

# 8. Xóa file cấu hình mặc định (không đủ tốt) của NGINX đi.
RUN rm /etc/nginx/conf.d/default.conf

# 9. Lấy file cấu hình chuẩn (nginx.conf) của chúng ta ném vào thay thế.
# File này chứa bí kíp xử lý lỗi 404 (chuyển hướng về index.html) đặc trưng của React Router.
COPY nginx.conf /etc/nginx/conf.d/

# 10. Dòng ma thuật: Lẻn sang máy "builder", nhấc bổng cái thư mục /app/dist (chứa web thành phẩm),
# và chép đè thẳng vào thư mục phục vụ web của NGINX.
COPY --from=builder /app/dist /usr/share/nginx/html

# 11. Gắn biển báo "Mở cửa giao dịch ở Port 80". (Cổng web mặc định).
EXPOSE 80

# 12. Khởi động NGINX chạy ngầm (daemon off) để giữ cho Container sống mãi mãi không bị thoát.
CMD ["nginx", "-g", "daemon off;"]
