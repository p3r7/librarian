-- librarian/model/eventide h3000


local H3000 = {}
H3000.__index = H3000

local KIND = "H3000"
local SHORTHAND = "H3000"


-- ------------------------------------------------------------------------
-- deps

local controlspec = require "controlspec"
local formatters = require "formatters"
local midiutil = include('librarian/lib/midiutil')
local h3000 = include('librarian/lib/models/impl/eventide_h3000')

include('librarian/lib/core')


-- ------------------------------------------------------------------------
-- API - supported object params

H3000.PARAMS = {
  'device_id',
}

local DEVICE_ID = 0


-- ------------------------------------------------------------------------
-- API - constructors

function H3000.new(id, midi_device, ch)
  local p = setmetatable({}, H3000)

  p.kind = KIND
  p.shorthand = SHORTHAND

  p.id = id
  p.fqid = p.shorthand.."_"..id
  p.display_name = p.kind.." #"..id

  p.midi_device = midi_device

  if ch == nil then ch = 1 end
  p.ch = ch

  p.device_id = DEVICE_ID

  return p
end


-- ------------------------------------------------------------------------
-- API - norns-assignable params

function H3000:get_nb_params()

  local nb_algo_params = 0
  for _, algo_props in pairs(h3000.ALGOS) do
    nb_algo_params = nb_algo_params + #algo_props.params
  end

  return nb_algo_params
end

function H3000:register_params()
  for algo_id, props in pairs(h3000.ALGOS) do
    local algo_name = props.name
    for _, p in ipairs(props.params) do
      local param_id = self.fqid .. '_' .. algo_id .. '_' .. p.id

      if p.values then
        params:add_option(param_id, p.name, tvals(p.values))
        params:set_action(param_id,
                          function(val)
                            local v = tkeys(p.values)[val]
                            midiutil.send_nrpn(self.midi_device, self.ch, p.id, v)
        end)
      elseif p.min and p.max then
        params:add{type = "number", id = param_id, name = p.name,
                   min = p.min, max = p.max,
                   -- formatter = param_formatter(p)
        }
        params:set_action(param_id,
                          function(val)
                            if p.outfn then
                              val = p.outfn(val)
                            end
                            midiutil.send_nrpn(self.midi_device, self.ch, p.id, val)

        end)
      end
    end
  end
end


-- ------------------------------------------------------------------------

return H3000
