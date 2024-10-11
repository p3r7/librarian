
local ms2000_sysex = {}


-- ------------------------------------------------------------------------
-- deps

local binutils = include('librarian/lib/binutils')
local midiutil = include('librarian/lib/midiutil')
include("librarian/lib/core") -- for `tab_sliced`


-- ------------------------------------------------------------------------
-- consts

local SYSEX_KORG = 0x42
local SYSEX_MS2000 = 0x58 -- shared between MS2000, MS2000R & microKORG

-- NB: device id is more or less the midi channel (0x30 + ch - 1)
local MTCH_DEV_ID = 'dev'


-- ------------------------------------------------------------------------
-- device id (channel)

function ms2000_sysex.dev_id(ch)
  return 0x30 + ch - 1
end


-- ------------------------------------------------------------------------
-- PGM_DUMP

-- NB: is whole PGM DUMP message as well as the header in responces
ms2000_sysex.SYSEX_PGM_DUMP = {SYSEX_KORG, MTCH_DEV_ID, SYSEX_MS2000, 0x10}
ms2000_sysex.SYSEX_PGM_DUMP_RESP_HEADER = {SYSEX_KORG, MTCH_DEV_ID, SYSEX_MS2000, 0x40}

function ms2000_sysex.is_pgm_dump_rq(payload, ch)
  local payload = midiutil.sysex_sans_header(payload)
  local ok, _matches = midiutil.sysex_match(payload,
                                            ms2000_sysex.SYSEX_PGM_DUMP)
  if not ok then
    return false
  end

  if ch then
    return matches[MTCH_DEV_ID] == ms2000_sysex.dev_id(ch)
  end

  return true
end

