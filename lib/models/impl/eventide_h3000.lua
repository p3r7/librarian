-- librarian/model/impl/eventide h3000

local h3000 = {}


-- ------------------------------------------------------------------------
-- deps

local midiutil = include("librarian/lib/midiutil")
include("librarian/lib/core") -- for `tab_sliced`


-- ------------------------------------------------------------------------
-- consts

local NB_SOFT_FNS = 4


-- ------------------------------------------------------------------------
-- pgm list

function h3000.read_pgm_list()
  local conf_path = _path.data .. 'librarian' .. '/' .. "h3000_pgm_list.lua"
  if util.file_exists(conf_path) then
    return dofile(conf_path)
  end
end

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

local function handle_neg_x100(v)
  v = v * 100
  if v < 0 then
    v = 16384 + v
  end
  return v
end


-- ------------------------------------------------------------------------
-- formatters

local function fmt_low_note(param)
  -- TODO: this one is super tricky as depends on the high note one
  -- can get current id w/ `param.id`

  return param:get()
end

local function fmt_high_note(param)
  return "C" .. (param:get() + 4)
end

local function fmt_source(param)
  local v = param:get()
  -- local pct = v/19
  return "P" .. string.rep(" ", v-1) .. "*" .. string.rep(" ", 19-v) .. "S"
end

local function fmt_image(param)
  local v = param:get()
  local WIDTH = 15
  if v == 0 then
    return "|" .. string.rep(" ", util.round(WIDTH/2)) .. "M" .. string.rep(" ", util.round(WIDTH/2)) .. "|"
  elseif v < 0 then
    local offset = util.round(util.linlin(0, 99, WIDTH/2, 0, -v))
    return "|" .. string.rep(" ", offset) .. "R" .. string.rep(" ", WIDTH - offset * 2) .. "L" .. string.rep(" ", offset) .. "|"
  else
    local offset = util.round(util.linlin(0, 99, WIDTH/2, 0, v))
    return "|" .. string.rep(" ", offset) .. "L" .. string.rep(" ", WIDTH - offset * 2) .. "R" .. string.rep(" ", offset) .. "|"
  end
end

-- function fmt_image(v)
--   local WIDTH = 19
--   if v < 0 then
--     local offset = util.round(util.linlin(0, 99, WIDTH/2, 0, -v))
--     return string.rep(" ", offset) .. "R" .. string.rep(" ", WIDTH - offset * 2) .. "L" .. string.rep(" ", offset)
--   else
--     local offset = util.round(util.linlin(0, 99, WIDTH/2, 0, v))
--     return string.rep(" ", offset) .. "L" .. string.rep(" ", WIDTH - offset * 2) .. "R" .. string.rep(" ", offset)
--   end
-- end

local function fmt_pct_x10(param)
  local v = param:get()
  return string.format("%.1f", v/10) .. "%"
end


local function fmt_pitch(param)
  -- displayed range: 0.250 -> 2.0
  -- - -2400 [109 32] -> 1200 [9 48]
  local v = param:get()
  if v < 0 then
    return string.format("%.3f", util.linlin(0, 2400, 1, 0.250, -v)) .. ":1"
  else
    return string.format("%.3f", util.linlin(0, 1200, 1, 2, v)) .. ":1"
  end
end

local function fmt_pitch_multi_shift(param)
  -- bellow 1.0
  -- 0.125 - 0.944  ->  12784 - 16284

  -- 1.0 - 2.0  ->  0 - 1200, in step of 100
  -- goes to 8.0 (3600) like that
  local v = param:get()
  if v < 0 then
    return string.format("%.3f", util.linlin(0, 3600, 1, 0.125, -v)) .. ":1"
  else
    return string.format("%.3f", util.linlin(0, 3600, 1, 8, v)) .. ":1"
  end
end

