package com.onlinejudge.problem.config;

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
    public OpenAPI problemServiceOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Problem Service API")
                .version("1.0.0")
                .description("CRUD operations for coding problems, code stubs, and test cases")
                .contact(new Contact()
                    .name("Online Judge Team")))
            .servers(List.of(
                new Server().url("http://localhost:8081").description("Direct"),
                new Server().url("http://localhost:8080").description("Via API Gateway")));
    }
}
