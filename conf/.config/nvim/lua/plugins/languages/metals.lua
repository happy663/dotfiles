return {
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
      "hrsh7th/cmp-nvim-lsp",
    },
    ft = { "scala", "sbt", "java" },
    opts = function()
      local metals = require("metals")
      local metals_config = metals.bare_config()

      metals_config.settings = {
        showImplicitArguments = true,
        showInferredType = true,
        showImplicitConversionsAndClasses = true,
        superMethodLensesEnabled = true,
        enableSemanticHighlighting = true,
        excludedPackages = {
          "akka.actor.typed.javadsl",
          "com.github.swagger.akka.javadsl",
        },
      }

      metals_config.init_options.statusBarProvider = "off"

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())
      end
      metals_config.capabilities = capabilities

      metals_config.on_attach = function(_, bufnr)
        local function buf_map(mode, lhs, rhs, opts)
          vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or { noremap = true, silent = true })
        end
        buf_map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
        buf_map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
        buf_map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
        buf_map("n", "<C-k>", "<cmd>lua vim.lsp.buf.hover()<CR>")
        buf_map("n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
        buf_map(
          "n",
          "<leader>di",
          '<cmd>lua vim.diagnostic.open_float(nil, {focus=true, border="double",source="always"})<CR>'
        )

        vim.keymap.set("n", "<leader>mc", function()
          local ok_telescope = pcall(require, "telescope")
          if ok_telescope then
            require("telescope").extensions.metals.commands()
          else
            require("metals").commands()
          end
        end, { buffer = bufnr, desc = "Metals commands" })
        vim.keymap.set("n", "<leader>mws", function()
          require("metals").hover_worksheet()
        end, { buffer = bufnr, desc = "Metals worksheet hover" })

        local ok_dap = pcall(require, "dap")
        if ok_dap then
          require("metals").setup_dap()
        end
      end

      return metals_config
    end,
    config = function(self, metals_config)
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = self.ft,
        callback = function()
          require("metals").initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
    end,
  },
}
