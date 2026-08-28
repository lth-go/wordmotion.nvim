-- Core motion / text-object logic.
-- All functions take a `pats` table built by wordmotion.pattern.build.

local M = {}

--- Wrapper around `:normal!` for synchronous key execution from Lua.
local function normal(keys)
  vim.cmd("normal! " .. keys)
end

--- Check whether 'hor' is listed in 'foldopen'.
local function foldopen_hor()
  local fo = vim.o.foldopen or ""
  return fo == "hor"
    or fo:match("^hor[,]") ~= nil
    or fo:match("[, ]hor[,]") ~= nil
    or fo:match("[, ]hor$") ~= nil
end

--- Run `count` searches for `pattern` in the given direction.
--- @param pattern string  the regex pattern (already wrapped in \\%(...\\))
--- @param count integer   how many matches to consume
--- @param flags string    search flags ("", "e", "b", "be") plus "c" for cursor match
local function search_repeated(pattern, count, flags)
  local remaining = count
  while remaining > 0 do
    vim.fn.search("\\m" .. pattern, flags .. "W")
    remaining = remaining - 1
  end
end

--- If `dw` crossed into the next line, walk the cursor back to the newline
--- so the operator doesn't consume the newline and leading whitespace.
local function fix_dw_boundary(pats, mode, flags, pos_before)
  local is_dw = mode == "o" and vim.v.operator == "d" and flags == ""
  if not is_dw then
    return
  end
  local pos_after = vim.fn.getpos(".")
  if pos_before[2] >= pos_after[2] then
    return
  end
  if vim.fn.search("\\m\\n\\%(" .. pats.s .. "\\)*\\%#", "bW") == 0 then
    return
  end
  local dwpos = vim.fn.getpos(".")
  vim.fn.setpos(".", pos_before)
  normal("v")
  vim.fn.setpos(".", dwpos)
end

--- If the cursor didn't move (no more matches), jump to the start of the
--- first line (for backward-end motion like `ge`) or the end of the last
--- line (for forward motion like `w`).
local function fix_eof(pos_before, flags, mode)
  if not vim.deep_equal(pos_before, vim.fn.getpos(".")) then
    return
  end
  if flags == "be" and vim.fn.line(".") == 1 then
    normal("0")
  elseif flags == "" and vim.fn.line(".") == vim.fn.line("$") then
    if mode == "o" then
      normal("v")
    end
    normal("$")
  end
end

--- Open the fold under the cursor if 'hor' is in 'foldopen'.
local function maybe_open_fold(actual_mode)
  if (actual_mode == "n" or actual_mode == "x") and foldopen_hor() then
    normal("zv")
  end
end

--- Move the cursor by searching for word/space patterns.
---
--- @param pats table        patterns built by wordmotion.pattern.build
--- @param count integer      repeat count (from v:count1)
--- @param mode string        "n" | "x" | "o" — the calling mapping's mode
--- @param flags string       search direction: "" forward, "e" end, "b" backward, "be" backward-end
--- @param extra string[]?    additional search alternatives (used by text objects for space runs)
--- @param actual_mode string? override for fold-open logic (defaults to `mode`)
function M.motion(pats, count, mode, flags, extra, actual_mode)
  actual_mode = actual_mode or mode
  flags = flags or ""

  -- cw special case: `cw` acts like `ce` (see :help cw).
  -- Must be detected before the visual/inclusive setup because 'e' flag
  -- affects whether we enter visual mode in operator-pending mode.
  local cw = (mode == "o" and vim.v.operator == "c" and flags == "")
  if cw then
    flags = "e"
  end

  -- Visual mode: reselect last selection.
  -- Operator-pending with 'e' flag: enter visual mode so the motion is inclusive.
  if mode == "x" then
    normal("gv")
  elseif mode == "o" and flags:find("e") then
    normal("v")
  end

  -- Build the OR'd search pattern.
  -- For non-'e' motions, also match empty lines so w/b stop on blank lines.
  local words = vim.deepcopy(extra or {})
  words[#words + 1] = pats.word
  if flags ~= "e" then
    words[#words + 1] = "^$"
  end
  local pattern = "\\%(" .. table.concat(words, "\\|") .. "\\)"

  local pos = vim.fn.getpos(".")

  -- cw: first search accepts a match at the cursor (the 'c' flag),
  -- then count is decremented so we don't skip the current word.
  if cw then
    vim.fn.search("\\m" .. pattern, flags .. "cW")
    search_repeated(pattern, count - 1, flags)
  else
    search_repeated(pattern, count, flags)
  end

  fix_dw_boundary(pats, mode, flags, pos)
  fix_eof(pos, flags, mode)
  maybe_open_fold(actual_mode)
end

--- Set up visual mode for a text object, detecting existing selections.
--- @return boolean, string  (has_existing_selection, search_flags)
local function setup_visual_for_object(mode)
  if mode ~= "x" then
    return false, "e"
  end

  normal("gv")

  -- No existing selection: exit the (empty) visual mode.
  if vim.deep_equal(vim.fn.getpos("'<"), vim.fn.getpos("'>")) then
    local vm = vim.fn.visualmode()
    if vm and vm ~= "" then
      normal(vm)
    end
    return false, "e"
  end

  -- Existing selection: check if cursor is at the start ('<) → search backward.
  local start = vim.fn.getpos(".")
  if vim.deep_equal(start, vim.fn.getpos("'<")) then
    return true, "b"
  end
  return true, "e"
end

--- Select a text object (aw/iw, both behave as "inner word").
---
--- @param pats table     patterns built by wordmotion.pattern.build
--- @param count integer   repeat count (from v:count1)
--- @param mode string     "x" | "o"
function M.object(pats, count, mode)
  local extra = { pats.s .. "\\+" }

  local existing_selection, flags = setup_visual_for_object(mode)

  -- First word: find word start (backward), enter visual mode, find word end (forward).
  if not existing_selection then
    M.motion(pats, 1, "n", "bc", extra, mode)
    normal("v")
    M.motion(pats, 1, "n", "ec", extra, mode)
    count = count - 1
  end

  -- Remaining count: extend the selection in the determined direction.
  if count > 0 then
    M.motion(pats, count, "n", flags, extra, mode)
  end
end

return M
