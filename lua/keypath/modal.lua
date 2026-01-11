----------------------------------------------------------------------------------------------------
local utils = require("keypath.utils")
local floatwin = require("keypath.floatwin")
----------------------------------------------------------------------------------------------------
---@alias On_key fun(self:ModalOption, modal:Modal, Key:string, Typed:string):HandleResult
---@alias On_registry fun(self:ModalOption, modal:Modal):void
---@alias Show_which_key fun(modal:Modal, state:ModalState, self:ModalOption):table
---@alias Handle_key_typed fun(self, custom_modal:ModalOption, key:string, typed:string, v:ModalHandler?):HandleResult
---@alias GenerateModalOption fun(modal:Modal):ModalOption?
---
---@alias ModalState table{ [string]:ModalHandler, handler:Handle_key_typed? }
---
---@class ModalHandlerRegistryKeymap
---@field [1] string|table @按键映射的模式 mode
---@field [2] string @按键映射 lhs
---@field [3] table? @按键映射的选项 opt
---
---@class ModalOption
---@field name string @自定义模式名称,做为inventory的键
---@field state ModalState @模式中接受的按键
---@field keymap ModalHandlerRegistryKeymap
---@field on_registry On_registry? @注册至仓库里的回调函数
---@field on_key On_key? @完全自助处理按键事件
---@field current_state table|? @指定当前的按键处理组,一个自定义模式下可能有多个 ModalState
---@field show_which_key Show_which_key|? @显示提示的浮动窗口
---@field _enter function|? @内置函数
---
---@class ModalHandler
---@field desc string @功能描述
---@field handle string|function @字符串形式的命令或是按键序列或是自定义函数
---@field state ModalState @是否要转到其他 ModalState
---@field condition boolean|function|? @判断是否生效
---
---@class Modal
---@field options table @配置
---@field post_key_count number @需要略过的字符序列长度
---@field is_active bool @是否开启处理输入序列
---@field current_modal string @当前自定义模式的名称
---@field handle_result table @自定义模式处理函数的返回值表
---@field floatwin table @浮动提示窗口
---@field inventory table @注册表 modal_name=ModalOption
---@field set_modal fun(self, new_modal:string):void @切换到指定模式
---@field registry fun(self, ...:ModalOption|string):Modal @注册模式
---@field feed_native_key fun(self, key:string, count:number?):number @把按键加入输入序列并且模式不处理这些按键,直接发给nvim
---@field feed_native_cmd_key fun(self, key:string):number @与feed_native_key不同,这里只把输入做为一个字符略过
---@field dispatch fun(self, key:string, typed:string):string? @核心分发逻辑：根据「模式+条件+按键」执行不同行为
---@field dispatch_state fun(self, custom_modal:ModalOption, key:string, typed:string):HandleResult
---@field active fun(self):self @设置标志开启处理输入序列
---@field deactive fun(self):void @关闭输入序列的处理
---@field is_custom_modal fun(self):bool @判断当前是否在某个自定义模式中
---@field setup fun(self, conf:table, opt:table?):self @判断当前是否在某个自定义模式中
---@field get_default_options fun(self):DefaultOptions @判断当前是否在某个自定义模式中
---@field default_options DefaultOptions @判断当前是否在某个自定义模式中
---@field show_which_key fun(self, state:ModalState):table @判断当前是否在某个自定义模式中
---@field switch_state fun(self, state:ModalState) @某个自定义模式中切换下一次接受的按键
---@field status_component_condition fun(self):bool @状态栏组件有效的判断函数
---@field parse_condition fun(self, item:table, custom_modal:ModalOption, state:table, key:string):bool
---@field put_inventory fun(self, name:string, custom_modal:ModalOption)
---@field get_inventory fun(self, name:string):ModalOption?
---@field get_modal_state fun(self, custom_modal_name:string):ModalState? @返回某个已注册的ModalOption的state
---@field get_modal_current_state fun(self, custom_modal_name:string):ModalState? @返回某个已注册的ModalOption的current_state
---@field set_timeout fun(self, recover:bool|nil):self @设置等待时间或是恢复初始设置
---@field show_all_custom_modal fun(self):table @显示仓库所有已经注册的模式
---@field configure fun(self, configure:table, opt:table|?) @合并选项
---@field registry_default_custom fun(self) @注册缺省的一个模式,这个模式用于展示所有已注册的模式
---@field handle_key_typed fun(self, custom_modal:ModalOption, key:string, typed:string, v:ModalHandler?):HandleResult
---@field root_modal_handle_key_typed fun(self, custom_modal:ModalOption, key:string, typed:string, v:ModalHandler?):HandleResult
---@field get_root_modal fun(self, mode:string|table, lhs:string, opt:table?):ModalOption
---@field show_floatwin fun(self, hints:table) @显示浮动窗口,配合floatwin_visible
---@field load_modal_option fun(self, script_path:string):ModalOption? @加载ModalOption
---@field create_custom_modal_enter fun(self, current_modal:ModalOption) @生成一个进入自定义模式的函数
---@field simulate_keypath fun(self, keypath:string, hide_floatwin:boolean?) @模拟按键序列调用自定义模式中handle
---@field get_status_component_content fun():function
---@field get_status_component_condition fun():function
---@field get_status_component_color fun():function
---@field get_status_component fun():table
---@field force_show_floatwin fun(self)
---@field trigger_event fun(self, event_name:string, ...)
---
----------------------------------------------------------------------------------------------------
---@class DefaultOptions
---@field NSID number @namespace id
---@field active boolean
---@field default_mode string
---@field status_component table
---@field keymap table
---@field timeout table
---@field enter_defer_time number
---@field floatwin_visible_recover_time number

