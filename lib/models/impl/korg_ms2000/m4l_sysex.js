inlets  = 2;
outlets = 2;


// -------------------------------------------------------------------------
// UTILS: LOG


function log() {
    for(var i=0,len=arguments.length; i<len; i++) {
        var message = arguments[i];
        if(message && message.toString) {
            var s = message.toString();
            if(s.indexOf("[object ") >= 0) {
                s = JSON.stringify(message);
            }
            post(s);
        }
        else if(message === null) {
            post("<null>");
        }
        else {
            post(message);
        }
    }
    post("\n");
}


// -------------------------------------------------------------------------
// UTILS: INTEROP

var d = new Dict("current_pgm");
var d_midi = new Dict("midi_setup");
var prfx = jsarguments[1];


function reg (k, v) {
    d.set(k, v);
	//messnamed(prfx+k, v);
}

function regT (t_id, k, v) {
	d.replace([t_id, k].join('::'), v);

	//if (t_id == 1)
	//	messnamed(prfx+k, v);
}


// -------------------------------------------------------------------------
// UTILS: STRING

if(typeof(String.prototype.trim) === "undefined")
{
    String.prototype.trim = function()
    {
        return String(this).replace(/^\s+|\s+$/g, '');
    };
}

function reverseString(str) {
	return str.split("").reverse().join("");
}

function stringPadEnd(str, l, c) {
	while (str.length <= l) {
		str += c;
	}
	return str;
}

function stringToCharCodes(str) {
	var result = [];
	for (var i = 0; i < str.length; i++) {
		result[i] = str.charCodeAt(i);
	}
	return result;
}


// -------------------------------------------------------------------------
// UTILS: BINARY

function convert7to8bit(inputData) {
    var convertedData = [];
    var count = 0;
    var highBits = 0;
    for (var i = 0; i < inputData.length; i++) {
        var pos = i % 8; // relative position in this group of 8 bytes
        if (!pos) { // first byte
            highBits = inputData[i];
        }
        else {
            var highBit = highBits & (1 << (pos - 1));
            highBit <<= (8 - pos); // shift it to the high bit
            convertedData[count++] = inputData[i] | highBit;
        }
    }
    return convertedData;
}


function byteAsString(byte) {
	return stringPadEnd(reverseString((byte).toString(2)), 8, '0');
}

function bitsInByte(byte, from, to) {
	var asStr = byteAsString(byte);
	var bitsStr = asStr.substring(from, to);
	return parseInt(reverseString(bitsStr), 2);
}


// -------------------------------------------------------------------------
// UTILS: SYSEX

receiveBuffer = [];
completeMsg = null;

function recv(b) {
    if (b === 0xF0) { // new sysex
	    //log("got a new sysex msg")
        receiveBuffer = [b];
		completeMsg = null;
    }
    else if (b === 0xF7) { // end of sysex
        receiveBuffer.push(b);
        // slice off the 7-byte header and the 1-byte footer
        //var data = receiveBuffer.slice(7, receiveBuffer.length - 1);
        //var converted = convert7to8bit(data);
        // do something with the converted buffer here...
        //var convertedBack = convert8to7bit(converted); // test
        //for (var i in data) {
        //    if (data[i] !== convertedBack[i]) {
        //        post("there is a mismatch at byte " + i + "\n");
        //    }
        //}
		completeMsg = receiveBuffer;
        receiveBuffer = [];
    }
    else if (b & 0x80) {
        log("bad sysex byte, aborting receive");
        receiveBuffer = [];
    }
    else if (receiveBuffer.length) { // data byte, append to buffer
        receiveBuffer.push(b);
    }
}


// -------------------------------------------------------------------------
// UTILS: FILE

function writeBytesToFile (fname, bytes) {
	var f = new File(fname, "write", "Midi");
	if (f.isopen) {
		f.writebytes(bytes);
		f.eof = f.position;
		f.close();
		post("wrote to " + fname + "\n");
		return;
	}
	post("error writing to " + fname + "\n");
}

function readBytesFromFile (fname) {
	var f = new File(fname, "read");
	if (f.isopen) {
		var a = f.readbytes(f.eof);
		f.close();
		if (a) {
			post("read binary file " + fname + "\n");
			return a;
		}
	}
	post("error reading binary file " + fname + "\n");
	return null;
}



// -------------------------------------------------------------------------
// MAIN

function is_sysex_mk_pgm_dump_req(bytes) {
	var midi_chan = d_midi.get('channel');

	if (! midi_chan)
		return false;

	return bytes[1] === 66
		&& bytes[2] === (0x30 + midi_chan - 1)
		&& bytes[3] === 88
		&& bytes[4] === 16;
}

