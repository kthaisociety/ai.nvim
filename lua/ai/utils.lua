local M = {}

local namespace = vim.api.nvim_create_namespace("kthais")

---@class ai.Selection
---@field buffer integer The buffer the selection came from
---@field mark_id integer Pass to nvim_buf_get_extmark_by_id to get mark
---@field mark? vim.api.keyset.get_extmark_item_by_id Result of nvim_buf_get_extmark_by_id
---@field mode "v"|"V"|"\22" Visual mode captured at request time
---@field left integer Left column used in visual block
---@field right integer Right column used in visual block

---Replace the marked region with an agent's output.
---@param lines string[] Agent output, split on newlines
---@param selection ai.Selection
---@return boolean ok True if the replacement was applied
function M.set_lines(lines, selection)
  local buffer = selection.buffer

  if not vim.api.nvim_buf_is_valid(buffer) then
    vim.notify("KTHAIS.set_lines: Cancelled due to invalid buffer", vim.log.levels.WARN)
    return false
  end

  local mark = vim.api.nvim_buf_get_extmark_by_id(buffer, namespace, selection.mark_id, { details = true })

  if mark[3].invalid then
    -- Do we want to cancel the AI call if the prompt was removed?
    vim.notify("KTHAIS.set_lines: Selection was entirely removed, cancelling", vim.log.levels.WARN)
    return false
  end

  if selection.mode == "v" then
    vim.api.nvim_buf_set_text(buffer, mark[1], mark[2], mark[3].end_row, mark[3].end_col, lines)
  elseif selection.mode == "V" then
    vim.api.nvim_buf_set_lines(buffer, mark[1], mark[3].end_row, false, lines)
  else -- visual block
    -- TODO: do we want VISUAL BLOCK selections at all? are there any use cases?
    local line_ranges = vim.fn.getregionpos(
      { buffer, mark[1] + 1, selection.mark[2], 0 },
      { buffer, mark[3].end_row, selection.mark[3].end_col, 0 },
      { type = selection.mode })
    if #line_ranges ~= #lines then
      -- TODO: How do we handle these cases?
      -- What do we call our plugin? KTHAIS-nvim-plugin? ai-nvim?
      vim.notify("KTHAIS.set_lines: Number of lines set does not match number of lines in selection", vim.log.levels
        .WARN)
      return false
    end
    local selection_left = selection.left - 1
    for i = 1, #line_ranges do
      local row = line_ranges[i][1][2] - 1
      local start_col = line_ranges[i][1][3] - 1
      local end_col = line_ranges[i][2][3]

      if line_ranges[i][1][3] == 0 then
        local line_width = #vim.api.nvim_buf_get_lines(buffer, row, row + 1, false)[1]
        local padding = (" "):rep(selection_left - line_width)
        vim.api.nvim_buf_set_text(buffer, row, start_col, row, start_col, { padding })
        start_col, end_col = selection_left, selection_left
      end

      vim.api.nvim_buf_set_text(buffer, row, start_col, row, end_col, { lines[i] })
    end
  end
  return true
end

return M