----------------------------------------------------------------------------------------------------
---@type Modal
local M = {
  options = {
    status_component = {}, -- 未配置前也需要存在
  },
  is_active = false,
  current_modal = "normal",
  inventory = {},
  post_key_count = 0, -- 需要在模式中忽略的字符数量(字符在输入序列中)
  floatwin = floatwin,
  ---@enum HandleResult
  handle_result = {
    bypass = 0,
    feedkey = 1,
    leavemodal = 2,
    feedandleave = 3,
    discarded = 4,
    bypassandleave = 5,
  },

  ---@type DefaultOptions
  default_options = {
    -- on_key的namspace id
    NSID = 9998,
    -- 按键监听是否启用
    active = true,
    -- 控制浮动窗口是否可见
    floatwin_visible = true,
    -- 在simulate时恢复floatwin_visible设置的延迟时间
    floatwin_visible_recover_time = 50,
    -- 退出模式后切换回的缺少mode
    default_mode = "normal",
    -- 状态栏上组件的字体颜色
    status_component = {
      -- 状态栏组件默认的图标字符
      status_icon = " ",
      -- 状态栏组件内容函数
      -- content
      -- condition
      color = function()
        return {
          fg = "#957CC6",
        }
      end,
    },
    -- 触发默认模式的按键
    keymap = { mode = { "n", "v" }, lhs = "<leader>", opt = { desc = "modal help" } },
    -- 管理按键组合的等待时间
    timeout = {
      enable = true,
      timeout = true,
      timeoutlen = 10,
      ttimeoutlen = 10,
      original = {},
    },
    -- 从默认模式进入注册模式时的延迟时间ms
    enter_defer_time = 50,
    -- 模拟按键序列时的模式，m表示继续触发映射
    simulate_mode = "m",
    -- 退出模式的固定按键,要保证它不会被应用到按键路径中
    leave_modal_key = ";",
    -- 一些自定义的函数
    event = {
      -- show_which_key
    },
  },

  ----------------------------------------------------------------------------------------------------
  dispatch = function(self, key, typed)
    local handle = self.handle_result.bypass
    ---@diagnostic disable-next-line
    if self.post_key_count > 0 then
      self.post_key_count = self.post_key_count - 1 -- 略过指定数量的字符
    else
      -- 在模式中再添加到输入序列的字符不再按模式处理,略过这些字符
      local custom_modal = self:get_inventory(self.current_modal)
      if custom_modal then
        if "function" == type(custom_modal.on_key) then
          handle = custom_modal:on_key(self, key, typed)
        else
          handle = self:dispatch_state(custom_modal, key, typed)
        end
        -- 离开某个模式
        if
          handle == self.handle_result.leavemodal
          or handle == self.handle_result.feedandleave
          or handle == self.handle_result.bypassandleave
        then
          self:set_modal(self.options.default_mode) --默认切回 normal 模式
        end
      end
    end
    -- :help vim.on_key
    -- nil: 继续处理字符序列, '' : 抛弃输入序列
    if handle == self.handle_result.bypass or handle == self.handle_result.bypassandleave then
      return nil -- 这里不用使用 x and y or z 形式，因为 y 是 nil
    else
      return ""
    end
  end,
}

