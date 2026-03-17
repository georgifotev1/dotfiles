return {
	"sindrets/diffview.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local diffview = require("diffview")

		diffview.setup({
			enhanced_diff_hl = true, -- better syntax highlighting in diffs
			view = {
				default = {
					layout = "diff2_horizontal", -- same style as Gvdiffsplit (horizontal split)
				},
			},
			file_panel = {
				listing_style = "tree",
				win_config = {
					width = 35,
				},
			},
		})

		-- Keymaps
		local map = vim.keymap.set

		map("n", "<leader>gd", ":DiffviewOpen<CR>", { desc = "Diff open (all files)" })
		map("n", "<leader>gD", ":DiffviewOpen HEAD~1<CR>", { desc = "Diff vs previous commit" })
		map("n", "<leader>gh", ":DiffviewFileHistory %<CR>", { desc = "File git history" })
		map("n", "<leader>gH", ":DiffviewFileHistory<CR>", { desc = "Repo git history" })
		map("n", "<leader>gx", ":DiffviewClose<CR>", { desc = "Diff close" })
	end,
}
