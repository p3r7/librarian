-- librarian/model/nord drum 2
--
-- NB: requires the deive to have been updated to v3.0
--
-- manual: https://www.nordkeyboards.com/sites/default/files/files/downloads/manuals/nord-drum-2/Nord%20Drum%202%20English%20User%20Manual%20v3.0x%20Edition%20F.pdf

-- ------------------------------------------------------------------------

local NordDrum2 = {}
NordDrum2.__index = NordDrum2

local KIND = "NordDrum2"
local SHORTHAND = "nd2"


-- ------------------------------------------------------------------------
-- deps

local controlspec = require "controlspec"
local formatters = require "formatters"
local midiutil = include('librarian/lib/midiutil')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- API - supported object params

NordDrum2.PARAMS = {
  'voice_channels',
  'global_channel_notes',
}

local VOICE_CH_LIST = {1, 2, 3, 4, 5, 6}

local GLOBAL_CH = 10
local GLOBAL_CH_NOTES = {60, 62, 64, 65, 67, 69}


-- ------------------------------------------------------------------------
-- API - constructors

function NordDrum2.new(id, midi_device, ch)
  local p = setmetatable({}, NordDrum2)

  p.kind = KIND
  p.shorthand = SHORTHAND

  p.id = id
  p.fqid = p.shorthand.."_"..id
  p.display_name = p.kind.." #"..id

  p.midi_device = midi_device

  if ch == nil then
    ch = GLOBAL_CH
  end

  p.ch = ch
  p.global_channel_notes = GLOBAL_CH_NOTES

  p.voice_channels = VOICE_CH_LIST

  return p
end


-- ------------------------------------------------------------------------
-- API- norns-assignable params

