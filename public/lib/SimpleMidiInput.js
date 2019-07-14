!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.SimpleMidiInput=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
"use strict";

module.exports = require('./src/simple-midi-input');

},{"./src/simple-midi-input":4}],2:[function(require,module,exports){
"use strict";

var MidiLearning = require('./midi-learning');

var MidiLearn = function (smi) {
    this.smi = smi;
    this.bindings = {};
};

MidiLearn.prototype.smi = null;
MidiLearn.prototype.currentMidiLearning = null;
MidiLearn.prototype.bindings = null;

MidiLearn.prototype.getMidiLearning = function (options) {
    return new MidiLearning(this, options);
};

MidiLearn.prototype.listenerForBinding = function (event) {
    if (this.currentMidiLearning && event) {
        var midiLearning = this.currentMidiLearning;

        midiLearning.events.bind(event);

        this.stopListeningForBinding();

        this.addBinding(midiLearning, event);
    }
};

MidiLearn.prototype.startListeningForBinding = function (midiLearning) {
    this.stopListeningForBinding();
    this.currentMidiLearning = midiLearning;

    midiLearning.listener = this.listenerForBinding.bind(this);

    midiLearning.events.listen(midiLearning);

    this.smi.on('global', midiLearning.listener);
};

MidiLearn.prototype.stopListeningForBinding = function (midiLearning) {
    if (this.currentMidiLearning !== null && (!midiLearning || this.currentMidiLearning === midiLearning)) {
        this.smi.off('global', this.currentMidiLearning.listener);
        this.currentMidiLearning.events.cancel();
        this.currentMidiLearning = null;
    }
};

MidiLearn.prototype.setCallback = function (midiLearning, eventName, func) {
    midiLearning.activeCallbacks[eventName] = func;
    this.smi.on(eventName, midiLearning.channel, func);
};

MidiLearn.prototype.removeBinding = function (midiLearning) {
    if (midiLearning && midiLearning.activeCallbacks) {
        var callbacks = midiLearning.activeCallbacks;

        for (var key in callbacks) {
            if (callbacks.hasOwnProperty(key)) {
                this.smi.off(key, midiLearning.channel, callbacks[key]);
            }
        }

        midiLearning.activeCallbacks = {};
    }

    delete this.bindings[midiLearning.id];
};

MidiLearn.prototype.addBinding = function (midiLearning, event) {
    this.removeBinding(midiLearning);

    this.bindings[midiLearning.id] = midiLearning;

    if (event.event === 'cc') {
        this.addCCBinding(midiLearning, event);
    } else if (event.event === 'noteOn') {
        this.addNoteBinding(midiLearning, event);
    }
};

MidiLearn.prototype.addNoteBinding = function (midiLearning, event) {
    midiLearning.channel = event.channel;

    this.setCallback(midiLearning, 'noteOn', function (e) {
        if (e.key === event.key) {
            midiLearning.setValue(e, 'velocity');
        }
    });

    this.setCallback(midiLearning, 'noteOff', function (e) {
        if (e.key === event.key) {
            midiLearning.setValue();
        }
    });

    this.setCallback(midiLearning, 'polyphonicAftertouch', function (e) {
        if (e.key === event.key) {
            midiLearning.setValue(e, 'pressure');
        }
    });
};

MidiLearn.prototype.addCCBinding = function (midiLearning, event) {
    midiLearning.channel = event.channel;

    this.setCallback(midiLearning, 'cc' + event.cc, function (e) {
        midiLearning.setValue(e, 'value');
    });
};

module.exports = MidiLearn;

},{"./midi-learning":3}],3:[function(require,module,exports){
"use strict";

/**
 * Generate a random id
 * @returns {Number}
 */
var generateRandomId = function () {
    return (new Date()).getTime() + Math.floor(Math.random() * 1000000);
};

var scale = function scale (value, min, max, dstMin, dstMax) {
    value = (max === min ? 0 : (Math.max(min, Math.min(max, value)) / (max - min)));

    return value * (dstMax - dstMin) + dstMin;
};

var limit = function limit (value, min, max) {
    return Math.max(min, Math.min(max, value));
};

var MidiLearning = function (midiLearn, options) {
    var noop = function () {};

    this.midiLearn = midiLearn;

    this.id = options.id || generateRandomId();
    this.min = parseFloat(options.min || 0);
    this.max = parseFloat(options.max);
    this.channel = null;
    this.activeCallbacks = {};

    this.events = {
        change: options.events.change || noop,
        bind: options.events.bind || noop,
        unbind: options.events.unbind || noop,
        cancel: options.events.cancel || noop,
        listen: options.events.listen || noop
    };

    this.setValue(limit(parseFloat(options.value || 0), this.min, this.max));
};

MidiLearning.prototype.id = null;
MidiLearning.prototype.min = null;
MidiLearning.prototype.max = null;
MidiLearning.prototype.value = null;
MidiLearning.prototype.channel = null;
MidiLearning.prototype.activeCallbacks = null;
MidiLearning.prototype.events = null;

MidiLearning.prototype.unbind = function () {
    this.midiLearn.removeBinding(this);
};

MidiLearning.prototype.startListening = function () {
    this.midiLearn.startListeningForBinding(this);
};

MidiLearning.prototype.stopListening = function () {
    this.midiLearn.startListeningForBinding(this);
};

MidiLearning.prototype.setValue = function (event, property) {
    var value;

    if (event && property) {
        value = scale(event[property], 0, 127, this.min, this.max);
    } else if (typeof event === 'number') {
        value = event;
    } else {
        value = this.min;
    }

    if (value !== this.value) {
        this.value = value;
        this.events.change(this.id, value);
    }
};

module.exports = MidiLearning;

},{}],4:[function(require,module,exports){
"use strict";

var MidiLearn = require('./midi-learn');

/**
 * Returns whether a value is numeric
 * @param {*} value
 * @returns {boolean}
 */
var isNumeric = function (value) {
    return !isNaN(parseFloat(value)) && isFinite(value);
};

/**
 * Returns whether a value is an array
 * @param {*} value
 * @returns {boolean}
 */
var isArray = function (value) {
    return Object.prototype.toString.call(value) === '[object Array]';
};

/**
 * Returns whether a value is a MIDIInputMap
 * @param {*} value
 * @returns {boolean}
 */
var isMIDIInputMap = function (value) {
    return Object.prototype.toString.call(value) === '[object MIDIInputMap]';
};

/**
 * Returns whether a value is a MIDIInput
 * @param {*} value
 * @returns {boolean}
 */
var isMIDIInput = function (value) {
    return Object.prototype.toString.call(value) === '[object MIDIInput]';
};

/**
 * Returns whether a value is a MIDIAccess
 * @param {*} value
 * @returns {boolean}
 */
var isMIDIAccess = function (value) {
    return Object.prototype.toString.call(value) === '[object MIDIAccess]';
};

/**
 * Returns whether a value is a function
 * @param {*} value
 * @returns {boolean}
 */
var isFunction = function (value) {
    return typeof value === 'function';
};

/**
 * Returns whether a value is an iterator
 * @param {*} value
 * @returns {boolean}
 */
var isIterator = function (value) {
    return Object.prototype.toString.call(value) === '[object Iterator]';
};

/**
 * Force whatever it receive to an array of MIDIInput when possible
 * @param {Function|Iterator|MIDIAccess|MIDIInputMap|MIDIInput|MIDIInput[]} source
 * @returns {MIDIInput[]} Array of MIDIInput
 */
var normalizeInputs = function (source) {
    var inputs = [],
        input;

    if (isMIDIInput(source)) {
        inputs.push(source);
    } else {
        if (isMIDIAccess(source)) {
            source = source.inputs;
        }

        if (isFunction(source)) {
            source = source();
        } else if (isMIDIInputMap(source)) {
            source = source.values();
        }

        if (isArray(source)) {
            inputs = source;
        } else if (isIterator(source)) {
            while (input = source.next().value) {
                inputs.push(input);
            }
        }
    }

    return inputs;
};

/**
 * Convert Variable Length Quantity to integer
 * @param {int} first LSB
 * @param {int} second MSB
 * @returns {int} Standard integer
 */
var readVLQ = function (first, second) {
    return (second << 7) + (first & 0x7F);
};

/**
 * Instanciate a SimpleMidiInput object
 * @param {MIDIInput|MIDIInput[]} [midiInput]
 * @constructor
 */
var SimpleMidiInput = function (midiInput) {
    this.events = {};
    this.innerEventListeners = {};

    if (midiInput) {
        this.attach(midiInput);
    }
};

SimpleMidiInput.prototype.filter = null;
SimpleMidiInput.prototype.events = null;
SimpleMidiInput.prototype.innerEventListeners = null;

/**
 * Attach this instance to one or several MIDIInput
 * @param {MIDIAccess|MIDIInputMap|MIDIInput|MIDIInput[]} midiInput
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.attach = function (midiInput) {
    var inputs = normalizeInputs(midiInput);

    for (var i = 0; i < inputs.length; i++) {
        this.attachIndividual(inputs[i]);
    }

    return this;
};

/**
 * Attach this instance to a given MIDIInput
 * @private
 * @param {MIDIInput} midiInput
 */
SimpleMidiInput.prototype.attachIndividual = function (midiInput) {
    if (!this.innerEventListeners[midiInput.id]) {
        var originalListener = midiInput.onmidimessage,
            listener,
            self = this;

        if (typeof originalListener === 'function') {
            listener = function (event) {
                originalListener(event);
                self.processMidiMessage(event.data);
            };
        } else {
            listener = function (event) {
                self.processMidiMessage(event.data);
            };
        }

        midiInput.onmidimessage = listener;

        this.innerEventListeners[midiInput.id] = {
            input: midiInput,
            listener: listener
        };
    }
};

/**
 * Detach this instance from one or several MIDIInput
 * @param {MIDIAccess|MIDIInputMap|MIDIInput|MIDIInput[]} midiInput
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.detach = function (midiInput) {
    var inputs = normalizeInputs(midiInput);

    for (var i = 0; i < inputs.length; i++) {
        this.detachIndividual(inputs[i]);
    }

    return this;
};

/**
 * Detach this instance from a given MIDIInput
 * @private
 * @param {MIDIInput} midiInput
 */
SimpleMidiInput.prototype.detachIndividual = function (midiInput) {
    if (!!this.innerEventListeners[midiInput.id]) {
        var listener = this.innerEventListeners[midiInput.id].listener;
        midiInput = this.innerEventListeners[midiInput.id].input;

        midiInput.removeEventListener("midimessage", listener);
        delete this.innerEventListeners[midiInput.id];
    }
};

/**
 * Detach this instance from everything
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.detachAll = function () {
    for (var id in this.innerEventListeners) {
        if (this.innerEventListeners.hasOwnProperty(id)) {
            var midiInput = this.innerEventListeners[midiInput.id].input;
            var listener = this.innerEventListeners[midiInput.id].listener;

            midiInput.removeEventListener("midimessage", listener);
        }
    }

    this.innerEventListeners = {};

    return this;
};

/**
 * Parse an incoming midi message
 * @private
 * @param {UInt8Array} data - Midi mesage data
 * @returns {Object} Midi event, as a readable object
 */
SimpleMidiInput.prototype.parseMidiMessage = function (data) {
    var event;

    switch (data[0]) {
        case 0x00:
            //some iOS app are sending a massive amount of seemingly empty messages, ignore them
            return null;
        case 0xF2:
            event = {
                event: 'songPosition',
                position: readVLQ(data[1], data[2]),
                data: data
            };
            break;
        case 0xF3:
            event = {
                event: 'songSelect',
                song: data[1],
                data: data
            };
            break;
        case 0xF6:
            event = {
                event: 'tuneRequest',
                data: data
            };
            break;
        case 0xF8:
            event = {
                event: 'clock',
                command: 'clock',
                data: data
            };
            break;
        case 0xFA:
            event = {
                event: 'clock',
                command: 'start',
                data: data
            };
            break;
        case 0xFB:
            event = {
                event: 'clock',
                command: 'continue',
                data: data
            };
            break;
        case 0xFC:
            event = {
                event: 'clock',
                command: 'stop',
                data: data
            };
            break;
        case 0xFE:
            event = {
                event: 'activeSensing',
                data: data
            };
            break;
        case 0xFF:
            event = {
                event: 'reset',
                data: data
            };
            break;
    }

    if (data[0] >= 0xE0 && data[0] < 0xF0) {
        event = {
            event: 'pitchWheel',
            channel: 1 + data[0] - 0xE0,
            value: readVLQ(data[1], data[2]) - 0x2000,
            data: data
        };
    } else if (data[0] >= 0xD0 && data[0] < 0xE0) {
        event = {
            event: 'channelAftertouch',
            channel: 1 + data[0] - 0xD0,
            pressure: data[1],
            data: data
        };
    } else if (data[0] >= 0xC0 && data[0] < 0xD0) {
        event = {
            event: 'programChange',
            channel: 1 + data[0] - 0xC0,
            program: data[1],
            data: data
        };
    } else if (data[0] >= 0xB0 && data[0] < 0xC0) {
        event = {
            event: 'cc',
            channel: 1 + data[0] - 0xB0,
            cc: data[1],
            value: data[2],
            data: data
        };
    } else if (data[0] >= 0xA0 && data[0] < 0xB0) {
        event = {
            event: 'polyphonicAftertouch',
            channel: 1 + data[0] - 0xA0,
            key: data[1],
            pressure: data[2],
            data: data
        };
    } else if (data[0] >= 0x90 && data[0] < 0xA0) {
        event = {
            event: 'noteOn',
            channel: 1 + data[0] - 0x90,
            key: data[1],
            velocity: data[2],
            data: data
        };

        //abstracting the fact that a noteOn with a velocity of 0 is supposed to be equal to a noteOff message
        if (event.velocity === 0) {
            event.velocity = 127;
            event.event = 'noteOff';
        }
    } else if (data[0] >= 0x80 && data[0] < 0x90) {
        event = {
            event: 'noteOff',
            channel: 1 + data[0] - 0x80,
            key: data[1],
            velocity: data[2],
            data: data
        };
    }

    if (!event) {
        event = {
            event: 'unknown',
            data: data
        };
    }

    return event;
};

/**
 * Process an incoming midi message and trigger the matching event
 * @private
 * @param {UInt8Array} data - Midi mesage data
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.processMidiMessage = function (data) {
    var event = this.parseMidiMessage(data);

    if (event) {
        if (this.filter) {
            if (this.filter(event) === false) {
                return this;
            }
        }

        if (!!event.cc) {
            this.trigger(event.event + event.cc, event);
            this.trigger(event.channel + '.' + event.event + event.cc, event);
        } else {
            this.trigger(event.event, event);
            if (!!event.channel) {
                this.trigger(event.channel + '.' + event.event, event);
            }
        }

        this.trigger('global', event);
    }

    return this;
};

/**
 * Set the filter function
 * @param {Function} [filter] - Filter function
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.setFilter = function (filter) {
    if (isFunction(filter)) {
        this.filter = filter;
    } else {
        delete this.filter;
    }

    return this;
};

/**
 * Subscribe to an event
 * @param {String} event - Name of the event
 * @param {Number} [channel] - Channel of the event
 * @param {Function} func - Callback for the event
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.on = function (event, channel, func) {
    if (isFunction(channel)) {
        func = channel;
    } else if (isNumeric(channel)) {
        event = channel + '.' + event;
    }

    if (!this.events[event]) {
        this.events[event] = [];
    }

    this.events[event].push(func);

    return this;
};

/**
 * Unsubscribe to an event
 * @param {String} event - Name of the event
 * @param {Number} [channel] - Channel of the event
 * @param {Function} [func] - Callback to remove (if none, all are removed)
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.off = function (event, channel, func) {
    if (isFunction(channel)) {
        func = channel;
    } else if (isNumeric(channel)) {
        event = channel + '.' + event;
    }

    if (!func) {
        delete this.events[event];
    } else {
        var pos = this.events[event].indexOf(func);
        if (pos >= 0) {
            this.events[event].splice(pos, 1);
        }
    }

    return this;
};

/**
 * Trigger an event
 * @param {String} event - Name of the event
 * @param {Array} args - Arguments to pass to the callbacks
 * @returns {SimpleMidiInput} Instance for method chaining
 */
SimpleMidiInput.prototype.trigger = function (event, args) {
    if (!!this.events[event] && this.events[event].length) {
        for (var l = this.events[event].length; l--;) {
            this.events[event][l].call(this, args);
        }
    }

    return this;
};

/**
 * Return an instance of the MidiLearn handling class
 * @private
 * @returns {MidiLearn} Instance of MidiLearn
 */
SimpleMidiInput.prototype.getMidiLearnInstance = function () {
    if (!this.midiLearn) {
        this.midiLearn = new MidiLearn(this);
    }

    return this.midiLearn;
};

/**
 * Return an instance of MidiLearning for a given parameter
 * @param {Object} options - Options of the parameter (id, min, max, value, events)
 * @returns {MidiLearning}
 */
SimpleMidiInput.prototype.getMidiLearning = function (options) {
    return this.getMidiLearnInstance().getMidiLearning(options);
};

module.exports = SimpleMidiInput;

},{"./midi-learn":2}]},{},[1])(1)
});
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uL3Vzci9sb2NhbC9saWIvbm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2Jyb3dzZXItcGFjay9fcHJlbHVkZS5qcyIsImluZGV4LmpzIiwic3JjL21pZGktbGVhcm4uanMiLCJzcmMvbWlkaS1sZWFybmluZy5qcyIsInNyYy9zaW1wbGUtbWlkaS1pbnB1dC5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBO0FBQ0E7QUFDQTtBQUNBOztBQ0hBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDaEhBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNoRkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSIsImZpbGUiOiJnZW5lcmF0ZWQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlc0NvbnRlbnQiOlsiKGZ1bmN0aW9uIGUodCxuLHIpe2Z1bmN0aW9uIHMobyx1KXtpZighbltvXSl7aWYoIXRbb10pe3ZhciBhPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7aWYoIXUmJmEpcmV0dXJuIGEobywhMCk7aWYoaSlyZXR1cm4gaShvLCEwKTt2YXIgZj1uZXcgRXJyb3IoXCJDYW5ub3QgZmluZCBtb2R1bGUgJ1wiK28rXCInXCIpO3Rocm93IGYuY29kZT1cIk1PRFVMRV9OT1RfRk9VTkRcIixmfXZhciBsPW5bb109e2V4cG9ydHM6e319O3Rbb11bMF0uY2FsbChsLmV4cG9ydHMsZnVuY3Rpb24oZSl7dmFyIG49dFtvXVsxXVtlXTtyZXR1cm4gcyhuP246ZSl9LGwsbC5leHBvcnRzLGUsdCxuLHIpfXJldHVybiBuW29dLmV4cG9ydHN9dmFyIGk9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtmb3IodmFyIG89MDtvPHIubGVuZ3RoO28rKylzKHJbb10pO3JldHVybiBzfSkiLCJcInVzZSBzdHJpY3RcIjtcblxubW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKCcuL3NyYy9zaW1wbGUtbWlkaS1pbnB1dCcpO1xuIiwiXCJ1c2Ugc3RyaWN0XCI7XG5cbnZhciBNaWRpTGVhcm5pbmcgPSByZXF1aXJlKCcuL21pZGktbGVhcm5pbmcnKTtcblxudmFyIE1pZGlMZWFybiA9IGZ1bmN0aW9uIChzbWkpIHtcbiAgICB0aGlzLnNtaSA9IHNtaTtcbiAgICB0aGlzLmJpbmRpbmdzID0ge307XG59O1xuXG5NaWRpTGVhcm4ucHJvdG90eXBlLnNtaSA9IG51bGw7XG5NaWRpTGVhcm4ucHJvdG90eXBlLmN1cnJlbnRNaWRpTGVhcm5pbmcgPSBudWxsO1xuTWlkaUxlYXJuLnByb3RvdHlwZS5iaW5kaW5ncyA9IG51bGw7XG5cbk1pZGlMZWFybi5wcm90b3R5cGUuZ2V0TWlkaUxlYXJuaW5nID0gZnVuY3Rpb24gKG9wdGlvbnMpIHtcbiAgICByZXR1cm4gbmV3IE1pZGlMZWFybmluZyh0aGlzLCBvcHRpb25zKTtcbn07XG5cbk1pZGlMZWFybi5wcm90b3R5cGUubGlzdGVuZXJGb3JCaW5kaW5nID0gZnVuY3Rpb24gKGV2ZW50KSB7XG4gICAgaWYgKHRoaXMuY3VycmVudE1pZGlMZWFybmluZyAmJiBldmVudCkge1xuICAgICAgICB2YXIgbWlkaUxlYXJuaW5nID0gdGhpcy5jdXJyZW50TWlkaUxlYXJuaW5nO1xuXG4gICAgICAgIG1pZGlMZWFybmluZy5ldmVudHMuYmluZChldmVudCk7XG5cbiAgICAgICAgdGhpcy5zdG9wTGlzdGVuaW5nRm9yQmluZGluZygpO1xuXG4gICAgICAgIHRoaXMuYWRkQmluZGluZyhtaWRpTGVhcm5pbmcsIGV2ZW50KTtcbiAgICB9XG59O1xuXG5NaWRpTGVhcm4ucHJvdG90eXBlLnN0YXJ0TGlzdGVuaW5nRm9yQmluZGluZyA9IGZ1bmN0aW9uIChtaWRpTGVhcm5pbmcpIHtcbiAgICB0aGlzLnN0b3BMaXN0ZW5pbmdGb3JCaW5kaW5nKCk7XG4gICAgdGhpcy5jdXJyZW50TWlkaUxlYXJuaW5nID0gbWlkaUxlYXJuaW5nO1xuXG4gICAgbWlkaUxlYXJuaW5nLmxpc3RlbmVyID0gdGhpcy5saXN0ZW5lckZvckJpbmRpbmcuYmluZCh0aGlzKTtcblxuICAgIG1pZGlMZWFybmluZy5ldmVudHMubGlzdGVuKG1pZGlMZWFybmluZyk7XG5cbiAgICB0aGlzLnNtaS5vbignZ2xvYmFsJywgbWlkaUxlYXJuaW5nLmxpc3RlbmVyKTtcbn07XG5cbk1pZGlMZWFybi5wcm90b3R5cGUuc3RvcExpc3RlbmluZ0ZvckJpbmRpbmcgPSBmdW5jdGlvbiAobWlkaUxlYXJuaW5nKSB7XG4gICAgaWYgKHRoaXMuY3VycmVudE1pZGlMZWFybmluZyAhPT0gbnVsbCAmJiAoIW1pZGlMZWFybmluZyB8fCB0aGlzLmN1cnJlbnRNaWRpTGVhcm5pbmcgPT09IG1pZGlMZWFybmluZykpIHtcbiAgICAgICAgdGhpcy5zbWkub2ZmKCdnbG9iYWwnLCB0aGlzLmN1cnJlbnRNaWRpTGVhcm5pbmcubGlzdGVuZXIpO1xuICAgICAgICB0aGlzLmN1cnJlbnRNaWRpTGVhcm5pbmcuZXZlbnRzLmNhbmNlbCgpO1xuICAgICAgICB0aGlzLmN1cnJlbnRNaWRpTGVhcm5pbmcgPSBudWxsO1xuICAgIH1cbn07XG5cbk1pZGlMZWFybi5wcm90b3R5cGUuc2V0Q2FsbGJhY2sgPSBmdW5jdGlvbiAobWlkaUxlYXJuaW5nLCBldmVudE5hbWUsIGZ1bmMpIHtcbiAgICBtaWRpTGVhcm5pbmcuYWN0aXZlQ2FsbGJhY2tzW2V2ZW50TmFtZV0gPSBmdW5jO1xuICAgIHRoaXMuc21pLm9uKGV2ZW50TmFtZSwgbWlkaUxlYXJuaW5nLmNoYW5uZWwsIGZ1bmMpO1xufTtcblxuTWlkaUxlYXJuLnByb3RvdHlwZS5yZW1vdmVCaW5kaW5nID0gZnVuY3Rpb24gKG1pZGlMZWFybmluZykge1xuICAgIGlmIChtaWRpTGVhcm5pbmcgJiYgbWlkaUxlYXJuaW5nLmFjdGl2ZUNhbGxiYWNrcykge1xuICAgICAgICB2YXIgY2FsbGJhY2tzID0gbWlkaUxlYXJuaW5nLmFjdGl2ZUNhbGxiYWNrcztcblxuICAgICAgICBmb3IgKHZhciBrZXkgaW4gY2FsbGJhY2tzKSB7XG4gICAgICAgICAgICBpZiAoY2FsbGJhY2tzLmhhc093blByb3BlcnR5KGtleSkpIHtcbiAgICAgICAgICAgICAgICB0aGlzLnNtaS5vZmYoa2V5LCBtaWRpTGVhcm5pbmcuY2hhbm5lbCwgY2FsbGJhY2tzW2tleV0pO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgbWlkaUxlYXJuaW5nLmFjdGl2ZUNhbGxiYWNrcyA9IHt9O1xuICAgIH1cblxuICAgIGRlbGV0ZSB0aGlzLmJpbmRpbmdzW21pZGlMZWFybmluZy5pZF07XG59O1xuXG5NaWRpTGVhcm4ucHJvdG90eXBlLmFkZEJpbmRpbmcgPSBmdW5jdGlvbiAobWlkaUxlYXJuaW5nLCBldmVudCkge1xuICAgIHRoaXMucmVtb3ZlQmluZGluZyhtaWRpTGVhcm5pbmcpO1xuXG4gICAgdGhpcy5iaW5kaW5nc1ttaWRpTGVhcm5pbmcuaWRdID0gbWlkaUxlYXJuaW5nO1xuXG4gICAgaWYgKGV2ZW50LmV2ZW50ID09PSAnY2MnKSB7XG4gICAgICAgIHRoaXMuYWRkQ0NCaW5kaW5nKG1pZGlMZWFybmluZywgZXZlbnQpO1xuICAgIH0gZWxzZSBpZiAoZXZlbnQuZXZlbnQgPT09ICdub3RlT24nKSB7XG4gICAgICAgIHRoaXMuYWRkTm90ZUJpbmRpbmcobWlkaUxlYXJuaW5nLCBldmVudCk7XG4gICAgfVxufTtcblxuTWlkaUxlYXJuLnByb3RvdHlwZS5hZGROb3RlQmluZGluZyA9IGZ1bmN0aW9uIChtaWRpTGVhcm5pbmcsIGV2ZW50KSB7XG4gICAgbWlkaUxlYXJuaW5nLmNoYW5uZWwgPSBldmVudC5jaGFubmVsO1xuXG4gICAgdGhpcy5zZXRDYWxsYmFjayhtaWRpTGVhcm5pbmcsICdub3RlT24nLCBmdW5jdGlvbiAoZSkge1xuICAgICAgICBpZiAoZS5rZXkgPT09IGV2ZW50LmtleSkge1xuICAgICAgICAgICAgbWlkaUxlYXJuaW5nLnNldFZhbHVlKGUsICd2ZWxvY2l0eScpO1xuICAgICAgICB9XG4gICAgfSk7XG5cbiAgICB0aGlzLnNldENhbGxiYWNrKG1pZGlMZWFybmluZywgJ25vdGVPZmYnLCBmdW5jdGlvbiAoZSkge1xuICAgICAgICBpZiAoZS5rZXkgPT09IGV2ZW50LmtleSkge1xuICAgICAgICAgICAgbWlkaUxlYXJuaW5nLnNldFZhbHVlKCk7XG4gICAgICAgIH1cbiAgICB9KTtcblxuICAgIHRoaXMuc2V0Q2FsbGJhY2sobWlkaUxlYXJuaW5nLCAncG9seXBob25pY0FmdGVydG91Y2gnLCBmdW5jdGlvbiAoZSkge1xuICAgICAgICBpZiAoZS5rZXkgPT09IGV2ZW50LmtleSkge1xuICAgICAgICAgICAgbWlkaUxlYXJuaW5nLnNldFZhbHVlKGUsICdwcmVzc3VyZScpO1xuICAgICAgICB9XG4gICAgfSk7XG59O1xuXG5NaWRpTGVhcm4ucHJvdG90eXBlLmFkZENDQmluZGluZyA9IGZ1bmN0aW9uIChtaWRpTGVhcm5pbmcsIGV2ZW50KSB7XG4gICAgbWlkaUxlYXJuaW5nLmNoYW5uZWwgPSBldmVudC5jaGFubmVsO1xuXG4gICAgdGhpcy5zZXRDYWxsYmFjayhtaWRpTGVhcm5pbmcsICdjYycgKyBldmVudC5jYywgZnVuY3Rpb24gKGUpIHtcbiAgICAgICAgbWlkaUxlYXJuaW5nLnNldFZhbHVlKGUsICd2YWx1ZScpO1xuICAgIH0pO1xufTtcblxubW9kdWxlLmV4cG9ydHMgPSBNaWRpTGVhcm47XG4iLCJcInVzZSBzdHJpY3RcIjtcblxuLyoqXG4gKiBHZW5lcmF0ZSBhIHJhbmRvbSBpZFxuICogQHJldHVybnMge051bWJlcn1cbiAqL1xudmFyIGdlbmVyYXRlUmFuZG9tSWQgPSBmdW5jdGlvbiAoKSB7XG4gICAgcmV0dXJuIChuZXcgRGF0ZSgpKS5nZXRUaW1lKCkgKyBNYXRoLmZsb29yKE1hdGgucmFuZG9tKCkgKiAxMDAwMDAwKTtcbn07XG5cbnZhciBzY2FsZSA9IGZ1bmN0aW9uIHNjYWxlICh2YWx1ZSwgbWluLCBtYXgsIGRzdE1pbiwgZHN0TWF4KSB7XG4gICAgdmFsdWUgPSAobWF4ID09PSBtaW4gPyAwIDogKE1hdGgubWF4KG1pbiwgTWF0aC5taW4obWF4LCB2YWx1ZSkpIC8gKG1heCAtIG1pbikpKTtcblxuICAgIHJldHVybiB2YWx1ZSAqIChkc3RNYXggLSBkc3RNaW4pICsgZHN0TWluO1xufTtcblxudmFyIGxpbWl0ID0gZnVuY3Rpb24gbGltaXQgKHZhbHVlLCBtaW4sIG1heCkge1xuICAgIHJldHVybiBNYXRoLm1heChtaW4sIE1hdGgubWluKG1heCwgdmFsdWUpKTtcbn07XG5cbnZhciBNaWRpTGVhcm5pbmcgPSBmdW5jdGlvbiAobWlkaUxlYXJuLCBvcHRpb25zKSB7XG4gICAgdmFyIG5vb3AgPSBmdW5jdGlvbiAoKSB7fTtcblxuICAgIHRoaXMubWlkaUxlYXJuID0gbWlkaUxlYXJuO1xuXG4gICAgdGhpcy5pZCA9IG9wdGlvbnMuaWQgfHwgZ2VuZXJhdGVSYW5kb21JZCgpO1xuICAgIHRoaXMubWluID0gcGFyc2VGbG9hdChvcHRpb25zLm1pbiB8fCAwKTtcbiAgICB0aGlzLm1heCA9IHBhcnNlRmxvYXQob3B0aW9ucy5tYXgpO1xuICAgIHRoaXMuY2hhbm5lbCA9IG51bGw7XG4gICAgdGhpcy5hY3RpdmVDYWxsYmFja3MgPSB7fTtcblxuICAgIHRoaXMuZXZlbnRzID0ge1xuICAgICAgICBjaGFuZ2U6IG9wdGlvbnMuZXZlbnRzLmNoYW5nZSB8fCBub29wLFxuICAgICAgICBiaW5kOiBvcHRpb25zLmV2ZW50cy5iaW5kIHx8IG5vb3AsXG4gICAgICAgIHVuYmluZDogb3B0aW9ucy5ldmVudHMudW5iaW5kIHx8IG5vb3AsXG4gICAgICAgIGNhbmNlbDogb3B0aW9ucy5ldmVudHMuY2FuY2VsIHx8IG5vb3AsXG4gICAgICAgIGxpc3Rlbjogb3B0aW9ucy5ldmVudHMubGlzdGVuIHx8IG5vb3BcbiAgICB9O1xuXG4gICAgdGhpcy5zZXRWYWx1ZShsaW1pdChwYXJzZUZsb2F0KG9wdGlvbnMudmFsdWUgfHwgMCksIHRoaXMubWluLCB0aGlzLm1heCkpO1xufTtcblxuTWlkaUxlYXJuaW5nLnByb3RvdHlwZS5pZCA9IG51bGw7XG5NaWRpTGVhcm5pbmcucHJvdG90eXBlLm1pbiA9IG51bGw7XG5NaWRpTGVhcm5pbmcucHJvdG90eXBlLm1heCA9IG51bGw7XG5NaWRpTGVhcm5pbmcucHJvdG90eXBlLnZhbHVlID0gbnVsbDtcbk1pZGlMZWFybmluZy5wcm90b3R5cGUuY2hhbm5lbCA9IG51bGw7XG5NaWRpTGVhcm5pbmcucHJvdG90eXBlLmFjdGl2ZUNhbGxiYWNrcyA9IG51bGw7XG5NaWRpTGVhcm5pbmcucHJvdG90eXBlLmV2ZW50cyA9IG51bGw7XG5cbk1pZGlMZWFybmluZy5wcm90b3R5cGUudW5iaW5kID0gZnVuY3Rpb24gKCkge1xuICAgIHRoaXMubWlkaUxlYXJuLnJlbW92ZUJpbmRpbmcodGhpcyk7XG59O1xuXG5NaWRpTGVhcm5pbmcucHJvdG90eXBlLnN0YXJ0TGlzdGVuaW5nID0gZnVuY3Rpb24gKCkge1xuICAgIHRoaXMubWlkaUxlYXJuLnN0YXJ0TGlzdGVuaW5nRm9yQmluZGluZyh0aGlzKTtcbn07XG5cbk1pZGlMZWFybmluZy5wcm90b3R5cGUuc3RvcExpc3RlbmluZyA9IGZ1bmN0aW9uICgpIHtcbiAgICB0aGlzLm1pZGlMZWFybi5zdGFydExpc3RlbmluZ0ZvckJpbmRpbmcodGhpcyk7XG59O1xuXG5NaWRpTGVhcm5pbmcucHJvdG90eXBlLnNldFZhbHVlID0gZnVuY3Rpb24gKGV2ZW50LCBwcm9wZXJ0eSkge1xuICAgIHZhciB2YWx1ZTtcblxuICAgIGlmIChldmVudCAmJiBwcm9wZXJ0eSkge1xuICAgICAgICB2YWx1ZSA9IHNjYWxlKGV2ZW50W3Byb3BlcnR5XSwgMCwgMTI3LCB0aGlzLm1pbiwgdGhpcy5tYXgpO1xuICAgIH0gZWxzZSBpZiAodHlwZW9mIGV2ZW50ID09PSAnbnVtYmVyJykge1xuICAgICAgICB2YWx1ZSA9IGV2ZW50O1xuICAgIH0gZWxzZSB7XG4gICAgICAgIHZhbHVlID0gdGhpcy5taW47XG4gICAgfVxuXG4gICAgaWYgKHZhbHVlICE9PSB0aGlzLnZhbHVlKSB7XG4gICAgICAgIHRoaXMudmFsdWUgPSB2YWx1ZTtcbiAgICAgICAgdGhpcy5ldmVudHMuY2hhbmdlKHRoaXMuaWQsIHZhbHVlKTtcbiAgICB9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IE1pZGlMZWFybmluZztcbiIsIlwidXNlIHN0cmljdFwiO1xuXG52YXIgTWlkaUxlYXJuID0gcmVxdWlyZSgnLi9taWRpLWxlYXJuJyk7XG5cbi8qKlxuICogUmV0dXJucyB3aGV0aGVyIGEgdmFsdWUgaXMgbnVtZXJpY1xuICogQHBhcmFtIHsqfSB2YWx1ZVxuICogQHJldHVybnMge2Jvb2xlYW59XG4gKi9cbnZhciBpc051bWVyaWMgPSBmdW5jdGlvbiAodmFsdWUpIHtcbiAgICByZXR1cm4gIWlzTmFOKHBhcnNlRmxvYXQodmFsdWUpKSAmJiBpc0Zpbml0ZSh2YWx1ZSk7XG59O1xuXG4vKipcbiAqIFJldHVybnMgd2hldGhlciBhIHZhbHVlIGlzIGFuIGFycmF5XG4gKiBAcGFyYW0geyp9IHZhbHVlXG4gKiBAcmV0dXJucyB7Ym9vbGVhbn1cbiAqL1xudmFyIGlzQXJyYXkgPSBmdW5jdGlvbiAodmFsdWUpIHtcbiAgICByZXR1cm4gT2JqZWN0LnByb3RvdHlwZS50b1N0cmluZy5jYWxsKHZhbHVlKSA9PT0gJ1tvYmplY3QgQXJyYXldJztcbn07XG5cbi8qKlxuICogUmV0dXJucyB3aGV0aGVyIGEgdmFsdWUgaXMgYSBNSURJSW5wdXRNYXBcbiAqIEBwYXJhbSB7Kn0gdmFsdWVcbiAqIEByZXR1cm5zIHtib29sZWFufVxuICovXG52YXIgaXNNSURJSW5wdXRNYXAgPSBmdW5jdGlvbiAodmFsdWUpIHtcbiAgICByZXR1cm4gT2JqZWN0LnByb3RvdHlwZS50b1N0cmluZy5jYWxsKHZhbHVlKSA9PT0gJ1tvYmplY3QgTUlESUlucHV0TWFwXSc7XG59O1xuXG4vKipcbiAqIFJldHVybnMgd2hldGhlciBhIHZhbHVlIGlzIGEgTUlESUlucHV0XG4gKiBAcGFyYW0geyp9IHZhbHVlXG4gKiBAcmV0dXJucyB7Ym9vbGVhbn1cbiAqL1xudmFyIGlzTUlESUlucHV0ID0gZnVuY3Rpb24gKHZhbHVlKSB7XG4gICAgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUudG9TdHJpbmcuY2FsbCh2YWx1ZSkgPT09ICdbb2JqZWN0IE1JRElJbnB1dF0nO1xufTtcblxuLyoqXG4gKiBSZXR1cm5zIHdoZXRoZXIgYSB2YWx1ZSBpcyBhIE1JRElBY2Nlc3NcbiAqIEBwYXJhbSB7Kn0gdmFsdWVcbiAqIEByZXR1cm5zIHtib29sZWFufVxuICovXG52YXIgaXNNSURJQWNjZXNzID0gZnVuY3Rpb24gKHZhbHVlKSB7XG4gICAgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUudG9TdHJpbmcuY2FsbCh2YWx1ZSkgPT09ICdbb2JqZWN0IE1JRElBY2Nlc3NdJztcbn07XG5cbi8qKlxuICogUmV0dXJucyB3aGV0aGVyIGEgdmFsdWUgaXMgYSBmdW5jdGlvblxuICogQHBhcmFtIHsqfSB2YWx1ZVxuICogQHJldHVybnMge2Jvb2xlYW59XG4gKi9cbnZhciBpc0Z1bmN0aW9uID0gZnVuY3Rpb24gKHZhbHVlKSB7XG4gICAgcmV0dXJuIHR5cGVvZiB2YWx1ZSA9PT0gJ2Z1bmN0aW9uJztcbn07XG5cbi8qKlxuICogUmV0dXJucyB3aGV0aGVyIGEgdmFsdWUgaXMgYW4gaXRlcmF0b3JcbiAqIEBwYXJhbSB7Kn0gdmFsdWVcbiAqIEByZXR1cm5zIHtib29sZWFufVxuICovXG52YXIgaXNJdGVyYXRvciA9IGZ1bmN0aW9uICh2YWx1ZSkge1xuICAgIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodmFsdWUpID09PSAnW29iamVjdCBJdGVyYXRvcl0nO1xufTtcblxuLyoqXG4gKiBGb3JjZSB3aGF0ZXZlciBpdCByZWNlaXZlIHRvIGFuIGFycmF5IG9mIE1JRElJbnB1dCB3aGVuIHBvc3NpYmxlXG4gKiBAcGFyYW0ge0Z1bmN0aW9ufEl0ZXJhdG9yfE1JRElBY2Nlc3N8TUlESUlucHV0TWFwfE1JRElJbnB1dHxNSURJSW5wdXRbXX0gc291cmNlXG4gKiBAcmV0dXJucyB7TUlESUlucHV0W119IEFycmF5IG9mIE1JRElJbnB1dFxuICovXG52YXIgbm9ybWFsaXplSW5wdXRzID0gZnVuY3Rpb24gKHNvdXJjZSkge1xuICAgIHZhciBpbnB1dHMgPSBbXSxcbiAgICAgICAgaW5wdXQ7XG5cbiAgICBpZiAoaXNNSURJSW5wdXQoc291cmNlKSkge1xuICAgICAgICBpbnB1dHMucHVzaChzb3VyY2UpO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIGlmIChpc01JRElBY2Nlc3Moc291cmNlKSkge1xuICAgICAgICAgICAgc291cmNlID0gc291cmNlLmlucHV0cztcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChpc0Z1bmN0aW9uKHNvdXJjZSkpIHtcbiAgICAgICAgICAgIHNvdXJjZSA9IHNvdXJjZSgpO1xuICAgICAgICB9IGVsc2UgaWYgKGlzTUlESUlucHV0TWFwKHNvdXJjZSkpIHtcbiAgICAgICAgICAgIHNvdXJjZSA9IHNvdXJjZS52YWx1ZXMoKTtcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChpc0FycmF5KHNvdXJjZSkpIHtcbiAgICAgICAgICAgIGlucHV0cyA9IHNvdXJjZTtcbiAgICAgICAgfSBlbHNlIGlmIChpc0l0ZXJhdG9yKHNvdXJjZSkpIHtcbiAgICAgICAgICAgIHdoaWxlIChpbnB1dCA9IHNvdXJjZS5uZXh0KCkudmFsdWUpIHtcbiAgICAgICAgICAgICAgICBpbnB1dHMucHVzaChpbnB1dCk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4gaW5wdXRzO1xufTtcblxuLyoqXG4gKiBDb252ZXJ0IFZhcmlhYmxlIExlbmd0aCBRdWFudGl0eSB0byBpbnRlZ2VyXG4gKiBAcGFyYW0ge2ludH0gZmlyc3QgTFNCXG4gKiBAcGFyYW0ge2ludH0gc2Vjb25kIE1TQlxuICogQHJldHVybnMge2ludH0gU3RhbmRhcmQgaW50ZWdlclxuICovXG52YXIgcmVhZFZMUSA9IGZ1bmN0aW9uIChmaXJzdCwgc2Vjb25kKSB7XG4gICAgcmV0dXJuIChzZWNvbmQgPDwgNykgKyAoZmlyc3QgJiAweDdGKTtcbn07XG5cbi8qKlxuICogSW5zdGFuY2lhdGUgYSBTaW1wbGVNaWRpSW5wdXQgb2JqZWN0XG4gKiBAcGFyYW0ge01JRElJbnB1dHxNSURJSW5wdXRbXX0gW21pZGlJbnB1dF1cbiAqIEBjb25zdHJ1Y3RvclxuICovXG52YXIgU2ltcGxlTWlkaUlucHV0ID0gZnVuY3Rpb24gKG1pZGlJbnB1dCkge1xuICAgIHRoaXMuZXZlbnRzID0ge307XG4gICAgdGhpcy5pbm5lckV2ZW50TGlzdGVuZXJzID0ge307XG5cbiAgICBpZiAobWlkaUlucHV0KSB7XG4gICAgICAgIHRoaXMuYXR0YWNoKG1pZGlJbnB1dCk7XG4gICAgfVxufTtcblxuU2ltcGxlTWlkaUlucHV0LnByb3RvdHlwZS5maWx0ZXIgPSBudWxsO1xuU2ltcGxlTWlkaUlucHV0LnByb3RvdHlwZS5ldmVudHMgPSBudWxsO1xuU2ltcGxlTWlkaUlucHV0LnByb3RvdHlwZS5pbm5lckV2ZW50TGlzdGVuZXJzID0gbnVsbDtcblxuLyoqXG4gKiBBdHRhY2ggdGhpcyBpbnN0YW5jZSB0byBvbmUgb3Igc2V2ZXJhbCBNSURJSW5wdXRcbiAqIEBwYXJhbSB7TUlESUFjY2Vzc3xNSURJSW5wdXRNYXB8TUlESUlucHV0fE1JRElJbnB1dFtdfSBtaWRpSW5wdXRcbiAqIEByZXR1cm5zIHtTaW1wbGVNaWRpSW5wdXR9IEluc3RhbmNlIGZvciBtZXRob2QgY2hhaW5pbmdcbiAqL1xuU2ltcGxlTWlkaUlucHV0LnByb3RvdHlwZS5hdHRhY2ggPSBmdW5jdGlvbiAobWlkaUlucHV0KSB7XG4gICAgdmFyIGlucHV0cyA9IG5vcm1hbGl6ZUlucHV0cyhtaWRpSW5wdXQpO1xuXG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCBpbnB1dHMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgdGhpcy5hdHRhY2hJbmRpdmlkdWFsKGlucHV0c1tpXSk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHRoaXM7XG59O1xuXG4vKipcbiAqIEF0dGFjaCB0aGlzIGluc3RhbmNlIHRvIGEgZ2l2ZW4gTUlESUlucHV0XG4gKiBAcHJpdmF0ZVxuICogQHBhcmFtIHtNSURJSW5wdXR9IG1pZGlJbnB1dFxuICovXG5TaW1wbGVNaWRpSW5wdXQucHJvdG90eXBlLmF0dGFjaEluZGl2aWR1YWwgPSBmdW5jdGlvbiAobWlkaUlucHV0KSB7XG4gICAgaWYgKCF0aGlzLmlubmVyRXZlbnRMaXN0ZW5lcnNbbWlkaUlucHV0LmlkXSkge1xuICAgICAgICB2YXIgb3JpZ2luYWxMaXN0ZW5lciA9IG1pZGlJbnB1dC5vbm1pZGltZXNzYWdlLFxuICAgICAgICAgICAgbGlzdGVuZXIsXG4gICAgICAgICAgICBzZWxmID0gdGhpcztcblxuICAgICAgICBpZiAodHlwZW9mIG9yaWdpbmFsTGlzdGVuZXIgPT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgICAgIGxpc3RlbmVyID0gZnVuY3Rpb24gKGV2ZW50KSB7XG4gICAgICAgICAgICAgICAgb3JpZ2luYWxMaXN0ZW5lcihldmVudCk7XG4gICAgICAgICAgICAgICAgc2VsZi5wcm9jZXNzTWlkaU1lc3NhZ2UoZXZlbnQuZGF0YSk7XG4gICAgICAgICAgICB9O1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgbGlzdGVuZXIgPSBmdW5jdGlvbiAoZXZlbnQpIHtcbiAgICAgICAgICAgICAgICBzZWxmLnByb2Nlc3NNaWRpTWVzc2FnZShldmVudC5kYXRhKTtcbiAgICAgICAgICAgIH07XG4gICAgICAgIH1cblxuICAgICAgICBtaWRpSW5wdXQub25taWRpbWVzc2FnZSA9IGxpc3RlbmVyO1xuXG4gICAgICAgIHRoaXMuaW5uZXJFdmVudExpc3RlbmVyc1ttaWRpSW5wdXQuaWRdID0ge1xuICAgICAgICAgICAgaW5wdXQ6IG1pZGlJbnB1dCxcbiAgICAgICAgICAgIGxpc3RlbmVyOiBsaXN0ZW5lclxuICAgICAgICB9O1xuICAgIH1cbn07XG5cbi8qKlxuICogRGV0YWNoIHRoaXMgaW5zdGFuY2UgZnJvbSBvbmUgb3Igc2V2ZXJhbCBNSURJSW5wdXRcbiAqIEBwYXJhbSB7TUlESUFjY2Vzc3xNSURJSW5wdXRNYXB8TUlESUlucHV0fE1JRElJbnB1dFtdfSBtaWRpSW5wdXRcbiAqIEByZXR1cm5zIHtTaW1wbGVNaWRpSW5wdXR9IEluc3RhbmNlIGZvciBtZXRob2QgY2hhaW5pbmdcbiAqL1xuU2ltcGxlTWlkaUlucHV0LnByb3RvdHlwZS5kZXRhY2ggPSBmdW5jdGlvbiAobWlkaUlucHV0KSB7XG4gICAgdmFyIGlucHV0cyA9IG5vcm1hbGl6ZUlucHV0cyhtaWRpSW5wdXQpO1xuXG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCBpbnB1dHMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgdGhpcy5kZXRhY2hJbmRpdmlkdWFsKGlucHV0c1tpXSk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHRoaXM7XG59O1xuXG4vKipcbiAqIERldGFjaCB0aGlzIGluc3RhbmNlIGZyb20gYSBnaXZlbiBNSURJSW5wdXRcbiAqIEBwcml2YXRlXG4gKiBAcGFyYW0ge01JRElJbnB1dH0gbWlkaUlucHV0XG4gKi9cblNpbXBsZU1pZGlJbnB1dC5wcm90b3R5cGUuZGV0YWNoSW5kaXZpZHVhbCA9IGZ1bmN0aW9uIChtaWRpSW5wdXQpIHtcbiAgICBpZiAoISF0aGlzLmlubmVyRXZlbnRMaXN0ZW5lcnNbbWlkaUlucHV0LmlkXSkge1xuICAgICAgICB2YXIgbGlzdGVuZXIgPSB0aGlzLmlubmVyRXZlbnRMaXN0ZW5lcnNbbWlkaUlucHV0LmlkXS5saXN0ZW5lcjtcbiAgICAgICAgbWlkaUlucHV0ID0gdGhpcy5pbm5lckV2ZW50TGlzdGVuZXJzW21pZGlJbnB1dC5pZF0uaW5wdXQ7XG5cbiAgICAgICAgbWlkaUlucHV0LnJlbW92ZUV2ZW50TGlzdGVuZXIoXCJtaWRpbWVzc2FnZVwiLCBsaXN0ZW5lcik7XG4gICAgICAgIGRlbGV0ZSB0aGlzLmlubmVyRXZlbnRMaXN0ZW5lcnNbbWlkaUlucHV0LmlkXTtcbiAgICB9XG59O1xuXG4vKipcbiAqIERldGFjaCB0aGlzIGluc3RhbmNlIGZyb20gZXZlcnl0aGluZ1xuICogQHJldHVybnMge1NpbXBsZU1pZGlJbnB1dH0gSW5zdGFuY2UgZm9yIG1ldGhvZCBjaGFpbmluZ1xuICovXG5TaW1wbGVNaWRpSW5wdXQucHJvdG90eXBlLmRldGFjaEFsbCA9IGZ1bmN0aW9uICgpIHtcbiAgICBmb3IgKHZhciBpZCBpbiB0aGlzLmlubmVyRXZlbnRMaXN0ZW5lcnMpIHtcbiAgICAgICAgaWYgKHRoaXMuaW5uZXJFdmVudExpc3RlbmVycy5oYXNPd25Qcm9wZXJ0eShpZCkpIHtcbiAgICAgICAgICAgIHZhciBtaWRpSW5wdXQgPSB0aGlzLmlubmVyRXZlbnRMaXN0ZW5lcnNbbWlkaUlucHV0LmlkXS5pbnB1dDtcbiAgICAgICAgICAgIHZhciBsaXN0ZW5lciA9IHRoaXMuaW5uZXJFdmVudExpc3RlbmVyc1ttaWRpSW5wdXQuaWRdLmxpc3RlbmVyO1xuXG4gICAgICAgICAgICBtaWRpSW5wdXQucmVtb3ZlRXZlbnRMaXN0ZW5lcihcIm1pZGltZXNzYWdlXCIsIGxpc3RlbmVyKTtcbiAgICAgICAgfVxuICAgIH1cblxuICAgIHRoaXMuaW5uZXJFdmVudExpc3RlbmVycyA9IHt9O1xuXG4gICAgcmV0dXJuIHRoaXM7XG59O1xuXG4vKipcbiAqIFBhcnNlIGFuIGluY29taW5nIG1pZGkgbWVzc2FnZVxuICogQHByaXZhdGVcbiAqIEBwYXJhbSB7VUludDhBcnJheX0gZGF0YSAtIE1pZGkgbWVzYWdlIGRhdGFcbiAqIEByZXR1cm5zIHtPYmplY3R9IE1pZGkgZXZlbnQsIGFzIGEgcmVhZGFibGUgb2JqZWN0XG4gKi9cblNpbXBsZU1pZGlJbnB1dC5wcm90b3R5cGUucGFyc2VNaWRpTWVzc2FnZSA9IGZ1bmN0aW9uIChkYXRhKSB7XG4gICAgdmFyIGV2ZW50O1xuXG4gICAgc3dpdGNoIChkYXRhWzBdKSB7XG4gICAgICAgIGNhc2UgMHgwMDpcbiAgICAgICAgICAgIC8vc29tZSBpT1MgYXBwIGFyZSBzZW5kaW5nIGEgbWFzc2l2ZSBhbW91bnQgb2Ygc2VlbWluZ2x5IGVtcHR5IG1lc3NhZ2VzLCBpZ25vcmUgdGhlbVxuICAgICAgICAgICAgcmV0dXJuIG51bGw7XG4gICAgICAgIGNhc2UgMHhGMjpcbiAgICAgICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgICAgIGV2ZW50OiAnc29uZ1Bvc2l0aW9uJyxcbiAgICAgICAgICAgICAgICBwb3NpdGlvbjogcmVhZFZMUShkYXRhWzFdLCBkYXRhWzJdKSxcbiAgICAgICAgICAgICAgICBkYXRhOiBkYXRhXG4gICAgICAgICAgICB9O1xuICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgIGNhc2UgMHhGMzpcbiAgICAgICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgICAgIGV2ZW50OiAnc29uZ1NlbGVjdCcsXG4gICAgICAgICAgICAgICAgc29uZzogZGF0YVsxXSxcbiAgICAgICAgICAgICAgICBkYXRhOiBkYXRhXG4gICAgICAgICAgICB9O1xuICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgIGNhc2UgMHhGNjpcbiAgICAgICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgICAgIGV2ZW50OiAndHVuZVJlcXVlc3QnLFxuICAgICAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgICAgIH07XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgY2FzZSAweEY4OlxuICAgICAgICAgICAgZXZlbnQgPSB7XG4gICAgICAgICAgICAgICAgZXZlbnQ6ICdjbG9jaycsXG4gICAgICAgICAgICAgICAgY29tbWFuZDogJ2Nsb2NrJyxcbiAgICAgICAgICAgICAgICBkYXRhOiBkYXRhXG4gICAgICAgICAgICB9O1xuICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgIGNhc2UgMHhGQTpcbiAgICAgICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgICAgIGV2ZW50OiAnY2xvY2snLFxuICAgICAgICAgICAgICAgIGNvbW1hbmQ6ICdzdGFydCcsXG4gICAgICAgICAgICAgICAgZGF0YTogZGF0YVxuICAgICAgICAgICAgfTtcbiAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICBjYXNlIDB4RkI6XG4gICAgICAgICAgICBldmVudCA9IHtcbiAgICAgICAgICAgICAgICBldmVudDogJ2Nsb2NrJyxcbiAgICAgICAgICAgICAgICBjb21tYW5kOiAnY29udGludWUnLFxuICAgICAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgICAgIH07XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgY2FzZSAweEZDOlxuICAgICAgICAgICAgZXZlbnQgPSB7XG4gICAgICAgICAgICAgICAgZXZlbnQ6ICdjbG9jaycsXG4gICAgICAgICAgICAgICAgY29tbWFuZDogJ3N0b3AnLFxuICAgICAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgICAgIH07XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgY2FzZSAweEZFOlxuICAgICAgICAgICAgZXZlbnQgPSB7XG4gICAgICAgICAgICAgICAgZXZlbnQ6ICdhY3RpdmVTZW5zaW5nJyxcbiAgICAgICAgICAgICAgICBkYXRhOiBkYXRhXG4gICAgICAgICAgICB9O1xuICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgIGNhc2UgMHhGRjpcbiAgICAgICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgICAgIGV2ZW50OiAncmVzZXQnLFxuICAgICAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgICAgIH07XG4gICAgICAgICAgICBicmVhaztcbiAgICB9XG5cbiAgICBpZiAoZGF0YVswXSA+PSAweEUwICYmIGRhdGFbMF0gPCAweEYwKSB7XG4gICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgZXZlbnQ6ICdwaXRjaFdoZWVsJyxcbiAgICAgICAgICAgIGNoYW5uZWw6IDEgKyBkYXRhWzBdIC0gMHhFMCxcbiAgICAgICAgICAgIHZhbHVlOiByZWFkVkxRKGRhdGFbMV0sIGRhdGFbMl0pIC0gMHgyMDAwLFxuICAgICAgICAgICAgZGF0YTogZGF0YVxuICAgICAgICB9O1xuICAgIH0gZWxzZSBpZiAoZGF0YVswXSA+PSAweEQwICYmIGRhdGFbMF0gPCAweEUwKSB7XG4gICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgZXZlbnQ6ICdjaGFubmVsQWZ0ZXJ0b3VjaCcsXG4gICAgICAgICAgICBjaGFubmVsOiAxICsgZGF0YVswXSAtIDB4RDAsXG4gICAgICAgICAgICBwcmVzc3VyZTogZGF0YVsxXSxcbiAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgfTtcbiAgICB9IGVsc2UgaWYgKGRhdGFbMF0gPj0gMHhDMCAmJiBkYXRhWzBdIDwgMHhEMCkge1xuICAgICAgICBldmVudCA9IHtcbiAgICAgICAgICAgIGV2ZW50OiAncHJvZ3JhbUNoYW5nZScsXG4gICAgICAgICAgICBjaGFubmVsOiAxICsgZGF0YVswXSAtIDB4QzAsXG4gICAgICAgICAgICBwcm9ncmFtOiBkYXRhWzFdLFxuICAgICAgICAgICAgZGF0YTogZGF0YVxuICAgICAgICB9O1xuICAgIH0gZWxzZSBpZiAoZGF0YVswXSA+PSAweEIwICYmIGRhdGFbMF0gPCAweEMwKSB7XG4gICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgZXZlbnQ6ICdjYycsXG4gICAgICAgICAgICBjaGFubmVsOiAxICsgZGF0YVswXSAtIDB4QjAsXG4gICAgICAgICAgICBjYzogZGF0YVsxXSxcbiAgICAgICAgICAgIHZhbHVlOiBkYXRhWzJdLFxuICAgICAgICAgICAgZGF0YTogZGF0YVxuICAgICAgICB9O1xuICAgIH0gZWxzZSBpZiAoZGF0YVswXSA+PSAweEEwICYmIGRhdGFbMF0gPCAweEIwKSB7XG4gICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgZXZlbnQ6ICdwb2x5cGhvbmljQWZ0ZXJ0b3VjaCcsXG4gICAgICAgICAgICBjaGFubmVsOiAxICsgZGF0YVswXSAtIDB4QTAsXG4gICAgICAgICAgICBrZXk6IGRhdGFbMV0sXG4gICAgICAgICAgICBwcmVzc3VyZTogZGF0YVsyXSxcbiAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgfTtcbiAgICB9IGVsc2UgaWYgKGRhdGFbMF0gPj0gMHg5MCAmJiBkYXRhWzBdIDwgMHhBMCkge1xuICAgICAgICBldmVudCA9IHtcbiAgICAgICAgICAgIGV2ZW50OiAnbm90ZU9uJyxcbiAgICAgICAgICAgIGNoYW5uZWw6IDEgKyBkYXRhWzBdIC0gMHg5MCxcbiAgICAgICAgICAgIGtleTogZGF0YVsxXSxcbiAgICAgICAgICAgIHZlbG9jaXR5OiBkYXRhWzJdLFxuICAgICAgICAgICAgZGF0YTogZGF0YVxuICAgICAgICB9O1xuXG4gICAgICAgIC8vYWJzdHJhY3RpbmcgdGhlIGZhY3QgdGhhdCBhIG5vdGVPbiB3aXRoIGEgdmVsb2NpdHkgb2YgMCBpcyBzdXBwb3NlZCB0byBiZSBlcXVhbCB0byBhIG5vdGVPZmYgbWVzc2FnZVxuICAgICAgICBpZiAoZXZlbnQudmVsb2NpdHkgPT09IDApIHtcbiAgICAgICAgICAgIGV2ZW50LnZlbG9jaXR5ID0gMTI3O1xuICAgICAgICAgICAgZXZlbnQuZXZlbnQgPSAnbm90ZU9mZic7XG4gICAgICAgIH1cbiAgICB9IGVsc2UgaWYgKGRhdGFbMF0gPj0gMHg4MCAmJiBkYXRhWzBdIDwgMHg5MCkge1xuICAgICAgICBldmVudCA9IHtcbiAgICAgICAgICAgIGV2ZW50OiAnbm90ZU9mZicsXG4gICAgICAgICAgICBjaGFubmVsOiAxICsgZGF0YVswXSAtIDB4ODAsXG4gICAgICAgICAgICBrZXk6IGRhdGFbMV0sXG4gICAgICAgICAgICB2ZWxvY2l0eTogZGF0YVsyXSxcbiAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBpZiAoIWV2ZW50KSB7XG4gICAgICAgIGV2ZW50ID0ge1xuICAgICAgICAgICAgZXZlbnQ6ICd1bmtub3duJyxcbiAgICAgICAgICAgIGRhdGE6IGRhdGFcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICByZXR1cm4gZXZlbnQ7XG59O1xuXG4vKipcbiAqIFByb2Nlc3MgYW4gaW5jb21pbmcgbWlkaSBtZXNzYWdlIGFuZCB0cmlnZ2VyIHRoZSBtYXRjaGluZyBldmVudFxuICogQHByaXZhdGVcbiAqIEBwYXJhbSB7VUludDhBcnJheX0gZGF0YSAtIE1pZGkgbWVzYWdlIGRhdGFcbiAqIEByZXR1cm5zIHtTaW1wbGVNaWRpSW5wdXR9IEluc3RhbmNlIGZvciBtZXRob2QgY2hhaW5pbmdcbiAqL1xuU2ltcGxlTWlkaUlucHV0LnByb3RvdHlwZS5wcm9jZXNzTWlkaU1lc3NhZ2UgPSBmdW5jdGlvbiAoZGF0YSkge1xuICAgIHZhciBldmVudCA9IHRoaXMucGFyc2VNaWRpTWVzc2FnZShkYXRhKTtcblxuICAgIGlmIChldmVudCkge1xuICAgICAgICBpZiAodGhpcy5maWx0ZXIpIHtcbiAgICAgICAgICAgIGlmICh0aGlzLmZpbHRlcihldmVudCkgPT09IGZhbHNlKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBpZiAoISFldmVudC5jYykge1xuICAgICAgICAgICAgdGhpcy50cmlnZ2VyKGV2ZW50LmV2ZW50ICsgZXZlbnQuY2MsIGV2ZW50KTtcbiAgICAgICAgICAgIHRoaXMudHJpZ2dlcihldmVudC5jaGFubmVsICsgJy4nICsgZXZlbnQuZXZlbnQgKyBldmVudC5jYywgZXZlbnQpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgdGhpcy50cmlnZ2VyKGV2ZW50LmV2ZW50LCBldmVudCk7XG4gICAgICAgICAgICBpZiAoISFldmVudC5jaGFubmVsKSB7XG4gICAgICAgICAgICAgICAgdGhpcy50cmlnZ2VyKGV2ZW50LmNoYW5uZWwgKyAnLicgKyBldmVudC5ldmVudCwgZXZlbnQpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgdGhpcy50cmlnZ2VyKCdnbG9iYWwnLCBldmVudCk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHRoaXM7XG59O1xuXG4vKipcbiAqIFNldCB0aGUgZmlsdGVyIGZ1bmN0aW9uXG4gKiBAcGFyYW0ge0Z1bmN0aW9ufSBbZmlsdGVyXSAtIEZpbHRlciBmdW5jdGlvblxuICogQHJldHVybnMge1NpbXBsZU1pZGlJbnB1dH0gSW5zdGFuY2UgZm9yIG1ldGhvZCBjaGFpbmluZ1xuICovXG5TaW1wbGVNaWRpSW5wdXQucHJvdG90eXBlLnNldEZpbHRlciA9IGZ1bmN0aW9uIChmaWx0ZXIpIHtcbiAgICBpZiAoaXNGdW5jdGlvbihmaWx0ZXIpKSB7XG4gICAgICAgIHRoaXMuZmlsdGVyID0gZmlsdGVyO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIGRlbGV0ZSB0aGlzLmZpbHRlcjtcbiAgICB9XG5cbiAgICByZXR1cm4gdGhpcztcbn07XG5cbi8qKlxuICogU3Vic2NyaWJlIHRvIGFuIGV2ZW50XG4gKiBAcGFyYW0ge1N0cmluZ30gZXZlbnQgLSBOYW1lIG9mIHRoZSBldmVudFxuICogQHBhcmFtIHtOdW1iZXJ9IFtjaGFubmVsXSAtIENoYW5uZWwgb2YgdGhlIGV2ZW50XG4gKiBAcGFyYW0ge0Z1bmN0aW9ufSBmdW5jIC0gQ2FsbGJhY2sgZm9yIHRoZSBldmVudFxuICogQHJldHVybnMge1NpbXBsZU1pZGlJbnB1dH0gSW5zdGFuY2UgZm9yIG1ldGhvZCBjaGFpbmluZ1xuICovXG5TaW1wbGVNaWRpSW5wdXQucHJvdG90eXBlLm9uID0gZnVuY3Rpb24gKGV2ZW50LCBjaGFubmVsLCBmdW5jKSB7XG4gICAgaWYgKGlzRnVuY3Rpb24oY2hhbm5lbCkpIHtcbiAgICAgICAgZnVuYyA9IGNoYW5uZWw7XG4gICAgfSBlbHNlIGlmIChpc051bWVyaWMoY2hhbm5lbCkpIHtcbiAgICAgICAgZXZlbnQgPSBjaGFubmVsICsgJy4nICsgZXZlbnQ7XG4gICAgfVxuXG4gICAgaWYgKCF0aGlzLmV2ZW50c1tldmVudF0pIHtcbiAgICAgICAgdGhpcy5ldmVudHNbZXZlbnRdID0gW107XG4gICAgfVxuXG4gICAgdGhpcy5ldmVudHNbZXZlbnRdLnB1c2goZnVuYyk7XG5cbiAgICByZXR1cm4gdGhpcztcbn07XG5cbi8qKlxuICogVW5zdWJzY3JpYmUgdG8gYW4gZXZlbnRcbiAqIEBwYXJhbSB7U3RyaW5nfSBldmVudCAtIE5hbWUgb2YgdGhlIGV2ZW50XG4gKiBAcGFyYW0ge051bWJlcn0gW2NoYW5uZWxdIC0gQ2hhbm5lbCBvZiB0aGUgZXZlbnRcbiAqIEBwYXJhbSB7RnVuY3Rpb259IFtmdW5jXSAtIENhbGxiYWNrIHRvIHJlbW92ZSAoaWYgbm9uZSwgYWxsIGFyZSByZW1vdmVkKVxuICogQHJldHVybnMge1NpbXBsZU1pZGlJbnB1dH0gSW5zdGFuY2UgZm9yIG1ldGhvZCBjaGFpbmluZ1xuICovXG5TaW1wbGVNaWRpSW5wdXQucHJvdG90eXBlLm9mZiA9IGZ1bmN0aW9uIChldmVudCwgY2hhbm5lbCwgZnVuYykge1xuICAgIGlmIChpc0Z1bmN0aW9uKGNoYW5uZWwpKSB7XG4gICAgICAgIGZ1bmMgPSBjaGFubmVsO1xuICAgIH0gZWxzZSBpZiAoaXNOdW1lcmljKGNoYW5uZWwpKSB7XG4gICAgICAgIGV2ZW50ID0gY2hhbm5lbCArICcuJyArIGV2ZW50O1xuICAgIH1cblxuICAgIGlmICghZnVuYykge1xuICAgICAgICBkZWxldGUgdGhpcy5ldmVudHNbZXZlbnRdO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIHZhciBwb3MgPSB0aGlzLmV2ZW50c1tldmVudF0uaW5kZXhPZihmdW5jKTtcbiAgICAgICAgaWYgKHBvcyA+PSAwKSB7XG4gICAgICAgICAgICB0aGlzLmV2ZW50c1tldmVudF0uc3BsaWNlKHBvcywgMSk7XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4gdGhpcztcbn07XG5cbi8qKlxuICogVHJpZ2dlciBhbiBldmVudFxuICogQHBhcmFtIHtTdHJpbmd9IGV2ZW50IC0gTmFtZSBvZiB0aGUgZXZlbnRcbiAqIEBwYXJhbSB7QXJyYXl9IGFyZ3MgLSBBcmd1bWVudHMgdG8gcGFzcyB0byB0aGUgY2FsbGJhY2tzXG4gKiBAcmV0dXJucyB7U2ltcGxlTWlkaUlucHV0fSBJbnN0YW5jZSBmb3IgbWV0aG9kIGNoYWluaW5nXG4gKi9cblNpbXBsZU1pZGlJbnB1dC5wcm90b3R5cGUudHJpZ2dlciA9IGZ1bmN0aW9uIChldmVudCwgYXJncykge1xuICAgIGlmICghIXRoaXMuZXZlbnRzW2V2ZW50XSAmJiB0aGlzLmV2ZW50c1tldmVudF0ubGVuZ3RoKSB7XG4gICAgICAgIGZvciAodmFyIGwgPSB0aGlzLmV2ZW50c1tldmVudF0ubGVuZ3RoOyBsLS07KSB7XG4gICAgICAgICAgICB0aGlzLmV2ZW50c1tldmVudF1bbF0uY2FsbCh0aGlzLCBhcmdzKTtcbiAgICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiB0aGlzO1xufTtcblxuLyoqXG4gKiBSZXR1cm4gYW4gaW5zdGFuY2Ugb2YgdGhlIE1pZGlMZWFybiBoYW5kbGluZyBjbGFzc1xuICogQHByaXZhdGVcbiAqIEByZXR1cm5zIHtNaWRpTGVhcm59IEluc3RhbmNlIG9mIE1pZGlMZWFyblxuICovXG5TaW1wbGVNaWRpSW5wdXQucHJvdG90eXBlLmdldE1pZGlMZWFybkluc3RhbmNlID0gZnVuY3Rpb24gKCkge1xuICAgIGlmICghdGhpcy5taWRpTGVhcm4pIHtcbiAgICAgICAgdGhpcy5taWRpTGVhcm4gPSBuZXcgTWlkaUxlYXJuKHRoaXMpO1xuICAgIH1cblxuICAgIHJldHVybiB0aGlzLm1pZGlMZWFybjtcbn07XG5cbi8qKlxuICogUmV0dXJuIGFuIGluc3RhbmNlIG9mIE1pZGlMZWFybmluZyBmb3IgYSBnaXZlbiBwYXJhbWV0ZXJcbiAqIEBwYXJhbSB7T2JqZWN0fSBvcHRpb25zIC0gT3B0aW9ucyBvZiB0aGUgcGFyYW1ldGVyIChpZCwgbWluLCBtYXgsIHZhbHVlLCBldmVudHMpXG4gKiBAcmV0dXJucyB7TWlkaUxlYXJuaW5nfVxuICovXG5TaW1wbGVNaWRpSW5wdXQucHJvdG90eXBlLmdldE1pZGlMZWFybmluZyA9IGZ1bmN0aW9uIChvcHRpb25zKSB7XG4gICAgcmV0dXJuIHRoaXMuZ2V0TWlkaUxlYXJuSW5zdGFuY2UoKS5nZXRNaWRpTGVhcm5pbmcob3B0aW9ucyk7XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IFNpbXBsZU1pZGlJbnB1dDtcbiJdfQ==
