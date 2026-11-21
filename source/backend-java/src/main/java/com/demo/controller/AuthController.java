package com.demo.controller;

import com.demo.dto.LoginRequest;
import com.demo.dto.LoginResponse;
import com.demo.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@CrossOrigin(origins = "*") // CHÚ Ý: Cho phép mọi frontend (như React ở cổng 3000) gọi vào API này mà không bị lỗi CORS
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    // API: POST http://localhost:8080/api/v1/auth/login
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        log.info("Nhận được HTTP Request POST /api/v1/auth/login từ client");
        try {
            LoginResponse response = authService.authenticateUser(loginRequest);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(401).body(e.getMessage()); // Lỗi 401 Unauthorized
        }
    }
}
