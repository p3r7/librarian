-- librarian/model/meng qi wingie2


local Wingie2 = {}
Wingie2.__index = Wingie2


-- -------------------------------------------------------------------------
-- global params

Wingie2.TUNINGS = { '12 Equal Temperament', 'Centaur', 'Harp of New Albion',
                    'Carlos Harmonic', 'Well Tuned Piano', 'Meta Slendro',
                    'Bihexany', 'Hexachordal Dodecaphonic', 'Augmented[12]'}

local LEFT_CH       = 1
local RIGHT_CH      = 2
local LEFT_RIGHT_CH = 3

local CAVE_COUNT = 8

Wingie2.GLOBAL_PARAMS = {
  -- NB: don't expose those 3 as it'd be cumbersome to dynamically re-inject updated channels in voice params
  -- 'left_ch',
  -- 'right_ch',
  -- 'both_ch',
  'global_tuning_offset',
}

Wingie2.VOICE_PARAM_PROPS = {
  left_ch = {
    ch = 16,
    cc = 20,
    default = LEFT_CH,
    max = 16,
  },
  right_ch = {
    ch = 16,
    cc = 21,
    default = RIGHT_CH,
    max = 16,
  },
  both_ch = {
    ch = 16,
    cc = 21,
    default = LEFT_RIGHT_CH,
    max = 16,
  },
  global_tuning_offset = {
    ch = 16,
    cc14 = {23, 55},
    default = 0,
    max = 16,
  },

  tuning = {
    disp = "Tuning",
    ch = 13,
    cc = 23,
    opts = Wingie2.TUNINGS,
  },
}


-- -------------------------------------------------------------------------
-- voice params

Wingie2.MODES = {'Polyphony', 'String', 'Bar', 'Cave'}
Wingie2.MODES_CC_VALS = {
  'Polyphony' = 0,
  'String'    = 31,
  'Bar'       = 64,
  'Cave'      = 96,
}

Wingie2.VOICE_PARAMS = {
  'mode',
  'mix',
  'decay',
  'volume',
}

Wingie2.VOICE_PARAM_PROPS = {
  mode = {
    disp = "Mode",
    cc = 0,
    opts = Wingie2.MODES,
    outfn = function(v)
      return Wingie2.MODES_CC_VALS[Wingie2.MODES[v]]
    end,
  },
  mix = {
    disp = "Mix",
    cc14 = { 11, 43 },
  },
  decay = {
    disp = "Decay Time",
    cc14 = { 1, 33 },
  },
  volume = {
    disp = "Volume",
    cc14 = { 7, 39 },
  },
}


-- ------------------------------------------------------------------------
-- API - exposed object params

Wingie2.PARAMS = {
  "left_channel",
  "right_channel",
  "left_right_channel",
}


-- ------------------------------------------------------------------------
-- API - constructors

function Wingie2.new(id, count, midi_device, ch, nb)
  local p = setmetatable({}, NordDrum2)

  p.kind = KIND
  p.shorthand = SHORTHAND
  p.display_name = DISPLAY_NAME

  p.id = id
  p.fqid = p.shorthand.."_"..id
  if count > 1 then
    p.display_name = p.display_name.." #"..id
  end

  p.midi_device = midi_device

  if ch == nil then
    ch = LEFT_RIGHT_CH
  end

  p.left_ch = LEFT_CH
  p.right_ch = RIGHT_CH

  p.nb = true
  if nb ~= nil and not nb then
    p.nb = false
  end

  p.supports_notes_off = false

  return p
end


-- ------------------------------------------------------------------------
-- API - norns-assignable params

function Wingie2:get_nb_params()
  -- NB: in reality we have 2 `nd2.GLOBAL_PARAMS` for selecting the BANK & the PGM
  -- ...but we expose them as a single param for convenience
  local nb_global_params = #Wingie2.GLOBAL_PARAMS

  local nb_voices = 2 -- left & right

  -- NB: `+ 1` is for the separators
  local nb_voice_params = (nb_voices * (#Wingie2.VOICE_PARAM_PROPS + CAVE_COUNT + 1))

  return nb_global_params + nb_voice_params
end

function Wingie2:register_params()
  paramutils.add_params(o, Wingie2.GLOBAL_PARAM_PROPS, Wingie2.GLOBAL_PARAMS)

  local voices = {
    {
      id = "lr",
      desc = "Left + Right",
      ch = self.ch,
    }
    {
      id = "l",
      desc = "Left",
      ch = self.left_ch,
    },
    {
      id = "r",
      desc = "Right",
      ch = self.right_ch,
    },
  }
  for _, v in pairs(voices) do
    local hw = hwutils.cloned(self)
    hw.fqid = self.fqid..'_'..v.id
    hw.ch = v.ch
    paramutils.add_params(hw, Wingie2.VOICE_PARAM_PROPS, Wingie2.VOICE_PARAMS)
    if v.id == 'l' or v.id == 'r' then
      local ch = (v.id == 'l') and 14 or 15
      for i=1,CAVE_COUNT do
        local p_id = 'cave_'..i
        local p_props = {}
        p_props[p_id] = {
          disp = v.desc.." Cave "..i,
          ch = ch,
          cc14 = { 23 + (i-1), 55 + (i-1)},
        }
        paramutils.add_param(hw, p_props, 'cave_'..i)
      end
    end
  end

end

-- ------------------------------------------------------------------------

return Wingie2
