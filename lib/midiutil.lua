-- librarian/midiutil

local midiutil = {}


-- ------------------------------------------------------------------------
-- consts

midiutil.MIDI_DEV_ALL = "ALL"


-- ------------------------------------------------------------------------
-- bytes (sysex)

local DEFAULT_BYTE_FORMATER = midiutil.byte_to_str

function midiutil.byte_to_str(b)
  return "0x" .. string.format("%02x", b)
end

function midiutil.byte_to_str_midiox(b)
  return string.upper(string.format("%02x", b))
end

function midiutil.bytes_to_string_midiox(a)
  local out = ""
  for i, b in ipairs(a) do
    if i ~= 1 then
      out = out .. " "
    end
    out = out .. midiutil.byte_to_str_midiox(b)
  end
  return out
end

function midiutil.byte_array_diff(a, a2)
  local diffs = {}
  for i, b in ipairs(a) do
    local b2 = a2[i]
    if b ~= a2[i] then
      diffs[i] = {b, b2}
    end
  end
  return diffs
end


function midiutil.print_byte_array(a, fmt_fn, per_line)
  if fmt_fn == nil then fmt_fn = DEFAULT_BYTE_FORMATER end
  if per_line == nil then per_line = 1 end

  local line = ""
  local per_line_count = 0
  for _, b in ipairs(a) do
    line = line .. fmt_fn(b) .. " "
    per_line_count = per_line_count + 1
    if per_line_count >= per_line then
      print(line:sub(1, -2)) -- without last " "
      line = ""
      per_line_count = 0
    end
  end
  if per_line_count > 0 then
    print(line:sub(1, -2)) -- without last " "
  end
end

function midiutil.print_byte_array_midiox(a)
  midiutil.print_byte_array(a, midiutil.byte_to_str_midiox, 18)
end

function midiutil.byte_array_from_midiox(str)
  local a = {}
  for line in str:gmatch("([^\n]*)\n?") do
    for hs in string.gmatch(line, "[^%s]+") do
      table.insert(a, tonumber(hs, 16))
    end
  end
  return a
end

function midiutil.are_equal_byte_arrays(a, a2)
  if #a ~= #a2 then
    return false
  end

  for i, h in ipairs(a2) do
    if a[i] ~= h then
      return false
    end
  end
  return true
end

if seamstress and tab.gather == nil then
  function tab.gather(default_values, custom_values)
    local result = {}
    for k,v in pairs(default_values) do
      result[k] = (custom_values[k] ~= nil) and custom_values[k] or v
    end
    return result
  end
end

function midiutil.sysex_sarts_with(a, header)
  for i, h in ipairs(header) do
    if a[i] ~= h then
      return false
    end
  end
  return true
end

function midiutil.sysex_match(a, matcher)
  if #a ~= #matcher then
    return false
  end

  local res = {}

  for i, h in ipairs(matcher) do
    if type(h) == "string" then
      res[h] = a[i]
    elseif a[i] ~= h then
      return false, {}
    end
  end
  return true, res
end

function midiutil.sysex_valorized(a, vars)
  local a2 = tab.gather(a, {}) -- sort of a `table.copy`
  for i, h in ipairs(a2) do
    if type(h) == "string" and vars[h] ~= nil then
      a2[i] = vars[h]
    end
  end
  return a2
end

-- as used by some Clavia synths, Waldorf...
function midiutil.checksum_7bit(a)
  local v = 0
  for _, b in ipairs(a) do
    v = v + a
  end
  return (v & 0x7f)
end

function midiutil.sysex_has_header(a)
  return (a[1] == 0xf0 and a[tab.count(a)] == 0xf7)
end

