return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		"saghen/blink.cmp",
	},
	config = function()
		local function client_supports_method(client, method, bufnr)
			if vim.fn.has("nvim-0.11") == 1 then
				return client:supports_method(method, bufnr)
			else
				return client.supports_method(method, { bufnr = bufnr })
			end
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
				map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
				map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
				map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
				map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
				map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
				map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.name == "oxlint" then
					vim.api.nvim_buf_create_user_command(event.buf, "LspOxlintFixAll", function()
						client:exec_cmd({
							title = "Apply Oxlint automatic fixes",
							command = "oxc.fixAll",
							arguments = { { uri = vim.uri_from_bufnr(event.buf) } },
						})
					end, { desc = "Apply Oxlint automatic fixes" })
				end

				if
					client
					and client_supports_method(
						client,
						vim.lsp.protocol.Methods.textDocument_documentHighlight,
						event.buf
					)
				then
					local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = function()
							local ok, err = pcall(vim.lsp.buf.document_highlight)
							if not ok and err and err:match("document should be opened") then
								vim.api.nvim_clear_autocmds({ buffer = event.buf, group = highlight_augroup })
							end
						end,
					})
					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})
					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
						end,
					})
				end

				if
					client
					and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
				then
					map("<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, "[T]oggle Inlay [H]ints")
				end
			end,
		})

		vim.diagnostic.config({
			severity_sort = true,
			float = { border = "rounded", source = "if_many" },
			underline = { severity = vim.diagnostic.severity.ERROR },
			signs = vim.g.have_nerd_font and {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.INFO] = "󰋽 ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
				},
			} or {},
			virtual_text = {
				source = "if_many",
				spacing = 2,
				format = function(diagnostic)
					local diagnostic_message = {
						[vim.diagnostic.severity.ERROR] = diagnostic.message,
						[vim.diagnostic.severity.WARN] = diagnostic.message,
						[vim.diagnostic.severity.INFO] = diagnostic.message,
						[vim.diagnostic.severity.HINT] = diagnostic.message,
					}
					return diagnostic_message[diagnostic.severity]
				end,
			},
		})

		local capabilities = require("blink.cmp").get_lsp_capabilities()

		local vue_language_server_path = vim.fn.stdpath("data")
			.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

		local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }

		local vue_plugin = {
			name = "@vue/typescript-plugin",
			location = vue_language_server_path,
			languages = { "vue" },
		}

		local ts_ls_config = {
			filetypes = tsserver_filetypes,
			init_options = {
				plugins = { vue_plugin },
			},
		}

		local servers = {
			ts_ls = {
				on_attach = function(client)
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
				end,
			},

			vue_ls = {
				on_init = function(client)
					client.handlers["tsserver/request"] = function(_, result, context)
						local ts_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })

						if #ts_clients == 0 then
							vim.notify("Could not find `ts_ls` LSP client, `vue_ls` would not work without it.", vim.log.levels.ERROR)
							return
						end
						local ts_client = ts_clients[1]

						local param = unpack(result)
						local command, payload = unpack(param)
						ts_client:exec_cmd({
							title = "vue_request_forward",
							command = "typescript.tsserverRequest",
							arguments = {
								command,
								payload,
							},
						}, { bufnr = context.bufnr }, function(_, r)
							local response = r and r.body
							local response_data = { { 1, response } }

							client:notify("tsserver/response", response_data)
						end)
					end
				end,
			},

			lua_ls = {
				settings = {
					Lua = {
						completion = { callSnippet = "Replace" },
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						diagnostics = {
							globals = { "vim" },
							disable = { "missing-fields" },
						},
						format = { enable = false },
					},
				},
			},
		}

		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"stylua",
			"prettierd",
			"prettier",
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		require("mason-lspconfig").setup({
			ensure_installed = vim.tbl_keys(servers),
			automatic_installation = true,
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "vue",
			callback = function(args)
				local root_dir = vim.fs.root(args.buf, { "package.json", "tsconfig.json", "jsconfig.json" })

				local init_options = vim.deepcopy(ts_ls_config.init_options)

				if vim.fn.isdirectory(vue_language_server_path) == 1 then
					init_options.plugins[1].location = vue_language_server_path
				end

				vim.lsp.start({
					name = "ts_ls",
					cmd = { "typescript-language-server", "--stdio" },
					root_dir = root_dir,
					init_options = init_options,
					capabilities = capabilities,
				})
			end,
		})

		vim.lsp.config("oxlint", {
			capabilities = capabilities,
		})
		vim.lsp.enable("oxlint")

		vim.lsp.config("oxfmt", {
			capabilities = capabilities,
		})
		vim.lsp.enable("oxfmt")

		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = { "*.js", "*.ts", "*.jsx", "*.tsx", "*.vue" },
			callback = function()
				vim.lsp.buf.format({ name = "oxfmt", async = false })
			end,
		})
	end,
}
