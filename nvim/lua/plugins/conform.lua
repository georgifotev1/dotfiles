return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			rust = { "rustfmt" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true }, -- .jsx
			typescriptreact = { "prettierd", "prettier", stop_after_first = true }, -- .tsx
		},
		format_on_save = {
			-- These options will be passed to conform.format()
			timeout_ms = 2000,
			lsp_format = "fallback",
		},
	},
}