----------------------------------------------------------------------------------------------------
function M:dispatch_state(custom_modal, key, typed)
  local handle = self.handle_result.bypass
  local state
  if "table" == type(custom_modal.current_state) then
    state = custom_modal.current_state
  else
    handle = self.handle_result.leavemodal
  end
  if state then
    local wk = (typed == "") and key or typed
    local handler = state[wk]
    if handler then
      -- 从state找到触发按键对应的处理配置
      -- local cond = self:parse_condition(handler, custom_modal, state, wk)
      if handler.condition_result then
        handle = self:handle_key_typed(custom_modal, key, typed, handler) -- local global func
      else
        handle = self.handle_result.leavemodal -- leave when no v
      end
    elseif "function" == type(state.handle_key_typed) then
      -- 允许state有一个全局的处理配置
      handle = state.handle_key_typed(self, custom_modal, key, typed, handler)
    else
      handle = self.handle_result.leavemodal -- leave when no handle
    end
  else
    handle = self.handle_result.leavemodal -- leave when no v
  end
  return handle
end

----------------------------------------------------------------------------------------------------
function M:handle_key_typed(custom_modal, key, typed, handler)
  local handle = self.handle_result.bypass
  if "table" ~= type(handler) then
    return handle
  end
  local type_of_handle = type(handler.handle)
  if "function" == type_of_handle then -- 最优先处理
    handle = handler.handle(custom_modal, self, key, typed)
  elseif "string" == type_of_handle then
    -- 如果处理方法是个字符串则认为它是按键序列,并且配合option.keep来决定on_key返回值
    if vim.tbl_get(handler, "option", "keep") == true then -- 继续留在模式中
      handle = self.handle_result.feedkey
    else
      handle = self.handle_result.feedandleave
    end

    local keystr = tostring(handler.handle)
    if string.lower(keystr):find("<cmd>") == 1 then -- <cmd>...<cr>
      -- 这个形式的序列被当成一个字符,标记为接下来略过1个字符的处理
      self:feed_native_key(keystr, 1)
      handler.handle = function() -- 改写,下次就不再走这个路径
        self:feed_native_key(keystr, 1)
        return handle
      end
    else
      self:feed_native_key(keystr)
      handler.handle = function() -- 统一改写成函数,下次就不再走这个路径
        self:feed_native_key(keystr)
        return handle
      end
    end
  elseif "table" == type(handler.state) then
    -- 切换至同一个 custom_modal 的内部 state
    -- custome_modal 保持不变
    self:switch_state(handler.state)
    handle = self.handle_result.discarded
    handler.handle = function() -- 统一改写成函数,下次就不再走这个路径
      self:switch_state(handler.state)
      handle = self.handle_result.discarded
    end
  end
  return handle
end

