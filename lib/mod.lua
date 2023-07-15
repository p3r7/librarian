-- librarian mod.
-- @eigen

local mod = require 'core/mods'
local MOD_NAME = mod.this_name


-- -------------------------------------------------------------------------
-- conf file

local CONF_EXT = ".inventory"

-- TODO: support multiple conf file
local CONF_PATH = _path.data .. MOD_NAME .. '/' .. "default" .. CONF_EXT

local function load_conf_file()
  if util.file_exists(CONF_PATH) then
    return dofile(CONF_PATH)
  end
end

local function init_devices_from_conf(conf)
  local midiutil = include('librarian/lib/midiutil')

  local model_libs = {}
  local model_counts = {}

  for _, hw_conf in ipairs(conf.devices) do
    local HW
    local id_for_model = 1

    if model_libs[hw_conf.model] ~= nil then
      HW = model_libs[hw_conf.model]
      model_counts[hw_conf.model] = model_counts[hw_conf.model] + 1
      id_for_model = model_counts[hw_conf.model]
    else
      HW = include('librarian/lib/models/' .. hw_conf.model)
      if HW == nil then
        print(MOD_NAME .. ' - WARN - ' .. "Unknown model ".. hw_conf.model .. ', skipping.')
        goto NEXT_HW_LOAD
      end
      model_libs[hw_conf.model] = HW
      model_counts[hw_conf.model] = 1
    end

    local midi_device = hw_conf.device
    if midi_device == nil then
      midi_device = midiutil.MIDI_DEV_ALL
    end

    local hw = HW.new(id_for_model, midi_device, hw_conf.ch)

    for k, v in pairs(hw_conf.params) do
      if k == 'midi_device' or tab.contains(HW.PARAMS, k) then
        hw[k] = v
      else
        print(MOD_NAME .. ' - WARN - ' .. "Cannot set param "..k.."="..v.." for "..hw_conf.model .. '#' .. id_for_model .. ", unsupported param.")
      end
    end

    params:add_group(hw.display_name, hw:get_nb_params())
    hw:register_params()
    ::NEXT_HW_LOAD::
  end
end


-- -------------------------------------------------------------------------
-- menu

local m = {
}

m.init = function()
  -- (nothing to do)
end

m.deinit = function()
  -- (nothing to do)
end

m.key = function(n, z)
  if n == 2 and z == 1 then
    _menu.set_page("MODS")
    return
  end
end

m.enc = function(n, d)
end

local SCREEN_W = 128
local SCREEN_H = 64

m.redraw = function()
  screen.clear()

  -- NB: borders of the screen, to see boundaries
  -- screen.aa(0)
  -- screen.line_width(1)
  -- screen.rect(1, 1, 128-1, 64-1)
  -- screen.stroke()

  screen.display_png(_path.code .. MOD_NAME .. '/rsc/img/librarian.png', 0, 5)

  screen.move(SCREEN_W*3/4, SCREEN_H/4)
  if norns.state.name == 'none' then
    screen.text("Inactive")
  else
    screen.text("Active")
  end

  screen.update()
end

m.keychar = function(char)
end

m.keycode = function(code, value)
end

mod.menu.register(mod.this_name, m)


-- -------------------------------------------------------------------------
-- plumbing

mod.hook.register("script_pre_init", MOD_NAME.."-script-pre-init",
                  function()
                    local script_init = init
                    init = function ()
                      script_init()

                      local conf = load_conf_file()
                      if conf == nil then
                        print(MOD_NAME .. ' - ERR - ' .. "No conf file exists, aborting.")
                        return
                      end
                      params:add_separator("librarian", "librarian")
                      init_devices_from_conf(conf)
                    end
                  end
)

mod.hook.register("script_post_cleanup", MOD_NAME.."-script-post-cleanup",
                  function()
                  end
)
