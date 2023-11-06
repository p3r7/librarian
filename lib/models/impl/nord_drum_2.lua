
local nd2 = {}


-- ------------------------------------------------------------------------
-- deps

local midiutil = include('librarian/lib/midiutil')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- consts

local SYSEX_CLAVIA = 0x33

local MTCH_UUID      = 'uuid'
local MTCH_BANK      = 'bank'
local MTCH_PGM       = 'pgm'
local MTCH_CHECKSUM  = 'checksum'


-- ------------------------------------------------------------------------
-- sysex - ping

nd2.SYSEX_PING_RQ = {SYSEX_CLAVIA, 0x7f, 0x7f, 0x07, 0x00, 0x06, 0x00, 0x7f}
nd2.SYSEX_PING_RESP = {SYSEX_CLAVIA, 0x7f, 0x19, 0x07, 0x00, 0x07, 0x00,
                       0x00, 0x4b, 0x00, 0x00, 0x37, 0x40, 0x18} -- NB: not sure this is universal!

function nd2.ping(midi_dev)
  local payload = midiutil.sysex_with_header(nd2.SYSEX_PING_RQ)
  midiutil.print_byte_array_midiox(payload)
  midi.send(midi_dev, payload)
end

function nd2.is_pong(payload)
  return midiutil.are_equal_byte_arrays(midiutil.sysex_sans_header(payload),
                                        nd2.SYSEX_PING_RESP)
end


-- ------------------------------------------------------------------------
-- sysex - get uuid

nd2.DEFAULT_UUID = 0x08

nd2.SYSEX_UUID_RQ = {SYSEX_CLAVIA, 0x7f, 0x7f, 0x07, 0x00, 0x02, 0x3a}
nd2.SYSEX_UUID_RESP = {SYSEX_CLAVIA, 0x7f, 0x19, 0x07, 0x00, 0x03, 0x02,
                       0x07, 0x00, MTCH_UUID, 0x03, 0x48}

function nd2.ask_uuid(midi_dev)
  local payload = midiutil.sysex_with_header(nd2.SYSEX_UUID_RQ)
  midi.send(midi_dev, payload)
end

function nd2.extract_uuid(payload)
  local ok, matches = midiutil.sysex_match(midiutil.sysex_sans_header(payload),
                                           nd2.SYSEX_UUID_RESP)
  if ok then
    return true, matches[MTCH_UUID]
  end

  return false, nil
end

function nd2.is_uuid_resp(payload)
  local ok, _ = nd2.extract_uuid(payload)
  return ok
end


-- ------------------------------------------------------------------------
-- sysex - in-mem pgm dump

nd2.SYSEX_MEM_PGM_DUMP_RESP_HEADER = {
  SYSEX_CLAVIA, 0x7f, 0x19, 0x08, 0x03, 0x06, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
}

-- nd2.SYSEX_PGM_MEM_RQ = {SYSEX_CLAVIA, 0x7f, 0x7f, MTCH_UUID, 0x03, 0x07,
--                         0x00, 0x00, MTCH_CHECKSUM}

-- function nd2.mem_pgm_dump(midi_dev, uuid, bank, pgm)
--   local payload = midiutil.sysex_with_header(nd2.SYSEX_PGM_MEM_RQ)
--   local vars = {
--     [MTCH_UUID] = uuid,
--     [MTCH_BANK] = 0x40 + bank - 1,
--     [MTCH_PGM] = pgm - 1,
--     [MTCH_CHECKSUM] = PGM_DUMP_CHECKSUM[bank][pgm],
--   }
--   payload = midiutil.sysex_valorized(payload, vars)
--   midi.send(midi_dev, payload)
-- end