function NordDrum2:get_nb_params()
  return (NordDrum2.NB_VOICES * (#NordDrum2.VOICE_PARAMS + 1)) + 1
end


-- ------------------------------------------------------------------------
-- static conf

NordDrum2.NB_VOICES = 6

local GLOBAL_PARAMS = {
  'bank',
  'voice',
}

local GLOBAL_PARAM_PROPS = {
  bank = {
    disp = "Bank Select",
    nrpn = {0, 32},
  },
  voice = {
    disp = "Channel Focus",
    cc = 70,
  },
}

NordDrum2.VOICE_PARAMS = {
  -- global
  'level',
  'pan',

  -- noise OSC
  "noise_filter_type",
  "noise_filter_freq",

  "noise_filter_eg",
  "noise_filter_q",

  "noise_amp_eg_a_mode",
  "noise_amp_eg_a",

  "noise_amp_eg_d_type",
  "noise_amp_eg_d",
  "noise_amp_eg_d_lo",

  -- tone OSC
  "tone_wave",
  "tone_spectra",

  "tone_timbre",
  "tone_timbre_eg",
  "tone_timbre_eg_d",

  "tone_pitch",
  "tone_bend",
  "tone_bend_time",

  "tone_punch",
  "tone_amp_eg_d_type",
  "tone_amp_eg_d",
  "tone_amp_eg_d_low",

  -- click OSC
  "click_level",
  "click_type",

  -- mixer
  "mixer_balance",

  -- fx
  "fx_dist_type",
  "fx_dist",

  "fx_eq_freq",
  "fx_eq_gain",

  "fx_echo",
  "fx_echo_fdbk",
  "fx_echo_bpm",
}

local VOICE_PARAM_PROPS = {
  -- global
  level = {
    disp = "Level",
    cc = 7,
  },
  pan = {
    disp = "Pan",
    cc = 10,
  },

  -- noise OSC
  noise_filter_freq = {
    disp = "Noise Filter Frequency",
    cc = 14,
  },
  noise_filter_type = {
    disp = "Noise Filter Type",
    cc = 15,
  },
  noise_filter_eg = {
    disp = "Noise Filter Envelope",
    cc = 16,
  },
  noise_filter_q = {
    disp = "Noise Filter Resonance",
    cc = 17,
  },
  noise_amp_eg_a = {
    disp = "Noise Attack/Rate",
    cc = 18,
  },
  noise_amp_eg_a_mode = {
    disp = "Noise Atk Mode",
    cc = 19,
  },
  noise_amp_eg_d_type = {
    disp = "Noise Decay Type",
    cc = 20,
  },
  noise_amp_eg_d = {
    disp = "Noise Decay",
    cc = 21,
  },
  noise_amp_eg_d_lo = {
    disp = "Noise Decay Lo",
    cc = 22,
  },

  -- tone OSC
  tone_spectra = {
    disp = "Tone Spectra",
    cc = 30,
    fmt = format_nd2_99,
  },
  tone_pitch = {
    disp = "Tone Pitch",
    nrpn = {31, 63},
  },
  tone_wave = {
    disp = "Tone Wave",
    cc = 46,
    fmt = format_nd2_wave,
  },
  tone_timbre_eg_d = {
    disp = "Tone Timbre Decay",
    cc = 47,
  },
  -- REVIEW: maybe rename into `tone_amp_eg_a_type` ?
  tone_punch = {
    disp = "Tone Punch",
    cc = 48,
  },
  tone_amp_eg_d_type = {
    disp = "Tone Decay Type",
    cc = 49,
  },
  tone_amp_eg_d = {
    disp = "Tone Decay",
    cc = 50,
  },
  tone_amp_eg_d_low = {
    disp = "Tone Decay Lo",
    cc = 51,
  },
  tone_timbre = {
    disp = "Tone Timbre",
    cc = 52,
  },
  -- REVIEW: give better name
  tone_timbre_eg = {
    disp = "Tone Timb Envelope",
    cc = 53,
  },
  tone_bend = {
    disp = "Tone Bend Amount",
    cc = 54,
  },
  tone_bend_time = {
    disp = "Tone Bend Time",
    cc = 55,
  },

  -- click OSC
  click_level = {
    disp = "Click Level",
    cc = 56,
  },
  click_type = {
    disp = "Click Type",
    cc = 57,
  },

  -- mixer
  mixer_balance = {
    -- disp = "Mix Balance",
    disp = "Mix Tone/Noise",
    cc = 58,
    fmt = format_nd2_balance,
  },

  -- fx - dist
  fx_dist = {
    disp = "Dist Amount",
    cc = 23,
  },
  fx_dist_type = {
    disp = "Dist Type",
    cc = 24,
  },
  -- fx - eq
  fx_eq_freq = {
    disp = "EQ Frequency",
    cc = 25,
  },
  fx_eq_gain = {
    disp = "EQ Gain",
    cc = 26,
  },
  -- fx - echo
  fx_echo_fdbk = {
    disp = "Echo Feedback",
    cc = 27,
  },
  fx_echo = {
    disp = "Echo Amount",
    cc = 28,
  },
  fx_echo_bpm = {
    disp = "Echo BPM",
    nrpn = {29, 61},
  },
}


-- ------------------------------------------------------------------------
-- consts

local WAVE_ORDER = {
  'A1', 'A2', 'A3', 'A4',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6',
  'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7',
  'P1', 'P2', 'P3', 'P4',
  'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8', 'd9',
  'C1', 'C2', 'C3',
}

-- NB: this is a mess...
local WAVE_CC_ORDER = {
  'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7',
  'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8',
  'P1', 'P2', 'P3', 'P4',

  -- 70-74 -> dead zone, sounds like P3
  'P3',

  'C1', 'C2',

  'A1', 'A3', 'A4', 'A2',

  'd9',

  'F1', 'F2', 'F3', 'F4', 'F5', 'F6',

  'C3',
}

local NB_BANKS = 8
local NB_PGM_PER_BANK = 50

local function make_pgm_list()
  local pgm_list = {}
  for b=1,NB_BANKS do
    for pgm=1,NB_PGM_PER_BANK do
      table.insert(pgm_list, 'P'..b..'.'..pgm)
    end
  end
  return pgm_list
end


-- ------------------------------------------------------------------------
-- formatters

local function format_nd2_basic(param)
  local value = param:get()
  return util.round(util.linlin(0, 127, 0, 50, value))
end

local function format_nd2_99(param)
  local value = param:get()
  return util.round(util.linlin(0, 127, 0, 99, value))
end

local function format_nd2_balance(param)
  local v = param:get()
  local v2 = v - 64

  local noise = 20
  local tone = 20

  if v2 < 0 then
    tone = tone - util.round(util.linlin(0, 64, 0, 20, math.abs(v2)))
  else
    noise = noise - util.round(util.linlin(0, 64, 0, 20, v2))
  end

  return noise .. "-" .. tone
end

local function format_raw(param)
  return param:get()
end

local function cc_to_wave(v)
  if v == 0 then
    v = 1
  end

  -- NB: still a glitch around d6/d7...

  local wave_i = util.round(util.linlin(1, 127, 1, #WAVE_CC_ORDER, v))

  return WAVE_CC_ORDER[wave_i]
end

local function wave_to_cc(w)
  local wi = tab.key(WAVE_CC_ORDER, w)
  return util.round(util.linlin(1, #WAVE_CC_ORDER, 1, 127, wi))
end

local function format_nd2_wave(param)
  local v = param:get()

  if v == 0 then
    v = 1
  end
  -- NB: still a glitch around d6/d7...
  local wave_i = util.round(util.linlin(1, 127, 1, #WAVE_CC_ORDER, v))

  -- local wave_i = util.round(util.linlin(0, 119, 1, #WAVE_CC_ORDER, v))

  return WAVE_CC_ORDER[wave_i]
end



local function param_display_name(p)
  if VOICE_PARAM_PROPS[p] == nil then
    print("------------------------")
    print(p)
    print("------------------------")
  end
  return VOICE_PARAM_PROPS[p].disp
end

local function param_midi_path(p)
  local cc = VOICE_PARAM_PROPS[p].cc
  if cc then
    return {
      type = 'cc',
      cc = cc,
    }
  end

  local nrpn = VOICE_PARAM_PROPS[p].nrpn
  if nrpn then
    return {
      type = 'nrpn',
      nrpn = nrpn,
    }
  end
end

local function param_formatter(p)
  local fmt = VOICE_PARAM_PROPS[p].fmt
  if fmt == nil then
    return format_nd2_basic
  end
  return fmt
end




function NordDrum2:register_params()
  params:add_option(self.fqid .. '_pgm', "Program", make_pgm_list())
  params:set_action(self.fqid .. '_pgm',
                    function(pgm_id)
                      local bank = math.floor(151/50) + 1
                      local pgm = mod1(pgm_id, 50)
                      self:pgm_change(bank, pgm)
  end)

  for v=1,NordDrum2.NB_VOICES do
    local prefix = self.fqid..'_v'..v
    params:add_separator(prefix, "Voice "..v)

    for _, p in ipairs(NordDrum2.VOICE_PARAMS) do
      local p_param = prefix..'_'..p
      params:add{type = "number", id = p_param, name = param_display_name(p),
                 min = 1, max = 127,
                 formatter = param_formatter(p)
      }
      params:set_action(p_param,
                        function(val)
                          self:midi_set_param(v, p, val)
      end)
    end
  end
end


-- ------------------------------------------------------------------------
-- implem

function NordDrum2:midi_set_param(v, p, val)
  local ch = self.voice_channels[v]
  local midi_path = param_midi_path(p)

  if midi_path.type == 'cc' then
    midiutil.send_cc(self.midi_device, ch, midi_path.cc, val)
  elseif midi_path.type == 'nrpn' then
    local msb = midi_path.nrpn[1]
    local lsb = midi_path.nrpn[2]
    midiutil.send_cc(self.midi_device, ch, msb, val)
    midiutil.send_cc(self.midi_device, ch, lsb, val)
  end
end

function NordDrum2:pgm_change(bank, program)
  local nrpn = GLOBAL_PARAM_PROPS['bank']
  local msb_cc = nrpn[1]
  local lsb_cc = nrpn[2]
  midiutil.send_cc(self.midi_device, self.ch, msb_cc, 0)
  midiutil.send_cc(self.midi_device, self.ch, lsb_cc, bank-1) -- 0-8
  midiutil.send_pgm_change(self.midi_device, self.ch, program-1)
end

-- ------------------------------------------------------------------------

return NordDrum2
