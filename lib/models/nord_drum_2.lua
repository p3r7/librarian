-- librarian/model/nord drum 2
--
-- NB: requires the device to have been updated to v3.0
--
-- manual: https://www.nordkeyboards.com/sites/default/files/files/downloads/manuals/nord-drum-2/Nord%20Drum%202%20English%20User%20Manual%20v3.0x%20Edition%20F.pdf
-- banks: https://www.nordkeyboards.com/sound-libraries/product-libraries/drums/nord-drum-2/nord-drum-2-factory-sounds


local NordDrum2 = {}
local GenericHw = include('librarian/lib/hw')
setmetatable(NordDrum2, {__index = GenericHw})

local KIND = "nord_drum_2"
local SHORTHAND = "nd2"
local DISPLAY_NAME = "Nord Drum 2"


-- ------------------------------------------------------------------------
-- deps

local controlspec = require "controlspec"
local formatters = require "formatters"
local voice = require 'lib/voice'

local hwutils = include('librarian/lib/hwutils')
local midiutil = include('librarian/lib/midiutil')
local paramutils = include('librarian/lib/paramutils')
local nbutils = include('librarian/lib/nbutils')

local nd2 = include('librarian/lib/models/impl/nord_drum_2/nord_drum_2')
local nd2_fmt = include('librarian/lib/models/impl/nord_drum_2/fmt')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- consts

local DO_EXPOSE_EDIT_ALL_VOICE_PARAMS = false


-- ------------------------------------------------------------------------
-- API - exposed object params

NordDrum2.PARAMS = {
  'voice_channels',
  'global_channel_notes',
}

local VOICE_CH_LIST = {1, 2, 3, 4, 5, 6}

local GLOBAL_CH = 10
local GLOBAL_CH_NOTES = {60, 62, 64, 65, 67, 69}


-- ------------------------------------------------------------------------
-- API - constructors

function NordDrum2.new(MOD_STATE, id, count, midi_device, ch, nb)
  ch = ch or GLOBAL_CH

  local hw = GenericHw.new(
    {
      kind         = KIND,
      shorthand    = SHORTHAND,
      display_name = DISPLAY_NAME,
      plays_notes  = true,
    },
    MOD_STATE, id, count, midi_device, ch, nb)
  setmetatable(hw, {__index = NordDrum2})

  hw.global_channel_notes = GLOBAL_CH_NOTES
  hw.voice_channels       = VOICE_CH_LIST

  hw.default_fmt = nd2_fmt.format_basic

  hw.supports_all_notes_off = false
  hw.supports_notes_off = false

  return hw
end


-- ------------------------------------------------------------------------
-- API - norns-assignable params

