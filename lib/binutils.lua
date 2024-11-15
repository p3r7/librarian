local binutils = {}


-- ------------------------------------------------------------------------
-- 14bit <-> 7bit

function binutils.ensure_14bits_as_table(v)
  if type(v) == 'table' then
    return v
  end
  return { v >> 7, v & 127 }
end

function binutils.ensure_14bits_as_val(v)
  if type(v) == 'table' then
    return v[1] << 7 + v[2]
  end
  return v
end

-- ------------------------------------------------------------------------

function binutils.conv7to8bit(bytes)
  local out = {}
  local count = 0
  local highBits = 0
  for i, b in ipairs(bytes) do
    local pos = (i - 1) % 8 -- relative position in this group of 8 bytes
    if pos == 0 then -- first byte
      highBits = b
    else
      local highBit = highBits & (1 << (pos - 1))
      highBit = highBit << (8 - pos) -- shift it to the high bit
      count = count + 1
      out[count] = b | highBit
    end
  end

  return out
end

-- extract consecutive bits in `byte`
-- NB: `from` is included and `to` is excluded
function binutils.bits_in_byte(byte, from, to)
  binutils.bits_in_byte_0(byte, from-1, to-1)
end

function binutils.bits_in_byte_0(byte, from, to)
  if not to then
    to = 8
  end

  local num_bits = to - from
  local mask = (1 << num_bits) - 1
  local extractedBits = (byte >> from) & mask
  return extractedBits
end


-- ------------------------------------------------------------------------

return binutils
