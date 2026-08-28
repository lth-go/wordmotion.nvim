-- Create all word-motion keymaps (w/e/b/ge/aw/iw).
-- Tracks created maps so that a subsequent setup() can clear them first.

local M = {}

-- Maps each motion name to its search-flags counterpart.
local map_flags = { w = "", e = "e", b = "b", ge = "be" }

-- Track every mapping we created, so the next setup() can delete them.
local created = {}

-- Delete all mappings created by the previous apply() call.
local function clear()
  for _, m in ipairs(created) do
    pcall(vim.keymap.del, m.mode, m.lhs)
  end
  created = {}
end

--- Create every mapping described by `opts`.
--- Clears any mappings from a previous call first.
--- @param opts table      merged user config
--- @param do_motion fun(count:integer, mode:string, flags:string, extra:table?)
--- @param do_object fun(count:integer, mode:string)
function M.apply(opts, do_motion, do_object)
  clear()

  -- Motion mappings: w/e/b/ge in n/x/o modes.
  local motions = { "w", "e", "b", "ge" }
  for _, m in ipairs(motions) do
    local lhs = opts.mappings[m]
    if not lhs or lhs == "" then
      goto continue
    end
    local flag = map_flags[m] or ""
    for _, mode in ipairs({ "n", "x", "o" }) do
      vim.keymap.set(mode, lhs, function()
        do_motion(vim.v.count1, mode, flag, {})
      end, { silent = true })
      created[#created + 1] = { mode = mode, lhs = lhs }
    end
    ::continue::
  end

  -- Text-object mappings: aw/iw in x/o modes.
  local obj_motions = { "aw", "iw" }
  for _, m in ipairs(obj_motions) do
    local lhs = opts.mappings[m]
    if not lhs or lhs == "" then
      goto continue
    end
    for _, mode in ipairs({ "x", "o" }) do
      vim.keymap.set(mode, lhs, function()
        do_object(vim.v.count1, mode)
      end, { silent = true })
      created[#created + 1] = { mode = mode, lhs = lhs }
    end
    ::continue::
  end
end

return M
