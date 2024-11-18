-- librarian mod.
-- @eigen

local mod = require 'core/mods'
local MOD_NAME = mod.this_name or "librarian"

local binutils  = include('librarian/lib/binutils')
local GenericHw  = include('librarian/lib/hw')
local hwutils  = include('librarian/lib/hwutils')
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
  -- - rpn / nrpn
  dev_rpn_mode = {},
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
      hw = GenericHw.new(HW, MOD_STATE, id, count_for_model, midi_device, hw_conf.ch)
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
-- midi plumbing

local function midi_event(MOD_STATE, dev, data, script_event_fn)
  local d = midi.to_msg(data)

  -- TODO: use device port (or device name + device port) in order to support multiple devices w/ same name
  local dev_id = dev.name

  -- --------------------------------
  -- sysex / (n)rpn reassembly

  local has_done_sysex = false
  local has_done_rpn = false
  local has_done_nrpn = false
  local rpn = nil
  local nrpn = nil

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

    local should_parse_rpn = hwutils.should_parse_rpn(dev, d.ch, MOD_STATE.hw_map, MOD_STATE.hw_rpn_map)
    local should_parse_nrpn = hwutils.should_parse_nrpn(dev, d.ch, MOD_STATE.hw_map, MOD_STATE.hw_nrpn_map)

    if (should_parse_rpn or should_parse_nrpn) then
      MOD_STATE.dev_rpn_p_msb[dev.name] = MOD_STATE.dev_rpn_p_msb[dev.name] or {}
      MOD_STATE.dev_rpn_p_msb[dev.name][d.ch] = MOD_STATE.dev_rpn_p_msb[dev.name][d.ch] or {}
      MOD_STATE.dev_rpn_p_lsb[dev.name] = MOD_STATE.dev_rpn_p_lsb[dev.name] or {}
      MOD_STATE.dev_rpn_p_lsb[dev.name][d.ch] = MOD_STATE.dev_rpn_p_lsb[dev.name][d.ch] or {}
    end

    if should_parse_rpn and tab.contains({101, 100}, d.cc) then
      MOD_STATE.dev_rpn_mode[dev.name][d.ch] = 'rpn'
      if d.cc == 101 then
        MOD_STATE.dev_rpn_p_msb[dev.name][d.ch] = d.val
      elseif d.cc == 100 then
        MOD_STATE.dev_rpn_p_lsb[dev.name][d.ch] = d.val
      end
    elseif should_parse_nrpn and tab.contains({99, 98}, d.cc) then
      MOD_STATE.dev_rpn_mode[dev.name][d.ch] = 'nrpn'
      if d.cc == 99 then
        MOD_STATE.dev_rpn_p_msb[dev.name][d.ch] = d.val
      elseif d.cc == 98 then
        MOD_STATE.dev_rpn_p_lsb[dev.name][d.ch] = d.val
      end
    elseif (should_parse_rpn or should_parse_nrpn) and tab.contains({6, 38}, d.cc) then
      if d.cc == 6 then
        MOD_STATE.dev_rpn_v_msb[dev.name][d.ch] = d.val
      elseif d.cc == 38 then
        MOD_STATE.dev_rpn_v_lsb[dev.name][d.ch] = d.val
        local got_complete_sequence = ( MOD_STATE.dev_rpn_p_msb[dev.name][d.ch]
                                        and MOD_STATE.dev_rpn_p_lsb[dev.name][d.ch]
                                        and MOD_STATE.dev_rpn_v_msb[dev.name][d.ch] )
        if MOD_STATE.dev_rpn_mode[dev.name][d.ch] == 'rpn' then
          has_done_rpn = got_complete_sequence
        elseif MOD_STATE.dev_rpn_mode[dev.name][d.ch] == 'nrpn' then
          has_done_nrpn = got_complete_sequence
        else
          print(MOD_NAME .. ' - WARN - ' .. "done parsing (N)RPN value but don't know which kind it is.")
        end
      end
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
      rpn = (MOD_STATE.dev_rpn_p_msb[dev.name][d.ch] << 7) + MOD_STATE.dev_rpn_p_lsb[dev.name][d.ch],
      val = (MOD_STATE.dev_rpn_v_msb[dev.name][d.ch] << 7) + MOD_STATE.dev_rpn_v_lsb[dev.name][d.ch],
    }
    MOD_STATE.dev_rpn_mode[dev.name][d.ch]  = nil
    MOD_STATE.dev_rpn_v_msb[dev.name][d.ch] = nil
    MOD_STATE.dev_rpn_v_lsb[dev.name][d.ch] = nil
  elseif has_done_nrpn then
    nrnp = {
      type = 'nrpn',
      ch = d.ch,
      nrpn = (MOD_STATE.dev_rpn_p_msb[dev.name][d.ch] << 7) + MOD_STATE.dev_rpn_p_lsb[dev.name][d.ch],
      val = (MOD_STATE.dev_rpn_v_msb[dev.name][d.ch] << 7) + MOD_STATE.dev_rpn_v_lsb[dev.name][d.ch],
    }
    MOD_STATE.dev_rpn_mode[dev.name][d.ch]  = nil
    MOD_STATE.dev_rpn_v_msb[dev.name][d.ch] = nil
    MOD_STATE.dev_rpn_v_lsb[dev.name][d.ch] = nil
  elseif has_done_cc14 then
    cc14 = {
      type = 'cc14',
      ch = d.ch,
      cc14 = {}, -- TODO: set it!
      val = (MOD_STATE.dev_cc14_v_msb[dev.name] << 7) + MOD_STATE.dev_cc14_v_lsb[dev.name],
    }
  end


  -- --------------------------------
  -- send to each matching hw

  for _, hw in ipairs(MOD_STATE.hw_list) do
    if hwutils.hw_matched_dev(hw, dev)
    -- FIXME: need to support that device can listen of multiple midi channels
      and ((not d.ch) or d.ch == hw.ch) then

      if hw.midi_event then

        -- if hwutils.should_parse_as_cc14(dev, d.ch, d.cc, MOD_STATE.cc14_hw_map) then
        --   print("received cc14")
        --   -- TODO: parse
        -- end

        local d2 = d
        if has_done_rpn and hwutils.listens_for_rpn(MOD_STATE.hw, MOD_STATE.hw_rpn_map) then
          d2 = rpn
        elseif has_done_nrpn and hwutils.listens_for_nrpn(MOD_STATE.hw, MOD_STATE.hw_nrpn_map) then
          d2 = nrpn
        elseif d.cc then
          local cc14_id = hw.cc14_param_map and midiutil.matched_cc14_for_cc(cc, hw.cc14_param_map)
          if cc14_id then

            -- REVIEW: is testing the channel here even a good thing?!
            -- case of hw that listen as regular cc on one channel and as cc14 on another one
            -- this test might not work as for multitrimbral synths we'd generally inject the ch dynamically, or even set it in the action callback
            -- this works for sending, but note for receiving
            -- -> we'd need an explicit ch/(cc|cc14|rpn|nrpn) -> fqid_p map, so we can target the "correct" param
            -- yet, there is the edge-case of multitimbral hw that have several fqid_p w/ same ch/cc, but only a "selected one" (e.g. Korg MS2000)
            -- could dwork if the map ONLY registers pp that have a custom ch configured

            -- local p = hw.cc14_param_map[binutils.ensure_14bits_as_val(cc14_id)]
            -- local pp = hw.param_props_map[p]
            -- if not pp.ch or pp.ch = d.ch then
            -- end

            if d.cc == cc14_id[1] then
              -- MSB
              MOD_STATE.dev_cc14_v_msb[hw.fqid] = MOD_STATE.dev_cc14_v_msb[hw.fqid] or {}
              MOD_STATE.dev_cc14_v_msb[hw.fqid][dev.name] = MOD_STATE.dev_cc14_v_msb[hw.fqid][dev.name] or {}
              MOD_STATE.dev_cc14_v_msb[hw.fqid][dev.name][d.ch] = d.val
              goto NEXT_HW_MIDI_RCV
            else
              -- LSB
              d2 = {
                type = 'cc14',
                ch = d.ch,
                cc14 = cc14_id,
                val = (MOD_STATE.dev_cc14_v_msb[hw.fqid][dev.name][d.ch] << 7) + d.val,
              }
              MOD_STATE.dev_cc14_v_msb[hw.fqid][dev.name][d.ch] = nil
            end
          end
        end

        hw:midi_event(dev, d2)

        if d.type == 'program_change' then
          hw.needs_pgm_dump = true
          hw.needs_pgm_dump_t = MOD_STATE.clock_pgm_dump_t
        end

      end
    end

    ::NEXT_HW_MIDI_RCV::
  end

  if script_event_fn then
    script_event_fn(data)
  end
end

-- check if we need to send a pgm change
local function pgm_change_clock_fn()
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
end

-- check if we need to send a pgm dump
local function pgm_dump_clock_fn()
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
end


-- -------------------------------------------------------------------------
-- mod hooks

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

                    for _, dev in pairs(midi.vports) do
                      if dev.connected then
                        local script_dev_event = dev.event
                        dev.event = function(data)
                          midi_event(MOD_STATE, dev, data, script_dev_event)
                        end
                      end
                    end

                    pgm_change_clock = clock.run(pgm_change_clock_fn)
                    pgm_dump_clock = clock.run(pgm_dump_clock_fn)

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
