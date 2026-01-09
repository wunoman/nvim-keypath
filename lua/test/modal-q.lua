----------------------------------------------------------------------------------------------------
-- <leader>q 进入模式
-- q :qa
-- s 清空选择
----------------------------------------------------------------------------------------------------
local utils = require("core.utils")
----------------------------------------------------------------------------------------------------
-- 有些需要某插件存在才有效
local status_fix_bufferline, fix_bufferline = utils.require("core.fix-bufferline")

----------------------------------------------------------------------------------------------------
local function create_state(_modal)
  ---@ModalState
  local q = {
    a = {
      desc = "exit qa",
      handle = function()
        if status_fix_bufferline and "table" == type(fix_bufferline) then
          fix_bufferline:disable() -- 暂停拦截:q命令
          vim.cmd("qa")
          fix_bufferline:enable()
        else
          vim.cmd("qa")
        end
      end,
    },
    e = {
      desc = "quit current buffer",
      handle = "<cmd>q<cr>",
    },
    s = {
      desc = "clear selection",
      handle = "<cmd>let @/=''<cr>",
    },
  }
  return q
end

----------------------------------------------------------------------------------------------------
return function(modal)
  ---@type ModalOption
  return {
    name = ":q quit",
    state = create_state(modal),
    keymap = { "n", "<leader>q", { desc = "q" } },
  }
end
----------------------------------------------------------------------------------------------------
