package com.inspection.logbackend.controller;

import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/logs")
@Slf4j
public class LogController {


    @PostMapping
    public ResponseEntity<Void> receiveLogs(@RequestBody String body) {
        log.info("Received logs: {}", body);
        return ResponseEntity.ok().build();
    }
}
