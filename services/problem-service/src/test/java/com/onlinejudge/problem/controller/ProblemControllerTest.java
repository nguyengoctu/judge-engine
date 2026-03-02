package com.onlinejudge.problem.controller;

import com.onlinejudge.problem.entity.Problem;
import com.onlinejudge.problem.repository.ProblemRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.*;

import static org.hamcrest.Matchers.*;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ProblemController.class)
class ProblemControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ProblemRepository problemRepository;

    private Problem createProblem(String title, String level) {
        Problem p = new Problem();
        p.setId(UUID.randomUUID());
        p.setTitle(title);
        p.setQuestion("Sample question");
        p.setLevel(level);
        p.setTags(new String[]{"array"});
        p.setCodeStubs(Map.of("python", "# code here"));
        return p;
    }

    @Test
    void listProblems_shouldReturnAll() throws Exception {
        given(problemRepository.findAll()).willReturn(List.of(
                createProblem("Two Sum", "easy"),
                createProblem("Valid Parentheses", "easy")
        ));

        mockMvc.perform(get("/api/problems"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].title", is("Two Sum")))
                .andExpect(jsonPath("$[0].level", is("easy")))
                .andExpect(jsonPath("$[0].question").doesNotExist());
    }

    @Test
    void getProblem_found_shouldReturnDetail() throws Exception {
        Problem p = createProblem("Two Sum", "easy");
        given(problemRepository.findById(p.getId())).willReturn(Optional.of(p));

        mockMvc.perform(get("/api/problems/" + p.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title", is("Two Sum")))
                .andExpect(jsonPath("$.question", is("Sample question")))
                .andExpect(jsonPath("$.codeStubs.python", is("# code here")));
    }

    @Test
    void getProblem_notFound_shouldReturn404() throws Exception {
        UUID randomId = UUID.randomUUID();
        given(problemRepository.findById(randomId)).willReturn(Optional.empty());

        mockMvc.perform(get("/api/problems/" + randomId))
                .andExpect(status().isNotFound());
    }
}
