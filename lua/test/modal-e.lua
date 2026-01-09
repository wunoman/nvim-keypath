----------------------------------------------------------------------------------------------------
-- <leader>e 进入模式
-- hl 左右选择buffer
-- e 跳到指定buffer
-- q 关闭指定buffer
-- n fzf的buffer选择
-- o fzf的文件选择
-- r fzf的live_grep
-- p 有路径相关
----------------------------------------------------------------------------------------------------
local utils = require("core.utils")
----------------------------------------------------------------------------------------------------
-- 有些需要某插件存在才有效
local status_bufferline, _ = utils.require("bufferline")
local status_fzf, _ = utils.require("fzf-lua")
local status_nvim_tree, _ = utils.require("nvim-tree")
local status_buffer_commands, buffer_commands = utils.require("bufferline.commands")

----------------------------------------------------------------------------------------------------

local tree_open_buffer_path = function()
  local tree = require("nvim-tree.api").tree
  tree.close()
  tree.toggle({ path = vim.fn.expand("%:p:h"), focus = false })
end

local tree_find_buffer_path = function(type)
  local tree = require("nvim-tree.api").tree
  local pathinfo = utils.get_path(type)
  tree.close()
  tree.toggle({ path = vim.fn.getcwd(), focus = false })
  tree.find_file()
  vim.fn.setreg("*", pathinfo)
  vim.notify(pathinfo)
end

----------------------------------------------------------------------------------------------------
local function create_state(modal)
  ---@ModalState
  local movebuffer = {
    h = {
      desc = "move to left",
      handle = function()
        if "table" == type(buffer_commands) then
          buffer_commands.move(-1)
          return modal.handle_result.discarded
        else
          vim.notify(tostring(buffer_commands))
          return modal.handle_result.leavemodal
        end
      end,
      option = { keep = true },
      condition = status_buffer_commands,
    },
    l = {
      desc = "move to right",
      handle = function()
        if "table" == type(buffer_commands) then
          buffer_commands.move(1)
          return modal.handle_result.discarded
        else
          vim.notify(tostring(buffer_commands))
          return modal.handle_result.leavemodal
        end
      end,
      option = { keep = true },
      condition = status_buffer_commands,
    },
  }
  ---@ModalState
  local path = {
    p = {
      desc = "copy full path",
      handle = function(_self)
        tree_find_buffer_path("full")
        return modal.handle_result.leavemodal
      end,
    },
    r = {
      desc = "copy relative path",
      handle = function(_self)
        tree_find_buffer_path("relative")
        return modal.handle_result.leavemodal
      end,
    },
    c = {
      desc = "explore cd",
      handle = function()
        tree_open_buffer_path() -- nvim-tree cd
        return modal.handle_result.feedandleave
      end,
      condition = status_nvim_tree,
    },
    d = {
      desc = "copy directory",
      handle = function(_self)
        tree_find_buffer_path("dir")
        return modal.handle_result.leavemodal
      end,
    },
  }
  ---@ModalState
  local state = {
    h = {
      desc = "buffer prev",
      -- handle = "<cmd>bp<cr>",
      -- option = { keep = true },
      handle = function()
        if "table" == type(buffer_commands) then
          buffer_commands.cycle(-1)
          return modal.handle_result.discarded
        else
          vim.notify(tostring(buffer_commands))
          return modal.handle_result.leavemodal
        end
      end,
      option = { keep = true },
    },
    l = {
      desc = "buffer next",
      -- handle = "<cmd>bn<cr>",
      -- option = { keep = true },
      -- 如果使用了bufferline移动buffer功能则:bp和:bn与看到了标签不一致
      -- 需要使用bufferline的cycle来切换buffer,这样标签的位置和切换到的buffer才一致
      handle = function()
        if "table" == type(buffer_commands) then
          buffer_commands.cycle(1)
          return modal.handle_result.discarded
        else
          vim.notify(tostring(buffer_commands))
          return modal.handle_result.leavemodal
        end
      end,
      option = { keep = true },
    },
    e = {
      desc = "pick buffer",
      handle = "<cmd>BufferLinePick<cr>",
      condition = status_bufferline,
    },
    q = {
      desc = "pick and close buffer",
      handle = "<cmd>BufferLinePickClose<cr>",
      condition = status_bufferline,
    },
    m = {
      desc = "buffer move",
      state = movebuffer,
      condition = status_buffer_commands,
    },
    n = {
      desc = "fzf buffers",
      handle = "<cmd>FzfLua buffers<cr>",
      condition = status_fzf,
    },
    o = {
      desc = "fzf files",
      handle = "<cmd>FzfLua files<cr>",
      condition = status_fzf,
    },
    r = {
      desc = "fzf live_grep",
      handle = "<cmd>FzfLua live_grep<cr>",
      condition = status_fzf,
    },
    p = {
      desc = "path...",
      state = path, -- key name or table
    },
    w = {
      desc = "win pick",
      handle = "<cmd>lua require('nvim-window').pick()<cr>",
    },
    g = {
      desc = "test...",
      state = {
        f = {
          desc = "foo",
          handle = '<cmd>lua print("foo")<cr>',
        },
      },
      option = { nowait = true },
      condition = true,
    },
  }
  -- 返回editor,需要在path外部定义,需要editor循环引用了path
  ---@ModalHandler
  path["-"] = {
    desc = "../",
    state = state,
  }
  -- 返回editor,需要在movebuffer外部定义,需要editor循环引用了movebuffer
  ---@ModalHandler
  movebuffer["-"] = {
    desc = "../",
    state = state,
  }
  return state
end

----------------------------------------------------------------------------------------------------
return function(modal)
  ---@type ModalOption
  return {
    name = ":e editor",
    state = create_state(modal),
    keymap = { { "n", "v" }, "<leader>e", { desc = "buffer" } },
  }
end
----------------------------------------------------------------------------------------------------
