# More useful word motions for Neovim

A Lua rewrite of [vim-wordmotion](https://github.com/chaoren/vim-wordmotion) for Neovim.

Vim treats `CamelCaseACRONYMWords_underscore1234` as one word. This plugin splits it into six words:

```
CamelCaseACRONYMWords_underscore1234
w--->w-->w----->w--->w--------->w->w
e-->e-->e----->e--->e--------->e-->e
b<---b<--b<-----b<----b<--------b<-b
```

## Word definition

A `word` is any of:

| Type             | Example               |
| :--------------- | :-------------------- |
| CamelCase        | `[Camel][Case]`       |
| Acronyms         | `[HTML]And[CSS]`      |
| Uppercase        | `[UPPERCASE]`         |
| Lowercase        | `[lowercase]`         |
| Hex color codes  | `[#0f0f0f]`           |
| Hex literals     | `[0x00ffFF]`          |
| Octal literals   | `[0o644]`             |
| Binary literals  | `[0b01]`              |
| Numbers          | `[1234]`              |
| Other printable  | `[~!@#$]`             |

Default space characters (where `w` stops):
1. Whitespace
2. Hyphens (`-`) between alphabetic characters
3. Underscores (`_`) between alphanumeric characters

## Installation

### lazy.nvim

```lua
{
  "lth-go/wordmotion.nvim",
  lazy = false,
  opts = {},
}
```

### Manual

```lua
require("wordmotion").setup()
```

## Configuration

```lua
require("wordmotion").setup({
  mappings = {
    ["w"] = "<M-w>",
    ["e"] = "<M-e>",
    ["b"] = "<M-b>",
    ["ge"] = "g<M-e>",
    ["aw"] = "a<M-w>",
    ["iw"] = "i<M-w>",
  },
})
```

### Default mappings

| Mode | Motion   | Description            |
| :--: | :------- | :--------------------- |
| nxo  | `<M-w>`  | Forward word motion    |
| nxo  | `<M-e>`  | Forward end of word    |
| nxo  | `<M-b>`  | Backward word motion   |
| nxo  | `g<M-e>` | Backward end of word   |
| xo   | `a<M-w>` | A word text object     |
| xo   | `i<M-w>` | Inner word text object |

### Custom mappings

Override any default mapping by setting its value. Set to `""` to disable.

```lua
require("wordmotion").setup({
  mappings = {
    ["w"] = "<Leader>w",
    ["e"] = "<Leader>e",
    ["b"] = "<Leader>b",
    ["ge"] = "<Leader>ge",
    ["iw"] = "i<Leader>w",
    ["aw"] = "a<Leader>w",
  },
})
```

### Disable specific mappings

```lua
require("wordmotion").setup({
  mappings = {
    ["w"] = "",   -- disabled
    ["e"] = "",   -- disabled
  },
})
```