function is_sysex_mk_pgm_dump_resp(bytes) {
	var midi_chan = d_midi.get('channel');

	if (! midi_chan)
		return false;

	return bytes[1] === 0x42
		&& bytes[2] === (0x30 + midi_chan - 1)
		&& bytes[3] === 0x58
		&& bytes[4] === 0x40;
}

function parse_mk_timbre_data(t_id, bytes) {
	var prfx = jsarguments[1];

	var midi_ch = bytes[1];

	// - PITCH
	regT(t_id, "pitch_tune", bytes[3] - 64);
	regT(t_id, "pitch_bend_range", bytes[4] - 64);
	regT(t_id, "pitch_transpose", bytes[5] - 64);
	regT(t_id, "pitch_vibrato_interval", bytes[6] - 64);
	regT(t_id, "glide_t", bitsInByte(bytes[15], 0, 4));

	// - OSC 1
	regT(t_id, "osc1_wave", bytes[7]);
	regT(t_id, "osc1_ctrl1", bytes[8]);
	regT(t_id, "osc1_ctrl2", bytes[9]);
	regT(t_id, "osc1_dwgs", bytes[10]);

    // - OSC 2
    regT(t_id, "osc2_ring", bitsInByte(bytes[12], 4, 6));
    regT(t_id, "osc2_wave", bitsInByte(bytes[12], 0, 2));
    regT(t_id, "osc2_semitone", bytes[13] - 64);
    regT(t_id, "osc2_tune", bytes[14] - 64);

    // - MIXER
    regT(t_id, "mix_osc1", bytes[16]);
    regT(t_id, "mix_osc2", bytes[17]);
    regT(t_id, "mix_noize", bytes[18]);

    // - FILTER
    regT(t_id, "filter_type", bytes[19]);
    regT(t_id, "filter_cutoff", bytes[20]);
    regT(t_id, "filter_reso", bytes[21]);
    regT(t_id, "filter_eg1_a", bytes[22] - 64);
    regT(t_id, "filter_velo_sense", bytes[23] - 64);
    regT(t_id, "filter_kbd_track", bytes[24] - 64);

    // - AMP
    regT(t_id, "amp_level", bytes[25]);
    regT(t_id, "amp_pan", bytes[26] - 64);
    regT(t_id, "amp_sw", bitsInByte(bytes[27], 6, 7));
    regT(t_id, "amp_dist", bitsInByte(bytes[27], 0, 1));
    regT(t_id, "amp_velo_sense", bytes[28] - 64);
    regT(t_id, "amp_kbd_track", bytes[29] - 64);

    // - EG1
    regT(t_id, "eg1_a", bytes[30]);
    regT(t_id, "eg1_d", bytes[31]);
    regT(t_id, "eg1_s", bytes[32]);
    regT(t_id, "eg1_r", bytes[33]);

    // - EG2
    regT(t_id, "eg2_a", bytes[34]);
    regT(t_id, "eg2_d", bytes[35]);
    regT(t_id, "eg2_s", bytes[36]);
    regT(t_id, "eg2_r", bytes[37]);

    // - LFO1
    regT(t_id, "lfo1_wave", bitsInByte(bytes[38], 0, 2));
    regT(t_id, "lfo1_hz", bytes[39]);
    regT(t_id, "lfo1_k_sync", bitsInByte(bytes[38], 4, 6));
    regT(t_id, "lfo1_tempo_sync", bitsInByte(bytes[40], 7, 8));
    regT(t_id, "lfo1_sync_note", bitsInByte(bytes[40], 0, 5));

    // - LFO2
    regT(t_id, "lfo2_wave", bitsInByte(bytes[41], 0, 2));
    regT(t_id, "lfo2_hz", bytes[42]);
    regT(t_id, "lfo2_k_sync", bitsInByte(bytes[41], 4, 6));
    regT(t_id, "lfo2_tempo_sync", bitsInByte(bytes[43], 7, 8));
    regT(t_id, "lfo2_sync_note", bitsInByte(bytes[43], 0, 5));

    // - PATCH1
    regT(t_id, "p1_src", bitsInByte(bytes[44], 0, 4));
    regT(t_id, "p1_dst", bitsInByte(bytes[44], 4, 8));
    regT(t_id, "p1_a", bytes[45] - 64);

    // - PATCH2
    regT(t_id, "p2_src", bitsInByte(bytes[46], 0, 4));
    regT(t_id, "p2_dst", bitsInByte(bytes[46], 4, 8));
    regT(t_id, "p2_a", bytes[47] - 64);

    // - PATCH3
    regT(t_id, "p3_src", bitsInByte(bytes[48], 0, 4));
    regT(t_id, "p3_dst", bitsInByte(bytes[48], 4, 8));
    regT(t_id, "p3_a", bytes[49] - 64);

    // - PATCH3
    regT(t_id, "p4_src", bitsInByte(bytes[50], 0, 4));
    regT(t_id, "p4_dst", bitsInByte(bytes[50], 4, 8));
    regT(t_id, "p4_a", bytes[51] - 64);
}


