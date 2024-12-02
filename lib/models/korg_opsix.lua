-- librarian/models/korg opsix
-- contributed by: dewb

return {
  -- main meta-data
  kind = "korg_opsix",
  display_name = "Korg Opsix",
  short_name = "opsix",

  -- notes / nb
  plays_notes = true,
  supports_all_notes_off = true,
  
  -- program change
  requires_bank_select = true,
  bank_size = 100,

  -- params
  params = {
    {
      name = "mod",
      cc = 1,
    },
    {
      name = "glide_time",
      cc = 5
    },
    {
      name = "volume",
      cc = 7
    },
    {
      name = "pan",
      cc = 10
    },
    {
      name = "expression",
      cc = 11
    },
    {
      name = "damper",
      cc = 64,
    },
    {
      name = "glide_mode",
      cc = 65,
    },
    {
      name = "sostenuto",
      cc = 66,
    },
    {
      name = "soft",
      cc = 67,
    },
    {
      name = "algorithm",
      cc = 70,
    },
    {
      name = "resonance",
      cc = 71,
    },
    {
      name = "attack",
      cc = 73,
    },
    {
      name = "cutoff",
      cc = 74,
    },
    {
      name = "decay_release",
      cc = 79,
    },
    {
      name = "fx1",
      cc = 81,
    },
    {
      name = "fx2",
      cc = 81,
    },
    {
      name = "fx3",
      cc = 81,
    },
    {
      name = "op1_level",
      cc = 102,
    },
    {
      name = "op2_level",
      cc = 103,
    },
    {
      name = "op3_level",
      cc = 104,
    },
    {
      name = "op4_level",
      cc = 105,
    },
    {
      name = "op5_level",
      cc = 106,
    },
    {
      name = "op6_level",
      cc = 107,
    },
    {
      name = "op1_ratio",
      cc = 108,
    },
    {
      name = "op2_ratio",
      cc = 109,
    },
    {
      name = "op3_ratio",
      cc = 110,
    },
    {
      name = "op4_ratio",
      cc = 111,
    },
    {
      name = "op5_ratio",
      cc = 112,
    },
    {
      name = "op6_ratio",
      cc = 113,
    },
    {
      name = "virtual_patch_cc2",
      cc = 2,
    },
    {
      name = "virtual_patch_cc3",
      cc = 3,
    },
    {
      name = "virtual_patch_cc4",
      cc = 4,
    },
    {
      name = "virtual_patch_cc5",
      cc = 5,
    },
    {
      name = "virtual_patch_cc6",
      cc = 6,
    },
    {
      name = "virtual_patch_cc8",
      cc = 8,
    },
    {
      name = "virtual_patch_cc9",
      cc = 9,
    },
    {
      name = "virtual_patch_cc12",
      cc = 12,
    },
    {
      name = "virtual_patch_cc13",
      cc = 13,
    },
    {
      name = "virtual_patch_cc14",
      cc = 14,
    },
    {
      name = "virtual_patch_cc15",
      cc = 15,
    },
    {
      name = "virtual_patch_cc16",
      cc = 16,
    },
    {
      name = "virtual_patch_cc17",
      cc = 17,
    },
    {
      name = "virtual_patch_cc18",
      cc = 18,
    },
    {
      name = "virtual_patch_cc19",
      cc = 19,
    },
    {
      name = "virtual_patch_cc20",
      cc = 20,
    },
    {
      name = "virtual_patch_cc21",
      cc = 21,
    },
    {
      name = "virtual_patch_cc22",
      cc = 22,
    },
    {
      name = "virtual_patch_cc23",
      cc = 23,
    },
    {
      name = "virtual_patch_cc24",
      cc = 24,
    },
    {
      name = "virtual_patch_cc25",
      cc = 25,
    },
    {
      name = "virtual_patch_cc26",
      cc = 26,
    },
    {
      name = "virtual_patch_cc27",
      cc = 27,
    },
    {
      name = "virtual_patch_cc28",
      cc = 28,
    },
    {
      name = "virtual_patch_cc29",
      cc = 29,
    },
    {
      name = "virtual_patch_cc30",
      cc = 30,
    },
    {
      name = "virtual_patch_cc31",
      cc = 31,
    },
    {
      name = "virtual_patch_cc32",
      cc = 32,
    },
    {
      name = "virtual_patch_cc33",
      cc = 33,
    },
    {
      name = "virtual_patch_cc34",
      cc = 34,
    },
    {
      name = "virtual_patch_cc35",
      cc = 35,
    },
    {
      name = "virtual_patch_cc36",
      cc = 36,
    },
    {
      name = "virtual_patch_cc37",
      cc = 37,
    },
    {
      name = "virtual_patch_cc38",
      cc = 38,
    },
    {
      name = "virtual_patch_cc39",
      cc = 39,
    },
    {
      name = "virtual_patch_cc40",
      cc = 40,
    },
    {
      name = "virtual_patch_cc41",
      cc = 41,
    },
    {
      name = "virtual_patch_cc42",
      cc = 42,
    },
    {
      name = "virtual_patch_cc43",
      cc = 43,
    },
    {
      name = "virtual_patch_cc44",
      cc = 44,
    },
    {
      name = "virtual_patch_cc45",
      cc = 45,
    },
    {
      name = "virtual_patch_cc46",
      cc = 46,
    },
    {
      name = "virtual_patch_cc47",
      cc = 47,
    },
    {
      name = "virtual_patch_cc48",
      cc = 48,
    },
    {
      name = "virtual_patch_cc49",
      cc = 49,
    },
    {
      name = "virtual_patch_cc50",
      cc = 50,
    },
    {
      name = "virtual_patch_cc51",
      cc = 51,
    },
    {
      name = "virtual_patch_cc52",
      cc = 52,
    },
    {
      name = "virtual_patch_cc53",
      cc = 53,
    },
    {
      name = "virtual_patch_cc54",
      cc = 54,
    },
    {
      name = "virtual_patch_cc55",
      cc = 55,
    },
    {
      name = "virtual_patch_cc56",
      cc = 56,
    },
    {
      name = "virtual_patch_cc57",
      cc = 57,
    },
    {
      name = "virtual_patch_cc58",
      cc = 58,
    },
    {
      name = "virtual_patch_cc59",
      cc = 59,
    },
    {
      name = "virtual_patch_cc60",
      cc = 60,
    },
    {
      name = "virtual_patch_cc61",
      cc = 61,
    },
    {
      name = "virtual_patch_cc62",
      cc = 62,
    },
    {
      name = "virtual_patch_cc63",
      cc = 63,
    },
    {
      name = "virtual_patch_cc68",
      cc = 68,
    },
    {
      name = "virtual_patch_cc69",
      cc = 69,
    },
    {
      name = "virtual_patch_cc75",
      cc = 75,
    },
    {
      name = "virtual_patch_cc76",
      cc = 76,
    },
    {
      name = "virtual_patch_cc77",
      cc = 77,
    },
    {
      name = "virtual_patch_cc78",
      cc = 78,
    },
    {
      name = "virtual_patch_cc80",
      cc = 80,
    },
    {
      name = "virtual_patch_cc84",
      cc = 84,
    },
    {
      name = "virtual_patch_cc85",
      cc = 85,
    },
    {
      name = "virtual_patch_cc86",
      cc = 86,
    },
    {
      name = "virtual_patch_cc87",
      cc = 87,
    },
    {
      name = "virtual_patch_cc88",
      cc = 88,
    },
    {
      name = "virtual_patch_cc89",
      cc = 89,
    },
    {
      name = "virtual_patch_cc90",
      cc = 90,
    },
    {
      name = "virtual_patch_cc91",
      cc = 91,
    },
    {
      name = "virtual_patch_cc92",
      cc = 92,
    },
    {
      name = "virtual_patch_cc93",
      cc = 93,
    },
    {
      name = "virtual_patch_cc94",
      cc = 94,
    },
    {
      name = "virtual_patch_cc95",
      cc = 95,
    },
    {
      name = "virtual_patch_cc96",
      cc = 96,
    },
    {
      name = "virtual_patch_cc97",
      cc = 97,
    },
    {
      name = "virtual_patch_cc98",
      cc = 98,
    },
    {
      name = "virtual_patch_cc99",
      cc = 99,
    },
    {
      name = "virtual_patch_cc100",
      cc = 100,
    },
    {
      name = "virtual_patch_cc101",
      cc = 101,
    },
    {
      name = "virtual_patch_cc114",
      cc = 114,
    },
    {
      name = "virtual_patch_cc115",
      cc = 115,
    },
    {
      name = "virtual_patch_cc116",
      cc = 116,
    },
    {
      name = "virtual_patch_cc117",
      cc = 117,
    },
    {
      name = "virtual_patch_cc118",
      cc = 118,
    },
    {
      name = "virtual_patch_cc119",
      cc = 119,
    }
  },
  
  -- factory program names
  pgm_list = {
    "Dat Electric Piano",
    "Original FM EP",
    "FM E.Piano Basic",
    "FM Dyno Tine EP",
    "SynBass/EP Split",
    "80's Sprit Split",
    "Waveshape EP",
    "Shooting Star EP",
    "Punchy Wire Piano",
    "Just Hang On",
    "FM Vamp",
    "Bouncey",
    "Soft Pad EP",
    "Ambi Sines",
    "Overcompressed",
    "Extra Knock EP",
    "Roads and Roads",
    "FM EP Body",
    "OP Delay E.Piano",
    "Ana Eleki Piano",
    "A.Piano Seed",
    "Comb Piano",
    "Wurly EP",
    "Dynamik",
    "Gritty Timber",
    "Portrait EP",
    "Digital Plucker",
    "Layerz",
    "Steam Church",
    "Mutated Piano",
    "Playable Bell",
    "Unsteady",
    "Folk Piano",
    "FM Syntar",
    "Comb Dulcimer",
    "OP Comb Sitar",
    "Metalic Pluck",
    "Metaklav",
    "Reso Phase Clav",
    "Clav O' Frog",
    "MW Phasing Clav",
    "Wave Shaper Clav",
    "Pulse Clav",
    "WahTalk",
    "DrawSlider Organ",
    "Tone Wheel Organ",
    "Paisley Organ",
    "Space Organ",
    "Lausanne Organ",
    "Ring Pipe Organ",
    "Glide Sine",
    "OPcordion",
    "Jazzy Guitar",
    "EG 2 EP",
    "Bright Plectrum",
    "Mod Crunch",
    "Strum Down",
    "Wire Guitar",
    "Slow Ambient Guitar",
    "Distant Memories",
    "Syn Marimba",
    "FMarimba",
    "Membrane Pluck",
    "Cold Coast",
    "4 Tap Diffusion",
    "Hold For Glitches",
    "Dynamic Tin Bells",
    "Delay = LFO",
    "LFO Grooves",
    "Glasklavier",
    "Lonely Star",
    "Crystal Syn Bell",
    "Maverick Bells",
    "Mallet Piano",
    "Percussion",
    "Ring Chime",
    "Zen Chime",
    "4 Bar Alterations",
    "Crystal Bells",
    "Shimmer & Folder",
    "1983",
    "MIDI Stack",
    "FM Heaven",
    "Frantasia",
    "Icy Shimmer",
    "FM Airy Bell",
    "Snow Ball",
    "Festival of Wind",
    "Ruin Chatters",
    "FINLAND",
    "Night Sky",
    "Ritual Decay",
    "Plinq Plunq",
    "Bureon Lead",
    "FM Wind Chime",
    "Introduction",
    "Cycles",
    "Cyber Pad Bell",
    "Pluck Drip",
    "Rand Spacing Pulses",
    "Bounce",
    "Angklung Lore",
    "Juicy Square",
    "Organic Glow",
    "FuwaFuwa",
    "Memories Pad",
    "MOD Storm",
    "Spinners",
    "Shifting 9th",
    "MS-20 Poly Cascade",
    "Steppy World",
    "Fairy Tweets",
    "DETROITrill",
    "Blue Cloud",
    "Aliasing Space",
    "Soft FM Brass",
    "Dyno FM Brass",
    "Bright FM Brass",
    "Sweep Stab",
    "Blended Brass",
    "Filtered Saws",
    "Franalog",
    "Phaseypulse",
    "Supersawyer",
    "Folder Comp",
    "VelociStabber",
    "Inspirational Story",
    "5th Stab",
    "Moody Chord Stabs",
    "Plucky Pad",
    "Fuzzy Glass",
    "Prog Pluck",
    "Purple Fringing",
    "Ring It On",
    "Velocity Hang",
    "Steamy Comp",
    "Faded Pad",
    "Shaky Dynamic Pad",
    "Hard Sync Stab",
    "Chordstreaming",
    "Dark Stages",
    "DUBSTAB",
    "DUBSTAB 2020",
    "Slight Touch",
    "Triplet Split",
    "Rasp & Static",
    "Wasps",
    "Dulled Rhythms",
    "Tremoloverb",
    "FM Ring Mod Pad",
    "Flexpad",
    "Immortal Pad",
    "Contemplation",
    "Slow Gear Clav",
    "Mod Those Bells",
    "Distant Wave Voices",
    "FilterFM Pad",
    "Floating Phase Pad",
    "Moist Vibe",
    "Feel The Pump",
    "Quiet",
    "Ninja Pad FX",
    "Harmonic Waiting Room",
    "Surged Saws",
    "Slow Vibe",
    "Glide Saw",
    "Exit Code",
    "Lab Coats",
    "Choral Aliasing",
    "Chill Pad ARP",
    "Floating Whistle",
    "Unbreakable",
    "Star Pad",
    "Ghost Voices",
    "Stellar Choir",
    "Holy Choir",
    "Retro Choir",
    "Formant Pad",
    "Throat FM",
    "Fog pad",
    "Dark Pad",
    "Lush Pad",
    "NotePad LFO",
    "opsix Concrete",
    "Sine Width Mod",
    "Deep Space",
    "Square Bear Pad",
    "New Motion",
    "Pad Mod Fizz",
    "Sun Baked Strings",
    "Retro Synth Strings",
    "Breezy Pad",
    "Smooth Split",
    "Comb Strings",
    "Aluminium Pad",
    "Gently Strings Pad",
    "Galactic Orchestra",
    "Velocity Pad",
    "Simple PWM",
    "Feel The Warmth",
    "1985 Bed",
    "Engagement Pad",
    "Digital Insects",
    "Self Arping Bells",
    "Glass Waves",
    "FM Elec Bass",
    "FM Slap",
    "Punchy SynBass",
    "Evolving Bass",
    "90's House Bass",
    "Funk Bass ",
    "Laid Bass",
    "Fonk Bass",
    "Clang Bass",
    "Sweepy Saw Bass",
    "Aphasin Bass",
    "Fwonky Bass",
    "Barking Bass",
    "Legato OctBS",
    "Analog<=>FM Bass",
    "Subby Bass",
    "Jazz Bass",
    "Worm Bass",
    "BoBgog'n'FMbass",
    "Concrete Bass",
    "Core Bass",
    "Unlucky Bass",
    "FLDR Bass",
    "Big Moon",
    "Ven aqui ya",
    "Jungle Drum Bass",
    "Sub'n Pluck",
    "Spread Love",
    "Harsh Bass",
    "Droid Bass",
    "Didge Bass",
    "Cinematic FB Doom",
    "Thick Screamer",
    "Fold Form Blend",
    "Dirty Trautonium",
    "Mod Saw Lead",
    "Xover Bright Lead",
    "Mega Saw",
    "Mixed Pulse Lead",
    "Mono Sweep Lead",
    "C.C.M.M SynLead",
    "Pure 80's Lead",
    "Rustic Lead",
    "SimpLEAD",
    "Theremax",
    "Sonic Lead",
    "Pray Lead",
    "Brat LEAD",
    "Fossil Lead",
    "Fragile Seq",
    "Koto Lead",
    "Paper Lead",
    "THE LEAD",
    "Big Lead",
    "Screamer",
    "Dubz Lead",
    "Hard Synkronicity",
    "Slippery Lead",
    "Talky Lead",
    "Rock God",
    "Purple Dist EG",
    "Dynamic Wood",
    "Fairy Dust",
    "Arp Swirls",
    "ARP Flurry",
    "Whistle & Guitar",
    "Hybrid Pluck",
    "Deli Arp",
    "Trance Generation",
    "Euphoria",
    "Res Arps",
    "Mono to Poly",
    "NOS",
    "Dusty Wood",
    "Algo Tripping MW",
    "Polyphonic Delays",
    "2Scenes",
    "Binary Tines",
    "Dub Club",
    "Dance Stabs",
    "Could You Repeat That?",
    "Death Ladder",
    "Obscure Arcade Game",
    "Patternizer",
    "WS Pulse Anthem",
    "Mod Pulse +",
    "Rhythmic Fold",
    "Quadratic Chord Pulse",
    "Hammerblade",
    "Tension Taps",
    "Cosmic Pluck",
    "Octave Gesture",
    "Fat Snake",
    "Instant Techno",
    "Frost Beatz",
    "RAVE-ON!!",
    "Hardgroove",
    "Table Tapping",
    "SAKURA",
    "GHOSTribe SEQ",
    "Electric Drum Kit",
    "Fis Drumparts",
    "KICK BETA",
    "El Ritmo",
    "Agua de las cavernas",
    "KONG's Footstep",
    "Industrial Smash",
    "Cockpit Emergency",
    "Delay Modulator",
    "Random Textures",
    "A bit dirty",
    "Feedback Loop",
    "Epic 30s Riser",
    "INFINITY",
    "Hot Revs",
    "[TMP] Detune Sine",
    "[TMP] Detune Saw",
    "[TMP] Unison Saw",
    "[TMP] Reso Noise",
    "[TMP] Chord Hit",
    "[TMP] Velocity FM",
    "[TMP] 2OP FM",
    "[TMP] Harmonics Mod",
    "[TMP] Modulator FM",
    "[TMP] Pulse Width",
    "[TMP] Ring Mod",
    "[TMP] FM Sync",
    "[TMP] Wavefolder Sync",
    "[TMP] Wavefolder",
    "[TMP] Filter FM",
    "[TMP] Waveshape",
    "[TMP] Delay Mod",
    "[TMP] Comb Flanger",
    "[TMP] Comb LFO",
    "[TMP] Phaser Noise",
    "[TMP] EG ADSR",
    "[TMP] Pitch EG Perc",
    "[TMP] Random Pan",
    "[TMP] OP Filter Mono",
    "[TMP] OP Mode Check",
    "[TMP] Quadra LFOs",
    "[TMP] Effect LFO",
    "[TMP] User Filter Ping",
    "[TMP] C4 Key Split",
    "[TMP] SEQ Key Trig"
  }
}