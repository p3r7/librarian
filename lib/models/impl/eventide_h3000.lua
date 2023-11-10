-- librarian/model/impl/eventide h3000

local h3000 = {}


-- ------------------------------------------------------------------------
-- deps

local midiutil = include("librarian/lib/midiutil")


-- ------------------------------------------------------------------------
-- consts

local NB_SOFT_FNS = 4


-- ------------------------------------------------------------------------
-- consts - param values

local DIATONIC_SHIFT_VOICE_MODES = {
  [0] = "-octave",
  [1] = "-seventh",
  [2] = "-sixth",
  [3] = "-fifth",
  [4] = "-fourth",
  [5] = "-third",
  [6] = "-second",
  [7] = "unison",
  [8] = "-second",
  [9] = "-third",
  [10] = "-fourth",
  [11] = "-fifth",
  [12] = "-sixth",
  [13] = "-seventh",
  [14] = "-octave",

  [15] = "lo ton ped",
  [16] = "lo dom ped",
  [17] = "hi ton ped",
  [18] = "hi dom ped",

  [19] = "user scale 1",
  [20] = "user scale 2",
}

local KEYS = {
  [0]  = "C",
  [1]  = "C#",
  [2]  = "D",
  [3]  = "Eb",
  [4]  = "E",
  [5]  = "F",
  [6]  = "F#",
  [7]  = "G",
  [8]  = "Ab",
  [9]  = "A",
  [10] = "Bb",
  [11] = "B",
}

function make_notes_table()
  local out = {}

  local k = 2
  local octave = 1

  for i=0,46 do
    table.insert(out, KEYS[k] .. octave)
    k = k + 1
    if k > #KEYS-1 then
      k = 0
      octave = octave + 1
    end
  end

  return out
end

local NOTES = make_notes_table()

local function handle_neg(v)
  if v < 0 then
    v = 16384 + v
  end
  return v
end

-- ------------------------------------------------------------------------
-- consts - algos

