return {
  "olimorris/codecompanion.nvim",
  version = "^19.0.0",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    adapters = {
      acp = {
        codeflicker = {
          name = "codeflicker",
          formatted_name = "CodeFlicker",
          type = "acp",
          roles = {
            llm = "assistant",
            user = "user",
          },
          commands = {
            default = {
              "flickcli",
              "acp",
            },
          },
          defaults = {
            auth_method = "codeflicker-api-key",
          },
          handlers = {
            setup = function(self)
              return true
            end,
            form_messages = function(self, messages, capabilities)
              return require("codecompanion.adapters.acp.helpers").form_messages(self, messages, capabilities)
            end,
            on_exit = function(self, code) end,
          },
        },
      },
    },
    interactions = {
      chat = {
        adapter = "codeflicker",
       },
      cli = {
        agents = {
          codeflicker = {
            cmd = "flickcli",
            -- args = { "-m", "wanqing/glm-5.1" },
            description = "CodeFlicker CLI Agent",
          },
        },
      },
    },
  },
  keys = {
    {
      "<leader>at",
      function()
        local cli = require("codecompanion.interactions.cli")
        local instance = cli.find_by_agent("codeflicker") or cli.last_cli()
        if instance and instance.ui:is_visible() then
          instance.ui:hide()
        elseif instance then
          instance.ui:open()
        else
          require("codecompanion").toggle_cli({ agent = "codeflicker" })
        end
      end,
      desc = "Toggle CodeFlicker CLI",
    },
  },
}
