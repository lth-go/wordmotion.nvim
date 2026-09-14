-- Build Vim-regex patterns for word/space matching.
-- Called once at setup time; the returned table is closed over by the
-- motion functions in motion.lua.

local M = {}

local alpha = "[[:lower:][:upper:]]"
local alnum = "[[:lower:][:upper:][:digit:]]"
local ss = "[[:space:]]"
local digit = "[[:digit:]]"
local printable = "[[:print:]]"
local lower = "[[:lower:]]"
local upper = "[[:upper:]]"
local xdigit = "[[:xdigit:]]"

-- Join a list of patterns with \)\|\%( and wrap in \%(...\).
local function or_list(list)
  return "\\%(\\%(" .. table.concat(list, "\\)\\|\\%(") .. "\\)\\)"
end

-- Match `s` when it is "between" `w` chars:--   (w s*)\@<=  s  (s* w)\@=
local function between(s, w)
  local before = "\\%(" .. w .. s .. "*\\)\\@<="
  local after = "\\%(" .. s .. "*" .. w .. "\\)\\@="
  return before .. s .. after
end

-- Match a char in `set` that is NOT in any of `excludes`.
local function complement(set, ...)
  local excludes = { ... }
  return "\\%(\\%(" .. table.concat(excludes, "\\|") .. "\\)\\@!" .. set .. "\\)"
end

--- Build the core regex patterns.
--- @return table  { s = space-pattern, word = word-pattern }
function M.build()
  -- Default space characters: whitespace + hyphen-between-alpha + underscore-between-alnum.
  local hyphen = between("-", alpha)
  local underscore = between("_", alnum)
  local s = or_list({ ss, hyphen, underscore })

  local words = {}
  local function add(p)
    words[#words + 1] = p
  end
  add(upper .. lower .. "\\+") -- CamelCase
  add(upper .. "\\+" .. lower .. "\\@!") -- UPPERCASE
  add(lower .. "\\+") -- lowercase
  add("#" .. xdigit .. "\\+\\>") -- #0F0F0F
  add("\\<0[xX]" .. xdigit .. "\\+\\>") -- 0x00 0Xff
  add("\\<0[oO][0-7]\\+\\>") -- 0o00 0O77
  add("\\<0[bB][01]\\+\\>") -- 0b00 0B11
  add(digit .. "\\+") -- 1234 5678
  add(complement(printable, alnum, s, "#" .. xdigit) .. "\\+") -- other printable
  add("\\%^") -- start of file
  add("\\%$") -- end of file
  local word = or_list(words)

  return { s = s, word = word }
end

return M
