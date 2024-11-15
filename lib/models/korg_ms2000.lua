-- librarian/model/korg ms2000

local MS2000 = {}
MS2000.__index = MS2000

MS2000.KIND = "korg_ms2000"
MS2000.SHORTHAND = "ms2k"
MS2000.DISPLAY_NAME = "Korg MS2000"


-- ------------------------------------------------------------------------
-- deps

local inspect = include("librarian/lib/inspect")

local hwutils = include('librarian/lib/hwutils')
local midiutil = include("librarian/lib/midiutil")
local paramutils = include('librarian/lib/paramutils')

local ms2000_sysex = include('librarian/lib/models/impl/korg_ms2000/sysex')
local ms2000_params = include('librarian/lib/models/impl/korg_ms2000/params')


-- ------------------------------------------------------------------------
-- API - exposed object params

MS2000.PARAMS = {
  'device_id',
}


-- ------------------------------------------------------------------------
-- API - constructors

function MS2000.new(MOD_STATE, id, count, midi_device, ch)
  local p = setmetatable({}, MS2000)

  p.MOD_STATE = MOD_STATE

  p.kind = MS2000.KIND
  p.shorthand = MS2000.SHORTHAND
  p.display_name = MS2000.DISPLAY_NAME

  p.id = id
  p.fqid = p.shorthand.."_"..id
  if count > 1 then
    p.display_name = p.display_name.." #"..id
  end

  p.midi_device = midi_device

  if ch == nil then ch = 1 end
  p.ch = ch

  -- NB: the device_id in sysex calls is equal to `ch`
  -- but it's interesting to be able to configure something else for when handling midi routing by overriding `ch` "on the wire"
  p.device_id = ch

  p.debug = false

  p.inhibit_midi = nil

  p.current_pgm_id = nil
  p.current_pgm_name = nil

  p.last_dump_rcv_t = nil

  p.timbre_params = {}

  p.child_hw = {}
  for t=1,2 do
    local hw = hwutils.cloned(p)
    hw.fqid = p.fqid..'_t'..t
    hw.debug = true -- FIXME: tmp
    p.child_hw[t] = hw
  end

  return p
end


-- ------------------------------------------------------------------------
-- API - norns-assignable params