----------------------------------------------------------------------------------------------------
function M:parse_condition(item, custom_modal, state, k)
  local cond = true
  local type_of_condtion = type(item.condition)
  if "boolean" == type_of_condtion then -- 直接值
    cond = item.condition
  elseif "function" == type_of_condtion then -- 通过函数计算
    cond = not not (item.condition(custom_modal, self, state, k))
  elseif "nil" == type_of_condtion then -- 没有提供,默认为true
    cond = true
  else
    cond = not not item.condition -- 转成boolan
  end
  return cond
end

----------------------------------------------------------------------------------------------------
function M:show_all_custom_modal()
  local hints = {}
  for name, custom_modal in pairs(self.inventory) do
    if custom_modal.keymap then
      local info = {
        key = custom_modal.keymap[2],
        mode = custom_modal.keymap[1],
        name = tostring(name),
      }
      if "table" == type(info.mode) then
        table.sort(info.mode)
        info.mode = table.concat(info.mode, "")
      end
      local line = string.format("%-10s %-12s %6s", info.key, info.name, info.mode)
      table.insert(hints, line)
    end
  end
  table.sort(hints)
  return hints
end

----------------------------------------------------------------------------------------------------
function M:show_which_key(state)
  local hints = {}
  ---@diagnostic disable-next-line
  if self.floatwin then
    if "table" == type(state) then
      local custom_modal = self:get_inventory(self.current_modal)
      if custom_modal then
        for k, v in pairs(state) do
          if v.condition_result then
            local hintline
            if "function" == type(self.options.event.show_which_key) then
              hintline = self.options.event.show_which_key(custom_modal, self, state, k, v)
            else
              local line = { tostring(k), " " }
              if vim.tbl_get(v, "option", "keep") == true then
                table.insert(line, "*") -- 继续留在模式中
              else
                table.insert(line, " ") -- 继续留在模式中
              end
              table.insert(line, ":")
              if "table" == type(v.state) then
                table.insert(line, "+") -- 表示达到另一个state
              else
                table.insert(line, " ") -- 普通路径
              end
              table.insert(line, " ")
              if "function" == type(v.desc) then
                table.insert(line, tostring(v.desc(custom_modal, self, state, k, v) or ""))
              elseif "string" == type(v.desc) then
                table.insert(line, tostring(v.desc or ""))
              else
                table.insert(line, "")
              end
              hintline = table.concat(line)
            end
            if "string" == type(hintline) then
              table.insert(hints, hintline)
            end
          end
        end
      end
      table.sort(hints)
    end
  end
  if #hints == 0 then
    table.insert(hints, "---empty---")
  end
  return { hints = hints }
end

----------------------------------------------------------------------------------------------------
function M:set_timeout(recover)
  if not self.options.timeout.enable then
    return self
  end
  if not recover then
    -- save
    local orig = self.options.timeout.original
    orig.timeout = vim.o.timeout
    orig.timeoutlen = vim.o.timeoutlen
    orig.ttimeoutlen = vim.o.ttimeoutlen
    -- set
    vim.o.timeout = true
    vim.o.timeoutlen = 10
    vim.o.ttimeoutlen = 10
  else
    -- recover
    local orig = self.options.timeout.original
    vim.o.timeout = orig.timeout
    vim.o.timeoutlen = orig.timeoutlen
    vim.o.ttimeoutlen = orig.ttimeoutlen
  end
  return self
end

----------------------------------------------------------------------------------------------------
function M:set_modal(new_modal)
  if not self.is_active then
    return
  end
  self.current_modal = new_modal
  if self:is_custom_modal() then
    self:set_timeout()
  else
    -- 如果退出自定义模式则关闭浮动提示窗口
    self:set_timeout(true) -- true mean recover
    self.floatwin:close()
    self:trigger_event("switch_state", nil)
  end
  --vim.notify(string.format("切换到 [%s] 模式", new_modal), vim.log.levels.INFO)
end

