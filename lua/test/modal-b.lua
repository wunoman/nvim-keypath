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
        modal:feed_native_key([[:w! >> snip.txt<cr>gv"_x]])
        return modal.handle_result.feedandleave
      end,
      condition = function()
        local mode = vim.api.nvim_get_mode().mode
        return mode == "v" or mode == "V"
      end,
    },
    s = {
      desc = "backup selection",
      handle = function()
        modal:feed_native_key([[:w! >> snip.txt<cr>]])
        return modal.handle_result.feedandleave
      end,
      condition = function()
        local mode = vim.api.nvim_get_mode().mode
        return mode == "v" or mode == "V"
      end,
    },
  }
  return state
end

----------------------------------------------------------------------------------------------------
---@GenerateModalOption
return function(modal)
  ---@type ModalOption
  return {
    name = ":b backup",
    state = create_state(modal),
    keymap = { { "n", "v" }, "<leader>b", { desc = "b backup" } },
  }
end
----------------------------------------------------------------------------------------------------