function nd2.is_mem_pgm_dump(payload)
  local payload = midiutil.sysex_sans_header(payload)
  -- return midiutil.are_equal_byte_arrays(payload,
  --                                       nd2.SYSEX_MEM_PGM_DUMP_RESP_HEADER)

  local ok, _matches = midiutil.sysex_match(tab_sliced(payload, 1, #nd2.SYSEX_MEM_PGM_DUMP_RESP_HEADER),
                                            nd2.SYSEX_MEM_PGM_DUMP_RESP_HEADER)
  if ok then
    return true
  end

  return false
end


-- ------------------------------------------------------------------------
-- sysex - pgm dump

nd2.SYSEX_PGM_DUMP_RESP_HEADER = {
  SYSEX_CLAVIA, 0x7f, 0x19, 0x08, 0x03, 0x08, MTCH_BANK, MTCH_PGM, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
}

local PGM_DUMP_CHECKSUM = {
  [1] = {
    0x0e, 0x06, 0x1e, 0x16, 0x2e, 0x26, 0x3e, 0x36, 0x4e, 0x46, 0x5e, 0x56, 0x6e, 0x66, 0x7e, 0x76, 0x07, 0x0f,
    0x17, 0x1f, 0x27, 0x2f, 0x37, 0x3f, 0x47, 0x4f, 0x57, 0x5f, 0x67, 0x6f, 0x77, 0x7f, 0x1c, 0x14, 0x0c, 0x04,
    0x3c, 0x34, 0x2c, 0x24, 0x5c, 0x54, 0x4c, 0x44, 0x7c, 0x74, 0x6c, 0x64, 0x15, 0x1d,
  },
  [2] = {
    0x17, 0x1f, 0x07, 0x0f, 0x37, 0x3f, 0x27, 0x2f, 0x57, 0x5f, 0x47, 0x4f, 0x77, 0x7f, 0x67, 0x6f, 0x1e, 0x16,
    0x0e, 0x06, 0x3e, 0x36, 0x2e, 0x26, 0x5e, 0x56, 0x4e, 0x46, 0x7e, 0x76, 0x6e, 0x66, 0x05, 0x0d, 0x15, 0x1d,
    0x25, 0x2d, 0x35, 0x3d, 0x45, 0x4d, 0x55, 0x5d, 0x65, 0x6d, 0x75, 0x7d, 0x0c, 0x04
  },
  [3] = {
    0x3d, 0x35, 0x2d, 0x25, 0x1d, 0x15, 0x0d, 0x05, 0x7d, 0x75, 0x6d, 0x65, 0x5d, 0x55, 0x4d, 0x45, 0x34, 0x3c,
    0x24, 0x2c, 0x14, 0x1c, 0x04, 0x0c, 0x74, 0x7c, 0x64, 0x6c, 0x54, 0x5c, 0x44, 0x4c, 0x2f, 0x27, 0x3f, 0x37,
    0x0f, 0x07, 0x1f, 0x17, 0x6f, 0x67, 0x7f, 0x77, 0x4f, 0x47, 0x5f, 0x57, 0x26, 0x2e
  },
  [4] = {
    0x24, 0x2c, 0x34, 0x3c, 0x04, 0x0c, 0x14, 0x1c, 0x64, 0x6c, 0x74, 0x7c, 0x44, 0x4c, 0x54, 0x5c, 0x2d, 0x25,
    0x3d, 0x35, 0x0d, 0x05, 0x1d, 0x15, 0x6d, 0x65, 0x7d, 0x75, 0x4d, 0x45, 0x5d, 0x55, 0x36, 0x3e, 0x26, 0x2e,
    0x16, 0x1e, 0x06, 0x0e, 0x76, 0x7e, 0x66, 0x6e, 0x56, 0x5e, 0x46, 0x4e, 0x3f, 0x37
  },
  [5] = {
    0x68, 0x60, 0x78, 0x70, 0x48, 0x40, 0x58, 0x50, 0x28, 0x20, 0x38, 0x30, 0x08, 0x00, 0x18, 0x10, 0x61, 0x69,
    0x71, 0x79, 0x41, 0x49, 0x51, 0x59, 0x21, 0x29, 0x31, 0x39, 0x01, 0x09, 0x11, 0x19, 0x7a, 0x72, 0x6a, 0x62,
    0x5a, 0x52, 0x4a, 0x42, 0x3a, 0x32, 0x2a, 0x22, 0x1a, 0x12, 0x0a, 0x02, 0x73, 0x7b
  },
  [6] = {
    0x71, 0x79, 0x61, 0x69, 0x51, 0x59, 0x41, 0x49, 0x31, 0x39, 0x21, 0x29, 0x11, 0x19, 0x01, 0x09, 0x78, 0x70,
    0x68, 0x60, 0x58, 0x50, 0x48, 0x40, 0x38, 0x30, 0x28, 0x20, 0x18, 0x10, 0x08, 0x00, 0x63, 0x6b, 0x73, 0x7b,
    0x43, 0x4b, 0x53, 0x5b, 0x23, 0x2b, 0x33, 0x3b, 0x03, 0x0b, 0x13, 0x1b, 0x6a, 0x62
  },
  [7] = {
    0x5b, 0x53, 0x4b, 0x43, 0x7b, 0x73, 0x6b, 0x63, 0x1b, 0x13, 0x0b, 0x03, 0x3b, 0x33, 0x2b, 0x23, 0x52, 0x5a,
    0x42, 0x4a, 0x72, 0x7a, 0x62, 0x6a, 0x12, 0x1a, 0x02, 0x0a, 0x32, 0x3a, 0x22, 0x2a, 0x49, 0x41, 0x59, 0x51,
    0x69, 0x61, 0x79, 0x71, 0x09, 0x01, 0x19, 0x11, 0x29, 0x21, 0x39, 0x31, 0x40, 0x48
  },
  [8] = {
    0x42, 0x4a, 0x52, 0x5a, 0x62, 0x6a, 0x72, 0x7a, 0x02, 0x0a, 0x12, 0x1a, 0x22, 0x2a, 0x32, 0x3a, 0x4b, 0x43,
    0x5b, 0x53, 0x6b, 0x63, 0x7b, 0x73, 0x0b, 0x03, 0x1b, 0x13, 0x2b, 0x23, 0x3b, 0x33, 0x50, 0x58, 0x40, 0x48,
    0x70, 0x78, 0x60, 0x68, 0x10, 0x18, 0x00, 0x08, 0x30, 0x38, 0x20, 0x28, 0x59, 0x51
  },
}

nd2.SYSEX_PGM_RQ = {SYSEX_CLAVIA, 0x7f, 0x7f, MTCH_UUID, 0x03, 0x07,
                    MTCH_BANK, MTCH_PGM, MTCH_CHECKSUM}

function nd2.pgm_dump(midi_dev, uuid, bank, pgm)
  local payload = midiutil.sysex_with_header(nd2.SYSEX_PGM_RQ)
  local vars = {
    [MTCH_UUID] = uuid,
    [MTCH_BANK] = 0x40 + bank - 1,
    [MTCH_PGM] = pgm - 1,
  }
  payload = midiutil.sysex_valorized(payload, vars)
  midi.send(midi_dev, payload)
end


function nd2.is_pgm_dump(payload)
  local payload = midiutil.sysex_sans_header(payload)
  -- return midiutil.are_equal_byte_arrays(payload,
  --                                       nd2.SYSEX_PGM_DUMP_RESP_HEADER)

  local ok, _matches = midiutil.sysex_match(tab_sliced(payload, 1, #nd2.SYSEX_PGM_DUMP_RESP_HEADER),
                                            nd2.SYSEX_PGM_DUMP_RESP_HEADER)
  if ok then
    return true
  end

  return false
end

function nd2.get_pgm_dump_data(payload)
  local payload = midiutil.sysex_sans_header(payload)
  -- -4 is for the payload at the end
  return tab_sliced(payload, #nd2.SYSEX_PGM_DUMP_RESP_HEADER+1, -4)
end

-- ------------------------------------------------------------------------

return nd2