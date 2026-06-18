package com.inspection.logbackend.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/logs")
public class LogController {

    private static final Logger log = LoggerFactory.getLogger(LogController.class);

    @PostMapping
    public ResponseEntity<Void> receiveLogs(@RequestBody String body) {
        log.info("Received logs: {}", body);
        return ResponseEntity.ok().build();
    }
}
