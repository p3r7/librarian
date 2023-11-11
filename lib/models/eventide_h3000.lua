-- librarian/model/eventide h3000


local H3000 = {}
H3000.__index = H3000

H3000.KIND = "Eventide H3000"
H3000.SHORTHAND = "H3000"


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

local FREQ_PGM_REFRESH = 1/20
local TRIG_PGM_CHANGE_S = 1/3
local TRIG_PGM_DUMP_S = 1/5


-- ------------------------------------------------------------------------
-- API - supported object params

H3000.PARAMS = {
  'device_id',
}

local DEVICE_ID = 0


-- ------------------------------------------------------------------------
-- API - constructors

function H3000.new(id, midi_device, ch)
  local p = setmetatable({}, H3000)

  p.kind = H3000.KIND
  p.shorthand = H3000.SHORTHAND

  p.id = id
  p.fqid = p.shorthand.."_"..id
  p.display_name = p.kind.." #"..id

  p.midi_device = midi_device

  if ch == nil then ch = 1 end
  p.ch = ch

  p.device_id = DEVICE_ID

  p.debug = false

  -- current pgm
  p.current_bank = nil
  p.current_pgm = nil
  p.current_pgm_name = nil
  p.current_algo = nil
  p.pgm_dump_rcv = nil

  -- midi congestion handling - params
  p.algo_p_map = {}
  p.clk_midi_smooth_t = 0
  p.p_last_sent_t = {}
  p.p_last_unsent_v = {}
  p.clock_params = clock.run(function()
      while true do
        clock.sleep(FREQ_MIDI_SMOOTH_CLK)
        p:param_congestion_clock(FREQ_MIDI_SMOOTH_CLK)
      end
  end)

  -- midi congestion handling - pgm
  p.clock_pgm_t = 0
  p.last_sent_pgm_change = false
  p.sent_pgm_new = false
  p.is_waiting_for_dump_after_pgm_change = false
  p.is_waiting_for_dump = false
  p.clock_pgm = clock.run(function()
      while true do
        clock.sleep(FREQ_PGM_REFRESH)
        p:pgm_change_clock(FREQ_PGM_REFRESH)
      end
  end)
  p.last_dump_rcv_t = 0

  return p
end


-- ------------------------------------------------------------------------
-- API - norns-assignable params

function H3000:get_nb_params()
  local nb_algo_params = 0
  for _, algo_props in pairs(h3000.ALGOS) do
    nb_algo_params = nb_algo_params + #algo_props.params
  end

  return nb_algo_params
end

function H3000:register_params()

  for algo_id, props in pairs(h3000.ALGOS) do
    local algo_name = props.name
    self.algo_p_map[algo_id] = {}
    for _, p in ipairs(props.params) do
      local param_id = self.fqid .. '_' .. algo_id .. '_' .. p.id

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
        table.insert(self.algo_p_map[algo_id], param_id)
        params:hide(param_id)
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
        table.insert(self.algo_p_map[algo_id], param_id)
        params:hide(param_id)
      end
    end
  end

  -- self.clock_midi_smooth = clock.run(function()
  --     while true do
  --       clock.sleep(FREQ_MIDI_SMOOTH_CLK)
  --       self.clk_midi_smooth_t = self.clk_midi_smooth_t + FREQ_MIDI_SMOOTH_CLK

  --       for param_id, p_v in pairs(self.p_last_unsent_v) do
  --         if (self.clk_midi_smooth_t - self.p_last_sent_t[param_id]) > MIDI_SMOOTH_THRESHOLD then
  --           midiutil.send_nrpn(self.midi_device, self.ch, table.unpack(p_v))
  --           self.p_last_sent_t[param_id] = self.clk_midi_smooth_t
  --           self.p_last_unsent_v[param_id] = nil
  --         end
  --       end
  --     end
  -- end)
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
-- pgm

-- NB: no echo back when initiating PGM CHANGE
-- kinda crappy, can't tell if dest PGM doesn't exist...

-- on startup, sometimes sends (PGM CHANGE - 0)

function H3000:pgm_change(pgm_id)
  -- self.asked_pgm_new = true
  self.asked_pgm_t = self.clock_pgm_t
  self.asked_pgm = pgm_id
end

-- NB: setting request_pgm_dump to true will trigger a pgm dump request
-- but this causes issues in some scenarios where the H3000 will crap if sent too soon
function H3000:pgm_change_sync(pgm_id, request_pgm_dump)
  if m == nil then
    return
  end
  self.last_sent_pgm_change = pgm_id
  if self.debug then
    print("-> PGM CHANGE - " .. pgm_id)
  end

  h3000.pgm_change(self.midi_device, self.ch, self.device_id, pgm_id, request_pgm_dump)

  -- self.sent_pgm_new = true
  self.sent_pgm_t = self.clock_pgm_t
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
    self.current_pgm_name = nil
    self.current_algo = nil
    self.sent_pgm_t = self.clock_pgm_t
    self.is_waiting_for_dump_after_pgm_change = true
  else
    print("   WARN: can't handle as current bank unknown")
  end
end

function H3000:dump_pgm()
  if self.debug then
    print("-> PGM DUMP")
  end
  self.is_waiting_for_dump = true
  h3000.dump_pgm_current(self.midi_device, self.device_id)
end

function H3000:update_state_from_pgm_dump(raw_payload)
  if self.debug then
    print("<- PGM DUMP (" .. (#raw_payload - 2) .. "B)")
  end

  local pgm = h3000.parse_pgm_dump(raw_payload)

  self.current_pgm = pgm.id
  self.current_pgm_name = pgm.name
  local prev_algo = self.current_algo
  self.current_algo = pgm.algo

  if prev_algo ~= self.current_algo then
    self:hide_params_for_algo(prev_algo)
    self:show_params_for_algo(self.current_algo)
    _menu.rebuild_params()
  end

  if self.pgm_dump_rcv then
    self.pgm_dump_rcv(pgm)
  end

  if self.debug then
    print("    " .. self.current_pgm .. " " .. self.current_pgm_name .. " (algo=" .. self.current_algo .. ")")
  end

  self.last_dump_rcv_t = self.clock_pgm_t
  self.is_waiting_for_dump = false
  self.is_waiting_for_dump_after_pgm_change = false
end

function H3000:pgm_change_clock(tick_d)
  self.clock_pgm_t = self.clock_pgm_t + tick_d

  local needs_pgm_change = self.asked_pgm_t ~= nil
    and (self.clock_pgm_t - self.asked_pgm_t) > TRIG_PGM_CHANGE_S

  local needs_pgm_dump = self.sent_pgm_t ~= nil
    and (self.clock_pgm_t - self.sent_pgm_t) > TRIG_PGM_DUMP_S

  -- local recent_pgm_dump = (self.clock_pgm_t - self.last_dump_rcv_t) < TRIG_PGM_CHANGE_S
  local recent_pgm_dump = false

  -- NB: also temporizes pgm_change / pgm_dump if just did a pgm_dump
  -- edge-case where H3000 craps and resets to either 100 of <bank>00
  if needs_pgm_change
    and not recent_pgm_dump then
    self:pgm_change_sync(self.asked_pgm)
    self.asked_pgm_t = nil
  end

  if needs_pgm_dump
    and not recent_pgm_dump then
    self:dump_pgm()
    self.sent_pgm_t = nil
  end

end


-- ------------------------------------------------------------------------
-- specific (global) params

function H3000:set_bypass(state)
  h3000.set_bypass(self.midi_device, self.ch, state)
end


-- ------------------------------------------------------------------------

return H3000
