package com.onlinejudge.problem.dto;

import java.util.UUID;

public record ProblemSummaryDto(
    UUID id,
    String title,
    String level,
    String[] tags
) {}
