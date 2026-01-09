----------------------------------------------------------------------------------------------------
-- 右下角浮动窗口管理器
local M = {
  options = {},
}

----------------------------------------------------------------------------------------------------
-- 默认配置
local default_config = {
  max_width = 80, -- 最大宽度
  max_height = 46, -- 最大高度
  min_width = 10, -- 最小宽度
  min_height = 1, -- 最小高度
  border = "rounded", -- 边框样式: "none", "single", "double", "rounded", "solid"
  style = "minimal", -- 窗口样式
  relative = "editor", -- 相对位置
  zindex = 50, -- 层级
  winblend = 10, -- 透明度混合
  title = "", -- 窗口标题
  title_pos = "center", -- 标题位置
  padding_row = 8, -- 距离边的距离
  padding_col = 8, -- 距离边的距离
}

----------------------------------------------------------------------------------------------------
function M:make_buf()
  -- 创建buffer
  if self.buf == nil then
    self.buf = vim.api.nvim_create_buf(false, true)
    local buf = self.buf

    -- 设置buffer为只读
    vim.api.nvim_buf_set_name(buf, "modal")
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "filetype", "text")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "hide") -- XXX:隐藏而不是卸载
    vim.api.nvim_buf_set_option(buf, "buflisted", false) -- 不在缓冲区列表中显示
  end
end

----------------------------------------------------------------------------------------------------
function M:make_win()
  local options = self.options
  -- 创建浮动窗口
  if self.win == nil or not vim.api.nvim_win_is_valid(self.win) then
    -- 创建浮动窗口配置
    local win_opts = {
      relative = options.relative,
      width = self.width,
      height = self.height,
      col = self.col,
      row = self.row,
      -- anchor = "SE", -- 右下角锚点
      style = options.style,
      border = options.border,
      zindex = options.zindex,
      title = options.title,
      title_pos = options.title_pos,
      focusable = false, -- 关键：禁止获得焦点
      noautocmd = true, -- 不触发自动命令
      hide = true, -- 创建时默认关闭
    }
    self.win = vim.api.nvim_open_win(self.buf, false, win_opts)
    local win = self.win

    -- 设置窗口选项
    vim.api.nvim_win_set_option(win, "winblend", options.winblend)
    vim.api.nvim_win_set_option(win, "wrap", true) -- 自动换行
    vim.api.nvim_win_set_option(win, "number", false)
    vim.api.nvim_win_set_option(win, "relativenumber", false)
    vim.api.nvim_win_set_option(win, "cursorline", false)
    vim.api.nvim_win_set_option(win, "signcolumn", "no")
    vim.api.nvim_win_set_option(win, "foldcolumn", "0")
  end
end

----------------------------------------------------------------------------------------------------
-- 根据内容计算窗口尺寸
function M:calculate(content_lines)
  if "table" ~= type(content_lines) then
    content_lines = {}
  end

  local max_line_len = 0
  for _, line in ipairs(content_lines) do
    max_line_len = math.max(max_line_len, #line)
  end

  local options = self.options
  -- 计算宽度和高度,取值在min和max之间
  self.width = math.min(math.max(max_line_len, options.min_width), options.max_width)

  self.height = math.min(math.max(#content_lines, options.min_height), options.max_height)

  -- 获取编辑器尺寸
  self.editor_width = vim.o.columns
  self.editor_height = vim.o.lines

  -- 计算右下角位置（考虑边框和状态栏）
  self.row = self.editor_height - self.height - options.padding_row
  self.col = self.editor_width - self.width - options.padding_col
end

----------------------------------------------------------------------------------------------------
-- 创建一个浮动窗口
function M:create(config)
  -- 合并配置
  self.options = vim.tbl_extend("force", default_config, config or {})
  self:make_buf()
end

----------------------------------------------------------------------------------------------------
function M:close()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_hide(self.win)
  end
end

----------------------------------------------------------------------------------------------------
function M:destroy()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_delete(self.buf, { force = true })
  end
  self.win = nil
  self.buf = nil
end

----------------------------------------------------------------------------------------------------
function M:show(content_lines)
  self:calculate(content_lines)
  self:set_lines(content_lines)
  self:make_win()

  -- 更新窗口大小和位置
  vim.api.nvim_win_set_config(self.win, {
    relative = self.options.relative,
    width = self.width,
    height = self.height,
    col = self.col,
    row = self.row,
    -- anchor = "SE",
    hide = false,
  })
end

----------------------------------------------------------------------------------------------------
function M:set_lines(content_lines)
  self:make_buf()
  -- 更新内容
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, content_lines)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

----------------------------------------------------------------------------------------------------
return M
