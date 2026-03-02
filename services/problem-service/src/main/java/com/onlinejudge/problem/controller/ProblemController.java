package com.onlinejudge.problem.controller;

import com.onlinejudge.problem.dto.ProblemDetailDto;
import com.onlinejudge.problem.dto.ProblemSummaryDto;
import com.onlinejudge.problem.entity.Problem;
import com.onlinejudge.problem.repository.ProblemRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/problems")
@Tag(name = "Problems", description = "Browse coding problems")
public class ProblemController {

    private final ProblemRepository problemRepository;

    public ProblemController(ProblemRepository problemRepository) {
        this.problemRepository = problemRepository;
    }

    @GetMapping
    @Operation(summary = "List all problems", description = "Returns all problems with summary info.")
    public List<ProblemSummaryDto> listProblems() {
        return problemRepository.findAll().stream()
                .map(p -> new ProblemSummaryDto(p.getId(), p.getTitle(), p.getLevel(), p.getTags()))
                .toList();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get problem detail", description = "Returns full problem with question and code stubs.")
    public ResponseEntity<ProblemDetailDto> getProblem(@PathVariable UUID id) {
        return problemRepository.findById(id)
                .map(p -> ResponseEntity.ok(new ProblemDetailDto(
                        p.getId(), p.getTitle(), p.getQuestion(),
                        p.getLevel(), p.getTags(), p.getCodeStubs())))
                .orElse(ResponseEntity.notFound().build());
    }
}