----------------------------------------------------------------------------------------------------
function M:force_show_floatwin()
  self.options.floatwin_visible = true
end

----------------------------------------------------------------------------------------------------
function M:show_floatwin(hints)
  if self.options.floatwin_visible then
    self.floatwin:show(hints)
  end
end

----------------------------------------------------------------------------------------------------
function M:switch_state(state)
  if not self.is_active then
    return
  end
  if self:is_custom_modal() then
    local custom_modal = self:get_inventory(self.current_modal)
    if custom_modal then
      custom_modal.current_state = state

      -- 切换时把先决条件也计算好
      for key, handler in pairs(state) do
        if string.len(key) == 1 and "table" == type(handler) then
          handler.condition_result = self:parse_condition(handler, custom_modal, state, key)
        end
      end

      if "function" == type(custom_modal.show_which_key) then
        -- 默认的模式提供了这样的函数,用于展示其他注册的模式
        local which_key_hint_info =
          custom_modal.show_which_key(self, custom_modal.state, custom_modal)
        if "table" == type(which_key_hint_info) and not which_key_hint_info.abort then
          if "table" == type(which_key_hint_info.hints) then
            self:show_floatwin(which_key_hint_info.hints)
          end
        end
      elseif "table" == type(state) then
        local which_key_hint_info = self:show_which_key(state)
        self:show_floatwin(which_key_hint_info.hints)
      end
    end

    self:trigger_event("switch_state", state)
  else
    self:trigger_event("switch_state", nil)
  end
end

function M:trigger_event(event_name, ...)
  local callback = self.options.event[event_name]
  if "function" == type(callback) then
    callback(self, ...)
  end
end

----------------------------------------------------------------------------------------------------
function M:active()
  if self.is_active == false then
    self.is_active = true
    vim.on_key(function(key, typed)
      -- print(("%q:%q"):format(key, typed))
      return self:dispatch(key, typed)
    end, self.options.NSID, {})
    self.floatwin:create()
  end

  return self
end

----------------------------------------------------------------------------------------------------
function M:deactive()
  if self.is_active == true then
    if self:is_custom_modal() then
      self:set_modal(self.options.default_mode)
    end
    vim.on_key(nil, self.options.NSID)
    self.is_active = false
    self.floatwin:destroy()
  end
end

----------------------------------------------------------------------------------------------------
function M:feed_native_key(key, count)
  local keycode = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keycode, "n", false) -- 不等待按键完成,避免阻塞(并不能去除g和d等待序列完成的等待)
  local keycode_length = count
  if "number" ~= type(keycode_length) then
    keycode_length = string.len(keycode)
  end
  self.post_key_count = self.post_key_count + keycode_length
  return keycode_length
end

----------------------------------------------------------------------------------------------------
function M:feed_native_cmd_key(key)
  key = "<cmd>" .. key .. "<cr>"
  local keycode = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keycode, "n", false) -- 不等待按键完成，避免阻塞
  -- <cmd>xxx<cr> 只作为了一个(这是测试出来的数值)字符略过
  local keycode_length = 1
  self.post_key_count = self.post_key_count + keycode_length
  return keycode_length
end

----------------------------------------------------------------------------------------------------
function M:put_inventory(name, custom_modal)
  self.inventory[name] = custom_modal
end

----------------------------------------------------------------------------------------------------
function M:get_inventory(name)
  return self.inventory[name]
end

----------------------------------------------------------------------------------------------------
function M:get_modal_state(name)
  return vim.tbl_get(self.inventory, name, "state")
end

----------------------------------------------------------------------------------------------------
function M:get_modal_current_state(name)
  return vim.tbl_get(self.inventory, name, "current_state")
end

----------------------------------------------------------------------------------------------------
function M:create_custom_modal_enter(modal_option)
  modal_option["_enter"] = function()
    self:set_modal(modal_option.name) -- 进入自定义模式
    self:switch_state(modal_option.state)
  end
end

