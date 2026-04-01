return {
	"goolord/alpha-nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		-- ── Header ───────────────────────────────────────────────
		dashboard.section.header.val = {
			[[                                                    ]],
			[[ ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗]],
			[[ ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║]],
			[[ ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║]],
			[[ ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
			[[ ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║]],
			[[ ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
			[[                                                    ]],
		}

		dashboard.section.header.opts.hl = "AlphaHeader"

		-- ── Buttons ──────────────────────────────────────────────
		dashboard.section.buttons.val = {
			dashboard.button("n", "  New file", "<cmd>ene <BAR> startinsert<CR>"),
			dashboard.button("f", "  Find file", "<cmd>Telescope find_files<CR>"),
			dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<CR>"),
			dashboard.button("g", "  Live grep", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("s", "  Restore session", "<cmd>SessionRestore<CR>"),
			dashboard.button("l", "  Lazy", "<cmd>Lazy<CR>"),
			dashboard.button("q", "  Quit", "<cmd>qa<CR>"),
		}

		-- Style each button
		for _, button in ipairs(dashboard.section.buttons.val) do
			button.opts.hl = "AlphaButton"
			button.opts.hl_shortcut = "AlphaButtonShortcut"
		end

		-- ── Footer ───────────────────────────────────────────────
		local function footer()
			local stats = require("lazy").stats()
			local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
			return "⚡ " .. stats.count .. " plugins loaded in " .. ms .. "ms"
		end

		dashboard.section.footer.val = footer()
		dashboard.section.footer.opts.hl = "AlphaFooter"

		-- ── Layout ───────────────────────────────────────────────
		dashboard.opts.layout = {
			{ type = "padding", val = 6 },
			dashboard.section.header,
			{ type = "padding", val = 2 },
			dashboard.section.buttons,
			{ type = "padding", val = 2 },
			dashboard.section.footer,
		}

		alpha.setup(dashboard.opts)

		-- ── Catppuccin Macchiato highlight groups ────────────────
		-- These run after the colorscheme loads so they always apply
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#8aadf4", bold = true }) -- blue
				vim.api.nvim_set_hl(0, "AlphaButton", { fg = "#cad3f5" }) -- text
				vim.api.nvim_set_hl(0, "AlphaButtonShortcut", { fg = "#c6a0f6", bold = true }) -- mauve
				vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#5b6078", italic = true }) -- surface2
			end,
		})

		-- Also set immediately in case colorscheme already loaded
		vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#8aadf4", bold = true })
		vim.api.nvim_set_hl(0, "AlphaButton", { fg = "#cad3f5" })
		vim.api.nvim_set_hl(0, "AlphaButtonShortcut", { fg = "#c6a0f6", bold = true })
		vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#5b6078", italic = true })
	end,
}
