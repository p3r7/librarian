-- librarian mod.
-- @eigen

local MOD_NAME = 'librarian'


-- -------------------------------------------------------------------------
-- deps

local mod = require 'core/mods'


-- -------------------------------------------------------------------------
-- conf file

local CONF_EXT = ".inventory"

-- TODO: support multiple conf file
local CONF_PATH = _path.data .. MOD_NAME .. '/' .. "default" .. CONF_EXT

local function load_conf_file()
  if util.file_exists(CONF_PATH) then
    return dofile(CONF_PATH)
  end
end

local function init_devices_from_conf(conf)

  local model_libs = {}
  local model_counts = {}

  for _, hw_conf in ipairs(conf.devices) do
    local HW
    local id_for_model = 1

    if model_libs[hw_conf.model] ~= nil then
      HW = model_libs[hw_conf.model]
      model_counts[hw_conf.model] = model_counts[hw_conf.model] + 1
      id_for_model = model_counts[hw_conf.model]
    else
      HW = include('librarian/lib/models/' .. hw_conf.model)
      if HW == nil then
        print(MOD_NAME .. ' - WARN - ' .. "Unknown model ".. hw_conf.model .. ', skipping.')
        goto NEXT_HW_LOAD
      end
      model_libs[hw_conf.model] = HW
      model_counts[hw_conf.model] = 1
    end

    local hw = HW.new(id_for_model)

    for k, v in pairs(hw_conf.params) do
      if k == 'midi_device' or tab.contains(HW.PARAMS, k) then
        hw[k] = v
      else
        print(MOD_NAME .. ' - WARN - ' .. "Cannot set param "..k.."="..v.." for "..hw_conf.model .. '#' .. id_for_model .. ", unsupported param.")
      end
    end

    params:add_group(hw.display_name, hw:get_nb_params())
    hw:register_params()
    ::NEXT_HW_LOAD::
  end
end


-- -------------------------------------------------------------------------
-- plumbing

mod.hook.register("script_pre_init", MOD_NAME.."-script-pre-init",
                  function()
                    local script_init = init
                    init = function ()
                      script_init()

                      local conf = load_conf_file()
                      if conf == nil then
                        print(MOD_NAME .. ' - ERR - ' .. "No conf file exists, aborting.")
                        return
                      end
                      params:add_separator("librarian", "librarian")
                      init_devices_from_conf(conf)
                    end
                  end
)

mod.hook.register("script_post_cleanup", MOD_NAME.."-script-post-cleanup",
                  function()
                  end
)
