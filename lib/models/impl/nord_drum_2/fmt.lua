
local nd2_fmt = {}

-- ------------------------------------------------------------------------

function nd2_fmt.format_balance(param)
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

function nd2_fmt.format_basic(param)
  local value = param:get()
  return math.floor(util.linlin(0, 127, 0, 50, value))
end

function nd2_fmt.format_20(param)
  local value = param:get()
  return math.floor(util.linlin(0, 127, 0, 20, value))
end

function nd2_fmt.format_50_bp(param)
  local value = param:get()
  local scaled = math.floor(util.linlin(0, 127, -50, 50, value))
  if scaled > 0 then
    return "+"..scaled
  end
  return scaled
end

function nd2_fmt.format_24_bp(param)
  local value = param:get()
  local scaled = math.floor(util.linlin(0, 127, -24, 24, value))
  if scaled > 0 then
    return "+"..scaled
  end
  return scaled
end

function nd2_fmt.format_99(param)
  local value = param:get()
  return math.floor(util.linlin(0, 127, 0, 99, value))
end

function nd2_fmt.format_pitch(param)
  local value = param:get()
  return value
end


nd2_fmt.TONE_WAVE_DESC = {
  A1 = 'sine',
  A2 = 'triangle',
  A3 = 'saw',
  A4 = 'square',
  A5 = 'square hpf',
  A6 = 'pulse',
}

nd2_fmt.TONE_WAVES = {
  'A1', 'A2', 'A3', 'A4', 'A5', 'A6',
  'r1', 'r2',
  't1',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6',
  'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7',
  'P1', 'P2', 'P3', 'P4',
  'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8', 'd9',
  'C1', 'C2', 'C3',
}

nd2_fmt.TONE_WAVES_CC_VALS = {
  A1 = 75, A2 = 85, A3 = 79, A4 = 82, A5 = 118, A6 = 121,
  r1 = 124, r2 = 127,
  t1 = 114,
  F1 = 92, F2 = 95, F3 = 98, F4 = 101, F5 = 105, F6 = 108,
  H1 = 0, H2 = 4, H3 = 7, H4 = 10, H5 = 14, H6 = 17, H7 = 20,
  P1 = 49, P2 = 53, P3 = 56, P4 = 59,
  d1 = 23, d2 = 27, d3 = 30, d4 = 33, d5 = 36, d6 = 40, d7 = 43, d8 = 46, d9 = 88,
  C1 = 69, C2 = 72, C3 = 111,
}

nd2_fmt.NOISE_FILTER_TYPES = {
  "LP12", "LP24",
  "bP6", "bP12",
  "HP12", "HP24",
  "HPhc",
}

nd2_fmt.NOISE_FILTER_TYPES_CC_VALS = {
  LP12 = 0, LP24 = 22,
  bP6 = 43, bP12 = 64,
  HP12 = 85, HP24 = 106,
  HPhc = 127,
}

nd2_fmt.CLICK_TYPES = {
  "n1", "n2", "n3", "n4", "n5", "n6", "n7", "n8", "n9",
  "P1", "P2",
}

nd2_fmt.CLICK_TYPES_CC_VALS = {
  n1 = 0, n2 = 4, n3 = 8, n4 = 11, n5 = 15, n6 = 19, n7 = 22, n8 = 26, n9 = 30,
  P1 = 33, P2 = 37, P3 = 40, P4 = 44, P5 = 48, P6 = 51, P7 = 55, P8 = 59, P9 = 62,
  PH1 = 66, PH2 = 69, PH3 = 73, PH4 = 77, PH5 = 80, PH6 = 84, PH7 = 88, PH8 = 91, PH9 = 95,
  C1 = 98, C2 = 102, C3 = 106, C4 = 109, C5 = 113, C6 = 117, C7 = 120, C8 = 124, C9 = 127,
}

nd2_fmt.NOISE_ATTACK_MODES = {
  'AD',
  'LFO1', 'LFO2', 'LFO3',
  'Clap1', 'Clap2', 'Clap3', 'Clap4', 'Clap5', 'Clap6', 'Clap7', 'Clap8', 'Clap9'
}

-- nd2_fmt.EQ_FREQS = {
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

return nd2_fmt
