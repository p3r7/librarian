
local ms2000_params = {}


-- ------------------------------------------------------------------------
-- deps

local ms2000_fmt = include('librarian/lib/models/impl/korg_ms2000/fmt')


-- ------------------------------------------------------------------------
-- consts

local VOICE_MODES = {
  "synth",
  "synth (bi-timbral)",
  "vocoder",
}
local VOICE_MODES_MAP = {
  [0] = "synth",
  [2] = "synth (bi-timbral)",
  [3] = "vocoder",
}

local ARPEG_TYPES = { 'Up', 'Down', 'Alt. 1', 'Alt. 2',
                      'Rand', 'Trig' }
local ARPEG_TYPES_MAP = {
  [0]   = 'Up',
  [26]  = 'Down',
  [51]  = 'Alt. 1',
  [77] = 'Alt. 2',
  [102] = 'Rand',
  [127] = 'Trig',
}

local OSC1_WAVEFORMS = { 'Saw', 'Square', 'Triangle', 'Sine',
                         'Vox Wave', 'DWGS', 'Noise', 'Audio In' }

local OSC2_WAVEFORMS = { 'Saw', 'Square', 'Triangle' }
local OSC2_MOD_FX = { 'OFF', 'Ring', 'Sync', 'Ring+Sync' }

local FILTER_TYPES = { '24P LP', '12P LP', '12P BP', '12P HP' }

local LFO1_WAVEFORMS = { 'Saw', 'Square', 'Triangle', 'S+H' }
local LFO2_WAVEFORMS = { 'Saw', 'Square', 'Sine',     'S+H' }

local FX_MOD_TYPES = { 'Ch/Flg', 'Ensemble', 'Phaser' }


-- ------------------------------------------------------------------------
-- conv

function ms2000_params.make_infn_opts(opts_length)
  return function(v)
    return util.round(v / (128 / opts_length)) + 1
  end
end

function ms2000_params.make_outfn_opts(opts_length)
  return function(v)
    return (v-1) * util.round(128 / opts_length)
  end
end

function ms2000_params.infn_bipolar(v)
  return v - 64
end

function ms2000_params.outfn_bipolar(v)
  return v - 64
end


-- ------------------------------------------------------------------------
-- params - special

-- special params not saved in dump but used to switch edit modes

ms2000_params.SELECT_PARAMS = {
  timbre = {
    cc = 95,
  },
}


-- ------------------------------------------------------------------------
-- params - global

ms2000_params.GLOBAL_PARAMS = {
  'voice_mode',
  'arpeg_trig_l',
  'arpeg_trig_pattern',
  'arpeg_status',
  'arpeg_latch',
  'arpeg_target',
  'arpeg_k_sync',
  'arpeg_type',
  'arpeg_range',
  'arpeg_gate_t',
  'arpeg_resolution',
  'arpeg_swing',
  'scale_type',
  'scale_key',
  'kbd_octave',
  'fx_mod_lfo_speed',
  'fx_mod_depth',
  'fx_mod_type',
  'fx_delay_sync',
  'fx_delay_t_base',
  'fx_delay_t',
  'fx_delay_depth',
  'fx_delay_type',
  'eq_hi_hz',
  'eq_hi_a',
  'eq_lo_hz',
  'eq_lo_a',
}

