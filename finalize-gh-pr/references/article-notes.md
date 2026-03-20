# Notes Adapted from the Anduril Skill Guide

Source used: Fox Hsiao's translation of Thariq Shihipar's article, "打造 Claude Code 的經驗：我們如何使用 Skills（翻譯）", published on March 18, 2026.
Link: https://www.anduril.tw/claude-code-skills-guide/

## What changed in this skill because of that article

### 1. Keep the main skill concise

The article argues against wasting context on things the model already knows. This skill now keeps `SKILL.md` focused on the workflow, gotchas, and triggering conditions.

### 2. Make `description` trigger-oriented

The article stresses that `description` is for the model, not for humans. This skill's frontmatter now describes when the skill should trigger, not just what it is.

### 3. Add a `Gotchas` section

The article says the highest-signal part of many skills is the accumulated list of common failure modes. This skill now includes a dedicated `Gotchas` section.

### 4. Use progressive disclosure

The article recommends using the filesystem as context engineering. This skill keeps the primary instructions in `SKILL.md` and moves supporting heuristics into reference files.

### 5. Avoid over-constraining the model

The article warns against making reusable skills too rigid. This skill gives a default PR-finalization workflow, but still leaves room to choose between 1, 2, or 3 semantic commits depending on reviewability.

## Relevant takeaways for PR-finalization skills

- Center the story on the final shipped behavior.
- Preserve reusable heuristics and common failure modes.
- Put only the highest-signal operational steps in the main skill file.
- Use references for supporting principles rather than overloading the main instructions.
- Treat skill iteration as ongoing: when new PR cleanup mistakes appear, add them to `Gotchas`.
