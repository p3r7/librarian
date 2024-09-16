return {
  -- main meta-data
  kind = "arturia_keystep_32",
  display_name = "Arturia Keystep",
  short_name = "kstp",

  -- notes / nb
  plays_notes = true,
  supports_all_notes_off = true,

  -- params
  params = {
    -- mod touch strip
    -- values sent to this CC value are forwarded to the `mod` CV output
    {
      name = "mod",
      cc = 1,
    },
    -- sustain pedal input
    {
      name = "sustain",
      cc = 64,
    },
  }
}
