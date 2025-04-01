-- librarian/model/eventide h3000


local H3000 = {}
local GenericHw = include('librarian/lib/hw')
setmetatable(H3000, {__index = GenericHw})

H3000.KIND = "eventide_h3000"
H3000.SHORTHAND = "h3k"
H3000.DISPLAY_NAME = "Eventide H3000"


-- ------------------------------------------------------------------------
-- deps

local controlspec = require "controlspec"
local formatters = require "formatters"
local midiutil = include('librarian/lib/midiutil')
local h3000 = include('librarian/lib/models/impl/eventide_h3000')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- consts

local FREQ_MIDI_SMOOTH_CLK = 1/20
local MIDI_SMOOTH_THRESHOLD = 1/5

-- local FREQ_PGM_REFRESH = 1/40
-- -- time to wait for the user to stop scrolling pgms before triggering pgm change
-- local TRIG_PGM_CHANGE_S = 1/3
-- -- time to wait for pgm dump after having sent a pgm_change
-- local TRIG_PGM_DUMP_S = 1/2

-- time to wait for pgm change/dump after having sent a dump
local AFTER_PGM_DUMP_WAIT_S = 1/2


-- ------------------------------------------------------------------------
-- API - exposed object params

H3000.PARAMS = {
  'device_id',
}

local DEVICE_ID = 0

local DEFAULT_CH = 1


-- ------------------------------------------------------------------------
-- API - constructors

function H3000.new(MOD_STATE, id, count, midi_device, ch)
  ch = ch or DEFAULT_CH

  local hw = GenericHw.new(
    {
      kind         = H3000.KIND,
      shorthand    = H3000.SHORTHAND,
      display_name = H3000.DISPLAY_NAME,
      -- TODO: a few algos kinda do, but that's rather niche...
      plays_notes  = false,
    },
    MOD_STATE, id, count, midi_device, ch)
  setmetatable(hw, {__index = H3000})

  hw.debug = false

  hw.inhibit_midi = false

  -- current pgm
  -- REVIEW: maybe pass pgm_list in the `GenericHw.new` as it knows how to interpret it?
  hw.pgm_list = {}
  hw.pgm_map = {}
  hw.algo_pgm_map = {}
  hw.name_pgm_map = {}
  local pgm_list = h3000.read_pgm_list()
  if pgm_list then
    hw.pgm_list = pgm_list
    for i, pgm in ipairs(hw.pgm_list) do
      local id, name, algo = table.unpack(pgm)
      hw.pgm_map[id] = {name, algo, i}
      hw.name_pgm_map[name] = id
      if hw.algo_pgm_map[algo] == nil then
        hw.algo_pgm_map[algo] = {}
      end
      table.insert(hw.algo_pgm_map[algo], id)
    end
  end

  hw.current_bank = nil
  hw.current_pgm = nil
  hw.current_pgm_name = nil
  hw.current_algo = nil
  hw.prev_algo = nil
  hw.pgm_change_rcv = nil
  hw.pgm_dump_rcv = nil

  -- midi congestion handling - params
  hw.algo_p_map = {}
  hw.clk_midi_smooth_t = 0
  hw.p_last_sent_t = {}
  hw.p_last_unsent_v = {}
  hw.clock_params = clock.run(function()
      while true do
        clock.sleep(FREQ_MIDI_SMOOTH_CLK)
        p:param_congestion_clock(FREQ_MIDI_SMOOTH_CLK)
      end
  end)

  -- midi congestion handling - pgm
  hw.after_pgm_dump_wait_s = AFTER_PGM_DUMP_WAIT_S
  hw.sent_pgm_t = nil -- REVIEW: keep that one?
  -- hw.clock_pgm_t = 0
  hw.last_sent_pgm_change = false
  hw.sent_pgm_new = false
  hw.is_waiting_for_dump_after_pgm_change = false
  hw.is_waiting_for_dump = false
  -- hw.clock_pgm = clock.run(function()
  --     while true do
  --       clock.sleep(FREQ_PGM_REFRESH)
  --       p:pgm_change_clock(FREQ_PGM_REFRESH)
  --     end
  -- end)
  hw.last_dump_rcv_t = 0

  return hw
end

function H3000:cleanup()
  clock.cancel(self.clock_params)
  clock.cancel(self.clock_pgm)
end


-- ------------------------------------------------------------------------
-- API - norns-assignable params

