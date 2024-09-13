-- librarian/model/impl/alesis_akira/params

local akira_params = {}


-- ------------------------------------------------------------------------
-- pgm / params

akira_params.PARAMS = { "X", "Y", "Z" }
akira_params.PARAMS_PROPS = {
  X = {
    cc = 45,
    fmt = AlesisAkira.fmt,
  },
  Y = {
    cc = 78,
    fmt = AlesisAkira.fmt,
  },
  Z = {
    cc = 93,
    fmt = AlesisAkira.fmt,
  },
}

akira_params.PGM_LIST = {
  -- REVERBS
  [0] = {
    name = "HALL",
    X = "DENSITY",
    Y = "DECAY",
    Z = "BRIGHTNESS",
  },
  [1] = {
    name = "VOCAL HALL",
    X = "DENSITY",
    Y = "DECAY",
    Z = "WARMTH",
  },
  [2] = {
    name = "VOCAL PLATE",
    X = "DENSITY",
    Y = "DECAY",
    Z = "WARMTH",
  },
  [3] = {
    name = "DRUM ROOM",
    X = "DENSITY",
    Y = "DECAY",
    Z = "BRIGHTNESS",
  },
  [4] = {
    name = "SPACE",
    X = "DENSITY",
    Y = "DECAY",
    Z = "BRIGHTNESS",
  },
  [5] = {
    name = "TRASH CAN",
    X = "DENSITY",
    Y = "DECAY",
    Z = "BRIGHTNESS",
  },
  [6] = {
    name = "GATED",
    X = "THRESHOLD",
    Y = "TIME",
    Z = "DECAY",
  },
  [7] = {
    name = "REVERSE",
    X = "PREDELAY",
    Y = "ATTACK",
    Z = "BRIGHTNESS",
  },
  [8] = {
    name = "DYNAMIC REVRB",
    X = "SENSITIVITY",
    Y = "DECAY TIME",
    Z = "BRIGHTNESS",
  },
  [9] = {
    name = "FLANGED REVERB",
    X = "BRIGHTNESS",
    Y = "DECAY",
    Z = "FEEDBACK",
  },
  [10] = {
    name = "PITCHED REVERB",
    X = "DENSITY",
    Y = "DECAY",
    Z = "PITCH SHIFT",
  },
  [11] = {
    name = "G GARAGE",
    X = "COMPRESSION",
    Y = "PHASOR",
    Z = "REVERB",
  },

  -- DELAYS
  [12] = {
    name = "DELAY",
    X = "DELAY",
    Y = "FEEDBACK",
    Z = "BRIGHTNESS",
  },
  [13] = {
    name = "STEREO DELAY",
    X = "DELAY",
    Y = "FEEDBACK",
    Z = "BRIGHTNESS",
  },
  [14] = {
    name = "RUNAWAY",
    X = "DELAY",
    Y = "FEEDBACK",
    Z = "BRIGHTNESS",
  },
  [15] = {
    name = "LPF DELAY",
    X = "DELAY",
    Y = "FEEDBACK",
    Z = "FREQUENCY",
  },
  [16] = {
    name = "HPF DELAY",
    X = "DELAY",
    Y = "FEEDBACK",
    Z = "FREQUENCY",
  },
  [17] = {
    name = "BPF DELAY",
    X = "DELAY",
    Y = "FEEDBACK",
    Z = "FREQUENCY",
  },
  [18] = {
    name = "PHASOR DELAY",
    X = "DELAY",
    Y = "FEEDBACK",
    Z = "REGEN",
  },

  -- PITCH EFFECTS
  [19] = {
    name = "PHASOR 1",
    X = "FEEDBACK",
    Y = "DEPTH",
    Z = "RATE",
  },
  [20] = {
    name = "PHASOR 2",
    X = "FREQUENCY",
    Y = "DEPTH",
    Z = "RATE",
  },
  [21] = {
    name = "AUTOPHAZ",
    X = "FREQUENCY",
    Y = "FEEDBACK",
    Z = "SENSITIVITY",
  },
  [22] = {
    name = "FLANGER",
    X = "FREQUENCY",
    Y = "DEPTH",
    Z = "RATE",
  },
  [23] = {
    name = "INV FLANGER",
    X = "FREQUENCY",
    Y = "DEPTH",
    Z = "RATE",
  },
  [24] = {
    name = "DUAL TRANSPOSER",
    X = "BALANCE",
    Y = "PITCH A",
    Z = "PITCH B",
  },
  [25] = {
    name = "STEREO DETUNE",
    X = "SPREAD",
    Y = "PITCH L",
    Z = "PITCH R",
  },
  [26] = {
    name = "FREQUENCY SHIFT",
    X = "FINE TUNE",
    Y = "SHIFT",
    Z = "RATE",
  },
  [27] = {
    name = "CHORUS",
    X = "RATE",
    Y = "DEPTH",
    Z = "WIDTH",
  },
  [28] = {
    name = "VIBRATO",
    X = "DEPTH",
    Y = "SHAPE",
    Z = "RATE",
  },
  [29] = {
    name = "VIBRO-WOBBLE",
    X = "VIBRATO",
    Y = "TREMOLO",
    Z = "DEPTH",
  },

  --  FILTERS
  [30] = {
    name = "BAND LIMIT",
    X = "FREQUENCY",
    Y = "WIDTH",
    Z = "NOISE",
  },
  [31] = {
    name = "LP BP HP",
    X = "FREQUENCY",
    Y = "Q",
    Z = "LP-BP-HP",
  },
  [32] = {
    name = "LFO LP",
    X = "FREQUENCY",
    Y = "DEPTH",
    Z = "RATE",
  },
  [33] = {
    name = "AUTOWAH",
    X = "FREQUENCY",
    Y = "SENSITIVITY",
    Z = "RATE",
  },
  [34] = {
    name = "FORMANTS",
    X = "VOWEL",
    Y = "RANGE",
    Z = "RATE",
  },
  [35] = {
    name = "SAMPLED BPF",
    X = "DEPTH",
    Y = "FREQUENCY",
    Z = "RATE",
  },
  [36] = {
    name = "RESONATOR",
    X = "FREQUENCY",
    Y = "DEPTH/SHAPE",
    Z = "RATE",
  },
  [37] = {
    name = "VOCO-BEND",
    X = "BRIGHTNESS",
    Y = "SIBILANCE",
    Z = "FREQUENCY",
  },
  [38] = {
    name = "VOCODER",
    X = "PITCH",
    Y = "SIBILANCE",
    Z = "SENSITIVITY",
  },

  -- DIRT
  [39] = {
    name = "RECORD NOISE",
    X = "DUST",
    Y = "TICKS",
    Z = "SKIP",
  },
  [40] = {
    name = "TAPE SATURATOR",
    X = "DRIVE",
    Y = "DISTORTION",
    Z = "BUMP",
  },
  [41] = {
    name = "FUZZ",
    X = "DRIVE",
    Y = "LOW",
    Z = "HIGH",
  },
  [42] = {
    name = "DECIMATOR",
    X = "DECIMATION",
    Y = "RING",
    Z = "DAMP",
  },
  [43] = {
    name = "GRINDER",
    X = "SENSITIVITY",
    Y = "RESONANCE",
    Z = "FREQUENCY",
  },

  -- MISC
  [44] = {
    name = "RING MODULATOR",
    X = "DEPTH",
    Y = "ENVELOPE",
    Z = "FREQUENCY",
  },
  [45] = {
    name = "RMS LIMITER",
    X = "DRIVE",
    Y = "RATE",
    Z = "OUTPUT",
  },
  [46] = {
    name = "SUB BASS",
    X = "SUB",
    Y = "DRIVE",
    Z = "LO CUT",
  },
  [47] = {
    name = "TREMOLO",
    X = "DEPTH",
    Y = "SHAPE",
    Z = "RATE",
  },
  [48] = {
    name = "AUTOPAN",
    X = "CENTER",
    Y = "WIDTH",
    Z = "RATE",
  },
  [49] = {
    name = "VOCAL CANCEL",
    X = "FREQUENCY",
    Y = "BALANCE",
    Z = "SHIFT",
  },
}

function akira_params.make_pgm_list()
  local pgm_list = {}
  -- system presets (RO)
  for i, pgm_props in pairs(akira_params.PGM_LIST) do
    table.insert(pgm_list, i.." - "..pgm_props.name)
  end
  -- user presets   (RW)
  for pgm=50,100 do
    table.insert(pgm_list, i.." - User #"..(pgm-49))
  end
  return pgm_list
end


function akira_params.param_name(pgm_id, knob)
  local pp = akira_params.PGM_LIST[pgm_id]
  if pp then
    return pp[knob]
  end
end


-- ------------------------------------------------------------------------
-- fmt

-- NB: this function returns a param formatter fn w/ `hw` & `knob` injected in its context so that we can query the current pgm
function akira_params.make_fmt(hw, knob)
  return function(param)
    local knob_name = akira_params.param_id(hw.pgm, knob)
    if knob_name then
      return knob_name .. " " .. v
    end
    return v
  end
end


-- ------------------------------------------------------------------------

return akira_params
