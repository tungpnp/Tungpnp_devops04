package com.demo.service;

import com.demo.dto.LoginRequest;
import com.demo.dto.LoginResponse;
import com.demo.model.User;
import com.demo.repository.UserRepository;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.util.Date;
import java.util.Optional;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private KafkaProducerService kafkaProducerService;

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpirationMs;

    public LoginResponse authenticateUser(LoginRequest request) {
        // 1. Tìm user trong Database
        Optional<User> userOpt = userRepository.findByUsername(request.getUsername());

        // 2. Kiểm tra tài khoản và mật khẩu
        if (userOpt.isPresent() && userOpt.get().getPassword().equals(request.getPassword())) {
            User user = userOpt.get();
            log.info("Xác thực thành công cho user: {}", user.getUsername());
            
            // 3. Đăng nhập thành công -> Sinh Token
            log.debug("Bắt đầu khởi tạo JWT Token cho user: {}", user.getUsername());
            String token = generateJwtToken(user.getUsername());
            
            // 4. Bắn sự kiện lên Kafka chạy ngầm
            kafkaProducerService.sendLoginEvent(user.getUsername());

            return new LoginResponse(token, user.getFullName(), "Đăng nhập thành công!");
        }
        
        // Đăng nhập thất bại
        log.error("Cảnh báo bảo mật: Phát hiện đăng nhập thất bại với username: {}", request.getUsername());
        throw new RuntimeException("Sai tên đăng nhập hoặc mật khẩu!");
    }

    private String generateJwtToken(String username) {
        Key key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(new Date())
                .setExpiration(new Date((new Date()).getTime() + jwtExpirationMs))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }
}
