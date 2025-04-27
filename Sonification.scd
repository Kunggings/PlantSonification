s.boot; // Boot the SuperCollider server

SerialPort.devices; // Check available serial ports if needed to update

~port = SerialPort.new("COM5", 9600); // Load Serial Port

// Incoming data handler
(
~valA = 0; // Holds current value of A
~valB = 0; // Holds current value of B
~mode = true; // true = audification, false = sonification
~charArray = [ ]; // Array to store incoming character data

~getValues = Routine.new({
    var ascii;
    {
        ascii = ~port.read.asAscii; // Read incoming data as ASCII

        if(ascii.isDecDigit, {
            ~charArray = ~charArray.add(ascii); // Add digit to charArray if it's a decimal digit
        });

        if(ascii == $a, {
            ~valB = ~charArray.collect(_.digit).convertDigits; // Convert charArray to valB
            ("B: ").post; ~valB.postln;
            ~charArray = [ ]; // Reset charArray
        });

        if(ascii == $b, {
            ~valA = ~charArray.collect(_.digit).convertDigits; // Convert charArray to valA
            ("A: ").post; ~valA.postln;
            ~charArray = [ ]; // Reset charArray
        });

        if(ascii == $c, {
            ~mode = ~mode.not; // Toggle mode between audification and sonification
            ("Mode toggled: ").post; ~mode.postln;
        });

        0.05.wait; // Pause to not overwhelm
    }.loop;
}).play;
)

// SynthDefs for audio generation
(
SynthDef(\simplePiano, {
    |freq = 440, amp = 0.2, gate = 1, reverbMix = 0.3| // Simple piano synth with reverb
    var env, sig, reverb;
    env = EnvGen.kr(Env.perc(0.01, 1.2), gate, doneAction: 2); // Envelope generation so synth can be muted
    sig = Mix.new([
        SinOsc.ar(freq, 0, 0.5), // Sine oscillator
        Saw.ar(freq * 2, 0.3) // Sawtooth oscillator
    ]);
    sig = LPF.ar(sig, freq * 3); // Low-pass filter
    sig = sig * env * amp; // Apply envelope and amplitude
    reverb = FreeVerb.ar(sig, 0.9, 0.5, reverbMix); // Reverb effect
    Out.ar(0, reverb.dup); // Output audio
}).add;

SynthDef(\saw, {
    |freq = 440, cutoff = 1000, gate = 1, pan = 0| // Saw synth with frequency and panning
    var sig, env;
    env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate); // Envelope generation
    sig = Saw.ar([freq, freq * 1.01]);
    sig = RLPF.ar(sig, cutoff.lag(0.02), 0.25, 0.2); // Resonant low-pass filter
    sig = sig * env; // Apply envelope
    sig = Pan2.ar(sig, pan); // Apply panning
    Out.ar(0, sig); // Output audio
}).add;
)

// Instantiate audification synths
~synth1 = Synth(\saw, [\pan, 1]);   // Fully right pan
~synth2 = Synth(\saw, [\pan, -1]);  // Fully left pan

// Control loop for data to sound conversion
(
~scale = [293.66, 329.63, 349.23, 392.00, 440.00, 466.16, 523.25, 587.33]; // Scale (d minor) - Sad Scale

~dataToSound = Routine({
    loop {
        if(~mode == false) { // Audification mode
            ~synth1.set(
                \gate, 1,
                \cutoff, ~valA.linexp(0, 700, 80, 4000), // Map valA to cutoff frequency
                \freq, ~valA.linlin(0, 700, 100, 1000) // Map valA to frequency
            );
            ~synth2.set(
                \gate, 1,
                \cutoff, ~valB.linexp(0, 700, 80, 4000), // Map valB to cutoff frequency
                \freq, ~valB.linlin(0, 700, 100, 1000) // Map valB to frequency
            );
            0.01.wait; // Small wait for timing
        } {
            // Sonification mode
            ~synth1.set(\gate, 0); // Stop synth1
            ~synth2.set(\gate, 0); // Stop synth2

            Synth(\simplePiano, [
                \freq, ~scale[~valA.linlin(0, 700, 0, 7).asInteger.clip(0, 7)], // Map valA to piano frequency
                \reverbMix, 0.3
            ]);
            rrand(0.4, 1).wait; // Random delay to add variation between notes
            Synth(\simplePiano, [
                \freq, ~scale[~valB.linlin(0, 700, 0, 7).asInteger.clip(0, 7)], // Map valB to piano frequency
                \reverbMix, 0.3
            ]);
            rrand(0.4, 1).wait; // Random delay to add variation between notes
        };
    }
}).play;
)

// Stop the proccesses
~getValues.stop;
~port.close;
~dataToSound.stop;
~synth1.free;
~synth2.free;

// Oscilloscope display
s.scope;
