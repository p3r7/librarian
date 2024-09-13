-- librarian mod.
-- @eigen

local mod = require 'core/mods'
local MOD_NAME = mod.this_name or "librarian"

local midiutil = include('librarian/lib/midiutil')

local function tempty(t)
  for k, v in pairs(t) do
    t[k] = nil
  end
end


-- -------------------------------------------------------------------------
-- consts

local IGNORED_MIDI_DEVS = {
  "16n", "bleached", "h2o2d",
}


-- -------------------------------------------------------------------------
-- state

local hw_list = {}

local conf = nil

librarian_done_init = false

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

  local model_libs = {}
  local model_counts = {}
  local hw_model_id = {}

  for i, hw_conf in ipairs(conf.devices) do
    local HW
    if model_libs[hw_conf.model] == nil then
      HW = include('librarian/lib/models/' .. hw_conf.model)
      if HW == nil then
        print(MOD_NAME .. ' - WARN - ' .. "Unknown model ".. hw_conf.model .. ', skipping.')
        goto NEXT_HW_LOAD
      end
      model_libs[hw_conf.model] = HW
      model_counts[hw_conf.model] = 1
    else
      model_counts[hw_conf.model] = model_counts[hw_conf.model] + 1
    end
    hw_model_id[i] = model_counts[hw_conf.model]

    ::NEXT_HW_LOAD::
  end

  for i, hw_conf in ipairs(conf.devices) do
    if hw_model_id[i] == nil then
      goto NEXT_HW_INIT
    end

    local midi_device = hw_conf.device
    if midi_device == nil then
      midi_device = midiutil.MIDI_DEV_ALL
    end

    local HW = model_libs[hw_conf.model]
    local id_for_model = hw_model_id[i]
    local count_for_model = model_counts[hw_conf.model]
    local hw = HW.new(id_for_model, count_for_model, midi_device, hw_conf.ch, hw_conf.nb)
    if hw_conf.params ~= nil then
      for k, v in pairs(hw_conf.params) do
        if k == 'midi_device' or tab.contains(HW.PARAMS, k) then
          hw[k] = v
        else
          print(MOD_NAME .. ' - WARN - ' .. "Cannot set param "..k.."="..v.." for "..hw_conf.model .. '#' .. id_for_model .. ", unsupported param.")
        end
      end
    end
    table.insert(hw_list, hw)

    ::NEXT_HW_INIT::
  end
end

local function init_devices_params()
  for _, hw in ipairs(hw_list) do
    params:add_group(hw.display_name, hw:get_nb_params())
    hw:register_params()
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

-- NB: only register menu when mod is active
-- the mod can be used as a lib even when not active
if mod.this_name then
  mod.menu.register(MOD_NAME, m)
end

-- -------------------------------------------------------------------------
-- plumbing

mod.hook.register("script_pre_init", MOD_NAME.."-script-pre-init",
                  function()

                    -- local script_init = init
                    -- init = function ()

                    conf = load_conf_file()
                    if conf then
                      init_devices_from_conf(conf)

                      for _, hw in ipairs(hw_list) do
                        if hw.nb and hw.register_nb_players then
                          print(MOD_NAME .. " - registering nb players for: "..hw.display_name)
                          hw:register_nb_players()
                        end
                      end

                    else
                      print(MOD_NAME .. ' - ERR - ' .. "No conf file exists!")
                    end

                    -- script_init()

end)

mod.hook.register("script_post_init", MOD_NAME.."-script-post-init",
                  function()

                    local function midi_event(dev, data, script_event_fn)
                      -- local midiutil = include('librarian/lib/midiutil')

                      local d = midi.to_msg(data)

                      for _, hw in ipairs(hw_list) do
                        if hw.midi_event and (hw.midi_device == dev.name
                                              or (hw.midi_device == midiutil.MIDI_DEV_ALL and not tab.contains(IGNORED_MIDI_DEVS, dev.name))) then
                          local has_channel = tab.contains({"note_on", "note_off",  "pitchbend",
                                                            "key_pressure", "channel_pressure",
                                                            "cc", "program_change"}, d.type)
                          if not has_channel or d.ch == hw.ch then
                            hw:midi_event(dev, data)
                          end
                        end
                      end

                      if script_event_fn then
                        script_event_fn(data)
                      end
                    end

                    for _, dev in pairs(midi.vports) do
                      if dev.connected then
                        local script_dev_event = dev.event
                        dev.event = function(data)
                          midi_event(dev, data, script_dev_event)
                        end
                      end
                    end

                    if conf then
                      params:add_separator("librarian", "librarian")
                      init_devices_params()
                    end

                    librarian_done_init = true
end)

mod.hook.register("script_post_cleanup", MOD_NAME.."-script-post-cleanup",
                  function()
                    for _, hw in ipairs(hw_list) do
                      if hw.cleanup then
                        hw:cleanup()
                      end
                    end
                    tempty(hw_list)
                  end
)


-- -------------------------------------------------------------------------
-- api

local api = {}

function api.is_active()
  return (mod.this_name ~= nil)
end

function api.get_hw_list()
  return hw_list
end

return api
