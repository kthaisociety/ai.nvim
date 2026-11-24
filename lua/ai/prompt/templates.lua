local prompt = require("ai.prompt")

local M = {}

M.replace = prompt.clause(
	"system_message",
	"Replace the above text. Respond with exactly what replaces."
)

M.explain = prompt.clause(
	"system_message",
	"Explain the above text concisely. Only respond with the explanation, don't come up with a plan."
)

return M
