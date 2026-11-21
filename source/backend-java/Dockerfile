# ==========================================
# STAGE 1: Giai đoạn "Thợ Xây" (Builder)
# ==========================================
# 1. Khởi tạo một máy ảo Linux có cài sẵn công cụ Maven và Java 17
# Đặt tên cho máy này là "builder" để lát nữa tái sử dụng.
FROM maven:3.9.6-eclipse-temurin-17 AS builder

# 2. Di chuyển vào thư mục /app bên trong máy ảo Linux này.
# Mọi lệnh sau dòng này đều thực thi trong /app.
WORKDIR /app

# 3. [Tối ưu hóa] Copy riêng file danh sách thư viện (pom.xml) vào trước.
# Lý do: Nếu code thay đổi mà thư viện không đổi, Docker sẽ dùng lại Cache của lớp này để tiết kiệm thời gian.
COPY pom.xml .

# 4. Ra lệnh cho Maven tải toàn bộ thư viện về máy ảo.
# Cờ -B giúp quá trình chạy ở chế độ non-interactive (không hỏi đáp).
RUN mvn dependency:go-offline -B

# 5. Copy toàn bộ mã nguồn thực sự (thư mục src) từ Windows vào máy ảo Linux.
COPY src ./src

# 6. Ra lệnh cho Maven dọn dẹp (clean), bỏ qua chạy Unit Test (-DskipTests) 
# và đóng gói toàn bộ thành 1 file Fat JAR.
RUN mvn clean package -DskipTests


# ==========================================
# STAGE 2: Giai đoạn "Máy Chạy" (Runtime)
# ==========================================
# 7. Vứt bỏ hoàn toàn máy ảo "builder" nặng nề ở trên.
# Tạo một máy ảo Linux siêu nhẹ tên là Alpine, chỉ cài duy nhất cục JRE (Môi trường chạy Java).
FROM eclipse-temurin:17-jre-alpine

# 8. Di chuyển vào thư mục /app của máy ảo siêu nhẹ này.
WORKDIR /app

# 9. Dòng ma thuật: Lẻn sang máy ảo "builder", lấy cái file .jar vừa được đóng gói ở bước 6 
# mang về máy ảo nhẹ này, và đổi tên nó thành "app.jar" cho gọn.
COPY --from=builder /app/target/backend-java-1.0.0.jar app.jar

# 9.5. Tải vũ khí giám sát: OpenTelemetry Java Agent (Zero-code Tracing)
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar /app/opentelemetry-javaagent.jar
RUN chmod 644 /app/opentelemetry-javaagent.jar

# 10. Gắn biển báo "Mở cửa ở Port 8080". Lệnh này không thực sự mở mạng, 
# nó chỉ dùng làm tài liệu tham khảo cho kỹ sư DevOps biết đường mà map port.
EXPOSE 8080

# 11. Cấu hình Nút Công Tắc Nguồn (ENTRYPOINT).
# Khi máy ảo này khởi động, nó sẽ tự động chạy lệnh `java -jar app.jar`.
# Cờ -Dfile.encoding=UTF-8 giúp ép hệ điều hành sử dụng bảng mã chuẩn để không bị lỗi font Tiếng Việt.
ENTRYPOINT ["java", "-Dfile.encoding=UTF-8", "-jar", "app.jar"]
