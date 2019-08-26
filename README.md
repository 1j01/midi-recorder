# [MIDI Recorder][app]

The simplest way to record MIDI.

Also a nice simple live MIDI visualizer.

If you've got a MIDI keyboard, plug in and [try it out][app].

Built with [SimpleMidiInput.js](https://github.com/kchapelier/SimpleMidiInput.js) and [MidiFile.js](https://github.com/nfroidure/midifile)

### TODO

* Attempt to open MIDI port when device is connected but port is closed, so you don't need to refresh the page

* Fix track length (end time)

* Replace fork on github banner with a small link somewhere

* Improve layout on mobile / small viewport size

* Fade out overlay when playing (with a button to show info again)

* A way to clear/reset other than refreshing, with a confirmation prompt (unless you just saved?)

* Save progressively to local storage
    - This is the killer feature IMO, letting you record for long periods of time without fear of loss
    - Note: must handle multiple tabs without conflict
        - Could be separate recording slots per tab, but then there'd have to be a way to recover different sessions, vs having just one
        - Could use a scheme of saving chunks including notes since the last time of the last chunk (where the last write wins for a chunk) (and assume connected inputs are the same, which should be fine) - with potential complexity around trying not to duplicate or drop notes around chunk borders
        - Could use a scheme where one tab is somehow elected as the one to save MIDI to local storage, but this doesn't seem nice... it would probably have to be chunked anyways
    - Specifically stress test the length of recording
    - Make it clear it's continuing off a previous recording session / recording was recovered

* Show note velocity (already recorded)

* Record + show aftertouch pressure

* Record instrument changes, maybe show as horizontal line with text for instrument number/name

* Support Pitch Bend Range selection

* Record miscellaneous MIDI events, maybe even SysEx (optionally)?

* Maybe allow scrolling back (pausing automatically (not recording, just the view))

* Color notes by channel or instrument (doesn't matter much with a single keyboard)

* Offline support with a service worker

[app]: https://midi-recorder.web.app/
