local M = {}

-- closure of a running process and RPC ops
---@param cmd string[]
---@param on_msg fn(method: string, params: table?): table?
---@param on_exit? fun(code: integer, signal: integer) called after the process ends
function M.init(cmd, on_msg, on_exit)
	local proc, id, pending, buf = nil, 0, {}, ""

	-- helper to write JSON RPC to process stdin
	local function send(msg)
		msg.jsonrpc = "2.0"
		proc:write(vim.json.encode(msg) .. "\n")
	end

	local function request(method, params, callback)
		id = id + 1
		pending[id] = callback
		send({ id = id, method = method, params = params })
	end

	local function notify(method, params)
		send({ method = method, params = params })
	end

	local function handle(line)
		local ok, msg = pcall(
			vim.json.decode,
			line,
			{ luanil = { object = true, array = true } }
		)
		if not ok then
			-- should log here
			return
		end

		if msg.method then
			local res = on_msg(msg.method, msg.params)
			-- unhandled (ACP requires)
			if msg.id and res == nil then
				send({
					id = msg.id,
					error = { code = -32601, message = "Method not found" },
				})
			elseif msg.id then
				send({ id = msg.id, result = res })
			end
		elseif pending[msg.id] then
			local callback = pending[msg.id]
			pending[msg.id] = nil
			callback(msg.result, msg.error)
		end
	end

	-- kill the process
	local function stop()
		if proc then
			proc:kill(15)
			proc = nil
		end
	end

	-- initialize the process
	proc = vim.system(cmd, {
		stdin = true,
		stdout = function(_, data)
			if not data then
				return
			end
			local lines = vim.split(buf .. data, "\n", { plain = true })
			buf = table.remove(lines) -- store anything incomplete after \n in the buffer
			for _, line in ipairs(lines) do
				vim.schedule(function()
					handle(line)
				end)
			end
		end,
	}, function(out)
		vim.schedule(function()
			-- unanswered requests would otherwise never complete
			for _, callback in pairs(pending) do
				callback(nil, { code = -32000, message = "process exited" })
			end
			pending = {}
			if on_exit then
				on_exit(out.code, out.signal)
			end
		end)
	end)

	return {
		request = request,
		notify = notify,
		stop = stop,
	}
end

return M
