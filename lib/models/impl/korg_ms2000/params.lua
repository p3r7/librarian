
local ms2000_params = {}


-- ------------------------------------------------------------------------

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

-- special params not saved in dump but used to switch edit modes
ms2000_params.SELECT_PARAMS = {
  timbre = {
    cc = 95,
  },
}

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
  },

  -- arpeggio
  arpeg_trig_l = {},
  arpeg_trig_pattern = {},
  arpeg_status = {},
  arpeg_latch = {},
  arpeg_target = {},
  arpeg_k_sync = {},
  arpeg_type = {},
  arpeg_range = {},
  arpeg_gate_t = {},
  arpeg_resolution = {},
  arpeg_swing = {},

  -- keyboard
  scale_type = {},
  scale_key = {},
  kbd_octave = {},

  -- fx - modulation
  fx_mod_lfo_speed = {},
  fx_mod_depth = {},
  fx_mod_type = {},

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
  osc_1_wave = {
    cc = 77,
  },
  osc_1_ctrl1 = {
    cc = 14,
  },
  osc_1_ctrl2 = {
    cc = 15,
  },
  osc_1_sync = {
    cc = 90,
  },

  -- osc 2
  osc_2_wave = {
    cc = 78,
  },
  osc_2_mod = {
    cc = 82,
  },
  osc_2_semitone = {
    cc = 18,
  },
  osc_2_tune = {
    cc = 19,
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
  },
  filter_cutoff = {
    cc = 74,
  },
  filter_reso = {
    cc = 71,
  },
  filter_eg1_a = {
    cc = 79,
  },
  filter_velo_sense = {
  },
  filter_kbd_track = {
  },

  -- amp
  amp_level = {
    cc = 7,
  },
  amp_pan = {
    cc = 10,
  },
  amp_sw = {
  },
  amp_dist = {
    cc = 92,
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
  p1_src = {},
  p1_dst = {},
  p1_a = {},

  -- patch 2
  p2_src = {},
  p2_dst = {},
  p2_a = {},

  -- patch 3
  p3_src = {},
  p3_dst = {},
  p3_a = {},

  -- patch 4
  p4_src = {},
  p4_dst = {},
  p4_a = {},
}

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
