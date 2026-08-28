-- Default configuration for wordmotion.
-- Users override these via require("wordmotion").setup({ ... }).
local M = {}

M.defaults = {
  mappings = {
    ["w"] = "<M-w>",
    ["e"] = "<M-e>",
    ["b"] = "<M-b>",
    ["ge"] = "g<M-e>",
    ["aw"] = "a<M-w>",
    ["iw"] = "i<M-w>",
  },
}

return M