----------------------------------------------------------------------------------------------------
function M:load_modal_option(script_path)
  local status, modal_option = utils.require(script_path)
  if status and modal_option and "function" == type(modal_option) then
    ---@diagnostic disable-next-line
    modal_option = modal_option(self)
  end
  return "table" == type(modal_option) and modal_option or nil
end

----------------------------------------------------------------------------------------------------
function M:registry(...)
  local self = self
  local list = {}
  for _, item in ipairs({ ... }) do -- 全部转化成table形式
    local modal_option = "string" == type(item) and self:load_modal_option(item) or item
    if "table" == type(modal_option) then
      table.insert(list, modal_option)
    end
  end
  -- 添加至仓库,执行启动按键映射和初始化配置
  for _, modal_option in ipairs(list) do
    self:put_inventory(modal_option.name, modal_option)
    if "function" == type(modal_option.on_registry) then
      -- 由自定义函数实现触发和初始化状态
      modal_option.on_registry(modal_option, self)
    end
    if "table" == type(modal_option.keymap) then
      -- 在这里完成触发键的映射和初始化状态
      local km = modal_option.keymap
      local mode, lhs, opts = km[1], km[2], km[3]
      self:create_custom_modal_enter(modal_option)
      vim.keymap.set(mode, lhs, modal_option["_enter"], opts)
    end
  end
  return self
end

----------------------------------------------------------------------------------------------------
function M:is_custom_modal()
  local checker = self.options.is_custom_modal
  if "function" == type(checker) then
    return not not (checker(self.current_modal))
  else
    return not not (string.find(self.current_modal, ":"))
  end
end

----------------------------------------------------------------------------------------------------
function M:get_default_options()
  return self.default_options
end

----------------------------------------------------------------------------------------------------
function M:configure(_configure, opts)
  local opt = ("table" == type(opts) and "table" == type(opts.options)) and opts.options
  self.options = vim.tbl_deep_extend(
    "force",
    self.default_options,
    "table" == type(self.options) and self.options or {},
    "table" == type(opt) and opt or {}
  )
end

----------------------------------------------------------------------------------------------------
function M:root_modal_handle_key_typed(_custom_modal, key, typed, _handler)
  local handle = self.handle_result.leavemodal
  for _, modal_option in pairs(self.inventory) do
    if modal_option.keymap then
      -- 形如<leader>加一个字符的解发键则允许在这个按键输入时触发模式切换
      local lhs = tostring(modal_option.keymap[2])
      local onechar = string.match(lhs, "<leader>(.)")
      if onechar and (onechar == key or onechar == typed) then
        if onechar == "q" then -- 命中之后才判断是否是录制指令
          self:feed_native_key("<esc>") -- q是宏记录的开始,取消它,结束它的等待
        end
        -- _enter是内部生成的,查看 registry 函数
        -- 如果没有则再生成一个
        if "function" ~= type(modal_option["_enter"]) then
          self:create_custom_modal_enter(modal_option)
        end
        -- 无须每次都创建一个进入模式的函数
        vim.defer_fn(modal_option["_enter"], self.options.enter_defer_time)
      else
        -- handle = self.handle_result.bypassandleave -- 让当前无效的输入放到序列中继续生效
        handle = self.handle_result.leavemodal -- 继续生效虽然能快一点但也造成困惑，还是统一较好
      end
    end
  end
  return handle
end

----------------------------------------------------------------------------------------------------
function M:get_root_modal(mode, lhs, opt)
  return {
    name = ":h help",
    state = { handle_key_typed = self.root_modal_handle_key_typed },
    keymap = { mode, lhs, opt },
    show_which_key = function(modal, _state, _modaloption)
      return { hints = modal:show_all_custom_modal() }
    end,
  }
end

