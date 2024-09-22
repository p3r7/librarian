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
    count = 0,
    -- non-standard props
    hw = hw
  }

  local nb_prfx = "nb_" .. hw.fqid
  local player_id = nb_prfx
  local player_name = hw.display_name
  if id then
    player_id = player_id .. '_'..id
    player_name = player_name .. ' '..id
  end

  function player:add_params()
    -- params:add_group(player_id, player_name, 0)
    -- params:hide(player_id)
  end

  function player:note_on(note, vel)
    -- print("note play - "..player_name..",  vel="..vel)
    midiutil.send_note_on(self.hw.midi_device, note, vel*127, self.hw.ch)
  end

  function player:note_off(note)
    if self.hw.supports_notes_off == false then
      return
    end
    midiutil.send_note_off(self.hw.midi_device, note, 0, self.hw.ch)
  end

  function player:describe(note)
    return {
      name = player_name,
      supports_bend = false,
      supports_slew = false,
      modulate_description = "unsupported",
    }
  end

  function player:stop_all()
    -- REVIEW: devices that don't support `note_off` generally don't support any way to set all notes to off
    -- but there might be a weird one out there...
    if self.hw.supports_notes_off == false then
      return
    end
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

  note_players[player_name] = player
end


-- ------------------------------------------------------------------------

return nbutils
