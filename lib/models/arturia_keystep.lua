-- librarian/model/arturia keystep
-- aka "keystep 32"
--
-- manual: https://downloads.arturia.com/products/keystep/manual/KeyStep_Manual_1_0_0_EN.pdf

local ArturiaKeystep = {}
ArturiaKeystep.__index = ArturiaKeystep

local KIND = "ArturiaKeystep"
local SHORTHAND = "keystep"


-- ------------------------------------------------------------------------
-- deps

local controlspec = require "controlspec"
local formatters = require "formatters"
local midiutil = include('librarian/lib/midiutil')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- API - supported object params

ArturiaKeystep.PARAMS = {
  'mod_cc',
  'sustain_cc',
}

local MOD_CC = 1
local SUSTAIN_CC = 64


-- ------------------------------------------------------------------------
-- API - constructors

function ArturiaKeystep.new(id, midi_device, ch)
  local p = setmetatable({}, ArturiaKeystep)

  p.kind = KIND
  p.shorthand = SHORTHAND

  p.id = id
  p.fqid = p.shorthand.."_"..id
  p.display_name = p.kind.." #"..id

  p.midi_device = midi_device

  p.ch = ch

  p.mod_cc = MOD_CC
  p.sustain_cc = SUSTAIN_CC

  return p
end


-- ------------------------------------------------------------------------
-- API- norns-assignable params

function ArturiaKeystep:get_nb_params()
  -- no param
  return 1
end

function ArturiaKeystep:register_params()
  params:add{type = "number", id = self.fqid .. '_mod', name = "Mod Strip",
             min = 1, max = 127}
  params:set_action(self.fqid .. '_mod',
                    function(val)
                      midiutil.send_cc(self.midi_device, self.ch, self.mod_cc, val)
  end)

  -- TODO: add sustain?
end


-- ------------------------------------------------------------------------

return ArturiaKeystep
