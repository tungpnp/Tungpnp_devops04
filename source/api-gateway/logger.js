const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const fs = require('fs');
const path = require('path');

// Đảm bảo thư mục log tồn tại
const logDirectory = process.env.LOG_DIR || '/app/logs';
if (!fs.existsSync(logDirectory)) {
    fs.mkdirSync(logDirectory, { recursive: true });
}

// Cấu hình định dạng log (Chỉ dùng JSON để dễ phân tích trên hệ thống lớn)
const logFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
    winston.format.json()
);

// Cấu hình xoay vòng file log hằng ngày
const fileTransport = new DailyRotateFile({
    filename: path.join(logDirectory, 'api-gateway-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true, // Nén file cũ cho nhẹ ổ cứng
    maxSize: '20m',      // Cắt file nếu vượt quá 20MB
    maxFiles: '14d'      // Giữ log tối đa 14 ngày
});

const logger = winston.createLogger({
    level: 'info',
    format: logFormat,
    transports: [
        fileTransport,
        // Vẫn in ra Console để gõ kubectl logs còn thấy được
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.printf(({ timestamp, level, message, ...meta }) => {
                    return `[${timestamp}] ${level}: ${message} ${Object.keys(meta).length ? JSON.stringify(meta) : ''}`;
                })
            )
        })
    ]
});

module.exports = logger;
