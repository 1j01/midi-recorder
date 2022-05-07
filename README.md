# ![](public/favicon-32x32.png) [MIDI Recorder][app]

The simplest way to record MIDI.

- **Records right away**, no install or setup required. Automatically connects to new MIDI devices.
- **Visualizes** notes, pitch bends, and instrument changes, as you play.
- **Recovers recordings** in case the browser crashes, or you close the tab by accident, or refresh the page, or there's a power outage.

If you've got a MIDI keyboard, plug it in and [try out the app!][app]

Built with [SimpleMidiInput.js](https://github.com/kchapelier/SimpleMidiInput.js) and [MidiFile.js](https://github.com/nfroidure/midifile), and written in [CoffeeScript](https://coffeescript.org/).


### License

MIT-licensed. See [LICENSE.md](LICENSE.md)

### Development Setup

- Install Git and Node.js if you don't already have them installed.
- Clone the repository.
- Open a terminal in the project directory.
- Run `npm i` to install dependencies.
- Run `npm start` to start a live server and automatically recompile coffeescript on changes.

### TODO

See the [issue tracker](https://github.com/1j01/midi-recorder/issues), and `TODO` comments in the source code.

[app]: https://midi-recorder.web.app/
