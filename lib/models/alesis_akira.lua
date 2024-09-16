-- librarian/model/alesis akira

local AlesisAkira = {}
AlesisAkira.__index = AlesisAkira

local KIND = "alesis_akira"
local SHORTHAND = "akr"
local DISPLAY_NAME = "Alesis Akira"


-- ------------------------------------------------------------------------
-- deps

local controlspec = require "controlspec"
local formatters = require "formatters"
local midiutil = include('librarian/lib/midiutil')
local paramutils = include('librarian/lib/paramutils')

local akira_params = include('librarian/lib/models/impl/alesis_akira/params')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- API - exposed object params

local DEFAULT_CH = 1

local DEFAULT_CC_X = 45
local DEFAULT_CC_Y = 78
local DEFAULT_CC_Z = 93


-- ------------------------------------------------------------------------
-- API - constructors

function AlesisAkira.new(id, count, midi_device, ch)
  local p = setmetatable({}, AlesisAkira)

  p.kind = KIND
  p.shorthand = SHORTHAND
  p.display_name = DISPLAY_NAME

  p.id = id
  p.fqid = p.shorthand.."_"..id
  p.display_name = p.kind
  if count > 1 then
    p.display_name = p.display_name.." #"..id
  end

  p.midi_device = midi_device

  if ch == nil then
    ch = DEFAULT_CH
  end

  p.ch = ch
  p.knob_ccs = {DEFAULT_CC_X, DEFAULT_CC_Y, DEFAULT_CC_Z}

  p.pgm = nil

  return p
end


-- ------------------------------------------------------------------------
-- API - norns-assignable params

function AlesisAkira:get_nb_params()
  -- pgm, X, Y, Z
  return 4
end

function AlesisAkira:register_params()
  params:add_option(self.fqid .. '_pgm', "Program", akira_params.make_pgm_list())
  params:set_action(self.fqid .. '_pgm',
                    function(pgm_id)
                      self:pgm_change(bank, pgm)
  end)

  for _, knob in pairs({'X', 'Y', 'Z'}) do
    local param_props = akira_params.PARAMS_PROPS[knob]
    param_props.fmt = akira_params.make_fmt(self, knob)
    paramutils.add_param(self, param_props, knob)
  end
end


-- ------------------------------------------------------------------------
-- API - midi

function AlesisAkira:pgm_change(pgm)
  midiutil.send_pgm_change(self.midi_device, self.ch, pgm)
  hw.pgm = pgm
end


-- ------------------------------------------------------------------------

return AlesisAkira
