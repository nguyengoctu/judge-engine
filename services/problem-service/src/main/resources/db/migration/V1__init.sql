CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE problems (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title       VARCHAR(255) NOT NULL,
    question    TEXT NOT NULL,
    level       VARCHAR(20) NOT NULL CHECK (level IN ('easy', 'medium', 'hard')),
    tags        TEXT[] DEFAULT '{}',
    code_stubs  JSONB NOT NULL DEFAULT '{}',
    test_cases  JSONB NOT NULL DEFAULT '[]',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_problems_level ON problems(level);
CREATE INDEX idx_problems_tags ON problems USING GIN(tags);

CREATE TABLE submissions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         VARCHAR(255) NOT NULL,
    problem_id      UUID NOT NULL REFERENCES problems(id),
    code            TEXT NOT NULL,
    language        VARCHAR(50) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    results         JSONB,
    execution_time  INTEGER,
    memory_used     INTEGER,
    competition_id  UUID,
    submitted_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_submissions_user_id ON submissions(user_id);
CREATE INDEX idx_submissions_problem_id ON submissions(problem_id);
CREATE INDEX idx_submissions_status ON submissions(status);
CREATE INDEX idx_submissions_competition_id ON submissions(competition_id);

CREATE TABLE competitions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    start_time  TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time    TIMESTAMP WITH TIME ZONE NOT NULL,
    problem_ids UUID[] NOT NULL DEFAULT '{}',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE submissions
    ADD CONSTRAINT fk_submissions_competition
    FOREIGN KEY (competition_id) REFERENCES competitions(id);

-- Seed data
INSERT INTO problems (title, question, level, tags, code_stubs, test_cases) VALUES
(
    'Two Sum',
    'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target. You may assume that each input would have exactly one solution, and you may not use the same element twice.',
    'easy',
    ARRAY['array', 'hash-table'],
    '{"python": "class Solution:\n    def twoSum(self, nums: list[int], target: int) -> list[int]:\n        pass", "javascript": "function twoSum(nums, target) {\n    // your code here\n}", "java": "class Solution {\n    public int[] twoSum(int[] nums, int target) {\n        // your code here\n    }\n}"}',
    '[{"input": {"nums": [2,7,11,15], "target": 9}, "expected": [0,1]}, {"input": {"nums": [3,2,4], "target": 6}, "expected": [1,2]}, {"input": {"nums": [3,3], "target": 6}, "expected": [0,1]}]'
),
(
    'FizzBuzz',
    'Given an integer n, return a string array answer (1-indexed) where: answer[i] == "FizzBuzz" if i is divisible by 3 and 5, answer[i] == "Fizz" if i is divisible by 3, answer[i] == "Buzz" if i is divisible by 5, answer[i] == i (as a string) if none of the above conditions are true.',
    'easy',
    ARRAY['string', 'math'],
    '{"python": "class Solution:\n    def fizzBuzz(self, n: int) -> list[str]:\n        pass", "javascript": "function fizzBuzz(n) {\n    // your code here\n}", "java": "class Solution {\n    public List<String> fizzBuzz(int n) {\n        // your code here\n    }\n}"}',
    '[{"input": {"n": 3}, "expected": ["1","2","Fizz"]}, {"input": {"n": 5}, "expected": ["1","2","Fizz","4","Buzz"]}, {"input": {"n": 15}, "expected": ["1","2","Fizz","4","Buzz","Fizz","7","8","Fizz","Buzz","11","Fizz","13","14","FizzBuzz"]}]'
),
(
    'Valid Parentheses',
    'Given a string s containing just the characters ''('', '')'', ''{'', ''}'', ''['' and '']'', determine if the input string is valid. An input string is valid if: Open brackets must be closed by the same type of brackets. Open brackets must be closed in the correct order. Every close bracket has a corresponding open bracket of the same type.',
    'easy',
    ARRAY['string', 'stack'],
    '{"python": "class Solution:\n    def isValid(self, s: str) -> bool:\n        pass", "javascript": "function isValid(s) {\n    // your code here\n}", "java": "class Solution {\n    public boolean isValid(String s) {\n        // your code here\n    }\n}"}',
    '[{"input": {"s": "()"}, "expected": true}, {"input": {"s": "()[]{}"}, "expected": true}, {"input": {"s": "(]"}, "expected": false}, {"input": {"s": "([)]"}, "expected": false}]'
);