local function fmt_time_reverb(param)
  local v = param:get()

  -- 0.1 -> 3.0 in 0.1 steps
  if v <= 29 then
    string.format("%.1f", (v+1)/10) .. "s"
  end

  -- 3.2 -> 5.0 in 0.2 steps
  if v <= 39 then
    string.format("%.1f", util.linlin(30, 39, 3.2, 5.0, v)) .. "s"
  end

  -- 5.5 -> 10.0 in 0.5 steps
  if v <= 49 then
    string.format("%.1f", util.linlin(31, 49, 5.5, 10.0, v)) .. "s"
  end

  -- 15 -> 30 in 5 steps
  if v <= 49 then
    string.format("%.1f", util.linlin(50, 53, 15, 30, v)) .. "s"
  end

  -- 40 -> 100 in 10 steps
  if v <= 60 then
    string.format("%.1f", util.linlin(54, 60, 40, 100, v)) .. "s"
  end

  -- 200 -> 500 in 100 steps
  if v <= 67 then
    string.format("%.1f", util.linlin(61, 67, 200, 800, v)) .. "s"
  end

  if v == 68 then
    return "big"
  end

  if v == 69 then
    return "infinite"
  end
end


-- ------------------------------------------------------------------------
-- consts - algos

h3000.ALGOS = {
  [100] = { -- DONE
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
        -- FIXME: not working...
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
        unit = "%",
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 2,
        name = "L Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 3,
        name = "R Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p3
      -- `tune` can't be triggered programmatically
      -- `shownote` is just for display
      {
        id = 7,
        name = "Delay",
        min = 0,
        max = 1000,
        unit = "ms",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 11,
        name = "Scale 1 Interval C",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 12,
        name = "Scale 1 Interval C#",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 13,
        name = "Scale 1 Interval D",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 14,
        name = "Scale 1 Interval Eb",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 15,
        name = "Scale 1 Interval E",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 16,
        name = "Scale 1 Interval F",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 17,
        name = "Scale 1 Interval F#",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 18,
        name = "Scale 1 Interval G",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 19,
        name = "Scale 1 Interval Ab",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 20,
        name = "Scale 1 Interval A",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 21,
        name = "Scale 1 Interval Bb",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 22,
        name = "Scale 1 Interval B",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 23,
        name = "Scale 2 Interval C",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 24,
        name = "Scale 2 Interval C#",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 25,
        name = "Scale 2 Interval D",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 26,
        name = "Scale 2 Interval Eb",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 27,
        name = "Scale 2 Interval E",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 28,
        name = "Scale 2 Interval F",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 29,
        name = "Scale 2 Interval F#",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 30,
        name = "Scale 2 Interval G",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 31,
        name = "Scale 2 Interval Ab",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 32,
        name = "Scale 2 Interval A",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 33,
        name = "Scale 2 Interval Bb",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },
      {
        id = 34,
        name = "Scale 2 Interval B",
        min = -24,
        max = 12,
        unit = "cents",
        outfn = handle_neg_x100,
      },

      {
        id = 8,
        name = "Low Note",
        -- TODO: custom formatter
        min = 0,
        max = 46,
        fmt = fmt_low_note,
      },
      {
        id = 9,
        name = "High Note",
        -- TODO: custom formatter
        min = 0,
        max = 4,
        fmt = fmt_high_note,
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
        fmt = fmt_source,
      },
    }
  },
  [101] = { -- DONE
    name = "LAYERED SHIFT",
    params = {
      -- basic
      -- p1
      {
        id = 4,
        name = "Left Pitch",
        min = -2400,
        max = 1200,
        outfn = handle_neg,
        fmt = fmt_pitch,
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
        min = -2400,
        max = 1200,
        outfn = handle_neg,
        fmt = fmt_pitch,
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
        unit = "%",
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 11,
        name = "Sustain",
        values = {[0] = "On", [16383] = "Off"},
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 8,
        name = "Low Note",
        -- TODO: custom formatter
        min = 0,
        max = 46,
        fmt = fmt_low_note,
      },
      {
        id = 9,
        name = "High Note",
        -- TODO: custom formatter
        min = 0,
        max = 4,
        fmt = fmt_high_note,
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
        fmt = fmt_source,
      },
    },
  },
  [102] = { -- DONE
    name = "DUAL SHIFT",
    params = {
      -- basic
      -- p1
      {
        id = 4,
        name = "Left Pitch",
        min = -2400,
        max = 1200,
        outfn = handle_neg,
        fmt = fmt_pitch,
      },
      {
        id = 5,
        name = "Left Delay",
        min = 0,
        max = 500,
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
        min = -2400,
        max = 1200,
        outfn = handle_neg,
        fmt = fmt_pitch,
      },
      {
        id = 7,
        name = "Right Delay",
        min = 0,
        max = 500,
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
        unit = "%",
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 11,
        name = "Sustain",
        values = {[0] = "On", [16383] = "Off"},
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 8,
        name = "Low Note",
        -- TODO: custom formatter
        min = 0,
        max = 46,
        fmt = fmt_low_note,
      },
      {
        id = 9,
        name = "High Note",
        -- TODO: custom formatter
        min = 0,
        max = 4,
        fmt = fmt_high_note,
      },
      {
        id = 10,
        name = "Source",
        -- NB: 5 (Polyphonic) -> 95 (Solo)
        min = 1,
        max = 19,
        outfn = function(v)
          return math.floor(5 * v)
        end,
        fmt = fmt_source,
      },
    },
  },
  [103] = { -- DONE
    name = "STEREO SHIFT",
    params = {
      -- p1
      {
        id = 6,
        name = "L+R Pitch",
        min = -2400,
        max = 1200,
        outfn = handle_neg,
        fmt = fmt_pitch,
      },
      {
        id = 7,
        name = "L+R Delay",
        min = 0,
        max = 1000,
        unit = "ms",
      },
      {
        id = 1,
        name = "L+R Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p2
      {
        id = 0,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 8,
        name = "Low Note",
        -- TODO: custom formatter
        min = 0,
        max = 46,
        fmt = fmt_low_note,
      },
      {
        id = 9,
        name = "High Note",
        -- TODO: custom formatter
        min = 0,
        max = 4,
        fmt = fmt_high_note,
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
        fmt = fmt_source,
      },
    },
  },
  [104] = { -- DONE
    name = "REVERSE SHIFT",
    params = {
      -- p1
      {
        id = 4,
        name = "Left Pitch",
        min = -2400,
        max = 1200,
        outfn = handle_neg,
        fmt = fmt_pitch,
      },
      {
        id = 5,
        name = "Left Length",
        min = 1,
        max = 1400,
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
        id = 5,
        name = "Right Pitch",
        min = -2400,
        max = 1200,
        outfn = handle_neg,
        fmt = fmt_pitch,
      },
      {
        id = 7,
        name = "Right Length",
        min = 1,
        max = 1400,
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
        unit = "%",
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 11,
        name = "Sustain",
        values = {[0] = "On", [16383] = "Off"},
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- no expert params
    },
  },
  [105] = { -- DONE
    name = "SWEPT COMBS",
    params = {
      -- p1
      {
        id = 2,
        name = "Master Delay",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 3,
        name = "Master Rate",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 8,
        name = "Master Depth",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 9,
        name = "Master Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p2
      {
        id = 10,
        name = "Width",
        min = -100,
        max = 100,
        outfn = handle_neg,
        fmt = fmt_image,
      },
      {
        id = 7,
        name = "Loop Repeats",
        values = {[0] = "On", [16383] = "Off"},
      },
      {
        id = 0,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 4,
        name = "Glide Rate",
        min = 0,
        max = 5000, (39 << 7) + 8
        -- unit = "%",
        -- TODO: custom formatter
      },
      {
        id = 5,
        name = "Delay Gliding",
        {[0] = "On", [16383] = "Off"}, -- (127 << 7) + 127
      },
      {
        id = 6,
        name = "Input Mode",
        {[0] = "Stereo", [16383] = "Mono"}, -- (127 << 7) + 127
      },
    },
  },
  [106] = { -- DONE
    name = "SWEPT REVERB",
    params = {
      -- p1
      {
        id = 2,
        name = "Master Delay",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 3,
        name = "Master Rate",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 8,
        name = "Master Depth",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 9,
        name = "Master Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p2
      {
        id = 0,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 7,
        name = "Loop Repeats",
        values = {[0] = "On", [16383] = "Off"},
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 4,
        name = "Glide Rate",
        min = 0,
        max = 5000, (39 << 7) + 8
        -- unit = "%",
        -- TODO: custom formatter
      },
      {
        id = 5,
        name = "Delay Gliding",
        {[0] = "On", [16383] = "Off"}, -- (127 << 7) + 127
      },
    },
  },
  [107] = {
    name = "REVERB FACTORY",
    params = {},
  },
  [108] = { -- DONE
    name = "ULTRA-TAP",
    params = {
      -- p1
      {
        id = 2,
        name = "Master Delay",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 3,
        name = "Diffusion",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 4,
        name = "Width",
        min = -100,
        max = 100,
        outfn = handle_neg,
        fmt = fmt_image,
      },
      {
        id = 49,
        name = "Feedback",
        min = -100,
        max = 99,
        outfn = handle_neg,
        unit = "%",
      },
      -- p2
      {
        id = 0,
        name = "Left Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 5,
        name = "Input Mode",
        {[0] = "Stereo", [16383] = "Mono"}, -- (127 << 7) + 127
      },
      {
        id = 50,
        name = "Feedback Tap",
        min = 0,
        max = 100,
      },
    },
  },
  [109] = { -- DONE
    name = "LONG DIGIPLEX",
    params = {
      -- p1
      {
        id = 2,
        name = "Loop Delay",
        min = 0,
        max = 1400,
        unit = "ms",
      },
      {
        id = 7,
        name = "Loop Repeats",
        values = {[0] = "On", [16383] = "Off"},
      },
      {
        id = 0,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 49,
        name = "Loop Feedback",
        min = -100,
        max = 99,
        outfn = handle_neg,
        unit = "%",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 4,
        name = "Glide Rate",
        min = 0,
        max = 5000, (39 << 7) + 8
        -- unit = "%",
        -- TODO: custom formatter
      },
      {
        id = 5,
        name = "Delay Gliding",
        {[0] = "On", [16383] = "Off"}, -- (127 << 7) + 127
      },
    },
  },
  [110] = { -- DONE
    name = "DUAL DIGIPLEX",
    params = {
      -- both on p1 & p2
      {
        id = 7,
        name = "Loop Repeats",
        values = {[0] = "On", [16383] = "Off"},
      },
      -- p1
      {
        id = 2,
        name = "Left Delay",
        min = 0,
        max = 700,
        unit = "ms",
      },
      {
        id = 0,
        name = "Left Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 3,
        name = "Left Feedback",
        min = -100,
        max = 99,
        outfn = handle_neg,
        unit = "%",
      },
      -- p2
      {
        id = 8,
        name = "Right Delay",
        min = 0,
        max = 700,
        unit = "ms",
      },
      {
        id = 1,
        name = "Right Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 9,
        name = "Right Feedback",
        min = -100,
        max = 99,
        outfn = handle_neg,
        unit = "%",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 4,
        name = "Glide Rate",
        min = 0,
        max = 5000, (39 << 7) + 8
        -- unit = "%",
        -- TODO: custom formatter
      },
      {
        id = 5,
        name = "Delay Gliding",
        {[0] = "On", [16383] = "Off"}, -- (127 << 7) + 127
      },
      {
        id = 6,
        name = "Input Mode",
        {[0] = "Stereo", [16383] = "Mono"}, -- (127 << 7) + 127
      },
    },
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
          [0] = "On",
          [16383] = "Off",
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

  [114] = { -- DONE
    name = "DENSE ROOM",
    params = {
      -- p1
      {
        id = 0,
        name = "Pre Delay",
        min = 0,
        max = 500,
        unit = "ms",
      },
      {
        id = 1,
        name = "Reverb Time",
        min = 0,
        max = 69,
        fmt = fmt_time_reverb,
      },
      {
        id = 2,
        name = "High Cut",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 3,
        name = "Room Size",
        min = 0,
        max = 1000,
        fmt = fmt_pct_1000,
      },
      -- p2
      {
        id = 4,
        name = "Position",
        min = 0,  -- front
        max = 23, -- back
        -- NB: visual mid point is at 12
        -- TODO: custom formatter, akin to width
      },
      {
        id = 5,
        name = "Pan",
        min = 0,  -- left
        max = 20, -- right
        -- TODO: custom formatter, akin to width
      },
      {
        id = 6,
        name = "Early Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 7,
        name = "Diffusion",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p3
      {
        id = 8,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 13,
        name = "Delay 1",
        min = 0,
        max = 5000,
        unit = "samples",
      },
      {
        id = 14,
        name = "Delay 2",
        min = 0,
        max = 5000,
        unit = "samples",
      },
      {
        id = 15,
        name = "Delay 3",
        min = 0,
        max = 5000,
        unit = "samples",
      },
      {
        id = 16,
        name = "Delay 4",
        min = 0,
        max = 5000,
        unit = "samples",
      },
    },
  },
  [115] = { -- DONE
    name = "VOCODER",
    params = {
      -- p1
      {
        id = 0,
        name = "Format Speed",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 1,
        name = "Env Speed",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 2,
        name = "Formant Shift",
        min = 0,
        max = 1000,
        fmt = fmt_pct_x10,
      },
      {
        id = 3,
        name = "Depth",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- p2
      {
        id = 4,
        name = "Stereo Width",
        min = 0,
        max = 100,
        fmt = function(param)
          local v = param:get()
          return string.format("%.1f", v/10) .. "ms"
        end,
      },
      {
        id = 5,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      -- levels
      {
        id = 36,
        name = "Left In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      {
        id = 37,
        name = "Right In",
        min = -48,
        max = 48,
        unit = "dB",
        outfn = handle_neg,
      },
      -- expert
      {
        id = 10,
        name = "Max Resonance",
        min = 0,
        max = 1000,
        fmt = fmt_pct_x10,
      },
      {
        id = 11,
        name = "Min Error",
        min = 0,
        max = 1000,
        fmt = fmt_pct_x10,
      },
      {
        id = 12,
        name = "Gate Threshold",
        min = 0,
        max = 100,
        unit = "%",
      },
    },
  },
  [116] = {
    name = "MULTI-SHIFT",
    params = {
      -- basic
      -- p1
      {
        id = 0,
        name = "Left Pitch",
        min = -3600,
        max = 3600,
        outfn = handle_neg,
        fmt = fmt_pitch_multi_shift,
      },
      {
        id = 1,
        name = "L Pitch Delay",
        min = 0,
        max = 675,
        unit = "ms",
      },
      {
        id = 2,
        name = "L Delay",
        min = 0,
        max = 700,
        unit = "ms",
      },
      {
        id = 3,
        name = "Right Pitch",
        min = -3600,
        max = 3600,
        outfn = handle_neg,
        fmt = fmt_pitch_multi_shift,
      },
      {
        id = 4,
        name = "R Pitch Delay",
        min = 0,
        max = 675,
        unit = "ms",
      },
      {
        id = 5,
        name = "R Delay",
        min = 0,
        max = 700,
        unit = "ms",
      },
      {
        id = 6,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 7,
        name = "Global Feedback",
        min = -1000,
        max = 1000,
        outfn = handle_neg,
        fmt = fmt_pct_x10,
      },
      {
        id = 8,
        name = "Image",
        min = -99,
        max = 99,
        outfn = handle_neg,
        fmt = fmt_image,
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
    params = {
      -- p1
      {
        id = 0,
        name = "Mix",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 1,
        name = "Feedback",
        min = 0,
        max = 100,
        unit = "%",
      },
      {
        id = 2,
        name = "Sweep Rate",
        min = 0,
        max = 5000,
        -- TODO: custom formatter
        -- not linear again...
      },
      {
        id = 5,
        name = "phaser mode",
        values = {[0] = "Sweep", [1] = "Env", [2] = "ADSR",},
      },
      -- p2
      -- TODO
    },
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
