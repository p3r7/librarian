-- librarian/model/nord drum 2
--
-- NB: requires the deive to have been updated to v3.0
--
-- manual: https://www.nordkeyboards.com/sites/default/files/files/downloads/manuals/nord-drum-2/Nord%20Drum%202%20English%20User%20Manual%20v3.0x%20Edition%20F.pdf
-- banks: https://www.nordkeyboards.com/sound-libraries/product-libraries/drums/nord-drum-2/nord-drum-2-factory-sounds

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
-- API - norns-assignable params

function NordDrum2:get_nb_params()
  return (NordDrum2.NB_VOICES * (#NordDrum2.VOICE_PARAMS + 1)) + 1
end


-- ------------------------------------------------------------------------
-- formatters

local function format_raw(param)
  return param:get()
end

local function format_nd2_basic(param)
  local value = param:get()
  return math.floor(util.linlin(0, 127, 0, 50, value))
end

local function format_nd2_20(param)
  local value = param:get()
  return math.floor(util.linlin(0, 127, 0, 20, value))
end

local function format_nd2_50_bp(param)
  local value = param:get()
  local scaled = math.floor(util.linlin(0, 127, -50, 50, value))
  if scaled > 0 then
    return "+"..scaled
  end
  return scaled
end

local function format_nd2_24_bp(param)
  local value = param:get()
  local scaled = math.floor(util.linlin(0, 127, -24, 24, value))
  if scaled > 0 then
    return "+"..scaled
  end
  return scaled
end

local function format_nd2_99(param)
  local value = param:get()
  return math.floor(util.linlin(0, 127, 0, 99, value))
end

local function format_nd2_pitch(param)
  local value = param:get()
  return value
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

local TONE_WAVE_DESC = {
  A1 = 'sine',
  A2 = 'triangle',
  A3 = 'saw',
  A4 = 'square',
  A5 = 'square hpf',
  A6 = 'pulse',
}

local TONE_WAVES = {
  'A1', 'A2', 'A3', 'A4', 'A5', 'A6',
  'r1', 'r2',
  't1',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6',
  'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7',
  'P1', 'P2', 'P3', 'P4',
  'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8', 'd9',
  'C1', 'C2', 'C3',
}

local TONE_WAVES_CC_VALS = {
  A1 = 75,
  A2 = 85,
  A3 = 79,
  A4 = 82,
  A5 = 118,
  A6 = 121,
  r1 = 124,
  r2 = 127,
  t1 = 114,
  F1 = 92,
  F2 = 95,
  F3 = 98,
  F4 = 101,
  F5 = 105,
  F6 = 108,
  H1 = 0,
  H2 = 4,
  H3 = 7,
  H4 = 10,
  H5 = 14,
  H6 = 17,
  H7 = 20,
  P1 = 49,
  P2 = 53,
  P3 = 56,
  P4 = 59,
  d1 = 23,
  d2 = 27,
  d3 = 30,
  d4 = 33,
  d5 = 36,
  d6 = 40,
  d7 = 43,
  d8 = 46,
  d9 = 88,
  C1 = 69,
  C2 = 72,
  C3 = 111,
}

local NOISE_FILTER_TYPES = {
  "LP12", "LP24",
  "bP6", "bP12",
  "HP12", "HP24",
  "HPhc",
}

local NOISE_FILTER_TYPES_CC_VALS = {
  LP12 = 0,
  LP24 = 22,
  bP6 = 43,
  bP12 = 64,
  HP12 = 85,
  HP24 = 106,
  HPhc = 127,
}

local CLICK_TYPES = {
  "n1", "n2", "n3", "n4", "n5", "n6", "n7", "n8", "n9",
  "P1", "P2",
}

local CLICK_TYPES_CC_VALS = {
  n1 = 0,
  n2 = 4,
  n3 = 8,
  n4 = 11,
  n5 = 15,
  n6 = 19,
  n7 = 22,
  n8 = 26,
  n9 = 30,
  P1 = 33,
  P2 = 37,
  P3 = 40,
  P4 = 44,
  P5 = 48,
  P6 = 51,
  P7 = 55,
  P8 = 59,
  P9 = 62,
  PH1 = 66,
  PH2 = 69,
  PH3 = 73,
  PH4 = 77,
  PH5 = 80,
  PH6 = 84,
  PH7 = 88,
  PH8 = 91,
  PH9 = 95,
  C1 = 98,
  C2 = 102,
  C3 = 106,
  C4 = 109,
  C5 = 113,
  C6 = 117,
  C7 = 120,
  C8 = 124,
  C9 = 127,
}

local NOISE_ATTACK_MODES = {'AD',
            'LFO1', 'LFO2', 'LFO3',
            'Clap1', 'Clap2', 'Clap3', 'Clap4', 'Clap5', 'Clap6', 'Clap7', 'Clap8', 'Clap9'}

-- local EQ_FREQS = {
--   "50" = 0,
--   "70" = 3,
--   "80" = 6,
--   "100" = 8,
--   "120" = 11,
--   "150" = 13,
--   "170" = 16,
--   "200" = 18,
--   "230" = 21,
--   "260" = 23,
--   "330" = 28,
--   "380" = 31,
--   "420" = 34,
--   "470" = 36,
--   "470" = 36,
-- }

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
  "click_type",
  "click_level",

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
    fmt = format_nd2_balance,
  },

  -- noise OSC
  noise_filter_type = {
    disp = "Noise Filter Type",
    cc = 15,
    opts = NOISE_FILTER_TYPES,
    outfn = function(v)
      return NOISE_FILTER_TYPES_CC_VALS[NOISE_FILTER_TYPES[v]]
    end,
  },
  noise_filter_freq = {
    disp = "Noise Filter Frequency",
    cc = 14,
  },
  noise_filter_eg = {
    disp = "Noise Filter Envelope",
    cc = 16,
    -- FIXME: glitchy around 0
    fmt = format_nd2_50_bp,
  },
  noise_filter_q = {
    disp = "Noise Filter Resonance",
    cc = 17,
    fmt = format_nd2_20,
  },
  noise_amp_eg_a = {
    disp = "Noise Attack/Rate",
    cc = 18,
  },
  noise_amp_eg_a_mode = {
    disp = "Noise Atk Mode",
    cc = 19,
    opts = NOISE_ATTACK_MODES,
    outfn = function(v)
      return util.round(util.linlin(1, #NOISE_ATTACK_MODES, 0, 127, v))
    end,
  },
  noise_amp_eg_d_type = {
    disp = "Noise Decay Type",
    cc = 20,
    opts = {'Exp.', 'Lin.', 'Gate'},
    outfn = function(v)
      return util.round(util.linlin(1, 3, 0, 127, v))
    end,
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
  tone_wave = {
    disp = "Tone Wave",
    cc = 46,
    opts = TONE_WAVES,
    outfn = function(v)
      return TONE_WAVES_CC_VALS[TONE_WAVES[v]]
    end,
  },
  tone_spectra = {
    disp = "Tone Spectra",
    cc = 30,
    fmt = format_nd2_99,
  },
  tone_pitch = {
    disp = "Tone Pitch",
    nrpn = {63, 31},
    cs = controlspec.def{
      min = 0.0,
      max = 127.5,
      warp = 'lin',
      step = 0.5,
      units = 'hz',
      -- quantum = 0.5,
      wrap = false,
    },
    outfn = function(v)
      if math.floor(v) == v then
        return v
      end

      -- NB: that's how the nd2 serializes the 0.5 steps
      -- essentially adding 1000000 0000000
      local half_step = 64 << 7
      return math.floor(v) + half_step
    end,
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
    opts = {'Exp.', 'Lin.'},
    outfn = function(v)
      return ( (v == 1) and 0 or 127 )
    end,
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
    fmt = format_nd2_50_bp,
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
    fmt = format_nd2_24_bp,
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
                      local bank = math.floor(pgm_id/50) + 1
                      local pgm = mod1(pgm_id, 50)
                      self:pgm_change(bank, pgm)
  end)

  for v=1,NordDrum2.NB_VOICES do
    local prefix = self.fqid..'_v'..v
    params:add_separator(prefix, "Voice "..v)

    for _, p in ipairs(NordDrum2.VOICE_PARAMS) do
      local p_param = prefix..'_'..p

      if VOICE_PARAM_PROPS[p].opts ~= nil then
        params:add_option(p_param, param_display_name(p),
                          VOICE_PARAM_PROPS[p].opts)
        params:set_action(p_param,
                          function(val)
                            local outfn = VOICE_PARAM_PROPS[p].outfn
                            if outfn ~= nil then
                              val = outfn(val)
                            end
                            self:midi_set_param(v, p, val)
        end)
      elseif VOICE_PARAM_PROPS[p].cs ~= nil then
        params:add_control(p_param, param_display_name(p),
                           VOICE_PARAM_PROPS[p].cs)
        params:set_action(p_param,
                          function(val)
                            local outfn = VOICE_PARAM_PROPS[p].outfn
                            if outfn ~= nil then
                              val = outfn(val)
                            end
                            self:midi_set_param(v, p, val)
        end)
      else
        local midi_path = param_midi_path(p)
        local max = 127
        if VOICE_PARAM_PROPS[p].max ~= nil then
          max = VOICE_PARAM_PROPS[p].max
        elseif midi_path.type == 'nrpn' then
          max = 4095 -- 1111111 1111111
        end

        params:add{type = "number", id = p_param, name = param_display_name(p),
                   min = 1, max = max,
                   formatter = param_formatter(p)
        }
        params:set_action(p_param,
                          function(val)
                            local outfn = VOICE_PARAM_PROPS[p].outfn
                            if outfn ~= nil then
                              val = outfn(val)
                            end
                            self:midi_set_param(v, p, val)
        end)
      end
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
    local msb_cc = midi_path.nrpn[1]
    local lsb_cc = midi_path.nrpn[2]
    midiutil.send_cc14(midi_device, ch, msb_cc, lsb_cc, val)
  end
end

function NordDrum2:pgm_change(bank, program)
  local nrpn = GLOBAL_PARAM_PROPS['bank'].nrpn
  local msb_cc = nrpn[1]
  local lsb_cc = nrpn[2]
  midiutil.send_cc14(self.midi_device, self.ch, msb_cc, lsb_cc, bank-1)
  midiutil.send_pgm_change(self.midi_device, self.ch, program-1)
end

-- ------------------------------------------------------------------------

return NordDrum2
