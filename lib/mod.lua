-- librarian mod.
-- @eigen

local MOD_NAME = 'librarian'


-- -------------------------------------------------------------------------
-- deps

local mod = require 'core/mods'


-- -------------------------------------------------------------------------
-- state


-- -------------------------------------------------------------------------
-- plumbing

mod.hook.register("script_pre_init", MOD_NAME.."-script-pre-init",
                  function()
                    local NordDrum2 = include('librarian/lib/models/nord_drum_2')

                    local script_init = init
                    init = function ()
                      script_init()

                      params:add_separator("librarian", "librarian")

                      local nd2 = NordDrum2.new(1)

                      params:add_group(nd2.display_name, nd2:get_nb_params())
                      nd2:register_params()
                    end
                  end
)

mod.hook.register("script_post_cleanup", MOD_NAME.."-script-post-cleanup",
                  function()
                  end
)