function registerDummy3rdTimbre () {
	// NB: used for 1+2 editing

	var t_id = 3;

	regT(t_id, "pitch_tune", 0);
	regT(t_id, "pitch_bend_range", 2);
	regT(t_id, "pitch_transpose", 0);
	regT(t_id, "pitch_vibrato_interval", 0);
	regT(t_id, "glide_t", 0);

	// - OSC 1
	regT(t_id, "osc1_wave", 0);
	regT(t_id, "osc1_ctrl1", 0);
	regT(t_id, "osc1_ctrl2", 0);
	regT(t_id, "osc1_dwgs", 0);

    // - OSC 2
    regT(t_id, "osc2_ring", 0);
    regT(t_id, "osc2_wave", 0);
    regT(t_id, "osc2_semitone", 0);
    regT(t_id, "osc2_tune", 0);

    // - MIXER
    regT(t_id, "mix_osc1", 127);
    regT(t_id, "mix_osc2", 127);
    regT(t_id, "mix_noize", 0);

    // - FILTER
    regT(t_id, "filter_type", 0);
    regT(t_id, "filter_cutoff", 78);
    regT(t_id, "filter_reso", 0);
    regT(t_id, "filter_eg1_a", 0);
    regT(t_id, "filter_velo_sense", 0);
    regT(t_id, "filter_kbd_track", 0);

    // - AMP
    regT(t_id, "amp_level", 127);
    regT(t_id, "amp_pan", 0);
    regT(t_id, "amp_sw", 0);
    regT(t_id, "amp_dist", 0);
    regT(t_id, "amp_velo_sense", 0);
    regT(t_id, "amp_kbd_track", 0);

    // - EG1
    regT(t_id, "eg1_a", 0);
    regT(t_id, "eg1_d", 31);
    regT(t_id, "eg1_s", 15);
    regT(t_id, "eg1_r", 15);

    // - EG2
    regT(t_id, "eg2_a", 0);
    regT(t_id, "eg2_d", 31);
    regT(t_id, "eg2_s", 15);
    regT(t_id, "eg2_r", 15);

    // - LFO1
    regT(t_id, "lfo1_wave", 0);
    regT(t_id, "lfo1_hz", 0);
    regT(t_id, "lfo1_k_sync", 0);
    regT(t_id, "lfo1_tempo_sync", 0);
    regT(t_id, "lfo1_sync_note", 0);

    // - LFO2
    regT(t_id, "lfo2_wave", 0);
    regT(t_id, "lfo2_hz", 0);
    regT(t_id, "lfo2_k_sync", 0);
    regT(t_id, "lfo2_tempo_sync", 0);
    regT(t_id, "lfo2_sync_note", 0);

    // - PATCH1
    regT(t_id, "p1_src", 0);
    regT(t_id, "p1_dst", 0);
    regT(t_id, "p1_a", 0);

    // - PATCH2
    regT(t_id, "p2_src", 0);
    regT(t_id, "p2_dst", 0);
    regT(t_id, "p2_a", 0);

    // - PATCH3
    regT(t_id, "p3_src", 0);
    regT(t_id, "p3_dst", 0);
    regT(t_id, "p3_a", 0);

    // - PATCH3
    regT(t_id, "p4_src", 0);
    regT(t_id, "p4_dst", 0);
    regT(t_id, "p4_a", 0);
}

