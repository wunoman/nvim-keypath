local M = {} -- 全局配置参数
----------------------------------------------------------------------------------------------------
---@return boolean
---@return table|string
function M.require(path, msg, level)
  local status, result = pcall(require, path)
  if not status then
    level = level or "warn"
    local message = "utils.pcall :: [" .. tostring(path) .. "] " .. tostring(result)
    if "string" == type(msg) then
      M.notify({
        msg,
        message,
      }, level)
    else
      if "table" == type(msg) then
        local temp = {}
        for _, v in pairs(msg) do
          if "string" == type(v) then
            table.insert(temp, v)
          end
        end
        table.insert(temp, message)
        M.notify(temp, level)
      else
        vim.notify(message)
      end
    end
  end
  return status, result
end

----------------------------------------------------------------------------------------------------
function M.notify(msg, level, opts)
  opts = opts or {}
  level = vim.log.levels[level:upper()]
  if type(msg) == "table" then
    msg = table.concat(msg, "\n")
  end
  local nopts = { title = opts.title or "" }
  if opts.once then
    return vim.schedule(function()
      vim.notify_once(msg, level, nopts)
    end)
  end
  vim.schedule(function()
    vim.notify(msg, level, nopts)
  end)
end

----------------------------------------------------------------------------------------------------
function M:validate_structure(sd, t, option)
  local invalid = {}
  option = option or { prefix = { "" } }
  option.prefix = option.prefix or { "" }
  local prefix = table.concat(option.prefix, ".")
  local checked = {}
  for k, desc in pairs(sd) do
    if desc.exist == "require" then -- 键必须存在
      if t[k] == nil then
        table.insert(invalid, table.concat({ prefix, k, " required" }))
      else
        if desc.type and "table" == type(desc.type) then -- 如果不存在表示接受任意类型
          if desc.type[type(t[k])] ~= true then
            table.insert(invalid, table.concat({ prefix, k, " wrong type" }))
          end
        end
      end
    elseif desc.exist == "condition" and "function" == type(desc.condition) then
      desc.condition(t, invalid)
    end

    -- 严格检查,非描述的键都认为不能存在
    if option.strict and not checked[sd] then -- 检测非名单中的键
      for x, _ in pairs(t) do
        if sd[x] == nil then
          table.insert(invalid, table.concat({ prefix, x, " not allow" }))
        end
      end
      checked[sd] = true -- 已经检测过了
    end

    -- 递归检查子表
    if "table" == type(desc.child) then
      if type(t[k]) ~= "table" then
        table.insert(invalid, table.concat({ prefix, k, " table expected" }))
      else
        table.insert(option.prefix, k)
        self:validate_structure(sd, t[k], option)
        table.remove(option.prefix, #option.prefix)
      end
    end
  end
  return invalid
end

----------------------------------------------------------------------------------------------------
function M.unpack(t)
  -- JIT have unpack
  return unpack(t) -- lua5.3 in table.unpack
end

----------------------------------------------------------------------------------------------------
function M.bytes(s)
  local t = {}
  local len = string.len(s)
  for i = 1, len do
    table.insert(t, string.byte(s, i))
  end
  return table.concat(t, ",")
end

----------------------------------------------------------------------------------------------------
function M.get_path(type)
  local types = {
    full = "%:p", -- 完整路径 /home/user/file.txt
    relative = "%", -- 相对路径 file.txt
    dir = "%:p:h", -- 所在目录 /home/user/
    name = "%:t", -- 文件名 file.txt
    root = "%:p:h:h", -- 上级目录 /home/
    noext = "%:t:r", -- 无扩展名 file
    ext = "%:e", -- 扩展名 txt
    drive = "%:p:h:h", -- Windows 驱动器
  }
  return vim.fn.expand(types[type] or "%:p")
end

----------------------------------------------------------------------------------------------------
function M.list_windows()
  local wins = vim.api.nvim_list_wins()

  print(":ListWindows")
  for i, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_name = vim.api.nvim_buf_get_name(buf)
    local modified = vim.api.nvim_buf_get_option(buf, "modified")
    local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

    -- 获取窗口位置信息
    -- local wininfo = vim.fn.getwininfo(win)[1]

    print(string.format(
      "%-4d id=%-4d type=%-20s %s buf=%s ",
      i,
      win,
      filetype ~= "" and filetype or "text",
      modified and "[+]" or "   ",
      buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t") or "[No Name]"
      -- wininfo.topline, -- 顶部行号
      -- wininfo.wincol -- 左侧列号
    ))
  end
end

----------------------------------------------------------------------------------------------------
function M.list_buffers()
  local buffers = vim.api.nvim_list_bufs()

  print(":ListBuffers")
  for i, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
      local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")

      local display_name = name == "" and "[No Name]" or name
      local modified_indicator = modified and "[+]" or "   "

      print(
        string.format(
          "%-4d id=%-4d type=%s %s name=%s",
          i,
          bufnr,
          buftype == "" and "file" or buftype,
          modified_indicator,
          display_name
        )
      )
    end
  end
end

----------------------------------------------------------------------------------------------------
function M.diagnostics_color()
  local diagnostic_hl_group = {
    DiagnosticVirtualTextError = { fg = "#ff2b6b" },
    DiagnosticVirtualTextWarn = { fg = "#ffda79" },
    DiagnosticVirtualTextInfo = { fg = "#7ee787" },
    DiagnosticVirtualTextHint = { fg = "#7035aa" },
    DiagnosticHeader = { fg = "#f1fa8c" },
  }
  for group, opts in pairs(diagnostic_hl_group) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

----------------------------------------------------------------------------------------------------

return M