function H3000:get_nb_params()
  local nb_global_params = 1 -- pgm

  local nb_algo_params = 0
  for _, algo_props in pairs(h3000.ALGOS) do
    nb_algo_params = nb_algo_params + #algo_props.params
  end

  return nb_global_params + nb_algo_params
end

function H3000:register_params()
  local pgm_list_opts = {}
  local pgm_p_id = self.fqid .. '_' .. 'pgm'
  for _, pgm in ipairs(self.pgm_list) do
    local id, name = table.unpack(pgm)
    table.insert(pgm_list_opts, id .. " - " .. strim(name))
  end
  params:add_option(pgm_p_id, "PGM", pgm_list_opts)
  params:set_action(pgm_p_id,
                    function(i)
                      if self.inhibit_midi then
                        return
                      end
                      local pgm_id, _ = table.unpack(self.pgm_list[i])
                      self:pgm_change_async(pgm_id)
  end)



  for algo_id, props in pairs(h3000.ALGOS) do
    local algo_name = props.name
    self.algo_p_map[algo_id] = {}
    for _, p in ipairs(props.params) do
      local param_id = self.fqid .. '_' .. algo_id .. '_' .. p.id
      local is_registered = true
      if p.values then
        params:add_option(param_id, p.name, tvals(p.values))
        params:set_action(param_id,
                          function(val)
                            local v = tkeys(p.values)[val]

                            if self.p_last_sent_t[param_id] == nil
                              or (self.clk_midi_smooth_t - self.p_last_sent_t[param_id]) > MIDI_SMOOTH_THRESHOLD then

                              midiutil.send_nrpn(self.midi_device, self.ch, p.id, v)
                              self.p_last_sent_t[param_id] = self.clk_midi_smooth_t
                              self.p_last_unsent_v[param_id] = nil
                            else
                              self.p_last_unsent_v[param_id] = {p.id, v}
                            end
        end)
      elseif p.min and p.max then
        local fmt
        if p.fmt then
          fmt = p.fmt
        elseif p.unit then
          fmt = function(param)
            return param:get() .. " " .. p.unit
          end
        end
        params:add{type = "number", id = param_id, name = p.name,
                   min = p.min, max = p.max,
                   formatter = fmt
        }
        params:set_action(param_id,
                          function(val)
                            local v = val
                            if p.outfn then
                              v = p.outfn(val)
                            end
                            if self.p_last_sent_t[param_id] == nil
                              or (self.clk_midi_smooth_t - self.p_last_sent_t[param_id]) > MIDI_SMOOTH_THRESHOLD then
                              midiutil.send_nrpn(self.midi_device, self.ch, p.id, v)
                              self.p_last_sent_t[param_id] = self.clk_midi_smooth_t
                              self.p_last_unsent_v[param_id] = nil
                            else
                              self.p_last_unsent_v[param_id] = {p.id, v}
                            end
        end)
      elseif p.is_trig then
        params:add_trigger(param_id, p.name)
        params:set_action(param_id, function(_v)
                            midiutil.send_nrpn(self.midi_device, self.ch, p.id, p.v)
        end)
      else
        is_registered = false
        print("!!! UNEXPECTED PARAM "..param_id)
      end
      if is_registered then
        table.insert(self.algo_p_map[algo_id], param_id)
        params:hide(param_id)
      end
    end
  end
end

function H3000:param_congestion_clock(tick_d)
  self.clk_midi_smooth_t = self.clk_midi_smooth_t + tick_d

  for param_id, p_v in pairs(self.p_last_unsent_v) do
    if (self.clk_midi_smooth_t - self.p_last_sent_t[param_id]) > MIDI_SMOOTH_THRESHOLD then
      midiutil.send_nrpn(self.midi_device, self.ch, table.unpack(p_v))
      self.p_last_sent_t[param_id] = self.clk_midi_smooth_t
      self.p_last_unsent_v[param_id] = nil
    end
  end
end

function H3000:hide_params_for_algo(algo_id)
  if algo_id == nil then
    return
  end
  for _, param_id in ipairs(self.algo_p_map[algo_id]) do
    params:hide(param_id)
  end
end

function H3000:show_params_for_algo(algo_id)
  if algo_id == nil then
    return
  end
  for _, param_id in ipairs(self.algo_p_map[algo_id]) do
    params:show(param_id)
  end
