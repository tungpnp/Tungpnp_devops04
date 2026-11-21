package com.demo.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class KafkaProducerService {

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    private static final String TOPIC_NAME = "user_activity";

    public void sendLoginEvent(String username) {
        // Đóng gói data dạng chuỗi JSON đơn giản
        String eventPayload = String.format("{\"username\": \"%s\", \"action\": \"LOGIN\", \"timestamp\": \"%s\"}", 
                                             username, Instant.now().toString());
        
        // Bắn lên Kafka
        kafkaTemplate.send(TOPIC_NAME, username, eventPayload);
        
        log.info("🚀 [KAFKA] Đã bắn sự kiện đăng nhập của user: {}", username);
    }
}
