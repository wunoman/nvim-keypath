----------------------------------------------------------------------------------------------------
-- <leader>b 进入模式
-- b <leader>bb 备份并清除
-- s <leader>bs 只备份
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
local function create_state(modal)
  ---@ModalState
  local state = {
    b = {
      desc = "backup and delete selection",
      handle = function()
        local mode = vim.api.nvim_get_mode().mode
        if mode == "v" or mode == "V" then
          modal:feed_native_key([[:w! >> snip.txt<cr>gv"_x]])
          return modal.handle_result.feedandleave
        else
          vim.notify("no selection")
          return modal.handle_result.leavemodal
        end
      end,
    },
    s = {
      desc = "backup selection",
      handle = function()
        local mode = vim.api.nvim_get_mode().mode
        if mode == "v" or mode == "V" then
          modal:feed_native_key([[:w! >> snip.txt<cr>]])
          return modal.handle_result.feedandleave
        else
          vim.notify("no selection")
          return modal.handle_result.leavemodal
        end
      end,
    },
  }
  return state
end

----------------------------------------------------------------------------------------------------
return function(modal)
  ---@type ModalOption
  return {
    name = ":b backup",
    state = create_state(modal),
    keymap = { { "n", "v" }, "<leader>b", { desc = "b backup" } },
  }
end
----------------------------------------------------------------------------------------------------
