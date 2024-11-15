-- librarian mod.
-- @eigen

local mod = require 'core/mods'
local MOD_NAME = mod.this_name or "librarian"

local hwutils = include('librarian/lib/hwutils')
local midiutil = include('librarian/lib/midiutil')

local function tempty(t)
  for k, v in pairs(t) do
    t[k] = nil
  end
end


-- -------------------------------------------------------------------------
-- state

local hw_list = {}
local hw_map = {}
local MOD_STATE = {
  hw_list = hw_list,
  hw_map = hw_map,
  conf = nil,

  clock_pgm_change_t = 0,
  clock_pgm_dump_t = 0,

  -- midi payload reassembly
  -- - sysex
  dev_sysex_dump_on = {},
  dev_sysex_payload = {},
  -- - cc14
  dev_cc14_v_msb = {},
  dev_cc14_v_lsb = {},
  -- - nrpn
  dev_nrpn_p_msb = {},
  dev_nrpn_p_lsb = {},
  dev_nrpn_v_msb = {},
  dev_knrpn_v_lsb = {},
  -- - rpn
  dev_rpn_p_msb = {},
  dev_rpn_p_lsb = {},
  dev_rpn_v_msb = {},
  dev_rpn_v_lsb = {},
}

-- NB: `pgm_dump_clock` re-fetches current pgm params, not necessarilly through a midi pgm_dump, it can use other APIs if available
local pgm_change_clock = nil
local pgm_dump_clock = nil

-- time to wait for the user to stop scrolling pgms before triggering pgm change
local TRIG_PGM_CHANGE_S = 1/3
-- time to wait for pgm dump after having sent a pgm_change
local TRIG_PGM_DUMP_S = 1/2
-- time to wait for pgm change/dump after having sent a dump
local AFTER_PGM_DUMP_WAIT_S = 1/10

-- at which rate to check for the need to send pgm changes
local FREQ_PGM_CHANGE = 1/40
-- local FREQ_PGM_DUMP = 1/40
local FREQ_PGM_DUMP = 1

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

    local midi_device = hw_conf.device or midiutil.MIDI_DEV_ALL

    local HW = model_libs[hw_conf.model]
    local id = hw_model_id[i]
    local count_for_model = model_counts[hw_conf.model]
    local hw
    if HW.new then
      hw = HW.new(MOD_STATE, id, count_for_model,
                  midi_device, hw_conf.ch, hw_conf.nb)
    else
      hw = hwutils.hw_from_static(HW, MOD_STATE, id, count_for_model, midi_device, hw_conf.ch)
    end
    if hw_conf.params ~= nil then
      for k, v in pairs(hw_conf.params) do
        if k == 'midi_device' or tab.contains(HW.PARAMS, k) then
          hw[k] = v
        else
          print(MOD_NAME .. ' - WARN - ' .. "Cannot set param "..k.."="..v.." for "..hw_conf.model .. '#' .. id .. ", unsupported param.")
        end
      end
    end
    table.insert(hw_list, hw)
    hw_map[hw.fqid] = hw

    ::NEXT_HW_INIT::
  end
end

