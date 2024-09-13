-- librarian/nbutils

local nbutils = {}


-- ------------------------------------------------------------------------
-- deps

local mod = require 'core/mods'
local midiutil = include('librarian/lib/midiutil')


-- ------------------------------------------------------------------------
-- state

if note_players == nil then
  note_players = {}
end


-- ------------------------------------------------------------------------
-- main

function nbutils.register_player(hw, id)
  local player = {
    ext = "_"..id,
    count = 0,
    -- non-standard props
    hw = hw
  }

  local nb_prfx = "nb_" .. hw.fqid
  local player_id = nb_prfx .. player.ext
  local player_name = hw.display_name.." "..id

  function player:add_params()
    -- params:add_group(player_id, player_name, 0)
    -- params:hide(player_id)
  end

  function player:note_on(note, vel)
    -- print("note play - "..self.ext..",  vel="..vel)
    midiutil.send_note_on(self.hw.midi_device, note, vel*127, self.hw.ch)
  end

  function player:note_off(note)
    midiutil.send_note_off(self.hw.midi_device, note, 0, self.hw.ch)
  end

  function player:describe(note)
    return {
      name = player_id,
      supports_bend = false,
      supports_slew = false,
      modulate_description = "unsupported",
    }
  end

  function player:stop_all()
    midiutil.send_all_notes_off(self.hw.midi_device, self.hw.ch,
                                self.hw.supports_all_notes_off)
  end


  function player:active()
    -- params:show(group_id)
    -- _menu.rebuild_params()
  end

  function player:inactive()
    -- params:hide(group_id)
    -- _menu.rebuild_params()
  end

  note_players[player_id] = player
end


-- ------------------------------------------------------------------------

return nbutils
