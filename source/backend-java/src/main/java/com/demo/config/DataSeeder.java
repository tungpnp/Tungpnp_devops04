package com.demo.config;

import com.demo.model.User;
import com.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

// Mục đích: Khởi tạo tài khoản demo phục vụ kiểm thử khi app.demo.enabled=true
// Bảo mật: Không hardcode mật khẩu trong source code; nạp hoàn toàn từ biến môi trường / K8s Secret
@Component
public class DataSeeder implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Value("${app.demo.enabled:false}")
    private boolean demoEnabled;

    @Value("${app.demo.username:}")
    private String demoUsername;

    @Value("${app.demo.password:}")
    private String demoPassword;

    @Override
    public void run(String... args) {
        if (!demoEnabled || demoUsername.isBlank() || demoPassword.isBlank()) {
            return;
        }
        if (userRepository.findByUsername(demoUsername).isEmpty()) {
            User demoUser = new User();
            demoUser.setUsername(demoUsername);
            demoUser.setPassword(demoPassword);
            demoUser.setFullName("Tung PNP (DevOps Demo)");
            userRepository.save(demoUser);
            System.out.println("✅ Đã khởi tạo tài khoản demo từ cấu hình môi trường cho: " + demoUsername);
        }
    }
}
