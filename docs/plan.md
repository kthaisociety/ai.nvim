# Ideas

## Infra
- ACP in Lua
- OpenCode or something similar
    i. Ideally, the system prompt should be customizable
    ii. Ideally, different agents/tasks could have different system prompts
    iii. The underlying agent system should be modular and not dictate the UI/workflow

## Like A Lot
1. Highlight sections of code (Visual Mode) to specify a targeted section for the agent to look at, explain, elaborate on, refactor, etc.
    i. The highlighted section becomes the primary context for the agent
    ii. Could be used for things like debugging, explaining, refactoring, optimization, test generation, etc.

2. Input the prompt through the command-line at the bottom.
    (Alternatively, use the prompt itself. I.e. "!!..." is a prompt and "!!?..." is some other type)

3. Input the prompt directly in the buffer.
    i. Write the prompt directly in the buffer
    ii. Highlight it
    iii. Hit `leader + <...>` to activate the agent
    iv. The plugin removes the prompt from the buffer and immediately uses it as the agent's prompt
    v. The agent starts in the background

4. Write pseudocode, highlight it, and hit `leader + r` to activate the agent and rewrite it as real code that fits the file. :fire:
    i. Use the current file's language, syntax, variables, functions, types, and coding conventions
    ii. Replace the pseudocode directly with the generated implementation

## A Bit More Controversial
1. Having a file-tree subset where only the files the agent(s) have modified/touched are shown
    i. Indicators showing which agent modified each file
    ii. A keybind to switch between the normal full file tree and the agent-specific subset
    iii. Could potentially group files by agent/task
    iv. Useful when multiple agents are working on different parts of the project

2. Using indicators at the bottom-right or top-right corner (i.e. `1`, `2`, `•`, blinking indicators) for different agents/tasks/threads
    i. `1`, `2`, `3`, etc. represent different agents/tasks/threads
    ii. A blinking dot or different indicator could show that an agent has finished or has something to report
    iii. `leader + 1, 2, 3, ...` to switch between which agent/task/thread you are currently prompting
    iv. The indicators should be small and unobtrusive so they do not interfere with the code

3. "Pop" a task and show a concise summary of the result from the agent/task/thread as a comment in the buffer instantly when it is finished
    i. `leader + p + 1, 2, 3, ...`
    ii. The result could appear as a comment at the cursor/directly in the current file?
    iii. Customizable level of conciseness
    iv. Could have several levels
    v. Could either use a separate stored summary that every agent/task/thread maintains, or use a lightweight model to summarize the conversation/output when requested?

4. Context management between chats/agents
    i. `leader + c + 1 + 2` → add the context of chat 1 to chat 2
    ii. `leader + c + 1 + <any other command>` → start a new chat using a compacted version of the context from chat 1
    iii. `leader + c + 1 + p` → write the compacted context of chat 1 into a new `.md` file
    iv. The compacted context could contain the goal, relevant files, decisions, what has been tried, current problems, and remaining tasks
    v. This would allow context to move between agents without manually copying and pasting long conversations

## Controversial Future
1. Dictation input
    i. Use voice/dictation as another way of entering prompts