function ms2000_sysex.is_pgm_dump_resp(payload, ch)
  local payload = midiutil.sysex_sans_header(payload)
  local ok, matches = midiutil.sysex_match(tab_sliced(payload, 1, #ms2000_sysex.SYSEX_PGM_DUMP_RESP_HEADER),
                                           ms2000_sysex.SYSEX_PGM_DUMP_RESP_HEADER)
  if not ok then
    return false
  end

  if ch then
    return matches[MTCH_DEV_ID] == ms2000_sysex.dev_id(ch)
  end

  return true
end

function ms2000_sysex.dump_pgm_current(m, ch)
  local payload = midiutil.sysex_with_header(ms2000_sysex.SYSEX_PGM_DUMP)
  payload = midiutil.sysex_valorized(payload, {[MTCH_DEV_ID]=ms2000_sysex.dev_id(ch)})
  midiutil.send_sysex(m, payload)
end

function ms2000_sysex.parse_pgm_dump(payload)
  local pgm = {
    name = "",
    voice_mode = nil,
  }

  local raw_payload = midiutil.sysex_sans_header(payload)

  -- remove pgm dump header
  raw_payload = tab_sliced(raw_payload, #ms2000_sysex.SYSEX_PGM_DUMP_RESP_HEADER + 1)

  -- NB: most of the the payload is encoded in 7 bits so we need to convert it back to 8 bits
  payload = binutils.conv7to8bit(raw_payload)

  -- pgm name
  for i=1,14 do
    if raw_payload[i] ~= 0 then
      pgm.name = pgm.name .. string.char(raw_payload[i])
    end
  end

  pgm.voice_mode                   = binutils.bits_in_byte_0(payload[17], 4, 6)

  -- arpeggio
  pgm.arpeg_trig_l                 = payload[15] + 1
  pgm.arpeg_trig_pattern           = payload[16]
  pgm.arpeg_status                 = binutils.bits_in_byte_0(payload[33], 7, 8)
  pgm.arpeg_latch                  = binutils.bits_in_byte_0(payload[33], 6, 7)
  pgm.arpeg_target                 = binutils.bits_in_byte_0(payload[33], 4, 6)
  pgm.arpeg_k_sync                 = binutils.bits_in_byte_0(payload[33], 0, 1)
  pgm.arpeg_type                   = binutils.bits_in_byte_0(payload[34], 0, 4)
  pgm.arpeg_range                  = binutils.bits_in_byte_0(payload[34], 4, 8)
  pgm.arpeg_gate_t                 = payload[35]
  pgm.arpeg_resolution             = payload[36]
  pgm.arpeg_swing                  = payload[37]

  -- keyboard
  pgm.scale_type                   = binutils.bits_in_byte_0(payload[18], 0, 4)
  pgm.scale_key                    = binutils.bits_in_byte_0(payload[18], 4, 8)
  pgm.kbd_octave                   = payload[38]

  -- fx - modulation
  pgm.fx_mod_lfo_speed             = payload[24]
  pgm.fx_mod_depth                 = payload[25]
  pgm.fx_mod_type                  = payload[26]

  -- fx - delay
  pgm.fx_delay_sync                = binutils.bits_in_byte_0(payload[20], 7, 8)
  pgm.fx_delay_t_base              = binutils.bits_in_byte_0(payload[20], 0, 4)
  pgm.fx_delay_t                   = payload[21]
  pgm.fx_delay_depth               = payload[22]
  pgm.fx_delay_type                = payload[23]

  -- eq
  pgm.eq_hi_hz                     = payload[27]
  pgm.eq_hi_a                      = payload[28]
  pgm.eq_lo_hz                     = payload[29]
  pgm.eq_lo_a                      = payload[30]

  -- timbre #1
  if pgm.voice_mode == 0 or pgm.voice_mode == 2 then
    pgm.timbre1 = ms2000_sysex.parse_timbre_data(tab_sliced(payload, 39, 146))
  end

  -- timbre #2
  if pgm.voice_mode == 2 then
    pgm.timbre2 = ms2000_sysex.parse_timbre_data(tab_sliced(payload, 147, 254))
  end

  return pgm
end

function ms2000_sysex.parse_timbre_data(payload)
  local t = {}
  t.ch = payload[2]

  -- pitch
  t.pitch_tune                     = payload[4] - 64
  t.pitch_bend_range               = payload[5] - 64
  t.pitch_transpose                = payload[6] - 64
  t.pitch_vibrato_interval         = payload[7] - 64
  t.portamento                     = binutils.bits_in_byte_0(payload[16], 0, 4)

  -- osc 1
  t.osc1_wave                      = payload[8]
  t.osc1_ctrl1                     = payload[9]
  t.osc1_ctrl2                     = payload[10]
  t.osc1_dwgs                      = payload[11]

  -- osc 2
  t.osc2_ring                      = binutils.bits_in_byte_0(payload[13], 4, 6)
  t.osc2_wave                      = binutils.bits_in_byte_0(payload[13], 0, 2)
  t.osc2_semitone                  = payload[14] - 64
  t.osc2_tune                      = payload[15] - 64

  -- mixer
  t.mix_osc1                       = payload[17]
  t.mix_osc2                       = payload[18]
  t.mix_noise                      = payload[19]

  -- filter
  t.filter_type                    = payload[20]
  t.filter_cutoff                  = payload[21]
  t.filter_reso                    = payload[22]
  t.filter_eg1_a                   = payload[23] - 64
  t.filter_velo_sense              = payload[24] - 64
  t.filter_kbd_track               = payload[25] - 64

  -- amp
  t.amp_level                      = payload[26]
  t.amp_pan                        = payload[27] - 64
  t.amp_sw                         = binutils.bits_in_byte_0(payload[28], 6, 7)
  t.amp_dist                       = binutils.bits_in_byte_0(payload[28], 0, 1)
  t.amp_velo_sense                 = payload[29] - 64
  t.amp_kbd_track                  = payload[30] - 64

  -- eg1 (filter)
  t.eg1_a                          = payload[31]
  t.eg1_d                          = payload[32]
  t.eg1_s                          = payload[33]
  t.eg1_r                          = payload[34]

  -- eg2 (amp)
  t.eg2_a                          = payload[35]
  t.eg2_d                          = payload[36]
  t.eg2_s                          = payload[37]
  t.eg2_r                          = payload[38]

  -- lfo1
  t.lfo1_wave                      = binutils.bits_in_byte_0(payload[39], 0, 2)
  t.lfo1_freq                      = payload[40]
  t.lfo1_k_sync                    = binutils.bits_in_byte_0(payload[39], 4, 6)
  t.lfo1_tempo_sync                = binutils.bits_in_byte_0(payload[41], 7, 8)
  t.lfo1_sync_note                 = binutils.bits_in_byte_0(payload[41], 0, 5)

  -- lfo2
  t.lfo2_wave                      = binutils.bits_in_byte_0(payload[42], 0, 2)
  t.lfo2_freq                      = payload[43]
  t.lfo2_k_sync                    = binutils.bits_in_byte_0(payload[42], 4, 6)
  t.lfo2_tempo_sync                = binutils.bits_in_byte_0(payload[44], 7, 8)
  t.lfo2_sync_note                 = binutils.bits_in_byte_0(payload[44], 0, 5)

  -- patch 1
  t.p1_src                         = binutils.bits_in_byte_0(payload[45], 0, 4)
  t.p1_dst                         = binutils.bits_in_byte_0(payload[45], 4, 8)
  t.p1_a                           = payload[46] - 64

  -- patch 2
  t.p2_src                         = binutils.bits_in_byte_0(payload[47], 0, 4)
  t.p2_dst                         = binutils.bits_in_byte_0(payload[47], 4, 8)
  t.p2_a                           = payload[48] - 64

  -- patch 3
  t.p3_src                         = binutils.bits_in_byte_0(payload[49], 0, 4)
  t.p3_dst                         = binutils.bits_in_byte_0(payload[49], 4, 8)
  t.p3_a                           = payload[50] - 64

  -- patch 4
  t.p4_src                         = binutils.bits_in_byte_0(payload[51], 0, 4)
  t.p4_dst                         = binutils.bits_in_byte_0(payload[51], 4, 8)
  t.p4_a                           = payload[52] - 64

  return t
end


-- ------------------------------------------------------------------------
-- .prg

ms2000_sysex.PRG_HEADER = {0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x01, 0x01, 0xe0, 0x4d, 0x54,
                           0x72, 0x6b, 0x00, 0x00, 0x01, 0x30, 0x00, 0xf0, 0x82}

function ms2000_sysex.pgm_dump_to_prg(pgm_dump)
  -- REVIEW: not sure about `tab_sliced`
  return tconcat(ms2000_sysex.PRG_HEADER, tab_sliced(pgm_dump, 2))
end

function ms2000_sysex.prg_to_pgm_dump(prg)
  return tab_sliced(prg, #ms2000_sysex.PRG_HEADER+1)
end


-- A1.13
-- /home/we/dust/data/librarian/ms2000/original/UnisonSawLD.prg
-- F0 42 30 58 40 00 55 6E 69 73 6F 6E 53 00 61 77 4C 44
-- 20 01 02 20 07 42 40 00 3C 05 3C 00 4D 02 11 1F 00 0F
-- 49 08 03 44 00 0A 40 00 64 18 01 00 00 7F 30 1E 40 00
-- 42 40 40 00 00 0A 00 00 00 20 34 40 00 7F 7F 00 00 00
-- 59 0E 63 40 54 00 6A 40 00 40 29 00 1F 00 0F 00 00 40
-- 7F 00 02 00 17 03 02 1D 0C 47 07 00 03 40 42 40 43 40
-- 00 00 00 00 00 40 40 40 40 00 40 40 40 40 40 40 40 00
-- 40 40 40 40 40 00 00 00 40 40 40 40 40 40 40 00 40 40
-- 40 40 40 40 40 00 40 40 00 00 40 40 40 00 40 40 40 40
-- 40 40 40 40 40 40 40 40 40 40 7F 00 70 0A 40 42 40 45
-- 00 00 00 00 00 00 00 40 40 00 00 7F 00 00 01 7F 14 00
-- 40 40 40 7F 40 00 40 00 40 00 40 7F 00 00 40 00 7F 00
-- 02 0A 03 02 46 00 0C 02 40 03 40 42 40 00 43 40 00 00
-- 00 00 40 00 40 40 40 40 40 40 40 00 40 40 40 40 40 40
-- 40 00 40 00 00 40 40 40 40 00 40 40 40 40 40 40 40 00
-- 40 40 40 40 40 00 00 00 40 40 40 40 40 40 40 00 40 40
-- 40 40 40 40 40 00 40 40 F7

-- from m4l device
-- - raw
-- F0 42 30 58 40 00 55 6E 69 73 6F 6E 53 00 61 77 4C 44
-- 20 01 02 20 07 42 40 00 3C 05 3C 00 4D 02 11 1F 00 0F
-- 49 08 03 44 00 0A 40 00 64 18 01 00 00 7F 30 1E 40 00
-- 42 40 40 00 00 0A 00 00 00 20 34 40 00 7F 7F 00 00 00
-- 59 0E 63 40 54 00 6A 40 00 40 29 00 1F 00 0F 00 00 40
-- 7F 00 02 00 17 03 02 1D 0C 47 07 00 03 40 42 40 43 40
-- 00 00 00 00 00 40 40 40 40 00 40 40 40 40 40 40 40 00
-- 40 40 40 40 40 00 00 00 40 40 40 40 40 40 40 00 40 40
-- 40 40 40 40 40 00 40 40 00 00 40 40 40 00 40 40 40 40
-- 40 40 40 40 40 40 40 40 40 40 7F 00 70 0A 40 42 40 45
-- 00 00 00 00 00 00 00 40 40 00 00 7F 00 00 01 7F 14 00
-- 40 40 40 7F 40 00 40 00 40 00 40 7F 00 00 40 00 7F 00
-- 02 0A 03 02 46 00 0C 02 40 03 40 42 40 00 43 40 00 00
-- 00 00 40 00 40 40 40 40 40 40 40 00 40 40 40 40 40 40
-- 40 00 40 00 00 40 40 40 40 00 40 40 40 40 40 40 40 00
-- 40 40 40 40 40 00 00 00 40 40 40 40 40 40 40 00 40 40
-- 40 40 40 40 40 00 40 40 F7
-- - sans sysex encapsulation
-- 00 55 6E 69 73 6F 6E 53 00 61 77 4C 44 20 01 02 20 07
-- 42 40 00 3C 05 3C 00 4D 02 11 1F 00 0F 49 08 03 44 00
-- 0A 40 00 64 18 01 00 00 7F 30 1E 40 00 42 40 40 00 00
-- 0A 00 00 00 20 34 40 00 7F 7F 00 00 00 59 0E 63 40 54
-- 00 6A 40 00 40 29 00 1F 00 0F 00 00 40 7F 00 02 00 17
-- 03 02 1D 0C 47 07 00 03 40 42 40 43 40 00 00 00 00 00
-- 40 40 40 40 00 40 40 40 40 40 40 40 00 40 40 40 40 40
-- 00 00 00 40 40 40 40 40 40 40 00 40 40 40 40 40 40 40
-- 00 40 40 00 00 40 40 40 00 40 40 40 40 40 40 40 40 40
-- 40 40 40 40 40 7F 00 70 0A 40 42 40 45 00 00 00 00 00
-- 00 00 40 40 00 00 7F 00 00 01 7F 14 00 40 40 40 7F 40
-- 00 40 00 40 00 40 7F 00 00 40 00 7F 00 02 0A 03 02 46
-- 00 0C 02 40 03 40 42 40 00 43 40 00 00 00 00 40 00 40
-- 40 40 40 40 40 40 00 40 40 40 40 40 40 40 00 40 00 00
-- 40 40 40 40 00 40 40 40 40 40 40 40 00 40 40 40 40 40
-- 00 00 00 40 40 40 40 40 40 40 00 40 40 40 40 40 40 40
-- 00 40 40
-- - 7->8 bytes
-- 55 6E 69 73 6F 6E 53 61 77 4C 44 20 01 02 07 42 40 00
-- 3C 85 3C 4D 02 11 1F 00 0F 49 03 44 00 8A 40 00 64 01
-- 00 00 FF B0 1E 40 42 40 40 00 00 0A 00 00 20 34 40 00
-- 7F 7F 00 00 59 0E 63 40 54 6A 40 00 40 29 00 1F 0F 00
-- 00 40 7F 00 02 17 03 02 1D 0C 47 07 03 40 42 40 43 40
-- 00 00 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 40 40 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 40 40 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 40 40 FF 70 0A 40 42 40 45 00 00 00 00 00 00 40 40 00
-- 7F 00 00 01 7F 14 40 40 40 7F 40 00 40 40 00 40 7F 00
-- 00 40 7F 00 02 0A 03 02 46 0C 02 40 03 40 42 40 43 40
-- 00 00 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 40 40 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 40 40 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 40 40
-- - voice mode: 64 -> 0
-- - timbre 1 data
-- FF B0 1E 40 42 40 40 00 00 0A 00 00 20 34 40 00 7F 7F
-- 00 00 59 0E 63 40 54 6A 40 00 40 29 00 1F 0F 00 00 40
-- 7F 00 02 17 03 02 1D 0C 47 07 03 40 42 40 43 40 00 00
-- 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- - trimbre 2 data
-- FF 70 0A 40 42 40 45 00 00 00 00 00 00 40 40 00 7F 00
-- 00 01 7F 14 40 40 40 7F 40 00 40 40 00 40 7F 00 00 40
-- 7F 00 02 0A 03 02 46 0C 02 40 03 40 42 40 43 40 00 00
-- 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40
-- 00 00 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40


-- ------------------------------------------------------------------------

return ms2000_sysex
