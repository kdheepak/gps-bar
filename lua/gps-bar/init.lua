local M = {}

M.nvim_gps_output = function()
	local present, gps = pcall(require, "nvim-gps")
	if not present then
		return ""
	end

	local data = gps.is_available() and gps.get_data() or {}
	if #data == 0 then
		return ""
	end
	local output = M.apply_highlight("Normal", " > ")

	local first = true

	for _, value in pairs(data) do
		local icon = value.icon
		local icon_hl = M.icon_highlights[value.type]
		if icon_hl ~= nil then
			icon = M.apply_highlight(icon_hl, icon)
		else
			icon = M.apply_highlight("TSVariable", icon)
		end
		local item = icon .. M.apply_highlight("LineNr", value.text)
		if not first then
			item = M.apply_highlight("Normal", " > ") .. item
		end
		output = output .. item
		first = false
	end

	return output
end

M.get_winbar_text = function()
	local gps_output = M.nvim_gps_output()
	local filename = vim.fn.expand("%")
	local status_ok_icons, nvim_web_devicons = pcall(require, "nvim-web-devicons")
	local icon = ""
	if status_ok_icons then
		local ft = vim.bo.filetype
		local nvw_icon, color = nvim_web_devicons.get_icon_color_by_filetype(ft)
		if color ~= nil then
			vim.cmd([[highlight! WinBarFileIcon guifg=]] .. color)
			icon = M.apply_highlight("WinBarFileIcon", nvw_icon)
		else
			icon = nvw_icon
		end
	end
	filename = M.apply_highlight("LineNr", filename)
	vim.cmd([[let g:mogo_winbar_textoff = getwininfo(win_getid())[0].textoff]])
	local gutter_width = vim.g.mogo_winbar_textoff or 0
	local result = (icon or "") .. " " .. filename .. gps_output
	result = string.rep(" ", tonumber(gutter_width) or 1) .. result
	return result
end

M.icon_highlights = {
	["class-name"] = "TSType", -- Classes and class-like objects
	["function-name"] = "TSFunction", -- Functions
	["method-name"] = "TSMethod", -- Methods (functions inside class-like objects)
	["container-name"] = "TSVariable", -- Containers (example: lua tables)
	["tag-name"] = "TSTag", -- Tags (example: html tags)
}

M.set_winbar = function()
	vim.opt.winbar = "%{%v:lua.require'gps-bar'.get_winbar_text()%}"
end

M.apply_highlight = function(hlname, str)
	return "%#" .. hlname .. "#" .. str
end

M.setup = function()
	M.set_winbar()
end

return M
