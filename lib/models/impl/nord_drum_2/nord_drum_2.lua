
local nd2 = {}


-- ------------------------------------------------------------------------
-- deps

local midiutil = include('librarian/lib/midiutil')
local nd2_fmt = include('librarian/lib/models/impl/nord_drum_2/fmt')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- consts

-- NB: goes only up to 4095 (instead of 16383)
nd2.CC14_RESOLUTION = 4095



-- ------------------------------------------------------------------------
-- banks

nd2.NB_BANKS = 8
nd2.NB_PGM_PER_BANK = 50

function nd2.make_pgm_list()
  local pgm_list = {}
  for b=1,nd2.NB_BANKS do
    for pgm=1,nd2.NB_PGM_PER_BANK do
      table.insert(pgm_list, 'P'..b..'.'..pgm)
    end
  end
  return pgm_list
end


-- ------------------------------------------------------------------------
-- global params

nd2.GLOBAL_PARAMS = {
  'bank',
  'voice',
}

nd2.GLOBAL_PARAM_PROPS = {
  bank = {
    disp = "Bank Select",
    cc14 = {0, 32},
    max = nd2.CC14_RESOLUTION,
  },
  voice = {
    disp = "Channel Focus",
    cc = 70,
  },
}


-- ------------------------------------------------------------------------
-- voice params

nd2.NB_VOICES = 6

-- NB: can seem redundant w/ `nd2.VOICE_PARAM_PROPS`, this is just the display order of params (as maps don't preserve order)
nd2.VOICE_PARAMS = {
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

nd2.VOICE_PARAM_PROPS = {
  -- global
  level = {
    disp = "Level",
    cc = 7,
  },
  pan = {
    disp = "Pan",
    cc = 10,
    fmt = nd2_fmt.format_balance,
  },

  -- noise OSC
  noise_filter_type = {
    disp = "Noise Filter Type",
    cc = 15,
    opts = nd2_fmt.NOISE_FILTER_TYPES,
    outfn = function(v)
      return nd2_fmt.NOISE_FILTER_TYPES_CC_VALS[nd2_fmt.NOISE_FILTER_TYPES[v]]
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
    fmt = nd2_fmt.format_50_bp,
  },
  noise_filter_q = {
    disp = "Noise Filter Resonance",
    cc = 17,
    fmt = nd2_fmt.format_20,
  },
  noise_amp_eg_a = {
    disp = "Noise Attack/Rate",
    cc = 18,
  },
  noise_amp_eg_a_mode = {
    disp = "Noise Atk Mode",
    cc = 19,
    opts = nd2_fmt.NOISE_ATTACK_MODES,
    outfn = function(v)
      return util.round(util.linlin(1, #nd2_fmt.NOISE_ATTACK_MODES, 0, 127, v))
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
    opts = nd2_fmt.TONE_WAVES,
    outfn = function(v)
      return nd2_fmt.TONE_WAVES_CC_VALS[nd2_fmt.TONE_WAVES[v]]
    end,
  },
  tone_spectra = {
    disp = "Tone Spectra",
    cc = 30,
    fmt = nd2_fmt.format_99,
  },
  tone_pitch = {
    disp = "Tone Pitch",
    cc14 = {63, 31},
    max = nd2_fmt.CC14_RESOLUTION,
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
    fmt = nd2_fmt.format_50_bp,
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
    fmt = nd2_fmt.format_balance,
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
    fmt = nd2_fmt.format_24_bp,
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
    cc14 = {29, 61},
    max = nd2_fmt.CC14_RESOLUTION,
  },
}


-- ------------------------------------------------------------------------

return nd2