ms2000_params.GLOBAL_PARAM_PROPS = {
  voice_mode = {
    opts = VOICE_MODES,
    infn = function(v)
      local m = VOICE_MODES_MAP[v]
      return tab.key(VOICE_MODES, m)
    end,
    outfn = function(v)
      local m = VOICE_MODES[v]
      return tab.invert(VOICE_MODES_MAP)[m]
    end,
  },

  -- arpeggio
  arpeg_trig_l = {},
  arpeg_trig_pattern = {},
  arpeg_status = {
    nrpn = {0, 2},
    opts = { 'OFF', 'ON' },
    infn = function(v)
      return (v > 0) and 1 or 0
    end,
    outfn = function(v)
      return v * 255
    end,
  },
  arpeg_latch = {
    nrpn = {0, 4},
    opts = { 'OFF', 'ON' },
    infn = function(v)
      return (v > 0) and 1 or 0
    end,
    outfn = function(v)
      return v * 255
    end,
  },
  arpeg_target = {},
  arpeg_k_sync = {},
  arpeg_type = {
    nrpn = {0, 7},
    opts = ARPEG_TYPES,
    infn = function(v)
      local t = nil
      for vstart, name in pairs(ARPEG_TYPES_MAP) do
        if v < vstart then
          break
        end
        t = name
      end
      return tab.key(ARPEG_TYPES, t)
    end,
    outfn = function(v)
      -- NB: is 127/math.ceil(#ARPEG_TYPES)
      -- return v * 22
      local t = ARPEG_TYPES[v]
      return tab.invert(ARPEG_TYPES_MAP)[t]
    end
  },
  arpeg_range = {
    nrpn = {0, 3},
    min = 1,
    max = 4,
  },
  arpeg_gate_t = {
    nrpn = {0, 10},
  },
  arpeg_resolution = {},
  arpeg_swing = {},

  -- keyboard
  scale_type = {},
  scale_key = {},
  kbd_octave = {},

  -- fx - modulation
  fx_mod_lfo_speed = {
    cc = 12,
  },
  fx_mod_depth = {
    cc = 93,
  },
  fx_mod_type = {
    opts = FX_MOD_TYPES,
  },

  -- fx - delay
  fx_delay_sync = {},
  fx_delay_t_base = {},
  fx_delay_t = {},
  fx_delay_depth = {},
  fx_delay_type = {},

  eq_hi_hz = {},
  eq_hi_a = {},
  eq_lo_hz = {},
  eq_lo_a = {},
}


-- ------------------------------------------------------------------------
-- params - timbre

ms2000_params.TIMBRE_PARAMS = {
  'pitch_tune',
  'pitch_bend_range',
  'pitch_transpose',
  'pitch_vibrato_interval',
  'portamento',
  'osc1_wave',
  'osc1_ctrl1',
  'osc1_ctrl2',
  'osc1_sync',
  'osc2_wave',
  'osc2_mod',
  'osc2_semitone',
  'osc2_tune',
  'mix_osc1',
  'mix_osc2',
  'mix_noise',
  'filter_type',
  'filter_cutoff',
  'filter_reso',
  'filter_eg1_a',
  'filter_velo_sense',
  'filter_kbd_track',
  'amp_level',
  'amp_pan',
  'amp_sw',
  'amp_dist',
  'amp_velo_sense',
  'amp_kbd_track',
  'eg1_a',
  'eg1_d',
  'eg1_s',
  'eg1_r',
  'eg2_a',
  'eg2_d',
  'eg2_s',
  'eg2_r',
  'lfo1_wave',
  'lfo1_freq',
  'lfo1_k_sync',
  'lfo1_tempo_sync',
  'lfo1_sync_note',
  'lfo2_wave',
  'lfo2_freq',
  'lfo2_k_sync',
  'lfo2_tempo_sync',
  'lfo2_sync_note',
  'p1_src',
  'p1_dst',
  'p1_a',
  'p2_src',
  'p2_dst',
  'p2_a',
  'p3_src',
  'p3_dst',
  'p3_a',
  'p4_src',
  'p4_dst',
  'p4_a',
}

ms2000_params.TIMBRE_PARAM_PROPS = {

  -- pitch
  pitch_tune = {},
  pitch_bend_range = {},
  pitch_transpose = {},
  pitch_vibrato_interval = {},
  portamento = {
    cc = 5,
  },

  -- osc 1
  osc1_wave = {
    cc = 77,
    opts = OSC1_WAVEFORMS,
    infn = ms2000_params.make_infn_opts(#OSC1_WAVEFORMS),
    outfn = ms2000_params.make_outfn_opts(#OSC1_WAVEFORMS),
  },
  osc1_ctrl1 = {
    cc = 14,
  },
  osc1_ctrl2 = {
    cc = 15,
  },
  osc1_sync = {
    cc = 90,
    opts = { 'OFF', 'ON' },
    infn = function(v)
      return (v > 0) and 1 or 0
    end,
    outfn = function(v)
      return v * 127
    end,
  },

  -- osc 2
  osc2_wave = {
    cc = 78,
    opts = OSC2_WAVEFORMS,
    infn = ms2000_params.make_infn_opts(#OSC2_WAVEFORMS),
    outfn = ms2000_params.make_outfn_opts(#OSC2_WAVEFORMS),
  },
  osc2_mod = {
    cc = 82,
    opts = OSC2_MOD_FX,
    infn = ms2000_params.make_infn_opts(#OSC2_MOD_FX),
    outfn = ms2000_params.make_outfn_opts(#OSC2_MOD_FX),
  },
  osc2_semitone = {
    cc = 18,
  },
  osc2_tune = {
    cc = 19,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },

  -- mixer
  mix_osc1 = {
    cc = 20,
  },
  mix_osc2 = {
    cc = 21,
  },
  mix_noise = {
    cc = 22,
  },

  -- filter
  filter_type = {
    cc = 83,
    opts = FILTER_TYPES,
    infn = ms2000_params.make_infn_opts(#FILTER_TYPES),
    outfn = ms2000_params.make_outfn_opts(#FILTER_TYPES),
  },
  filter_cutoff = {
    cc = 74,
  },
  filter_reso = {
    cc = 71,
  },
  filter_eg1_a = {
    cc = 79,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },
  filter_velo_sense = {
  },
  filter_kbd_track = {
    cc = 85,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },

  -- amp
  amp_level = {
    cc = 7,
  },
  amp_pan = {
    cc = 10,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },
  amp_sw = {
  },
  amp_dist = {
    cc = 92,
    opts = { 'OFF', 'ON' },
    infn = function(v)
      return (v > 0) and 1 or 0
    end,
    outfn = function(v)
      return v * 127
    end,
  },
  amp_velo_sense = {},
  amp_kbd_track = {},

  -- eg1 (filter)
  eg1_a = {
    cc = 23,
  },
  eg1_d = {
    cc = 24,
  },
  eg1_s = {
    cc = 25,
  },
  eg1_r = {
    cc = 26,
  },

  -- eg2 (amp)
  eg2_a = {
    cc = 73,
  },
  eg2_d = {
    cc = 75,
  },
  eg2_s = {
    cc = 70,
  },
  eg2_r = {
    cc = 72,
  },

  -- lfo1
  lfo1_wave = {
    cc = 87,
    opts = LFO1_WAVEFORMS,
    infn = ms2000_params.make_infn_opts(#LFO1_WAVEFORMS),
    outfn = ms2000_params.make_outfn_opts(#LFO1_WAVEFORMS),
  },
  lfo1_freq = {
    cc = 27,
  },
  lfo1_k_sync = {
  },
  lfo1_tempo_sync = {
  },
  lfo1_sync_note = {
  },

  -- lfo1
  lfo2_wave = {
    cc = 88,
    opts = LFO2_WAVEFORMS,
    infn = ms2000_params.make_infn_opts(#LFO2_WAVEFORMS),
    outfn = ms2000_params.make_outfn_opts(#LFO2_WAVEFORMS),
  },
  lfo2_freq = {
    cc = 76,
  },
  lfo2_k_sync = {
  },
  lfo2_tempo_sync = {
  },
  lfo2_sync_note = {
  },

  -- patch 1
  p1_src = {
    nrpn = {4, 0},
  },
  p1_dst = {
    nrpn = {4, 8},
  },
  p1_a = {
    cc = 28,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },

  -- patch 2
  p2_src = {
    nrpn = {4, 1},
  },
  p2_dst = {
    nrpn = {4, 9},
  },
  p2_a = {
    cc = 29,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },

  -- patch 3
  p3_src = {
    nrpn = {4, 2},
  },
  p3_dst = {
    nrpn = {4, 10},
  },
  p3_a = {
    cc = 30,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },

  -- patch 4
  p4_src = {
    nrpn = {4, 3},
  },
  p4_dst = {
    nrpn = {4, 11},
  },
  p4_a = {
    cc = 31,
    infn = ms2000_params.infn_bipolar,
    outfn = ms2000_params.outfn_bipolar,
  },
}


-- ------------------------------------------------------------------------
-- params - vocoder

local mk_vocoder_params = {
  -- vocoder audio in
  vocoder_hpf_lvl = {
    cc = 18,
  },
  vocoder_hpf_threshold = {
    cc = 19,
  },

  -- mix
  mix_vocoder = {
    cc = 21,
  },

  -- formant filter
  vocoder_formant_shift = {
    cc = 83,
  },
  vocoder_filter_cutoff = {
    cc = 74,
  },
  vocoder_mod_amt = {
    cc = 79,
  },

  -- REVIEW: direct=dry?
  vocoder_direct_level = {
    cc = 10,
  },
}


-- ------------------------------------------------------------------------

return ms2000_params