----------------------------------------------------------------------------------------------------
function M:registry_default_custom()
  -- 注册的默认模式,用于展示已经注册到仓库中的各个模式
  if "table" == type(self.options.keymap) then
    local keymap = self.options.keymap
    self:registry(
      self:get_root_modal(keymap.mode, keymap.lhs, "table" == type(keymap.opt) and keymap.opt or {})
    )
  end
end

----------------------------------------------------------------------------------------------------
function M:setup(configure, opt)
  self:configure(configure, opt)
  self:registry_default_custom()

  if self.options.active == true or self.options.active == nil then
    -- 默认是立即开始按键监听
    self:active()
  end
  return self
end

----------------------------------------------------------------------------------------------------
function M:simulate_keypath(keypath, hide_floatwin)
  -- 默认关闭浮动提示窗口的显示,因为模拟按键序列非常快,实际效果是闪烁,无法正常观看
  -- 如果最终指令不是退出模式,则要设置可视,不然与实际情况不符
  if "string" ~= type(keypath) or string.len(keypath) == 0 then
    return
  end
  local original_floatwin_visible = self.options.floatwin_visible
  self.options.floatwin_visible = not (hide_floatwin == nil or hide_floatwin == true)
  -- print(self.options.floatwin_visible, original_floatwin_visible)
  local keycode = vim.api.nvim_replace_termcodes(keypath, true, false, true)
  vim.api.nvim_feedkeys(keycode, self.options.simulate_mode, false)
  -- 恢复浮动窗口可视设置
  if self.options.floatwin_visible ~= original_floatwin_visible then
    vim.defer_fn(function()
      self.options.floatwin_visible = original_floatwin_visible
    end, self.options.floatwin_visible_recover_time)
  end
end

----------------------------------------------------------------------------------------------------
function M.get_status_component_content()
  local status, modal = utils.require("nvim-keypath")
  if status and "table" == type(modal) then
    local func = modal.options.status_component and modal.options.status_component.content
    if "function" ~= type(func) then
      func = function()
        local icon = modal.options.status_component.status_icon
        if "string" ~= type(icon) then
          icon = ""
        end
        return modal:is_custom_modal() and (icon .. modal.current_modal) or ""
      end
      modal.options.status_component.content = func
    end
    return func
  else
    return function()
      return ""
    end
  end
end

----------------------------------------------------------------------------------------------------
function M.get_status_component_condition()
  local status, modal = utils.require("nvim-keypath")
  if status and "table" == type(modal) then
    local func = modal.options.status_component and modal.options.status_component.condition
    if "function" ~= type(func) then
      func = function()
        return not not (modal:is_custom_modal() and (vim.o.columns > 100))
      end
      modal.options.status_component.condition = func
    end
    return func
  else
    return function()
      return false
    end
  end
end

----------------------------------------------------------------------------------------------------
function M.get_status_component_color()
  local status, modal = utils.require("nvim-keypath")
  if status and "table" == type(modal) then
    local func = modal.options.status_component.color
    if "function" ~= type(func) then
      func = function()
        return { fg = "#ee82ee" }
      end
      modal.options.status_component.color = func
    end
    return func
  else
    return function()
      return {}
    end
  end
end

----------------------------------------------------------------------------------------------------
function M.get_status_component()
  return {
    function()
      -- 由于nvim-keypath配置比较晚,这里都配置成函数调用的形式
      -- 真正需要显示的时间才调用,这时候nvim-keypath应该配置完毕
      local status, modal = utils.require("nvim-keypath")
      if status and "table" == type(modal) then
        return modal.get_status_component_content()()
      end
      return ""
    end,
    cond = function()
      local status, modal = utils.require("nvim-keypath")
      if status and "table" == type(modal) then
        return modal.get_status_component_condition()()
      end
      return false
    end,
    color = function()
      local status, modal = utils.require("nvim-keypath")
      if status and "table" == type(modal) then
        return modal.get_status_component_color()()
      end
      return {
        fg = "#ee82ee",
      }
    end,
  }
end

----------------------------------------------------------------------------------------------------
return M
