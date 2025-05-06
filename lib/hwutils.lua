-- librarian/hwutils

local hwutils = {}


-- ------------------------------------------------------------------------
-- deps

local binutils   = include('librarian/lib/binutils')
local paramutils = include('librarian/lib/paramutils')
local midiutil = include('librarian/lib/midiutil')
local nbutils = include('librarian/lib/nbutils')


-- ------------------------------------------------------------------------
-- constructors

function hwutils.hw_from_static(t, MOD_STATE, id, count, midi_device, ch, nb)
  -- reveiw: copy table?
  local hw = t

  hw.MOD_STATE = MOD_STATE

  if not hw.display_name then
    hw.display_name = hw.kind
  end

  if not hw.shorthand then
    hw.shorthand = hw.kind
  end

  if not hw.ch then
    hw.ch = 1
  end

  -- had default hw device name, typically USB midi devices
  if hw.midi_device and midi_device == midiutil.MIDI_DEV_ALL then
    -- pass
  else
    hw.midi_device = midi_device
  end

  hw.id = id
  hw.fqid = hw.shorthand.."_"..id
  if count > 1 then
    hw.display_name = hw.display_name.." #"..id
  end

  if hw.plays_notes then
    hw.nb = true
    if nb ~= nil and not nb then
      hw.nb = false
    end
  end

  hw.param_props = {}
  hw.param_list = {}
  for _, p in pairs(hw.params) do
    hw.param_props[p.name] = p
    table.insert(hw.param_list, p.name)
  end

  function hw:get_nb_params()
    local count = #self.params
    if self.pgm_count or self.pgm_list then
      count = count + 1
    end
    return count
  end

  function hw:register_params()
    local supports_pgm_change = false
    if self.pgm_list then
      params:add_option(self.fqid .. '_pgm', "Program", self.pgm_list)
      supports_pgm_change = true
    elseif self.pgm_count then
      params:add{ type = "number", id = self.fqid .. '_pgm', name = "Program",
                  min = 1, max = self.pgm_count }
      supports_pgm_change = true
    end
    if supports_pgm_change then
      params:set_action(self.fqid .. '_pgm',
                        function(pgm)
                          local bank_size = self.bank_size or 127
                          if self.requires_bank_select then
                            midiutil.send_cc14(self.midi_device, self.ch, 0, 32, (pgm - 1) // bank_size)
                          end
                          midiutil.send_pgm_change(self.midi_device, self.ch, (pgm - 1) % bank_size)
                          self.pgm = pgm
      end)
    end

    paramutils.add_params(hw, self.param_props, self.param_list)
  end

  function hw:register_nb_players()
    nbutils.register_player(self)
  end

  return hw
end


-- ------------------------------------------------------------------------
-- helpers

function hwutils.cloned(hw)
  return {
    parent = hw,

    id = hw.id,
    fqid = hw.fqid,
    display_name = hw.display_name,

    midi_device = hw.midi_device,
    ch = hw.ch,

    supports_all_notes_off = hw.supports_all_notes_off,
    supports_notes_off = hw.supports_notes_off,

    default_fmt = hw.default_fmt,

    -- REVIEW: maybe it's saner to have sub-hw w/ separate maps
    -- indeed, case of a device that listens to several channel, w/ channel same CC numbers...
    -- -> but we only have 1 global `HW:midi_event` fn, so it's up to the device to then route according to the received channel?
    cc_param_map = hw.cc_param_map,
    cc14_param_map = hw.cc14_param_map,
    rpn_param_map = hw.rpn_param_map,
    nrpn_param_map = hw.nrpn_param_map,
  }
end

function hwutils.og(hw)
  local og = hw
  while og.parent do
    og = og.parent
  end
  return og
end


-- ------------------------------------------------------------------------
-- hw params lookup maps

function hwutils.hw_cc_map(hw_list)
  local m = {}
  for _, hw in ipairs(hw_list) do
    m[hw.fqid] = hw.cc_param_map
  end
  return m
end

function hwutils.hw_cc14_map(hw_list)
  local m = {}
  for _, hw in ipairs(hw_list) do
    m[hw.fqid] = hw.cc14_param_map
  end
  return m
end

function hwutils.cc14_hw_map(hw_list)
  local m = {}
  for _, hw in ipairs(hw_list) do
    if hw.cc14_param_map then
      for cc14, _param in pairs(hw.cc14_param_map) do
        if not m[cc14] then
          m[cc14] = {}
        end
        table.insert(m[cc14], hw)
      end
    end
  end
  return m
end

function hwutils.hw_rpn_map(hw_list)
  local m = {}
  for _, hw in ipairs(hw_list) do
    m[hw.fqid] = hw.rpn_param_map
  end
  return m
end

function hwutils.hw_nrpn_map(hw_list)
  local m = {}
  for _, hw in ipairs(hw_list) do
    m[hw.fqid] = hw.nrpn_param_map
  end
  return m
end


-- ------------------------------------------------------------------------
-- hw params lookup fns

local IGNORED_MIDI_DEVS = {
  "16n", "bleached", "h2o2d",
}

function hwutils.hw_matched_dev(hw, dev)
  return ( hw.midi_device == dev.name
           or ( hw.midi_device == midiutil.MIDI_DEV_ALL
                and not tab.contains(IGNORED_MIDI_DEVS, dev.name) ) )
end

function hwutils.should_parse_rpn(dev, ch, hw_map, hw_rpn_map)
  for hw_fqid, _ in pairs(hw_rpn_map) do
    local hw = hw_map[hw_fqid]
    if hw.ch == ch
      and hwutils.hw_matched_dev(hw, dev) then
      return true
    end
  end
end

function hwutils.listens_for_rpn(hw, hw_rpn_map)
  return ( hw_rpn_map[hw.fqid] ~= nil )
end

function hwutils.should_parse_nrpn(dev, ch, hw_map, hw_nrpn_map)
  for hw_fqid, _ in pairs(hw_nrpn_map) do
    local hw = hw_map[hw_fqid]
    if hw.ch == ch
      and hwutils.hw_matched_dev(hw, dev) then
      return true
    end
  end
end

function hwutils.listens_for_nrpn(hw, hw_nrpn_map)
  return ( hw_nrpn_map[hw.fqid] ~= nil )
end

-- function hwutils.should_parse_as_cc14(dev, ch, cc, hw)
--   for cc14, _param in pairs(hw.cc14_param_map) do
--     local id = binutils.ensure_14bits_as_table(cc14)
--     if hw.ch == ch
--       and hwutils.hw_matched_dev(hw, dev)
--       and tab.contains(id, cc) then
--       return true
--     end
--   end
-- end


-- ------------------------------------------------------------------------

return hwutils
