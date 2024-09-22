# librarian - dev guide

`librarian` supports 2 ways to make a profile for some device:
- a *simple* format, easy to use but limited
- a *class-based* format, more verbose but which allows redefining almost everything

MIDI is a relatively open standard and as a result, many manufacturers implemented very specific and weird behaviours. that's why the *class-based* format allows to write code that reflect to specificities.

but in a lot of scenarios, the *simple* format is good enough.

you should us the *class-based* format when havin to deal with:
- `sysex`
- a device exposing multiple voices other different channels (bastl microGranny, nord drum, waldorf Q...)
- multi-algorythm (different params depending on current PGM algorythm)


## *simple* format

the simple format is just a lua table.

it should have the following fields:

| field                    | type       | mandatory          | default value   | comment                                 |
| `kind`                   | `string`   | :heavy_check_mark: |                 | what gets referenced in conf w/ `model` |
| `display_name`           | `string`   | :x:                | value of `kind` | how it appears in `params`              |
| `short_name`             | `string`   | :x:                | value of `kind` | shorthand (for small screens)           |
| `plays_notes`            | `bool`     | :x:                | `false`         |                                         |
| `supports_notes_off`     | `bool`     | :x:                | `true`          |                                         |
| `supports_all_notes_off` | `bool`     | :x:                | `true`          |                                         |
| `midi_device`            | `string`   | :x:                | `nil`           | default name of midi device (if USB)    |
| `ch`                     | `int`      | :x:                | `1`             | default midi channel                    |
| `pgm_list`               | `[]string` | :x:                |                 |                                         |
| `params`                 | `[]params` | :x:                |                 |                                         |
| `default_fmt`            | `function` | :x:                |                 |                                         |

all in all, your profile could look something like:

```lua
return {
    -- main meta-data
    kind = "akuma_trombone_star",
    display_name = "Akuma Trombone Star",
    short_name = "trbns",

    -- notes / nb
    plays_notes = true,
    supports_all_notes_off = true,

    pgm_list = { "Venus", "Mars", "Jupiter", "Sun", "Vega" },

    params = {
        {
            name = "filter cutoff",
            cc = 10,
        },
    },
}
```

## *class-based* format

just create a new lua class under [`lib/models/`](./lib/models/).

it should implement the following APIs:
- `<CLASS>.PARAMS`: list of additional params that could/should be set in conf
- `<CLASS>.new(id, count, midi_device, ch)`: object constructor
- `<CLASS>:get_nb_params()`: should return the nb of parameters that'd get created by `<CLASS>:register_params()`
- `<CLASS>:register_params()`: registers norns params at script init
- `<CLASS>:register_nb_players()`: registers `nb` players