function NordDrum2:get_nb_params()
  -- NB: in reality we have 2 `nd2.GLOBAL_PARAMS` for selecting the BANK & the PGM
  -- ...but we expose them as a single param for convenience
  local nb_global_params = 1

  local nb_voices = nd2.NB_VOICES
  if DO_EXPOSE_EDIT_ALL_VOICE_PARAMS then
    nb_voices = nb_voices + 1
  end

  -- NB: `+ 1` is for the separators
  local nb_voice_params = (nb_voices * (#nd2.VOICE_PARAMS + 1))

  return nb_global_params + nb_voice_params
end

function NordDrum2:register_params()
  params:add_option(self.fqid .. '_pgm', "Program", nd2.make_pgm_list())
  params:set_action(self.fqid .. '_pgm',
                    function(pgm_id)
                      local bank = math.floor(pgm_id/50) + 1
                      local pgm = mod1(pgm_id, 50)
                      self:pgm_change(bank, pgm)
  end)

  for v=1,nd2.NB_VOICES do
    local hw = hwutils.cloned(self)
    hw.fqid = self.fqid..'_v'..v
    hw.ch = self.voice_channels[v]

    params:add_separator(hw.fqid, "Voice "..v)

    paramutils.add_params(hw, nd2.VOICE_PARAM_PROPS, nd2.VOICE_PARAMS,
                          function(hw, p, _pp, val)
                            self:set_voice_param(v, p, val)
                          end
    )
  end

  if DO_EXPOSE_EDIT_ALL_VOICE_PARAMS then
    params:add_separator(self.fqid..'_v_all', "All Voices ")

    for _, p in pairs(nd2.VOICE_PARAMS) do
      paramutils.add_param(self, nd2.VOICE_PARAM_PROPS, p,
                           function(_hw, p, _pp, val)
                             self:set_param_all_voices(p, val)
                           end
      )
    end
  end

end


-- ------------------------------------------------------------------------
-- implem - norns-assignable params

-- NB: wrapper around `paramutils.set` for multi-voice support
function NordDrum2:set_voice_param(v, p, val)
  -- NB: we make a fake version of `self` w/ only the needed props and `ch` set to current voice's
  local o = {
    ch = self.voice_channels[v],
    midi_device = self.midi_device,
  }

  local pp = nd2.VOICE_PARAM_PROPS[p]

  if not pp then
    print("missin param "..p)
    return
  end

  paramutils.set(o, p, pp, val)

  -- focus to edited channel/voice
  -- doesn't seem to work...
  local voice_cc = nd2.GLOBAL_PARAM_PROPS['voice'].cc
  midiutil.send_cc(self.midi_device, ch, voice_cc, v-1)
end

function NordDrum2:set_param_all_voices(p, val)
  for v=1,nd2.NB_VOICES do
    local p_id = self.fqid..'_v'..v.."_"..p
    params:set(p_id, val)
  end
end


-- ------------------------------------------------------------------------
-- API - midi

function NordDrum2:pgm_change(bank, program)
  local cc14 = nd2.GLOBAL_PARAM_PROPS['bank'].cc14
  midiutil.send_cc14(self.midi_device, self.ch, cc14, bank-1)
  midiutil.send_pgm_change(self.midi_device, self.ch, program-1)
end


-- ------------------------------------------------------------------------
-- API - nb

function NordDrum2:register_nb_players()
  -- global ch, "hits", trigged w/ `GLOBAL_CH_NOTES` w/ not pitch support
  -- good for drums
  nbutils.register_player(self, "global")

  -- individual voice channels w/ pitch support
  -- good for synth leads
  for v=1,nd2.NB_VOICES do
    local hw = hwutils.cloned(self)
    hw.ch = self.voice_channels[v]
    print("registering player "..v.." w/ ch="..hw.ch)
    nbutils.register_player(hw, "v"..v)
  end

  -- polyphonic voice abstraction
  NordDrum2.register_poly_player(self)
end

if note_players == nil then
  note_players = {}
end

function NordDrum2.register_poly_player(hw)
  local player = {
    voice_count = nd2.NB_VOICES,
    last_voice = 1,
    release_fn = {},
    alloc_modes = { "rotate", "random" },
    hw = hw,
  }

  local id = "poly"
  local nb_prfx = "nb_" .. hw.fqid
  local player_id = nb_prfx .. "_"..id
  local player_name = hw.display_name .. " "..id
  local allow_mode_p = player_id.."_alloc_mode"

  function player:add_params()
    params:add_group(nb_prfx, nb_prfx, 1)
    params:add_option(allow_mode_p, "alloc mode", self.alloc_modes, 1)
    params:hide(nb_prfx)
  end

  function player:note_on(note, vel)
    local alloc_mode = self.alloc_modes[params:get(allow_mode_p)]
    local next_voice, voice_ch
    if alloc_mode == "rotate" then
      next_voice = self.last_voice % self.voice_count + 1
      self.last_voice = next_voice
      voice_ch = self.hw.voice_channels[next_voice]
    elseif alloc_mode == "random" then
      next_voice = math.random(self.voice_count)
      voice_ch = self.hw.voice_channels[next_voice]
    end
    self.release_fn[note] = function()
      if self.hw.supports_notes_off == false then
        return
      end
      midiutil.send_note_off(self.hw.midi_device, note, 0, voice_ch)
    end
    midiutil.send_note_on(self.hw.midi_device, note, vel*127, voice_ch)
  end

  function player:note_off(note)
    if self.release_fn[note] then
      self.release_fn[note]()
    end
  end

  function player:describe(note)
    return {
      name = player_name,
      supports_bend = false,
      supports_slew = false,
      modulate_description = "unsupported",
    }
  end

  function player:stop_all()
    if self.hw.supports_notes_off == false then
      return
    end
    for _, ch in pairs(self.hw.voice_channels) do
      midiutil.send_all_notes_off(self.hw.midi_device, ch)
    end
  end

  function player:active()
    params:show(nb_prfx)
    _menu.rebuild_params()
  end

  function player:inactive()
    params:hide(nb_prfx)
    _menu.rebuild_params()
  end

  note_players[player_name] = player
end


-- ------------------------------------------------------------------------

return NordDrum2
