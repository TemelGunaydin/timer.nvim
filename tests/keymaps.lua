vim.opt.runtimepath:append(vim.fn.getcwd())

local timer = require("timer")
local picker = timer.pick_and_start
local remaining = timer.showRemainingTime
local keys = { "\\tt", "\\tr", "<F5>", "<F6>", "<F7>" }

local cases = {
	{
		name = "default mappings",
		opts = {},
		expected = { ["\\tt"] = picker, ["\\tr"] = remaining },
	},
	{
		name = "disable both mappings",
		opts = { open_keymap = false, remaining_keymap = false },
		expected = {},
	},
	{
		name = "disable only the picker",
		opts = { open_keymap = false },
		expected = { ["\\tr"] = remaining },
	},
	{
		name = "disable only remaining time",
		opts = { remaining_keymap = false },
		expected = { ["\\tt"] = picker },
	},
	{
		name = "custom mappings",
		opts = { open_keymap = "<F5>", remaining_keymap = "<F6>" },
		expected = { ["<F5>"] = picker, ["<F6>"] = remaining },
	},
	{
		name = "legacy picker mapping",
		opts = { keymap = "<F7>" },
		expected = { ["<F7>"] = picker, ["\\tr"] = remaining },
	},
	{
		name = "disable the legacy picker mapping",
		opts = { keymap = false },
		expected = { ["\\tr"] = remaining },
	},
	{
		name = "explicit disable takes precedence over the legacy alias",
		opts = { open_keymap = false, keymap = "<F7>" },
		expected = { ["\\tr"] = remaining },
	},
	{
		name = "explicit picker mapping takes precedence over the legacy alias",
		opts = { open_keymap = "<F5>", keymap = "<F7>" },
		expected = { ["<F5>"] = picker, ["\\tr"] = remaining },
	},
}

for _, case in ipairs(cases) do
	for _, key in ipairs(keys) do
		pcall(vim.keymap.del, "n", key)
	end

	timer.setup(case.opts)

	for _, key in ipairs(keys) do
		local mapping = vim.fn.maparg(key, "n", false, true)
		vim.fn.assert_true(mapping.callback == case.expected[key], case.name .. ": " .. key)
	end

	vim.fn.assert_equal(2, vim.fn.exists(":TimerPick"), case.name .. ": TimerPick command")
	vim.fn.assert_equal(2, vim.fn.exists(":TimerRemaining"), case.name .. ": TimerRemaining command")
end

if #vim.v.errors > 0 then
	for _, message in ipairs(vim.v.errors) do
		io.stderr:write(message .. "\n")
	end
	vim.cmd("cquit 1")
end

print(string.format("Passed %d keymap configuration cases", #cases))
