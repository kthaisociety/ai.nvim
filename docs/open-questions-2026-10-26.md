Answers are in __bold__ after a question which has been answered.

### Open questions
- Should AgentReplace only be able to replace the selected text but be able to use any
read tool calls as it wants? __Yes__
    - Should AgentReplace be a tool call on its own or should it only use the returned
    response as replacement text. __Returned response as replacement__
- Do we need to define our own fs/read_text_file tool? (Non-saved buffers will not be findable by opencode fs/read) __Potentially in the future__
- Need some way to declare allowed tools for a given prompt. __Cababilities/permissions yes__
- How do we cancel a request? dd on a virtual text showing progress? undo (u)? delete the prompt?
- Should VISUAL BLOCK be supported for AgentReplace? __Not yet__
    - It should be supported for extracting text in the selection to be used as agent context
    for commands other than AgentReplace (AgentExplain, AgentImplement, etc.) __Yes__
- What commands do we want?
    - AgentReplace? Full read access, only modify current selection __Yes__
    - AgentExplain? Full read access, somehow show explaination __Yes__
    - AgentImplement? Full read access, full write access (but also include a selection for agent's main focus) __Yes__
- A selection can be either manual (v, V, CTRL-V) or use the current treesitter node (function, class, etc...)?
    - Should the treesitter context be a separate command or should only visual selections
    count as a selection and treesitter selections can be done with something like `vaf` (nvim-treesitter-textobjects ).

