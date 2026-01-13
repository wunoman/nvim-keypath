----------------------------------------------------------------------------------------------------
-- <leader>w 进入模式
-- h <cmd>vertial resize -2<cr>
-- l <cmd>vertial resize +2<cr>
-- k <cmd>resize -2<cr>
-- j <cmd>resize +2<cr>
----------------------------------------------------------------------------------------------------
---@GenerateModalOption
return function(_modal)
  ---@ModalState
  local state = {
    h = {
      desc = "vertial reize -2",
      handle = "<cmd>vertical resize -2<cr>",
      option = { keep = true },
    },
    l = {
      desc = "vertial reize +2",
      handle = "<cmd>vertical resize +2<cr>",
      option = { keep = true },
    },
    k = {
      desc = "reize -2",
      handle = "<cmd>vertical resize -2<cr>",
      option = { keep = true },
    },
    j = {
      desc = "reize +2",
      handle = "<cmd>vertical resize +2<cr>",
      option = { keep = true },
    },
    w = {
      desc = "win pick",
      handle = "<cmd>lua require('nvim-window').pick()<cr>",
    },
  }
  ---@type ModalOption
  return {
    name = ":w win",
    state = state,
    keymap = { { "n" }, "<leader>w", { desc = "w win" } },
  }
end
----------------------------------------------------------------------------------------------------