end


-- ------------------------------------------------------------------------
-- midi rcv

function H3000:midi_event(dev, d)
  if d.type == 'sysex' then
    -- NB: expects the full sysex payload to be reassembled by the mod
    self:handle_sysex(d.raw)
  elseif d.type == 'program_change' then
    self:update_state_from_pgm_change(d.val)
  elseif d.type == 'nrpn' then
    print("<- NRPN - #" .. d.nrpn .. " - " .. d.val)
  else
    if self.debug then
      print("<- CC - #" .. d.cc .. " - " .. d.val)
    end
  end
end

function H3000:handle_sysex(raw_payload)
  if h3000.is_sysex_bank_select(raw_payload, self.device_id, self.ch) then
    self:update_state_from_bank_change(raw_payload)
  elseif h3000.is_sysex_pgm_dump(raw_payload, self.device_id) then
    self:update_state_from_pgm_dump(raw_payload)

    local payload = h3000.parse_sysex_payload_ascii_encoded(raw_payload)

    -- param scanning
    -- local is_new_payload = true
    -- for pv, pp in pairs(prev_payloads) do
    --   -- local diff = midiutil.diff_byte_arrays(raw_payload, pp)
    --   -- if tab.count(diff) == 0 then
    -- if midiutil.are_equal_byte_arrays(raw_payload, pp) then
    -- is_new_payload = false
    -- break
    -- end
    -- end
    -- if is_new_payload then
    --   prev_payloads[curr_p .. "_" .. curr_v] = raw_payload
    --   -- midiutil.print_byte_array_midiox(raw_payload)
    -- end

    -- if was initiated by us (client) after a pgm_change...
    -- if self.asked_pgm then
    --   -- and is != than previous known one
    --   local is_new_payload = prev_payload == nil
    --     or not midiutil.are_equal_byte_arrays(raw_payload, prev_payload)
    --   if is_new_payload then
    --     print("new pgm: ".. my_h3000.asked_pgm .. " - " .. my_h3000.current_pgm_name)
    --     prev_payload = raw_payload
    --     scanned_pgm_list[my_h3000.asked_pgm] = {my_h3000.current_pgm_name, my_h3000.current_algo}
    --   end
    -- end

    midiutil.print_byte_array_midiox(payload)

  else
    if self.debug then
      print("<- UNKNOWN SYSEX (" .. (#raw_payload - 2) .. ")")
    end
    midiutil.print_byte_array_midiox(raw_payload)
  end
end


-- ------------------------------------------------------------------------
-- pgm

-- NB: no echo back when initiating PGM CHANGE
-- kinda crappy, can't tell if dest PGM doesn't exist...

-- on startup, sometimes sends (PGM CHANGE - 0)

function H3000:clear_pgm_state()
  self.current_pgm_name = nil
  if self.current_algo then
    self.prev_algo = self.current_algo
    self.current_algo = nil
  end
end

function H3000:pgm_change_async(pgm_id)
  self.asked_pgm_t = self.MOD_STATE.clock_pgm_change_t
  self.asked_pgm = pgm_id
  self:clear_pgm_state()
end

-- NB: setting request_pgm_dump to true will trigger a pgm dump request
-- but this causes issues in some scenarios where the H3000 will crap if sent too soon
function H3000:pgm_change(pgm_id, request_pgm_dump)
  self.last_sent_pgm_change = pgm_id
  if self.debug then
    print("-> PGM CHANGE - " .. pgm_id)
  end

  h3000.pgm_change(self.midi_device, self.ch, self.device_id, pgm_id, request_pgm_dump)

  -- self.sent_pgm_new = true
  self.sent_pgm_t = self.MOD_STATE.clock_pgm_change_t
  self.is_waiting_for_dump_after_pgm_change = true
end

function H3000:update_state_from_bank_change(raw_payload)
  local _, matches = h3000.extract_sysex_bank_select(raw_payload)
  self.current_bank = matches[h3000.MTCH_BANK]
  print("<- BANK SELECT - " .. self.current_bank)
end

function H3000:update_state_from_pgm_change(bank_pgm)
  if self.debug then
    print("<- PGM CHANGE - " .. bank_pgm)
  end
  if self.current_bank then
    self.current_pgm = self.current_bank * 100 + bank_pgm
    self:clear_pgm_state()
    self.sent_pgm_t = self.MOD_STATE.clock_pgm_change_t
    self.is_waiting_for_dump_after_pgm_change = true
  else
    print("   WARN: can't handle as current bank unknown")
  end

  if self.current_pgm then
    local _, _, p_id = table.unpack(self.pgm_map[self.current_pgm])
    if p_id then
      self:update_current_pgm_param(p_id)
    end
  end

  if self.pgm_change_rcv then
    self.pgm_change_rcv(self.current_pgm)
  end
end

function H3000:dump_pgm()
  if self.debug then
    print("-> PGM DUMP")
  end
  self.is_waiting_for_dump = true
  h3000.dump_pgm_current(self.midi_device, self.device_id)
end

function H3000:update_current_pgm_param(pgm_id)
  if self.debug then
    -- print("   UPDATE PGM PARAM: "..pgm_id)
  end

  local pgm = self.pgm_map[pgm_id]
  if pgm == nil then
    print("   Unknown PGM #"..pgm_id)
    return
  end
  local _, _, i = table.unpack(pgm)

  self.inhibit_midi = true
  params:set(self.fqid.."_pgm", i)
  self.inhibit_midi = false
end

function H3000:update_state_from_pgm_dump(raw_payload)
  if self.debug then
    print("<- PGM DUMP (" .. (#raw_payload - 2) .. "B)")
  end

  self.last_dump_rcv_t = self.MOD_STATE.clock_pgm_change_t
  self.pgm_dump_on = nil

  local pgm = h3000.parse_pgm_dump(raw_payload)

  -- NB: past a certain pgm_id, we can't just get it from the pgm_dump payload
  -- (or at least i haven't found where part of the pgm_id is encoded...)
  -- so instead we rely on a previosly dumped map of all programs and use the name as a key
  -- i'm not too happy about that...
  self.current_pgm_name = pgm.name
  -- self.current_pgm = pgm.id
  self.current_pgm = self.name_pgm_map[self.current_pgm_name]
  if self.current_pgm then
    if self.debug then
      print("   "..self.current_pgm_name .. " -> ".. self.current_pgm)
    end
    self:update_current_pgm_param(self.current_pgm)
  end
  self.current_algo = pgm.algo

  if self.debug then
    print("   ALGO: "..self.current_algo)
  end

  if self.prev_algo == nil or prev_algo ~= self.current_algo then
    self:hide_params_for_algo(self.prev_algo)
    self:show_params_for_algo(self.current_algo)
    _menu.rebuild_params()

    if self.prev_algo then
      print("    - hiding: "..self.prev_algo)
    end
    print("    - showing: "..self.current_algo)
  end

  if self.pgm_dump_rcv then
    self.pgm_dump_rcv(pgm)
  end

  if self.debug then
    print("    " .. self.current_pgm .. " " .. self.current_pgm_name .. " (algo=" .. self.current_algo .. ")")
  end

  self.is_waiting_for_dump = false
  self.is_waiting_for_dump_after_pgm_change = false
end

-- function H3000:pgm_change_clock(tick_d)
--   self.clock_pgm_t = self.clock_pgm_t + tick_d

--   local needs_pgm_change = self.asked_pgm_t ~= nil
--     and (self.clock_pgm_t - self.asked_pgm_t) > TRIG_PGM_CHANGE_S

--   local needs_pgm_dump = self.sent_pgm_t ~= nil
--     and (self.clock_pgm_t - self.sent_pgm_t) > TRIG_PGM_DUMP_S

--   local recent_pgm_dump = (self.clock_pgm_t - self.last_dump_rcv_t) < AFTER_PGM_DUMP_WAIT_S

--   -- NB: also temporizes pgm_change / pgm_dump if just did a pgm_dump
--   -- edge-case where H3000 craps and resets to either 100 of <bank>00
--   if needs_pgm_change
--     and not recent_pgm_dump then
--     self:pgm_change(self.asked_pgm)
--     self.asked_pgm_t = nil
--   end

--   if needs_pgm_dump
--     and not recent_pgm_dump then
--     self:dump_pgm()
--     self.sent_pgm_t = nil
--   end

-- end


-- ------------------------------------------------------------------------
-- specific (global) params

function H3000:set_bypass(state)
  h3000.set_bypass(self.midi_device, self.ch, state)
end


-- ------------------------------------------------------------------------

return H3000
