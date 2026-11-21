package com.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.Instant;
import java.util.Map;

@SpringBootApplication
@RestController
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @GetMapping("/api/java/hello")
    public Map<String, String> hello() {
        return Map.of(
            "service", "Java Spring Boot (Core API)",
            "message", "Hello from Java Microservice!",
            "timestamp", Instant.now().toString()
        );
    }
}