function MS2000:get_nb_params()
  local nb_global_params = #ms2000_params.EDIT_MODE_PARAMS + #ms2000_params.GLOBAL_PARAMS + 1 -- +1 for pgm select

  local nb_timbre_params = (#ms2000_params.TIMBRE_PARAMS + 1) * 2 -- bi-timbral, +1 for separators

  return nb_global_params + nb_timbre_params
end

MS2000.BANK_NAMES = { "TRANCE", "TECHNO+HOUSE", "ELECTRONICA", "D'n'B+BREAKS",
                      "HIPHOP+VINTAGE", "RETRO", "S.E.+HIT", "VOCODER" }

function MS2000.make_pgm_list()
  -- TODO: redo it programatically
  -- i took the lazy approach (copy-paste)

  local programs = {}

  for _, bs_name in ipairs({"A", "B"}) do
    for b_i, b_name in ipairs(MS2000.BANK_NAMES) do
      for i=1,8 do
        local pgm_name = b_name .. " " .. bs_name .. "." .. b_i .. i
        table.insert(programs, pgm_name)
      end
    end
  end

  return programs
end

function MS2000:register_params()
  local pgm_list_opts = MS2000.make_pgm_list()
  local pgm_p_id = self.fqid .. '_' .. 'pgm'
  params:add_option(pgm_p_id, "PGM", pgm_list_opts)
  params:set_action(pgm_p_id,
                    function(v)
                      if self.inhibit_midi then
                        return
                      end
                      -- NB: we don't directly send a PGM change but wait for the param to stop changing before firing
                      -- this prevents spamming the device w/ all the intermediate PGM change requests
                      self:pgm_change_async(v)
  end)

  paramutils.add_params(self, ms2000_params.EDIT_MODE_PARAM_PROPS, ms2000_params.EDIT_MODE_PARAMS)

  paramutils.add_params(self, ms2000_params.GLOBAL_PARAM_PROPS, ms2000_params.GLOBAL_PARAMS)
  for t=1,2 do
    local hw = self.child_hw[t]
    params:add_separator(hw.fqid, "Timbre "..t)

    self.timbre_params[t] = paramutils.add_params(hw, ms2000_params.TIMBRE_PARAM_PROPS, ms2000_params.TIMBRE_PARAMS,
                                                  function(hw, p, pp, val)
                                                    local og_hw = hwutils.og(hw)
                                                    if og_hw.inhibit_midi then
                                                      return
                                                    end

                                                    local current_timbre = params:get(self.fqid..'_'..'edited_timbre')
                                                    if current_timbre ~= t then
                                                      params:set(self.fqid..'_'..'edited_timbre', t)
                                                    end
                                                    paramutils.set(hw, p, pp, val)
    end)
    table.insert(self.timbre_params[t], hw.fqid) -- separator
  end
end


-- ------------------------------------------------------------------------
-- impl - pgm

function MS2000:clear_pgm_state()
  self.current_pgm_id = nil
  self.current_pgm_name = nil
end

function MS2000:pgm_change_async(pgm_id)
  self.asked_pgm = pgm_id
  self.asked_pgm_t = self.MOD_STATE.clock_pgm_change_t

  -- REVIEW: do it now or at effective PGM change send?
  self:clear_pgm_state()
end

function MS2000:pgm_change(pgm_id, request_pgm_dump)
  midiutil.send_pgm_change(self.midi_device, self.ch, pgm_id-1)

  self.asked_pgm = nil
  self.asked_pgm_t = nil
  self.needs_pgm_dump = true
  self.needs_pgm_dump_t = self.MOD_STATE.clock_pgm_dump_t
end


-- ------------------------------------------------------------------------
-- impl - midi rcv

function MS2000:midi_event(dev, d)
  if d.type == 'sysex' then
    -- NB: expects the full sysex payload to be reassembled by the mod
    self:handle_sysex(d.raw)
  elseif d.type == 'program_change' then
    if self.debug then
      print("<- PGM CHANGE - " .. self.fqid .. " - " .. d.val)
    end
    self:update_state_from_pgm_change(d.val)
  elseif d.type == 'cc' then
    -- d.cc / d.val
    if self.debug then
      print("<- CC - " .. self.fqid .. " - #" .. d.cc .. " - " .. d.val)
    end

    if self.cc_param_map[d.cc] then
      local p = self.cc_param_map[d.cc]
      local p_id = nil
      local pp = nil
      if ms2000_params.EDIT_MODE_PARAM_PROPS[p] then
        pp = ms2000_params.EDIT_MODE_PARAM_PROPS[p]
        p_id = self.fqid..'_'..p
      elseif ms2000_params.GLOBAL_PARAM_PROPS[p] then
        pp = ms2000_params.GLOBAL_PARAM_PROPS[p]
        p_id = self.fqid..'_'..p
      elseif ms2000_params.TIMBRE_PARAM_PROPS[p] then
        pp = ms2000_params.TIMBRE_PARAM_PROPS[p]
        -- TODO: depends on what current timbre is!
        if params:string(self.fqid..'_voice_mode') == 'synth' then
          p_id = self.fqid..'_t1_'..p
        elseif params:string(self.fqid..'_voice_mode') == 'synth (bi-timbral)' then
          local current_timbre = params:get(self.fqid..'_'..'edited_timbre')
          if current_timbre < 3 then
            p_id = self.fqid..'_t'..current_timbre..'_'..p
          else
            print("   warn - can't set param "..p.." as current patch is multi-timbral and BOTH timbres selected, not supported yet")
            return
          end
        else
          print("   warn - can't set param "..p.." as current patch is vocoder, not supported yet")
        end
      end

      if p_id and pp then

        local v = d.val
        if pp.infn then
          v = pp.infn(v)
        end

        if self.debug then
          print("   " .. p_id .. "=" .. v)
        end
        self.inhibit_midi = true
        params:set(p_id, v)
        self.inhibit_midi = false
      end
    else
      print("   unknown CC")
    end

  end
end

function MS2000:handle_sysex(raw_payload)
  if ms2000_sysex.is_pgm_dump_resp(raw_payload, self.device_id) then
    if self.debug then
      print("<- PGM DUMP (" .. (#raw_payload - 2) .. ")")
      -- midiutil.print_byte_array_midiox(raw_payload)
    end
    self:update_state_from_pgm_dump(raw_payload)

  else
    if self.debug then
      print("<- UNKNOWN SYSEX (" .. (#raw_payload - 2) .. ")")
      -- midiutil.print_byte_array_midiox(raw_payload)
    end
  end
end


function MS2000:update_state_from_pgm_change(pgm_id)
  self.current_pgm_id = pgm_id + 1

  self.inhibit_midi = true
  params:set(self.fqid .. '_' .. 'pgm', self.current_pgm_id)
  -- NB: when switching pgm, the hw resets its active timbre to the 1rst
  params:set(self.fqid .. '_' .. 'edited_timbre', 1)
  self.inhibit_midi = false

  -- self:clear_pgm_state()
  -- self.sent_pgm_t = self.clock_pgm_t
  -- self.is_waiting_for_dump_after_pgm_change = true
  -- script-definable callback
  if self.pgm_change_rcv then
    self.pgm_change_rcv(self.current_pgm_id)
  end
end

function MS2000:update_state_from_pgm_dump(raw_payload)
  self.last_dump_rcv_t = self.MOD_STATE.clock_pgm_change_t

  local pgm = ms2000_sysex.parse_pgm_dump(raw_payload)
  print(inspect(pgm))

  self.inhibit_midi = true

  self.current_pgm_name = pgm.name

  for k, v in pairs(pgm) do
    if not tab.contains({'timbre1', 'timbre2'}, k) then
      local pprops = ms2000_params.GLOBAL_PARAM_PROPS[k]
      if pprops then
        params:set(self.fqid..'_'..k, v)
      else
        print("WARN - unexpected param from pgm dump: "..k)
      end
    end
  end
  if pgm.timbre1 then
    for k, v in pairs(pgm.timbre1) do
      local pprops = ms2000_params.TIMBRE_PARAM_PROPS[k]
      if pprops then
        params:set(self.fqid..'_t1_'..k, v)
      else
        print("WARN - unexpected timbre param from pgm dump: "..k)
      end
    end
  end
  if pgm.timbre2 then
    for k, v in pairs(pgm.timbre2) do
      local pprops = ms2000_params.TIMBRE_PARAM_PROPS[k]
      if pprops then
        params:set(self.fqid..'_t2_'..k, v)
      else
        print("WARN - unexpected timbre param from pgm dump: "..k)
      end
    end
  end

  self.inhibit_midi = false

  if self.pgm_dump_rcv then
    self.pgm_dump_rcv(self.current_pgm_id)
  end
end


-- ------------------------------------------------------------------------
-- impl - pgm

function MS2000:dump_pgm()
  if self.debug then
    print("-> PGM DUMP")
  end
  self.is_waiting_for_dump = true
  ms2000_sysex.dump_pgm_current(self.midi_device, self.device_id)
end


-- ------------------------------------------------------------------------

return MS2000
