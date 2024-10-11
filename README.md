# Nōdus

<!--
Q: What the fuck is a "Nōdus"?
A: Latin for "node", fancy name
   for a plugin that connects
   things. Was more fun in my
   head.

I know nobody will ever read this, but if you do
then you get a star or something. I don't know.
-->

[![Neovim 0.10.1](https://img.shields.io/badge/Neovim-0.10.1-blueviolet.svg?logo=Neovim&logoColor=green)](https://neovim.io/)

A personal Neovim plugin to highlight & open links that match my criteria of a
valid link.

For a while now, I have been placing external URLs in any documentation I write
in the form of `<https://...>` as a stylistic choice, and as a mental reminder
that I can visit this page. This is a Neovim plugin that complements this choice
by highlighting and providing and open function for any links that contain valid
protocol prefixes (or scheme identifiers if you want to be pedantic) such as
`http://` or `https://` that are also surrounded in `< >`.

You _probably_ don't need this plugin, but if you do end up using it I
appreciate your feedback.

## Usage

Call `:lua require('nodus').open_link_under_cursor()` manually or with a keybind
to open the link under your cursor with your preferred link opener. This
defaults to `xdg-open`, but it can be changed in the setup table.

### How does matching work?

In short, links that start with a valid protocol prefix (http://, https://,
etc.) that are also inside `< >` will match.

```nix
# This should match.
# <https://sample.com>

# This should not match.
# https://sample.com
```

## Setup

```lua
-- Call the setup function. Follow your own package manager's instructions
-- if you use something like Lazy for loading plugins.
require("nodus").setup()
```

### Available configuration options:

```lua
{
    protocols = { "http://", "https://" },  -- default protocols to match, you can add your protocols here (e.g. "gemini://")
    highlight_group = "NodusLinkHighlight", -- highlight group for matching links
    ft = { "text", "md", "markdown" }       -- file types for which matching will be enabled
}
```

> [!TIP]
> Nodus now uses `vim.ui.open` to use your system's file opener. You will be
> able to open links _as long as_ Neovim has access to your file opener. Hurray
> for platform support!

### Highlighting

Nodus attempts to highlight matching links to help you identify valid links that
can be opened. By default, it will use the highlights for the
`NodusLinkHighlight` group and underline any matching links. You can modify the
group name or the highlights as per your preferences.

#### Example

```lua
-- Underline and red text.
vim.api.nvim_command("highlight NodusLinkHighlight gui=underline guifg=#ff0000")
```

### Registering a Keybind

Nodus does not register any keybinds, and expects the user to do so by
themselves. Below is an example of how you may choose to register your own
keybind to open matching links under the cursor:

```lua
vim.api.nvim_set_keymap("n", "<leader>ol", ":lua require('nodus').open_link_under_cursor()<CR>", {
    noremap = true, silent = true
})
```

You can call `open_link_under_cursor()` function however you want to open the
link.

## Contributing

Always welcome.

## License

This repository is licensed under the [MIT license](LICENSE).
