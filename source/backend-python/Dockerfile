# Stage 1: Build
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Production Image (Tối ưu)
FROM python:3.11-slim
WORKDIR /app
# Copy installed packages from builder
COPY --from=builder /root/.local /root/.local
COPY . .

# Đảm bảo pip packages nằm trong PATH
ENV PATH=/root/.local/bin:$PATH

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
