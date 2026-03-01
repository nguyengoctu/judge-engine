package com.onlinejudge.gateway.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI gatewayOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Online Judge API Gateway")
                .version("1.0.0")
                .description("API Gateway routing requests to Problem Service and Submission Service")
                .contact(new Contact()
                    .name("Online Judge Team")))
            .servers(List.of(
                new Server().url("http://localhost:8080").description("Local")));
    }
}
