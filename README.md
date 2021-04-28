# [MIDI Recorder][app]

The simplest way to record MIDI.

Also a nice simple live MIDI visualizer.

If you've got a MIDI keyboard, plug in and [try it out][app].

Built with [SimpleMidiInput.js](https://github.com/kchapelier/SimpleMidiInput.js) and [MidiFile.js](https://github.com/nfroidure/midifile)


### License

MIT-licensed. See [LICENSE.md](LICENSE.md)

### TODO

* Fix track length (end time)..................

* Improve layout on mobile / small viewport size

* Fade out overlay when playing (unless viz is disabled), with a button to show info again?
    - But there's a fullscreen button now (for the viz), is that good enough?

* Save progressively to local storage
    - This is the killer feature IMO, letting you record for long periods of time without fear of loss
    - Note: must handle multiple tabs without conflict
        - Could be separate recording slots per tab, but then there'd have to be a way to recover different sessions, vs having just one
        - Could use a scheme of saving chunks including notes since the last time of the last chunk (where the last write wins for a chunk) (and assume connected inputs are the same, which should be fine) - with potential complexity around trying not to duplicate or drop notes around chunk borders
        - Could use a scheme where one tab is somehow elected as the one to save MIDI to local storage, but this doesn't seem nice... it would probably have to be chunked anyways
    - Specifically stress test the length of recording
    - Make it clear it's continuing off a previous recording session / recording was recovered

* Record + show aftertouch pressure
    - I don't have a keyboard that supports this.

* Support Pitch Bend Range selection
    - How often is this sent? Probably only when you change it, if at all.
    - Might have to be a manual setting.

* Record miscellaneous MIDI events, maybe even SysEx (optionally)?
    - It'd be nice if I could just take a MIDI stream and append it to a header to get a MIDI file, but it's probably a lot more complicated.
    - Probably want to drop SimpleMIDIInput to do this... altho if it gives the raw data for all events, maybe I don't need to.

* Maybe allow scrolling back (pausing automatically (not pausing recording, just the view))
    - But the UI can also scroll, so how should you indicate to scroll the visualization versus the UI?

* Color notes by channel or instrument?
    - Doesn't matter much with a single keyboard

* Offline support with a service worker
    - Service workers are a serious footgun.

[app]: https://midi-recorder.web.app/
