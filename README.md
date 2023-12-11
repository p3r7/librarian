# librarian

![](./rsc/img/librarian_5x.png)

mod that allows binding external hw to norns params.

for now configuration has to be done manually by editing a conf file.


## configuration

hw devices need to be listed under the `.device` field.

each hw device takes the following fields:

| field    | type                    | mandatory          | description                                         | default value                 |
|----------|-------------------------|--------------------|-----------------------------------------------------|-------------------------------|
| `model`  | `string`                | :heavy_check_mark: | model of the device                                 |                               |
| `device` | `string`                | :x:                | name of the midi device us to communicate w/ the hw | `ALL` (sends & listen to all) |
| `ch`     | `int`                   | :heavy_check_mark: | main midi channel                                   |                               |
| `params` | `map[string]<anything>` | :x:                | additional configuration supported by the hw        | `{}`                          |


## example configuration

create file `/home/we/dust/data/librarian/default.inventory`

```lua
return {
  devices = {
    {
      model = "nord_drum_2",
      device = 'ALL',
      ch = 10,
      params = {
        voice_channels = {1, 2, 3, 4, 5, 6},
        global_channel_notes = {60, 62, 64, 65, 67, 69},
      }
    }
  },
  version = "0.1"
}
```


## supported devices

#### Nord Drum 2 (`nord_drum_2`)

![](./rsc/img/device/nord_drum_2_5x.png)

[implem](./lib/models/nord_drum_2.lua), [manual (PDF)](https://www.nordkeyboards.com/sites/default/files/files/downloads/manuals/nord-drum-2/Nord%20Drum%202%20English%20User%20Manual%20v3.0x%20Edition%20F.pdf)

the Nord Drum 2 is a drum synth exposing 6 completely individual voices.

each voice can be triggered through the main midi channel (factory default `10`) w/ dedicated notes (`global_channel_notes`) or through dedicated midi channels (`voice_channels`), in which case any note value can be send to play the voice melodically.

the global channel approach works better w/ percusive sequencer scripts (such as `argen`) & traditional dum kit presets (bank `#1` & `#2`).

the individual voice channel approach works better w/ melodic sequencers (`awake`, `less_concepts`, `washi`...) & presets in bank `#3`.


| param                  | type    | mandatory | default (factory) value    | comment                                                                      |
|------------------------|---------|-----------|----------------------------|------------------------------------------------------------------------------|
| `voice_channels`       | `int[]` | :x:       | `{1, 2, 3, 4, 5, 6}`       | additional midi channels that can be used to play & access individual voices |
| `global_channel_notes` | `int[]` | :x:       | `{60, 62, 64, 65, 67, 69}` | midi notes to trig individual voices using the global midi channel           |


#### Eventide H3000 (`eventide_h3000`)

![](./rsc/img/device/h3000_5x.png)

[implem](./lib/models/eventide_h3000.lua), [manual (PDF)](https://cdn.eventideaudio.com/uploads/2021/09/H3000-Service.pdf)

| param       | type  | mandatory | default (factory) value | comment                                                             |
|-------------|-------|-----------|-------------------------|---------------------------------------------------------------------|
| `device_id` | `int` | :x:       | `0`                     | unique H3000 midi id, set to a different value if you customized it |


## adding new models

just create a new lua class under [`lib/models/`](./lib/models/).

it should implement the following APIs:
- `<CLASS>.PARAMS`: list of additional params that could/should be set in conf
- `<CLASS>.new(id, midi_device, ch)`: object constructor
- `<CLASS>:get_nb_params()`: should return the nb of parameters that'd get created by `<CLASS>:register_params()`
- `<CLASS>:register_params()`: register norns params
