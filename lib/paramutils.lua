
local paramutils = {}


-- ------------------------------------------------------------------------
--deps

local midiutil = include('librarian/lib/midiutil')


-- ------------------------------------------------------------------------

-- NB: generic param set action, assuming that the device instance `o` only has 1 voice
-- for devices w/ more than a voice, you'd need to redefine/wrap this
-- see `lib/models/nord_drum_2.lua` for an example
function paramutils.set(o, p, pp, val)

  local ch = o.ch
  if pp.ch then
    ch = pp.ch
  end

  if pp.outfn then
    val = pp.outfn(val)
  end

  if pp.cc then
    midiutil.send_cc(o.midi_device, o.ch, pp.cc, val)
    return
  end

  if pp.cc14 then
    local msb_cc = pp.cc14[1]
    local lsb_cc = pp.cc14[2]
    midiutil.send_cc14(o.midi_device, o.ch, msb_cc, lsb_cc, val)
    return
  end

  if pp.nrpn then
    midiutil.send_nrpn(o.midi_device, o.ch, pp.nrpn, val)
    return
  end
end

function paramutils.add_param(o, paramprops, p, action)
  local p_id = o.fqid..'_'..p

  local pp = paramprops[p]
  if not pp then
    print("librarian - warn - failed to add param, unknown: "..p)
    return
  end

  if not action then
    action = function(p, val)
      paramutils.set(o, p, pp, val)
    end
  end

  local p_name = paramutils.display_name(paramprops, p)

  local fmt = pp.fmt
  if pp.fmt == nil and o.default_fmt then
    fmt = o.default_fmt
  end

  -- REVIEW: maybe use controlspecs for everything?

  if pp.opts then
    params:add_option(p_id, p_name, pp.opts, pp.default)
    params:set_action(p_id, function(val)
                        action(p, val)
    end)
    return
  end

  if pp.cs then
    params:add_control(p_id, p_name, pp.cs, fmt)
    -- NB: only way to set default on a control, unless redefining controlspec
    if pp.default then
      params:set(p_id, pp.default)
    end
    params:set_action(p_id, function(val)
                        action(p, val)
    end)
    return
  end

  if pp.cc or pp.cc14 or pp.nrpn then
    local min = 0
    local max = 127
    if pp.cc14 or pp.nrpn then
      max = 16383 -- 1111111 1111111
    end
    if pp.min then
      min = pp.min
    end
    if pp.max then
      max = pp.max
    end

    params:add{ type = "number", id = p_id, name = p_name,
                min = min, max = max, default = pp.default,
                formatter = fmt }
    params:set_action(p_id, function(val)
                        action(p, val)
    end)

    return
  end

end

function paramutils.add_params(o, paramprops, p_list,
                               action)
  for _, p in pairs(p_list) do
    paramutils.add_param(o, paramprops, p,
                         action)
  end
end


-- ------------------------------------------------------------------------

function paramutils.display_name(paramprops, p)
  local pp = paramprops[p]
  if not pp then
    print("librarian - warn - uknown param "..p)
    return
  end

  if pp.disp then
    return pp.disp
  end

  return p
end


-- ------------------------------------------------------------------------

return paramutils