function parse_mk_pgm_dump_resp(bytes) {
	var prfx = jsarguments[1];

    var bytes_7 = bytes.slice(5, bytes.length-1); // remove header / term
    bytes = convert7to8bit(bytes_7);

    //log("7bits:", bytes_7)
    //log("size 7bits:", bytes_7.length)

    //log("8bits:", bytes)
    //log("size 8bits:", bytes.length)

    // - PGM NAME
    var pgm_name = "";
	for (var i=0 ; i<13 ; i++) {
		// log(i, bytes_7[i], String.fromCharCode(bytes_7[i]));
		if (bytes_7[i] == 0)
			pgm_name += "";
		else
		    pgm_name += String.fromCharCode(bytes_7[i]);
	}
	pgm_name = pgm_name.trim();
	if (pgm_name == "")
		pgm_name = "<UNTITLED>";
	log("PGM name: " + pgm_name);
    reg("pgm_name", pgm_name);
	messnamed(prfx+"pgm_name", pgm_name);

    var voice_mode = bitsInByte(bytes[16], 4, 6);
    reg("voice_mode", voice_mode);
	messnamed(prfx+"voice_mode", voice_mode);

    // - ARPEGGIO
    reg("arpeg_trig_l", bytes[14] + 1);
    reg("arpeg_trig_pattern", bytes[15]);
    reg("arpeg_status", bitsInByte(bytes[32], 7, 8));
    reg("arpeg_latch", bitsInByte(bytes[32], 6, 7));
    reg("arpeg_target", bitsInByte(bytes[32], 4, 6));
    reg("arpeg_k_sync", bitsInByte(bytes[32], 0, 1));
    reg("arpeg_type", bitsInByte(bytes[33], 0, 4));
    reg("arpeg_range", bitsInByte(bytes[33], 4, 8));
    reg("arpeg_gate_t", bytes[34]);
    reg("arpeg_resolution", bytes[35]);
    reg("arpeg_swing", bytes[36]);

    // - KBD
    reg("scale_type", bitsInByte(bytes[17], 0, 4));
    reg("scale_key", bitsInByte(bytes[17], 4, 8));
    reg("kbd_octave", bytes[37]);

    // - FX - MODULATION
    reg("fx_mod_lfo_speed", bytes[23]);
    reg("fx_mod_depth", bytes[24]);
    reg("fx_mod_type", bytes[25]);

	// - FX - DELAY
	reg("fx_delay_sync", bitsInByte(bytes[19], 7, 8));
	reg("fx_delay_t_base", bitsInByte(bytes[19], 0, 4));
	reg("fx_delay_t", bytes[20]);
	reg("fx_delay_depth", bytes[21]);
	reg("fx_delay_type", bytes[22]);

	// EQ
	reg("eq_hi_hz", bytes[26]);
	reg("eq_hi_a", bytes[27]);
	reg("eq_lo_hz", bytes[28]);
	reg("eq_lo_a", bytes[29]);

	// - TIMBRE 1
	if (voice_mode == 0 || voice_mode == 2)
		parse_mk_timbre_data(1, bytes.slice(38, 146));


	// - TIMBRE 2
	if (voice_mode == 2) {
	   	parse_mk_timbre_data(2, bytes.slice(146, 253));
		registerDummy3rdTimbre();
	}
}

function parse_incoming_sysex(b) {
	recv(b);
	var currMsg = completeMsg
	if(currMsg !== null) {
		if (is_sysex_mk_pgm_dump_resp(currMsg)) {
			log("Is a PGM dump!");
			parse_mk_pgm_dump_resp(currMsg);
			outlet(0, currMsg); // output raw sysex to be stored
			outlet(1, 1); // tell message detected
		}
	}
}

function parse_outcoming_sysex(b) {
	recv(b);
	var currMsg = completeMsg
	if(currMsg !== null) {
		if (is_sysex_mk_pgm_dump_req(currMsg)) {
			log("Is a PGM dump request!");
			outlet(1, 1); // tell message detected
		}
	}
}

function save_curr_pgm_sysex (filePath) {
    var a = arrayfromargs(messagename,arguments);
    var bytes = a.slice(2, a.length + 1);

	// replace name w/ one potentially modified by user
    var pgm_name = d.get("new_pgm_name");
	pgm_name = pgm_name.substring(0,13);
	if (pgm_name != "" && pgm_name != "<UNTITLED>") {
		var pgm_name_bytes = stringToCharCodes(pgm_name);
		for (var i=0 ; i<13 ; i++) {
			v = 0;
			if (i < pgm_name_bytes.length)
				v = pgm_name_bytes[i];
			bytes[5 + i] = v;
		}
	}


    var ext = filePath.split('.').pop();
    if (ext == 'prg') {
	    //log("PRG file, adding header");
	    bytes = [].concat([0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x01, 0x01, 0xe0, 0x4d, 0x54,
			               0x72, 0x6b, 0x00, 0x00, 0x01, 0x30, 0x00, 0xf0, 0x82], bytes.slice(1, bytes.length + 1));
    }

    if(bytes !== null) {
		log("dumping");
		writeBytesToFile(filePath, bytes);
    } else {
		log("no current pgm loaded");
    }
}

function open_pgm_sysex_file (filePath) {
	var bytes = readBytesFromFile(filePath);

    var ext = filePath.split('.').pop();
    if (ext == 'prg') {
		//log("PRG file, removing header");
		//log(bytes);
		bytes = bytes.slice(26, bytes.length + 1);
		bytes.unshift(0xF0);
		//log(bytes);
    }

    if (bytes !== null && is_sysex_mk_pgm_dump_resp(bytes)) {
		//log("success", bytes);
		outlet(1, 1); // success
		outlet(0, bytes);
    } else {
		log("Cannot load, not a pgm dump in " + filePath);
		outlet(1, 0); // failure
    }
}
