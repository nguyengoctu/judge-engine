package com.onlinejudge.problem.dto;

import java.util.Map;
import java.util.UUID;

public record ProblemDetailDto(
    UUID id,
    String title,
    String question,
    String level,
    String[] tags,
    Map<String, String> codeStubs
) {}