function midiutil.sysex_sans_header(a)
  if midiutil.sysex_has_header(a) then
    local a2 = tab.gather(a, {}) -- sort of a `table.copy`
    return {table.unpack(a2, 2, #a2-1)}
  end
  return a
end

function midiutil.sysex_with_header(a)
  if midiutil.sysex_has_header(a) then
    return a
  end
  local a2 = tab.gather(a, {}) -- sort of a `table.copy`
  table.insert(a2, 1, 0xf0)
  table.insert(a2, 0xf7)
  return a2
end


-- ------------------------------------------------------------------------
-- send - generic

function midiutil.send_msg(m, msg)
  local data
  if type(msg) == "table" and (msg.type == "sysex" or msg.type == "other") then
    data = msg.raw
  else
    data = midi.to_data(msg)
  end

  local had_effect = false

  local devname = ""

  if type(m) == "string" then
    devname = m
  elseif type(m) == "table" then
    if m.dev and m.name then
      -- devname = m.name
      midi.vports[m.port]:send(data)
      had_effect = true
    elseif m.device then
      m:send(data)
      had_effect = true
    end
    return had_effect
  end

  for _, dev in pairs(midi.devices) do
    if dev.port ~= nil and dev.name ~= 'virtual' then
      if devname == midiutil.MIDI_DEV_ALL or devname == dev.name then
        midi.vports[dev.port]:send(data)
        had_effect = true
        if devname ~= midiutil.MIDI_DEV_ALL then
          break
        end
      end
    end
  end

  return had_effect
end


-- ------------------------------------------------------------------------
-- send - pgm change

function midiutil.send_pgm_change(midi_device, ch, pgm)
  local msg = {
      type = "program_change",
      val = pgm,
      ch = ch,
    }
  midiutil.send_msg(midi_device, msg)
end


-- ------------------------------------------------------------------------
-- send - sysex

function midiutil.send_sysex(midi_device, payload)
  local msg = {
    type = "sysex",
    raw = payload,
  }
  midiutil.send_msg(midi_device, msg)
end


-- ------------------------------------------------------------------------
-- send - note on / off

function midiutil.send_note_on(midi_device, note_num, vel, ch)
  local msg = {
    type = "note_on",
    note = note_num,
    vel = vel,
    ch = chan,
  }
  midiutil.send_msg(midi_device, msg)
end

function midiutil.send_note_off(midi_device, note_num, vel, ch)
  local msg = {
    type = "note_off",
    note = note_num,
    ch = chan,
  }
  midiutil.send_msg(midi_device, msg)
end


-- ------------------------------------------------------------------------
-- send - cc

-- range: 0-127
--
-- docs:
-- - http://midi.teragonaudio.com/tech/midispec/ctllist.htm
-- - http://www.philrees.co.uk/nrpnq.htm

function midiutil.send_cc(midi_device, ch, cc, val)
  local msg = {
    type = 'cc',
    cc = cc,
    val = val,
    ch = ch,
  }
  midiutil.send_msg(midi_device, msg)
end


-- ------------------------------------------------------------------------
-- send - 14-bit cc

-- range: 0-16384
--
-- used (at least in some cases) for MPE
--
-- NB: there are 3 standards:
-- - Coarse/Fine CC pair (aka "14-bit CC")
-- - RPN
-- - NRPN
--
-- The standard states to send MSB (coarse) then LSB (fine) but for some reasons some device implement it the other way around!
--
-- MSB then LSB is kinda flawed in that LSB is optional (per standards) and can result in a value jump in the device applies the MSB directly.
-- see :https://www.hakenaudio.com/mpe

-- Coarse/Fine CC pair
-- MSB & LSB CC numbers are traditionally 32 apart
function midiutil.send_cc14(midi_device, ch, msb_cc, lsb_cc, val)
  -- NB: MSB then LSB
  midiutil.send_cc(midi_device, ch, msb_cc, val >> 7)
  midiutil.send_cc(midi_device, ch, lsb_cc, val & 127)
end

-- RPN
-- NB: only very few standardized RPN params:
-- - 0x0000 Pitch Bend Sensitivity
-- - 0x0001 Fine Tuning
-- - 0x0002 Coarse Tuning
-- - 0x0003 Tuning Program Select
-- - 0x0004 Tuning Bank Select
-- - 0x7F7F Null (aka Dummy or Reset)
function midiutil.send_rpn(midi_device, ch, rpn, val, do_null)
  if do_null == nil then do_null = true end

  -- - address
  midiutil.send_cc(midi_device, ch, 101, rpn >> 7)
  midiutil.send_cc(midi_device, ch, 100, rpn & 127)

  -- - value
  midiutil.send_cc(midi_device, ch, 6,  val >> 7)
  midiutil.send_cc(midi_device, ch, 38, val & 127)

  -- - reset address
  if do_null then
    midiutil.send_rpn_null(midi_device, ch)
  end
end

-- see http://www.philrees.co.uk/nrpnq.htm
function midiutil.send_rpn_null(midi_device, ch)
  midiutil.send_cc(midi_device, ch, 101, 7)
  midiutil.send_cc(midi_device, ch, 100, 127)
end

-- NRPN
function midiutil.send_nrpn(midi_device, ch, nrpn, val)
  -- - address
  midiutil.send_cc(midi_device, ch, 99, nrpn >> 7)
  midiutil.send_cc(midi_device, ch, 98, nrpn & 127)

  -- - value
  midiutil.send_cc(midi_device, ch, 6,  val >> 7)
  midiutil.send_cc(midi_device, ch, 38, val & 127)
end


-- ------------------------------------------------------------------------

return midiutil
