-- Plugin fonksiyonlarini tutacak ana tablo
local TimerPlugin = {}

-- Varsayilan dakika secenekleri
TimerPlugin.duration_options = { 5, 10, 30,45,60 }

-- Aktif timer bilgilerini saklayan durum tablosu
local state = {
  active_timer = nil,
  active_minutes = nil,
  popup_win = nil,
  popup_buf = nil,
  start_time = nil,
  end_time = nil,
  duration_ms = nil,
}

-- Kullaniciya bildirim gondermek icin yardimci fonksiyon
local function notify(message)
  vim.notify(message, vim.log.levels.INFO, { title = "Timer" })
end

-- Calisan timer'i temizlemek icin fonksiyon
local function clear_timer()
  if state.active_timer then
    state.active_timer:stop()
    state.active_timer:close()
  end
  state.active_timer = nil
  state.active_minutes = nil
  state.start_time = nil
  state.end_time = nil
  state.duration_ms = nil
end

local function close_popup()
  if state.popup_win and vim.api.nvim_win_is_valid(state.popup_win) then
    vim.api.nvim_win_close(state.popup_win, true)
  end

  if state.popup_buf and vim.api.nvim_buf_is_valid(state.popup_buf) then
    vim.api.nvim_buf_delete(state.popup_buf, { force = true })
  end

  state.popup_buf = nil
  state.popup_win = nil
end

local function open_centered_popup(lines)
  close_popup()

  local width = 0
  for _, line in ipairs(lines) do
    if #line > width then
      width = #line
    end
  end

  local height = #lines
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    vim.api.nvim_buf_delete(buf, { force = true })
    notify("Unable to read UI information")
    return nil, nil
  end

  local win_opts = {
    relative = "editor",
    width = width + 4,
    height = height,
    row = math.max(math.floor((ui.height - height) / 2), 0),
    col = math.max(math.floor((ui.width - (width + 4)) / 2), 0),
    style = "minimal",
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  state.popup_buf = buf
  state.popup_win = win

  return buf, win
end

-- Verilen dakika icin timer baslatan fonksiyon
function TimerPlugin.start(minutes)
  close_popup()
  clear_timer()

  local timer = vim.loop.new_timer()
  state.active_timer = timer
  state.active_minutes = minutes
  state.duration_ms = minutes * 60 * 1000
  state.start_time = vim.loop.now()
  state.end_time = state.start_time + state.duration_ms

  notify(string.format("Timer started: %d minutes", minutes))

  timer:start(state.duration_ms, 0, vim.schedule_wrap(function()
    notify(string.format("Timer finished: %d minutes", minutes))
    clear_timer()
  end))
end

function TimerPlugin.showRemainingTime()
  if not (state.active_timer and state.end_time) then
    notify("No active timer")
    close_popup()
    return
  end

  local now = vim.loop.now()
  local remaining_ms = math.max(state.end_time - now, 0)

  local remaining_minutes = math.floor(remaining_ms / 60000)
  local remaining_seconds = math.floor((remaining_ms % 60000) / 1000)
  
  local lines = {
    "Timer info",
    "",
    string.format("Total time  : %d min", state.active_minutes or 0),
    string.format("Remaining   : %02d:%02d", remaining_minutes, remaining_seconds),
    "",
    "q / <Esc> / <CR> : close",
  }

  local buf, win = open_centered_popup(lines)
  if not buf then
    return
  end

  local function close()
    close_popup()
  end

  local function map(lhs)
    vim.keymap.set("n", lhs, close, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
  end

  map("q")
  map("<Esc>")
  map("<CR>")

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = close,
  })
end

-- Kullanicinin sure secmesi icin arayuz acan fonksiyon
function TimerPlugin.pick_and_start()
  local options = TimerPlugin.duration_options

  if #options == 0 then
    notify("No timer options defined")
    return
  end

  local lines = { "Select a duration (minutes)", "" }
  for idx, minutes in ipairs(options) do
    table.insert(lines, string.format("%d. %d minutes", idx, minutes))
  end
  table.insert(lines, "")
  table.insert(lines, "q / <Esc> : cancel")

  local buf, win = open_centered_popup(lines)
  if not buf or not win then
    return
  end

  local function select_option(index)
    close_popup()

    local minutes = options[index]
    if minutes then
      TimerPlugin.start(minutes)
    else
      notify("Invalid choice")
    end
  end

  local function map(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
  end

  for index, _ in ipairs(options) do
    map(tostring(index), function()
      select_option(index)
    end)
  end

  map("<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_index = cursor[1] - 2
    if line_index >= 1 and line_index <= #options then
      select_option(line_index)
    end
  end)

  map("q", function()
    close_popup()
    notify("Selection cancelled")
  end)

  map("<Esc>", function()
    close_popup()
    notify("Selection cancelled")
  end)

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      close_popup()
    end,
  })
end

-- Plugin'i kullanici ayarlariyla hazirlayan setup fonksiyonu
function TimerPlugin.setup(opts)
  opts = opts or {}

  if opts.options then
    TimerPlugin.duration_options = opts.options
  end

  local menu_key = opts.open_keymap or opts.keymap or "<leader>tt"
  local remaining_key = opts.remaining_keymap or "<leader>tr"

  vim.api.nvim_create_user_command("TimerPick", TimerPlugin.pick_and_start, {})
  vim.api.nvim_create_user_command("TimerRemaining", TimerPlugin.showRemainingTime, {})

  if menu_key then
    vim.keymap.set("n", menu_key, TimerPlugin.pick_and_start, { desc = "Timer picker" })
  end

  if remaining_key then
    vim.keymap.set("n", remaining_key, TimerPlugin.showRemainingTime, { desc = "Timer remaining time" })
  end
end

return TimerPlugin

