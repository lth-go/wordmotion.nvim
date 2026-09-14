-- wordmotion: more useful word motions for Neovim.
--
-- A `word` is any of: CamelCase, ACRONYM, lowercase, hex color codes,
-- hex/oct/bin literals, regular numbers, or other printable chars.
--
-- Usage (lazy.nvim):
--   { "lth-go/wordmotion.nvim", opts = { mappings = { ["w"] = "<M-w>" } } }
--
-- Or explicit:
--   require("wordmotion").setup({ mappings = { ["w"] = "<M-w>" } })

local config = require("wordmotion.config")
local pattern = require("wordmotion.pattern")
local mapping = require("wordmotion.mapping")
local motion = require("wordmotion.motion")

local M = {}

--- Initialise the plugin: merge user opts, build patterns, create keymaps.
--- Calling setup() again will first delete all previously created keymaps.
--- @param user_opts table?  overrides for defaults (see config.lua)
function M.setup(user_opts)
  local opts = vim.tbl_deep_extend("force", vim.deepcopy(config.defaults), user_opts or {})
  local pats = pattern.build()
  mapping.apply(opts, function(count, mode, flags, extra)
    motion.motion(pats, count, mode, flags, extra)
  end, function(count, mode)
    motion.object(pats, count, mode)
  end)
  return M
end

return M
