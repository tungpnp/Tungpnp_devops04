const express = require('express');
const cors = require('cors');
const { createClient } = require('redis');
const { rateLimit } = require('express-rate-limit');
const { RedisStore } = require('rate-limit-redis');
const { createProxyMiddleware } = require('http-proxy-middleware');
const promClient = require('prom-client');
const logger = require('./logger');

const app = express();
const PORT = process.env.PORT || 3001;

// 0. Cấu hình Trust Proxy (Cực kỳ quan trọng khi đứng sau Traefik)
// Khai báo cho Express biết nó đang đứng sau 1 lớp Proxy (Traefik), 
// để rate-limit có thể lấy đúng IP thật từ header X-Forwarded-For thay vì chửi lỗi.
app.set('trust proxy', 1);

// Biến môi trường được truyền từ K8s
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const JAVA_BACKEND_URL = process.env.JAVA_BACKEND_URL || 'http://localhost:8080';
const LOG_METRICS = process.env.LOG_METRICS === 'true';

// 1. Kết nối Redis
const redisClient = createClient({ url: REDIS_URL });
redisClient.connect().catch(err => logger.error('Redis Client Error', { error: err.message }));
redisClient.on('error', (err) => logger.error('Redis Client Error', { error: err.message }));
redisClient.on('connect', () => logger.info('✅ Đã kết nối thành công tới Redis!'));

app.use(cors());
// Parse body dạng JSON để có thể ghi log "param truyền vào"
app.use(express.json());

// 2. Middleware Ghi Log Chi tiết mọi Request từ Client (Chuẩn JSON)
app.use((req, res, next) => {
    // Tắt log cho các endpoint nội bộ nếu không được yêu cầu bật
    if (!LOG_METRICS && (req.originalUrl === '/metrics' || req.originalUrl === '/health')) {
        return next();
    }

    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const deviceId = req.headers['x-device-id'] || 'unknown';
    const userAgent = req.headers['user-agent'] || 'unknown';

    // Tạo payload log chuẩn
    const logData = {
        event: 'INCOMING_REQUEST',
        client_ip: clientIp,
        device_id: deviceId,
        user_agent: userAgent,
        method: req.method,
        url: req.originalUrl,
        query: req.query,
        body: req.body
    };

    logger.info('Received API Request', logData);
    next();
});

const ENABLE_RATE_LIMIT = process.env.ENABLE_RATE_LIMIT === 'true';

// 3. Cấu hình Rate Limiter (Giới hạn 10 request / 1 phút / 1 IP)
const apiLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 phút
    max: 10, // Tối đa 10 request
    standardHeaders: true, 
    legacyHeaders: false, 
    store: new RedisStore({
        sendCommand: (...args) => redisClient.sendCommand(args),
    }),
    message: {
        error: "Bạn đã vượt quá giới hạn truy cập (10 lần/phút). IP của bạn tạm thời bị khóa để chống Brute-force. Vui lòng thử lại sau 1 phút!"
    }
});

// Áp dụng khiên bảo vệ cho nhánh API Đăng nhập nếu công tắc bật
if (ENABLE_RATE_LIMIT) {
    app.use('/api/v1/auth/login', apiLimiter);
}

// ==========================================
// THÀNH PHẦN GIÁM SÁT (MONITORING & METRICS)
// ==========================================
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

app.get('/metrics', async (req, res) => {
    try {
        res.set('Content-Type', register.contentType);
        res.end(await register.metrics()); // Mở cổng cho Prometheus hút dữ liệu
    } catch (ex) {
        res.status(500).end(ex);
    }
});
// ==========================================

app.get('/health', (req, res) => {
    res.status(200).send('API Gateway is OK');
});

// 5. Định tuyến toàn bộ Traffic (Reverse Proxy) sang Core Java
const { fixRequestBody } = require('http-proxy-middleware');

// LƯU Ý QUAN TRỌNG:
// Ta KHÔNG DÙNG app.use('/api', proxy) vì Express sẽ cắt mất chữ '/api' khỏi đường dẫn trước khi ném cho Java (gây lỗi 404).
// Vì Traefik đã chắn ở ngoài và chỉ lùa request có /api vào đây, nên ta có thể dùng app.use('/', proxy) để giữ nguyên vẹn URL.
app.use('/', createProxyMiddleware({
    target: JAVA_BACKEND_URL,
    changeOrigin: true,
    logger: console, // Dùng console mặc định của thư viện cho các log nội bộ của nó
    // Do ta đã dùng express.json() ở trên để đọc body ghi log, 
    // ta phải fixRequestBody để gắn lại body vào stream trước khi ném cho Java
    on: {
        proxyReq: fixRequestBody,
        proxyRes: (proxyRes, req, res) => {
            logger.info('OUTGOING_RESPONSE', { 
                event: 'OUTGOING_RESPONSE',
                status_code: proxyRes.statusCode,
                url: req.originalUrl
            });
        },
        error: (err, req, res) => {
            logger.error('Lỗi khi kết nối Core Java', { error: err.message, url: req.originalUrl });
            res.status(502).json({ error: "Lỗi kết nối tới Core Backend!" });
        }
    }
}));

app.listen(PORT, () => {
    logger.info(`🚀 API Gateway (Node.js) đang chạy tại cổng ${PORT}`);
    logger.info(`🛡️  Luật Rate Limiter: ${ENABLE_RATE_LIMIT ? 'KÍCH HOẠT (10 req/phút)' : 'ĐÃ TẮT'}`);
    logger.info(`🔀 Định tuyến sang Core Java: ${JAVA_BACKEND_URL}`);
});