h3000.ALGOS = {
  [100] = {
    name = "DIATONIC SHIFT",
    params = {
      -- basic
      -- p1
      {
        id = 5,
        name = "Left Voice",
        values = DIATONIC_SHIFT_VOICE_MODES,
      },
      {
        id = 6,
        name = "Right Voice",
        values = DIATONIC_SHIFT_VOICE_MODES,
      },
      {
        id = 35,
        name = "Quantize",
        values = {
          [0] = "on",
          [16383] = "off",
        }
      },
      {
        id = 4,
        name = "Key",
        values = KEYS,
      },
      -- p2
      {
        id = 0,
        name = "Left Mix",
        min = 0,
        max = 100,
        -- unit: %
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        -- unit: %
      },
      {
        id = 2,
        name = "L Feedback",
        min = 0,
        max = 100,
        -- unit: %
      },
      {
        id = 3,
        name = "R Feedback",
        min = 0,
        max = 100,
        -- unit: %
      },
      -- p3
      -- `tune` can't be forced programmatically
      -- `shownote` is just for display
      {
        id = 7,
        name = "Delay",
        min = 0,
        max = 1000,
        -- unit: ms
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        -- unit: dB
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        -- unit: dB
        outfn = handle_neg,
      },
      -- expert
    }
  },
  [101] = {
    name = "LAYERED SHIFT",
    params = {
      -- basic
      -- p1
      {
        id = 4,
        name = "Left Pitch",
        min = -1200,
        max = 1200,
        outfn = handle_neg,
      },
      {
        id = 5,
        name = "L Delay",
        min = 0,
        max = 1000,
        unit = "ms",
      },
      {
        id = 2,
        name = "Left Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p2
      {
        id = 6,
        name = "Right Pitch",
        min = -1200,
        max = 1200,
        outfn = handle_neg,
      },
      {
        id = 7,
        name = "R Delay",
        min = 0,
        max = 1000,
        unit = "ms",
      },
      {
        id = 3,
        name = "Right Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p3
      {
        id = 0,
        name = "Left Mix",
        min = 0,
        max = 100,
        -- unit: %
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        -- unit: %
      },
      {
        id = 11,
        name = "Sustain",
        values = {[0] = "On", [16383] = "Off"},
        -- unit: %
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        -- unit: dB
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        -- unit: dB
        outfn = handle_neg,
      },
      -- expert
      {
        id = 8,
        name = "Low Note",
        -- TODO: custom formatter
        min = 0,
        max = 46,
      },
      {
        id = 9,
        name = "High Note",
        -- TODO: custom formatter
        min = 0,
        max = 4,
      },
      {
        id = 10,
        name = "Source",
        -- NB: 5 (Polyphonic) -> 95 (Mono)
        min = 1,
        max = 19,
        outfn = function(v)
          return math.floor(5 * v)
        end,
      },
    },
  },
  [102] = {
    name = "DUAL SHIFT",
    params = {},
  },
  [103] = {
    name = "STEREO SHIFT",
    params = {},
  },
  [104] = {
    name = "REVERSE SHIFT",
    params = {},
  },
  [105] = {
    name = "SWEPT COMBS",
    params = {},
  },
  [106] = {
    name = "SWEPT REVERB",
    params = {},
  },
  [107] = {
    name = "REVERB FACTORY",
    params = {},
  },
  [108] = {
    name = "ULTRA-TAP",
    params = {},
  },
  [109] = {
    name = "LONG DIGIPLEX",
    params = {},
  },
  [110] = {
    name = "DUAL DIGIPLEX",
    params = {},
  },
  [111] = {
    name = "PATCH FACTORY",
    params = {},
  },
  [112] = {
    name = "STUTTER",
    params = {
      {
        id = 0,
        name = "Trigger",
        is_trig = true,
        v = 7594,
      },
      {
        id = 1,
        name = "Trigger 2",
        is_trig = true,
        v = 7594,
      },
      {
        id = 2,
        name = "Trigger 3",
        is_trig = true,
        v = 7594,
      },
      {
        id = 3,
        name = "Trigger 4",
        is_trig = true,
        v = 7594,
      },
      {
        id = 4,
        name = "Auto",
        values = {
          On = 0,
          Off = 16383
        },
      },
      {
        id = 5,
        name = "Speed",
        min = 0,
        max = 100,
      },
      {
        id = 6,
        name = "Program",
        values = {
          [0] = "Total Random",
          [1] = "Random Sweep",
          [2] = "Random Pitch",
          [3] = "Just Stutter",
        },
      },
      -- left / right mix
      -- levels
      -- expert

    },
  },
  -- NB: 113, 120 & 121 might be the broadcast-specific time stretch thing & the sampler
  [114] = {
    name = "DENSE ROOM",
    params = {},
  },
  [115] = {
    name = "VOCODER",
    params = {},
  },
  [116] = {
    name = "MULTI-SHIFT",
    params = {
      -- basic
      -- p1
      {
        id = 5,
        name = "Left Pitch",
        min = 0,
        max = 3600,
        outfn = function(v)
          -- bellow 1.0
          -- 0.125 - 0.944  ->  12784 - 16284
          -- 35 steps of 100

          -- 1.0 - 2.0  ->  0 - 1200, in step of 100
          -- goes to 8.0 (3600) like that
          return math.floor(5 * v)
        end,
      },
    },
  },
  [117] = {
    name = "BAND DELAY",
    params = {},
  },
  [118] = {
    name = "STRING MODELLER",
    params = {},
  },
  [119] = {
    name = "PHASER",
    params = {},
  },
  [122] = {
    name = "mod factory|one",
    params = {},
  },
  [123] = {
    name = "mod factory|two",
    params = {},
  },
  [123] = {
    name = "mod factory|two",
    params = {},
  },
}


-- ------------------------------------------------------------------------
-- utils - nrpn

function h3000.nrpn_p_name(algo, p)
  if p >= 8208 and p < (8208 + NB_SOFT_FNS) then
    return "SOFT FN #" .. (p-8208+1)
  elseif p >= 8212 and p < (8212 + NB_SOFT_FNS) then
    return "SOFT FN #" .. (p-8212+1) .. " (t)"
  elseif p == 8216 then
    return "FN GEN TYPE"
  elseif p == 8217 then
    return "FN GEN FREQ/TRIG"
  elseif p == 8218 then
    return "FN GEN AMP"
  elseif p == 8196 then
    return "BYPASS"
  end

  return p
end

function h3000.set_bypass(m, ch, state)
  local v = state and 0 or 255
  midiutil.send_nrpn(m, ch, 8196, v)
end

function h3000.set_bank(m, ch, bank)
  midiutil.send_nrpn(m, ch, 8197, bank)
end


-- ------------------------------------------------------------------------
-- pgm change

function h3000.pgm_change(m, ch, dev_id, pgm_id, request_pgm_dump)
  local pgm = pgm_id % 100
  local bank = math.floor((pgm_id - pgm) / 100)

  h3000.set_bank(m, ch, bank)
  midiutil.send_pgm_change(m, ch, pgm)

  if request_pgm_dump then
    h3000.dump_pgm_current(m, dev_id)
  end
end


-- ------------------------------------------------------------------------
-- sysex - general

h3000.SYSEX_EVENTIDE = 0x1c
h3000.SYSEX_H3000 = 0x60

h3000.MTCH_DEV_ID      = 'dev_id'
h3000.MTCH_CH          = 'ch'
h3000.MTCH_BANK        = 'bank'

-- NB: for whatever reason, some sysex answers are doubly encoded!
function h3000.parse_sysex_payload_ascii_encoded(payload)
  local p2 = midiutil.sysex_sans_header(payload)
  p2 = {table.unpack(p2, 5, #p2)}
  local p3 = {}
  local msb = nil
  for _, h in ipairs(p2) do
    if msb == nil then
      msb = h
    else
      table.insert(p3, tonumber(string.char(msb) .. string.char(h), 16))
      msb = nil
    end
  end
  return p3
end


-- ------------------------------------------------------------------------
-- sysex - pgm dump

-- "DUMP EDIT" in manual

local SYSEX_PGM_DUMP_CURRENT = {h3000.SYSEX_EVENTIDE, h3000.SYSEX_H3000, h3000.MTCH_DEV_ID, 0x00,
                                0x7c, 0x46, 0x45, 0x34, 0x36, 0x42, 0x43}

function h3000.dump_pgm_current(m, dev_id)
  local payload = midiutil.sysex_with_header(SYSEX_PGM_DUMP_CURRENT)
  payload = midiutil.sysex_valorized(payload, {[h3000.MTCH_DEV_ID]=dev_id})

  midiutil.send_sysex(m, payload)
end

-- NB: overly simplistic but good enough for now
function h3000.is_sysex_pgm_dump(payload, dev_id)
  return midiutil.sysex_sarts_with(midiutil.sysex_sans_header(payload), {h3000.SYSEX_EVENTIDE, h3000.SYSEX_H3000, dev_id, 0x00, 0x3a, 0x30, 0x31, 0x36, 0x38, 0x41, 0x42, 0x30, 0x30, 0x41, 0x30, 0x34, 0x43})
end

local function pgm_id_from_pgm_dump(payload)
  -- NB: works for up to #399
  return payload[11] + payload[12]
end

function h3000.parse_pgm_dump(raw_payload)
  local payload = h3000.parse_sysex_payload_ascii_encoded(raw_payload)

  -- if payload[11] > 0xC8 then
  --   payload[11] = 0xC8 + (payload[11] - 0xC8) * 100
  -- end
  -- NB: works for up to #399
  local pgm_id = payload[11] + payload[12]

  local pgm_name = ""
  for i=1,15 do
    pgm_name = pgm_name .. string.char(payload[21+i-1])
  end

  local algo = payload[19]

  return {
    id = pgm_id,
    name = pgm_name,
    algo = algo,
  }
end


-- ------------------------------------------------------------------------
-- sysex - bank select

local SYSEX_BANK_SELECT = {0x7f, h3000.MTCH_DEV_ID, 0x02, 0x01, h3000.MTCH_CH, 0x00, 0x00, 0x00, 0x00, h3000.MTCH_BANK, 0x00}

function h3000.extract_sysex_bank_select(payload)
  return midiutil.sysex_match(midiutil.sysex_sans_header(payload),
                              SYSEX_BANK_SELECT)
end

function h3000.is_sysex_bank_select(payload, dev_id, ch)
  local ok, matches = h3000.extract_sysex_bank_select(payload)
  if not ok then
    return false
  end

  return (matches[h3000.MTCH_DEV_ID] == dev_id and (matches[h3000.MTCH_CH] + 1) == ch)
end


-- ------------------------------------------------------------------------
-- sysex - pgm change map

-- "DUMP PATCH"

local SYSEX_PGM_MAP_DUMP = {h3000.SYSEX_EVENTIDE, h3000.SYSEX_H3000, h3000.MTCH_DEV_ID, 0x00,
                            0x7c, 0x46, 0x45, 0x34, 0x34, 0x42, 0x45}


function h3000.sysex_dump_pgm_map(m, dev_id)
  local payload = midiutil.sysex_with_header(SYSEX_PGM_MAP_DUMP)
  payload = midiutil.sysex_valorized(payload, {[h3000.MTCH_DEV_ID]=dev_id})
  midiutil.send_sysex(m, payload)
end


-- ------------------------------------------------------------------------
-- sysex - user presets dump

-- "DUMP PRESETS"
-- dump all "user presets"

-- NB: always produces the same 2 messages as output?!
--
-- > F0 1C 60 00 01 3A 30 31 36 38 43 42 30 30 41 30 32 43
-- > 0D 0A 3A 30 38 30 33 30 30 30 30 41 41 35 35 30 30 30
-- > 38 46 39 30 30 30 30 30 30 46 35 0D 0A 3A 30 38 30 33
-- > 30 38 30 30 46 46 46 46 30 30 30 38 46 41 30 30 30 30
-- > 30 30 45 44 0D 0A F7
-- >
-- > F0 1C 60 00 00 7C 46 43 36 34 41 30 0D 0A F7
--
-- i guess that meas "no user preset", only ROM ones

local SYSEX_PRESETS_DUMP = {h3000.SYSEX_EVENTIDE, h3000.SYSEX_H3000, h3000.MTCH_DEV_ID, 0x00,
                            0x7c, 0x46, 0x45, 0x34, 0x32, 0x43, 0x30}

function h3000.sysex_dump_presets(m, dev_id)
  local payload = midiutil.sysex_with_header(SYSEX_PRESETS_DUMP)
  payload = midiutil.sysex_valorized(payload, {[h3000.MTCH_DEV_ID]=dev_id})
  midiutil.send_sysex(m, payload)
end



-- ------------------------------------------------------------------------

return h3000
