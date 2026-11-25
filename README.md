# Hệ thống Microservices Cloud-Native (Floci + Terraform + K3s + CI/CD + Observability)

Dự án xây dựng và triển khai trọn vẹn hệ thống ứng dụng Microservices từ tầng mạng Cloud/VPC, tự động hóa hạ tầng bằng IaC, điều phối Container trên Kubernetes, tự động hóa quy trình CI/CD GitOps đến hệ thống giám sát tập trung (Metrics, Logs, Tracing).

---

<!-- Bổ sung mục Video Demo trên YouTube và danh sách các Public URLs thực tế qua Cloudflare Tunnel -->
## Video Demo & Đường dẫn Truy cập Hệ thống (Live Public URLs)

- **Video Demo Toàn diện Dự án (YouTube):** https://youtu.be/aGAYyvmu5aM — Trình diễn thực tế từ bước khởi tạo hạ tầng Cloud bằng Terraform (7 Modules) trên Floci, vận hành cụm Kubernetes (K3s), luồng CI/CD tự động (GitHub Actions & ArgoCD) đến giám sát toàn diện (Grafana, Tempo, ELK Stack) và public domain qua Cloudflare Tunnel.
- **Trang Web Ứng dụng Chính (Frontend React & API Gateway):** https://tungpnp.org.uk/ — Giao diện Web Portfolio và hệ thống đăng nhập bảo mật (JWT + Kafka) kết nối cụm Microservices trên K3s.
- **Hệ thống Giám sát Metrics & Distributed Tracing (Grafana):** https://grafana.tungpnp.org.uk/ — Bảng điều khiển theo dõi chỉ số thời gian thực từ Prometheus (K8s Cluster, Node, JVM, Postgres, Redis, Kafka) và truy vết request qua Grafana Tempo.
- **Hệ thống Quản lý & Truy vấn Log Tập trung (Kibana - ELK Stack):** https://kibana.tungpnp.org.uk/ — Giao diện tìm kiếm, phân tích log tập trung thu thập từ các Pods ứng dụng qua Filebeat & Logstash.
- **Hệ thống Quản lý Triển khai GitOps (ArgoCD):** https://argocd.tungpnp.org.uk/ — Giao diện điều phối Continuous Delivery theo mô hình *App-of-Apps*, tự động đồng bộ trạng thái K8s từ GitHub Manifest Repo.

---

## 1. Kiến trúc & Công nghệ Sử dụng trong Dự án

- **Cloud & VPC:** **Floci** — Giả lập môi trường Cloud thay thế cho AWS và hoàn toàn miễn phí (Free 100%), nhưng vẫn đảm bảo đầy đủ tính năng và API tương tự AWS thực tế (VPC, Subnets, Route Tables, Internet/NAT Gateway, Security Groups, IAM, Secrets Manager, SSM, RDS, ElastiCache, S3, SQS/SNS, ECR, EKS, ALB).
- **Tự động dựng Hạ tầng Cloud (IaC):** **Terraform** — Thiết kế theo kiến trúc 7 Modules chuẩn hóa (`01-vpc` đến `07-eks-and-ingress`), tách biệt tầng khuôn mẫu dùng chung (`modules/`) và tầng cấu hình môi trường (`environments/floci`, `environments/prod`).
- **Điều phối Container (Container Orchestration):** **Kubernetes (K3s)** & **Docker** — Quản lý và vận hành toàn bộ các Microservices, Database, Message Broker và bộ công cụ giám sát; phân luồng giao thông qua **Traefik Ingress Controller**.
- **Hệ thống Ứng dụng Microservices (FE, GW, BE) & Dữ liệu:**
  - **Frontend (FE):** **React + TypeScript + Vite** (đóng gói Multi-stage trên **Nginx**).
  - **API Gateway (GW):** **Node.js (Express)** — Điều hướng request, kiểm soát truy cập (Rate Limiting) và thu thập chỉ số HTTP/Tracing.
  - **Backend (BE):** **Java Spring Boot 3** (xử lý xác thực JWT, nghiệp vụ cốt lõi) và **Python FastAPI** (dịch vụ API mở rộng).
  - **Database, Cache & Messaging:** **PostgreSQL 15** (cơ sở dữ liệu chính), **Redis 7** (bộ nhớ đệm & Rate Limit), **Apache Kafka + Zookeeper** (truyền tải sự kiện bất đồng bộ Event-Driven).
- **Quy trình CI/CD Tự động (GitHub Actions & ArgoCD GitOps):**
  - **CI (GitHub Actions):** Tự động kiểm tra mã nguồn Terraform (`fmt` & `validate`), biên dịch ứng dụng, đóng gói Docker Image đẩy lên **GitHub Container Registry (GHCR)** và cập nhật tag image mới vào kho Manifest.
  - **CD (ArgoCD):** Hoạt động theo mô hình GitOps (*App-of-Apps*), tự động đồng bộ cấu hình từ Git vào cụm K3s và tự phục hồi trạng thái Pod (Self-Healing).
- **Hệ thống Giám sát Toàn diện (Monitor / Observability):**
  - **Metrics:** **Prometheus + Grafana** kết hợp các Exporters (`node-exporter`, `kube-state-metrics`, `postgres-exporter`, `redis-exporter`, `kafka-exporter`, Traefik, Spring Boot Actuator) theo dõi sức khỏe hạ tầng và ứng dụng theo thời gian thực.
  - **Centralized Logging:** **ELK Stack (Filebeat -> Logstash -> Elasticsearch -> Kibana)** thu thập, bóc tách và truy vấn log tập trung toàn cụm.
  - **Distributed Tracing:** **OpenTelemetry + Grafana Tempo** truy vết hành trình của từng request xuyên qua API Gateway, Backend Java và Database theo `trace_id`.
- **Public Domain:** **Cloudflare Tunnel** — Đưa các dịch vụ nội bộ ra tên miền công khai (`*.tungpnp.org.uk`) có bảo mật HTTPS.

---

## 2. Cấu trúc Thư mục Dự án

```text
.
├── .github/workflows/   # Các pipeline CI tự động trên GitHub Actions (Terraform, FE, GW, BE)
├── floci/               # Docker Compose khởi chạy môi trường giả lập Cloud Floci & K3s
├── terraform/           # Mã nguồn Terraform IaC (7 Modules & cấu hình môi trường floci / prod)
├── source/              # Mã nguồn 4 Microservices (frontend-react, api-gateway, backend-java, backend-python)
├── k8s-manifests/       # Cấu hình triển khai Kubernetes (infrastructure, apps, network, argocd-apps, observability)
└── utilities/           # Các script PowerShell hỗ trợ đồng bộ cấu hình và vận hành hệ thống
```