local function init_devices_params()
  for _, hw in ipairs(hw_list) do
    params:add_group(hw.display_name, hw:get_nb_params())
    hw:register_params()
  end

  -- NB: we need to call those after registering params
  -- so that each underlying hw param maps are set
  MOD_STATE.hw_cc_map   = hwutils.hw_cc_map(hw_list)
  MOD_STATE.hw_cc14_map = hwutils.hw_cc14_map(hw_list)
  MOD_STATE.cc14_hw_map = hwutils.cc14_hw_map(hw_list)
  MOD_STATE.hw_rpn_map  = hwutils.hw_rpn_map(hw_list)
  MOD_STATE.hw_nrpn_map = hwutils.hw_nrpn_map(hw_list)

  _menu.rebuild_params()
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

                    MOD_STATE.conf = load_conf_file()
                    if MOD_STATE.conf then
                      init_devices_from_conf(MOD_STATE.conf)

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

                    -- NB: we do sysex reassembly at this level but let the interpretation of other messages to each hw implem
                    -- this is esp. the case for cc14/rpn/nrpn reassembly
                    local function midi_event(dev, data, script_event_fn)
                      local d = midi.to_msg(data)

                      -- TODO: use device port (or device name + device port) in order to support multiple devices w/ same name
                      local dev_id = dev.name

                      local has_done_sysex = false
                      local has_done_rpn = false
                      local rpn = nil
                      local has_done_nrpn = false
                      local nrpn = nil
                      local has_done_cc14 = false
                      local cc14 = nil

                      if MOD_STATE.dev_sysex_dump_on[dev_id] then
                        -- print("-> sysex (cont.)")
                        -- midiutil.print_byte_array_midiox(data)

                        for _, b in pairs(data) do
                          table.insert(MOD_STATE.dev_sysex_payload[dev_id], b)
                          if b == 0xf7 then
                            has_done_sysex = true
                            MOD_STATE.dev_sysex_dump_on[dev_id] = false
                          end
                        end
                      elseif d.type == 'sysex' then
                        -- print("-> sysex")
                        -- midiutil.print_byte_array_midiox(data)
                        MOD_STATE.dev_sysex_dump_on[dev_id] = true
                        MOD_STATE.dev_sysex_payload[dev_id] = {}
                        for _, b in pairs(d.raw) do
                          table.insert(MOD_STATE.dev_sysex_payload[dev_id], b)
                          if b == 0xf7 then
                            has_done_sysex = true
                            MOD_STATE.dev_sysex_dump_on[dev_id] = false
                          end
                        end
                      elseif d.type == 'cc' then
                        -- TODO: handle both RPN and NRPN in //
                        -- indeed, they use the same CCs for the val

                        -- TODO: this is way more tricky than that.
                        -- i need namespacing by ch + for cc14 by hw

                        if hwutils.should_parse_rpn(dev, d.ch, MOD_STATE.hw_map, MOD_STATE.hw_rpn_map)
                          and tab.contains({101, 100, 6, 38}, d.cc) then
                          if d.cc == 101 then
                            MOD_STATE.dev_rpn_p_msb[dev.name] = d.val
                          elseif d.cc == 100 then
                            MOD_STATE.dev_rpn_p_lsb[dev.name] = d.val
                          elseif d.cc == 6 then
                            MOD_STATE.dev_rpn_v_msb[dev.name] = d.val
                          elseif d.cc == 38 then
                            MOD_STATE.dev_rpn_v_lsb[dev.name] = d.val
                            has_done_rpn = true
                          end
                        elseif hwutils.should_parse_nrpn(dev, d.ch, MOD_STATE.hw_map, MOD_STATE.hw_nrpn_map)
                          and tab.contains({99, 98, 6, 38}, d.cc) then
                          if d.cc == 99 then
                            MOD_STATE.dev_nrpn_p_msb[dev.name] = d.val
                          elseif d.cc == 98 then
                            MOD_STATE.dev_nrpn_p_lsb[dev.name] = d.val
                          elseif d.cc == 6 then
                            MOD_STATE.dev_nrpn_v_msb[dev.name] = d.val
                          elseif d.cc == 38 then
                            MOD_STATE.dev_nrpn_v_lsb[dev.name] = d.val
                            has_done_nrpn = true
                          end
                        elseif hwutils.should_parse_as_cc14(dev, d.ch, d.cc, MOD_STATE.cc14_hw_map) then
                          print("received cc14")
                          -- TODO: parse
                        end
                      end

                      if has_done_sysex then
                        d = {
                          type = 'sysex',
                          raw = MOD_STATE.dev_sysex_payload[dev_id],
                        }
                      elseif has_done_rpn then
                        rpn = {
                          type = 'rpn',
                          ch = d.ch,
                          rpn = (MOD_STATE.dev_rpn_p_msb[dev.name] << 7) + MOD_STATE.dev_nrpn_p_lsb[dev.name],
                          val = (MOD_STATE.dev_rpn_v_msb[dev.name] << 7) + MOD_STATE.dev_nrpn_v_lsb[dev.name],
                        }
                        -- REVIEW: clear `MOD_STATE.dev_rpn_*`
                      elseif has_done_nrpn then
                        nrnp = {
                          type = 'nrpn',
                          ch = d.ch,
                          nrpn = (MOD_STATE.dev_nrpn_p_msb[dev.name] << 7) + MOD_STATE.dev_nrpn_p_lsb[dev.name],
                          val = (MOD_STATE.dev_nrpn_v_msb[dev.name] << 7) + MOD_STATE.dev_nrpn_v_lsb[dev.name],
                        }
                        -- REVIEW: clear `MOD_STATE.dev_nrpn_*`
                      elseif has_done_cc14 then
                        cc14 = {
                          type = 'cc14',
                          ch = d.ch,
                          cc14 = {}, -- TODO: set it!
                          val = (MOD_STATE.dev_cc14_v_msb[dev.name] << 7) + MOD_STATE.dev_cc14_v_lsb[dev.name],
                        }
                      end

                      for _, hw in ipairs(hw_list) do
                        if hwutils.hw_matched_dev(hw, dev) then

                          -- FIXME: need to support that device can listen of multiple midi channels
                          if hw.midi_event and ((not d.ch) or d.ch == hw.ch) then

                            local d2 = d
                            if has_done_rpn and hwutils.listens_for_rpn(MOD_STATE.hw, MOD_STATE.hw_rpn_map) then
                              d2 = rpn
                            elseif has_done_nrpn and hwutils.listens_for_nrpn(MOD_STATE.hw, MOD_STATE.hw_nrpn_map) then
                              d2 = nrpn
                            end

                            hw:midi_event(dev, d2)

                            if d.type == 'program_change' then
                              hw.needs_pgm_dump = true
                              hw.needs_pgm_dump_t = MOD_STATE.clock_pgm_dump_t
                            end
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

                    pgm_change_clock = clock.run(function()
                        while true do
                          clock.sleep(FREQ_PGM_CHANGE)
                          MOD_STATE.clock_pgm_change_t = MOD_STATE.clock_pgm_change_t + FREQ_PGM_CHANGE

                          for _, hw in ipairs(hw_list) do

                            local after_pgm_dump_wait_s = hw.after_pgm_dump_wait_s or AFTER_PGM_DUMP_WAIT_S

                            if hw.pgm_change == nil or hw.asked_pgm == nil then
                              goto NEXT_HW_PGM_CHANGE
                            end

                            -- just received need for a new pgm change
                            -- -> mark last pgm change request time as now & skip
                            if hw.asked_pgm and hw.asked_pgm_t == nil then
                              hw.asked_pgm_t = MOD_STATE.clock_pgm_change_t
                              hw.needs_pgm_dump = false
                              hw.needs_pgm_dump_t = nil
                              goto NEXT_HW_PGM_CHANGE
                            end

                            local needs_pgm_change = (MOD_STATE.clock_pgm_change_t - hw.asked_pgm_t) > TRIG_PGM_CHANGE_S
                            local recent_pgm_dump = hw.last_dump_rcv_t ~= nil and (MOD_STATE.clock_pgm_change_t - hw.last_dump_rcv_t) < after_pgm_dump_wait_s

                            if needs_pgm_change
                              and not recent_pgm_dump then
                              print("-> PGM CHANGE - "..hw.fqid.." - "..hw.asked_pgm)

                              hw:pgm_change(hw.asked_pgm)
                            end

                            ::NEXT_HW_PGM_CHANGE::
                          end
                        end
                    end)

                    pgm_dump_clock = clock.run(function()
                        while true do
                          clock.sleep(FREQ_PGM_DUMP)
                          MOD_STATE.clock_pgm_dump_t = MOD_STATE.clock_pgm_dump_t + FREQ_PGM_DUMP

                          for _, hw in ipairs(hw_list) do

                            local after_pgm_dump_wait_s = hw.after_pgm_dump_wait_s or AFTER_PGM_DUMP_WAIT_S

                            if hw.dump_pgm == nil or not hw.needs_pgm_dump then
                              goto NEXT_HW_PGM_DUMP
                            end

                            -- just received need for a new pgm change
                            -- -> mark last pgm change request time as now & skip
                            if hw.needs_pgm_dump and hw.needs_pgm_dump_t == nil then
                              hw.needs_pgm_dump_t = MOD_STATE.clock_pgm_dump_t
                              goto NEXT_HW_PGM_DUMP
                            end

                            local needs_pgm_dump = (MOD_STATE.clock_pgm_dump_t - hw.needs_pgm_dump_t) > TRIG_PGM_DUMP_S
                            local recent_pgm_dump = hw.last_dump_rcv_t ~= nil and (MOD_STATE.clock_pgm_change_t - hw.last_dump_rcv_t) < after_pgm_dump_wait_s

                            if needs_pgm_dump
                              and not recent_pgm_dump then
                              print("-> PGM DUMP - "..hw.fqid)

                              hw:dump_pgm()
                              hw.needs_pgm_dump = false
                              hw.needs_pgm_dump_t = nil
                            end

                            ::NEXT_HW_PGM_DUMP::
                          end
                        end
                    end)

                    if MOD_STATE.conf then
                      params:add_separator("librarian", "librarian")
                      init_devices_params()
                    end

                    librarian_done_init = true
end)

mod.hook.register("script_post_cleanup", MOD_NAME.."-script-post-cleanup",
                  function()

                    if pgm_change_clock then
                      clock.cancel(pgm_change_clock)
                    end
                    if pgm_dump_clock then
                      clock.cancel(pgm_dump_clock)
                    end

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
