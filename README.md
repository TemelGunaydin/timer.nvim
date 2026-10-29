<p align="center">
  <img src="./asset/logo.png" alt="timer.nvim logo: a green stopwatch with a terminal prompt" width="180" height="180" />
</p>

<h1 align="center">timer.nvim</h1>

Minimal Neovim plugin that lets you start short timers from anywhere inside the editor, pick predefined durations from a centered floating window, and check how much time remains without leaving your buffer.

## Features
- Floating picker that appears in the middle of the screen with configurable durations (`5`, `10`, `30`, `45`, `60` minutes by default).
- Remaining-time popup (`TimerRemaining`) with mm:ss readout and a reset shortcut.
- Notifications when the timer starts or finishes.
- Fully written in Lua, no external dependencies beyond a recent Neovim (0.8+) with `vim.ui` and floating-window support.

## Installation (Lazy.nvim)

```lua
{
  "temelgunaydin/timer.nvim",
  config = function()
    require("timer").setup({
      options = { 5, 10, 30, 45, 60 }, -- customize durations
      open_keymap = "<leader>tt",      -- open picker
      remaining_keymap = "<leader>tr", -- show remaining time popup
    })
  end,
}
```

### Packer.nvim
```lua
use({
  "temelgunaydin/timer.nvim",
  config = function()
    require("timer").setup()
  end,
})
```

## Usage
- `:TimerPick` or the `open_keymap` (default `<leader>tt`) opens the centered picker. Press `1`, `2`, `3`, … or use `<CR>` to start a timer.
- `:TimerRemaining` or `remaining_keymap` (default `<leader>tr`) shows the remaining time popup; press `r` to reset the timer, or close the popup with `q`, `<Esc>`, or `<CR>`.
- Notifications announce when a timer starts and finishes.

### Configuration Options
| Option             | Type            | Default           | Description                                 |
|--------------------|-----------------|-------------------|---------------------------------------------|
| `options`          | table           | `{5,10,30,45,60}`  | List of minute values shown in the picker.   |
| `open_keymap`      | string or false | `"<leader>tt"`    | Normal-mode mapping to open the picker.      |
| `remaining_keymap` | string or false | `"<leader>tr"`    | Mapping to show the remaining time popup.    |
| `keymap`           | string or false | `nil`             | Backwards-compatible alias for `open_keymap`.|

Set a keymap option to `false` to skip creating that mapping. Leave options unset or `nil` to use the defaults or legacy `keymap` alias. An explicit `open_keymap` takes precedence over `keymap`, including when set to `false`. The commands remain available when keymaps are disabled.

## Commands
- `:TimerPick` – open the duration picker.
- `:TimerRemaining` – show remaining time for the active timer.

## Screenshots
<p align="center">
  <img src="./asset/1.jpg" alt="timer.nvim picker" width="420" />
</p>

<p align="center">
  <img src="./asset/2.jpg" alt="timer.nvim remaining time popup" width="420" />
</p>

## Contributing
Bug reports and PRs are welcome.

Run the keymap regression checks in Neovim without loading your personal configuration:

```sh
nvim --headless -u NONE -i NONE -c "lua dofile('tests/keymaps.lua')" -c 'qa!'
```

## License
MIT © Temel Gunaydin

