(function(global, factory) {
  /* istanbul ignore next */
  if (typeof exports === 'object' && typeof module !== 'undefined') {
    module.exports = factory;
  }
  else if (typeof define === 'function' && define.amd) {
    define('JZZ.midi.GM', ['JZZ'], factory);
  }
  else {
    factory(JZZ);
  }
})(this, function(JZZ) {

var i;

var _group = ['Piano', 'Chromatic Percussion', 'Organ', 'Guitar', 'Bass', 'Strings', 'Ensemble', 'Brass', 'Reed', 'Pipe', 'Synth Lead', 'Synth Pad', 'Synth Effects', 'Ethnic', 'Percussive', 'Sound Effects'];

var _instr = [
'Acoustic Grand Piano', 'Bright Acoustic Piano', 'Electric Grand Piano', 'Honky-tonk Piano', 'Electric Piano 1', 'Electric Piano 2', 'Harpsichord', 'Clavinet', 
'Celesta', 'Glockenspiel', 'Music Box', 'Vibraphone', 'Marimba', 'Xylophone', 'Tubular Bells', 'Dulcimer', 
'Drawbar Organ', 'Percussive Organ', 'Rock Organ', 'Church Organ', 'Reed Organ', 'Accordion', 'Harmonica', 'Tango Accordion', 
'Acoustic Guitar (nylon)', 'Acoustic Guitar (steel)', 'Electric Guitar (jazz)', 'Electric Guitar (clean)', 'Electric Guitar (muted)', 'Overdriven Guitar', 'Distortion Guitar', 'Guitar Harmonics', 
'Acoustic Bass', 'Electric Bass (finger)', 'Electric Bass (pick)', 'Fretless Bass', 'Slap Bass 1', 'Slap Bass 2', 'Synth Bass 1', 'Synth Bass 2', 
'Violin', 'Viola', 'Cello', 'Contrabass', 'Tremolo Strings', 'Pizzicato Strings', 'Orchestral Harp', 'Timpani', 
'String Ensemble 1', 'String Ensemble 2', 'Synth Strings 1', 'Synth Strings 2', 'Choir Aahs', 'Voice Oohs', 'Synth Choir', 'Orchestra Hit', 
'Trumpet', 'Trombone', 'Tuba', 'Muted Trumpet', 'French Horn', 'Brass Section', 'Synth Brass 1', 'Synth Brass 2', 
'Soprano Sax', 'Alto Sax', 'Tenor Sax', 'Baritone Sax', 'Oboe', 'English Horn', 'Bassoon', 'Clarinet', 
'Piccolo', 'Flute', 'Recorder', 'Pan Flute', 'Blown Bottle', 'Shakuhachi', 'Whistle', 'Ocarina', 
'Lead 1 (square)', 'Lead 2 (sawtooth)', 'Lead 3 (calliope)', 'Lead 4 (chiff)', 'Lead 5 (charang)', 'Lead 6 (voice)', 'Lead 7 (fifths)', 'Lead 8 (bass + lead)', 
'Pad 1 (new age)', 'Pad 2 (warm)', 'Pad 3 (polysynth)', 'Pad 4 (choir)', 'Pad 5 (bowed)', 'Pad 6 (metallic)', 'Pad 7 (halo)', 'Pad 8 (sweep)', 
'FX 1 (rain)', 'FX 2 (soundtrack)', 'FX 3 (crystal)', 'FX 4 (atmosphere)', 'FX 5 (brightness)', 'FX 6 (goblins)', 'FX 7 (echoes)', 'FX 8 (sci-fi)', 
'Sitar', 'Banjo', 'Shamisen', 'Koto', 'Kalimba', 'Bagpipe', 'Fiddle', 'Shanai', 
'Tinkle Bell', 'Agogo', 'Steel Drums', 'Woodblock', 'Taiko Drum', 'Melodic Tom', 'Synth Drum', 'Reverse Cymbal', 
'Guitar Fret Noise', 'Breath Noise', 'Seashore', 'Bird Tweet', 'Telephone Ring', 'Helicopter', 'Applause', 'Gunshot'
];

var _perc = [
'High-Q', 'Slap', 'Scratch Push', 'Scratch Pull', 'Sticks', 'Square Click', 'Metronome Click', 'Metronome Bell', 
'Acoustic Bass Drum', 'Bass Drum 1', 'Side Stick', 'Acoustic Snare', 'Hand Clap', 'Electric Snare', 'Low Floor Tom', 'Closed Hi Hat', 
'High Floor Tom', 'Pedal Hi-Hat', 'Low Tom', 'Open Hi-Hat', 'Low-Mid Tom', 'Hi-Mid Tom', 'Crash Cymbal 1', 'High Tom', 
'Ride Cymbal 1', 'Chinese Cymbal', 'Ride Bell', 'Tambourine', 'Splash Cymbal', 'Cowbell', 'Crash Cymbal 2', 'Vibraslap', 
'Ride Cymbal 2', 'Hi Bongo', 'Low Bongo', 'Mute Hi Conga', 'Open Hi Conga', 'Low Conga', 'High Timbale', 'Low Timbale', 
'High Agogo', 'Low Agogo', 'Cabasa', 'Maracas', 'Short Whistle', 'Long Whistle', 'Short Guiro', 'Long Guiro', 
'Claves', 'Hi Wood Block', 'Low Wood Block', 'Mute Cuica', 'Open Cuica', 'Mute Triangle', 'Open Triangle', 'Shaker', 
'Jingle Bell', 'Bell Tree', 'Castanets', 'Mute Surdo', 'Open Surdo'
];

var _more = {
'Hammond': 17, 'Keyboard': 18, 'Uke': 24, 'Ukulele': 24, 'Fuzz': 30, 'Sax': 66, 'Saxophone': 66,
'Soprano Saxophone': 64, 'Alto Saxophone': 65, 'Tenor Saxophone': 66, 'Baritone Saxophone': 67
};

//#begin
var _gs = [
{0:"Piano 1",1:"Upright Piano",2:"Mild Piano",8:"Upright Piano Wide",9:"Mild Piano Wide",16:"European Pianoforte",24:"Piano + Strings",25:"Piano + Strings 2",26:"Piano + Choir 1",27:"Piano + Choir 2"},
{0:"Piano 2",1:"Pop Piano",2:"Rock Piano",8:"Pop Piano Wide",9:"Rock Piano Wide",16:"Dance Piano"},
{0:"Piano 3",1:"Electric Grand Piano + Rhodes 1",2:"Electric Grand Piano + Rhodes 2",8:"Piano 3 Wide"},
{0:"Honky-tonk",8:"Honky-tonk 2"},
{0:"Electric Piano 1",8:"Synth Soft Electric Piano",9:"Chorus Electric Piano",10:"Silent Rhodes Piano",16:"FM + SA Electric Piano",17:"Distortion Electric Piano",24:"Wurly",25:"Hard Rhodes Piano",26:"Mellow Rhodes Piano"},
{0:"Electric Piano 2",1:"Electric Piano 3",8:"Detuned Electric Piano 2",9:"Detuned Electric Piano 3",10:"Electric Piano Legend",16:"Synth FM Electric Piano",24:"Hard FM Electric Piano",32:"Electric Piano Phase"},
{0:"Harpsichord",1:"Harpsichord 2",2:"Harpsichord 3",8:"Coupled Harpsichord",16:"Harpsichord Wide",24:"Harpsichord Overdriven",32:"Synth Harpsichord"},
{0:"Clavinet",1:"Clavinet 2",2:"Attack Clavinet 1",3:"Attack Clavinet 2",8:"Comp Clavinet",16:"Resonant Clavinet",17:"Phase Clavinet",24:"Clavinet Overdriven",32:"Analog Clavinet",33:"JP8 Clavinet 1",35:"JP8 Clavinet 2",36:"Synth Ring Clavinet",37:"Synth Distortion Clavinet",38:"JP8000 Clavinet",39:"Pulse Clavinet"},
{0:"Celesta",1:"Pop Celesta"},
{0:"Glockenspiel"},
{0:"Music Box",1:"Music Box 2",8:"Synth Music Box"},
{0:"Vibraphone",1:"Pop Vibraphone",8:"Vibraphone Wide",9:"Vibraphones"},
{0:"Marimba",8:"Marimba Wide",16:"Barafon",17:"Barafon 2",24:"Log drum"},
{0:"Xylophone",8:"Xylophone Wide"},
{0:"Tubular Bells",8:"Church Bell",9:"Carillon",10:"Church Bell 2",16:"Tubular Bell Wide"},
{0:"Santur",1:"Santur 2",2:"Santur 3",8:"Cimbalom",16:"Zither 1",17:"Zither 2",24:"Dulcimer"},
{0:"Organ 1",1:"Organ 101",2:"Full Organ 1",3:"Full Organ 2",4:"Full Organ 3",5:"Full Organ 4",6:"Full Organ 5",7:"Full Organ 6",8:"Tremolo Organ",9:"Organ Overdriven",10:"Full Organ 7",11:"Full Organ 8",12:"Full Organ 9",16:"60's Organ 1",17:"60's Organ 2",18:"60's Organ 3",19:"Farf Organ",24:"Cheese Organ",25:"D-50 Organ",26:"JUNO Organ",27:"Hybrid Organ",28:"VS Organ",29:"Digital Church Organ",30:"JX-8P Organ",31:"FM Organ",32:"70's Electric Organ",33:"Even Bar Organ",40:"Organ Bass",48:"5th Organ"},
{0:"Organ 2",1:"Jazz Organ",2:"Electric Organ 16+2",3:"Jazz Organ 2",4:"Jazz Organ 3",5:"Jazz Organ 4",6:"Jazz Organ 5",7:"Jazz Organ 6",8:"Chorus Organ 2",9:"Octave Organ",32:"Percussive Organ",33:"Percussive Organ 2",34:"Percussive Organ 3",35:"Percussive Organ 4"},
{0:"Organ 3",8:"Rotary Organ 1",16:"Rotary Organ Slow",17:"Rock Organ 1",18:"Rock Organ 2",24:"Rotary Organ Fast"},
{0:"Church Organ 1",8:"Church Organ 2",16:"Church Organ 3",24:"Organ Flute",32:"Tremolo Flute",33:"Theater Organ"},
{0:"Reed Organ",8:"Wind Organ",16:"Puff Organ"},
{0:"Accordion French",8:"Accordion Italian",9:"Distortion Accordion",16:"Chorus Accordion",24:"Hard Accordion",25:"Soft Accordion"},
{0:"Harmonica",1:"Harmonica 2",8:"B. Harp Basic",9:"B. Harp Suppl"},
{0:"Bandoneon",8:"Bandoneon 2",16:"Bandoneon 3"},
{0:"Nylon String Guitar",8:"Ukulele",16:"Nylon String Guitar Overdriven",24:"Velo Harmonics",32:"Nylon String Guitar 2",40:"Lequint Guitar"},
{0:"Steel String Guitar",8:"12-String Guitar",9:"Nylon + Steel String Guitar",10:"Attack Steel String Guitar",16:"Mandolin",17:"Mandolin 2",18:"Mandolin Tremolo",32:"Steel String Guitar 2",33:"Steel String Guitar with Body Sound"},
{0:"Jazz Guitar",1:"Mellow Guitar",8:"Pedal Steel Guitar"},
{0:"Clean Guitar",1:"Clean Half Guitar",2:"Open Hard Guitar 1",3:"Open Hard Guitar 2",4:"Stratocaster Clean Guitar",5:"Attack Clean Guitar",8:"Chorus Guitar",9:"Stratocaster Chorus Guitar",16:"Telecaster Front Pick",17:"Telecaster Rear Pick",18:"Telecaster Clean ff",19:"Telecaster Clean 2:",20:"Les Paul Rear Pick",21:"Les Paul Rear 2",22:"Les Paul Rear Attack",23:"Mid Tone Guitar",24:"Chung Ruan",25:"Chung Ruan 2"},
{0:"Muted Guitar",1:"Muted Distortion Guitar",2:"Telecaster Muted Guitar",8:"Funk Pop Guitar",16:"Funk Guitar 2",24:"Jazz Man"},
{0:"Overdrive Guitar",1:"Overdrive Guitar 2",2:"Overdrive Guitar 3",3:"More Drive Guitar",4:"Guitar Pinch",5:"Attack Drive Guitar",8:"Les Paul Overdrive Guitar",9:"Les Paul Overdrive Guitar:",10:"Les Paul Half Drive",11:"Les Paul Half Drive 2",12:"Les Paul Chorus"},
{0:"Distortion Guitar",1:"Distortion Guitar 2",2:"Dazed Guitar",3:"Distortion Guitar:",4:"Distortion Fast Guitar",5:"Attack Dist",8:"Feedback Guitar",9:"Feedback Guitar 2",16:"Power Guitar",17:"Power Guitar 2",18:"5th Distortion",24:"Rock Rhythm Guitar",25:"Rock Rhythm Guitar 2",26:"Distortion Rhythm Guitar"},
{0:"Guitar Harmonics",8:"Guitar Feedback",9:"Guitar Feedback 2",16:"Acoustic Guitar Harmonics",24:"Electric Bass Harmonics"},
{0:"Acoustic Bass",1:"Rockabilly Bass",8:"Wild Acoustic Bass",9:"Attack Acoustic Bass",16:"Bass + OHH"},
{0:"Fingered Bass",1:"Fingered Bass 2",2:"Jazz Bass",3:"Jazz Bass 2",4:"Rock Bass",5:"Heart Bass",6:"Attack Finger",7:"Finger Slap",8:"Chorus Jazz Bass",16:"Fingered Bass/Harmonics"},
{0:"Picked Bass",1:"Picked Bass 2",2:"Picked Bass 3",3:"Picked Bass 4",4:"Double Pick",8:"Muted Pick Bass",16:"Picked Bass/Harmonics"},
{0:"Fretless Bass",1:"Fretless Bass 2",2:"Fretless Bass 3",3:"Fretless Bass 4",4:"Synth Fretless Bass",5:"Mr.Smooth",8:"Wood+Fretless Bass"},
{0:"Slap Bass 1",1:"Slap Pop",8:"Resonant Slap Bass",9:"Unison Slap"},
{0:"Slap Bass 2",1:"Slap Bass 3",8:"FM Slap Bass"},
{0:"Synth Bass 1",1:"Synth Bass 101",2:"CS Bass",3:"JP-4 Bass",4:"JP-8 Bass",5:"P5 Bass",6:"JPMG Bass",8:"Acid Bass",9:"TB303 Bass",10:"Tekno Bass",11:"TB303 Bass 2",12:"Kicked TB303",13:"TB303 Saw Bass",14:"Rubber303 Bass",15:"Resonant 303 Bass",16:"Resonant SH Bass",17:"TB303 Square Bass",18:"TB303 Distortion Bass",19:"Clavi Bass",20:"Hammer",21:"Jungle Bass",22:"Square Bass",23:"Square Bass 2",24:"Arpeggio Bass",32:"Hit & Saw Bass",33:"Ring Bass",34:"Attack Sine Bass",35:"OB sine Bass",36:"Auxiliary Bass",40:"303 Square Distortion Bass",41:"303 Square Distortion Bass 2",42:"303 Square Distortion Bass 3",43:"303 Square Rev",44:"TeeBee"},
{0:"Synth Bass 2",1:"Synth Bass 201",2:"Modular Bass",3:"Seq Bass",4:"MG Bass",5:"Mg Octave Bass 1",6:"MG Octave Bass 2",7:"MG Blip Bass:",8:"Beef FM Bass",9:"Delay Bass",10:"X Wire Bass",11:"WireStr Bass",12:"Blip Bass:",13:"Rubber Bass 1",14:"Synth Bell Bass",15:"Odd Bass",16:"Rubber Bass 2",17:"SH101 Bass 1",18:"SH101 Bass 2",19:"Smooth Bass",20:"SH101 Bass 3",21:"Spike Bass",22:"House Bass:",23:"KG Bass",24:"Sync Bass",25:"MG 5th Bass",26:"RND Bass",27:"Wow MG Bass",28:"Bubble Bass",29:"Attack Pulse",30:"Sync Bass 2",31:"Pulse Mix Bass",32:"MG Distortion Bass",33:"Seq Bass 2",34:"3rd Bass",35:"MG Octave Bass",36:"Slow Env Bass",37:"Mild Bass",38:"Distortion Env Bass",39:"MG Light Bass",40:"Distortion Synth Bass",41:"Rise Bass",42:"Cyber Bass"},
{0:"Violin:",1:"Violin Attack:",8:"Slow Violin"},
{0:"Viola:",1:"Viola Attack:"},
{0:"Cello:",1:"Cello Attack:"},
{0:"Contrabass"},
{0:"Tremolo Strings",2:"Tremolo Strings Synth",8:"Slow Tremolo Strings",9:"Suspense Strings",10:"Suspense Strings 2"},
{0:"Pizzicato Strings",1:"Vcs & Contrabass Pizzicato Strings",2:"Chamber Pizzicato Strings",3:"Synth Pizzicato Strings",8:"Solo Pizzicato",16:"Solo Spiccato",17:"Strings Spiccato"},
{0:"Harp",1:"Harp + Strings",2:"Harp Synth",8:"Uilleann Harp",16:"Synth Harp",24:"Yang Qin",25:"Yang Qin 2",26:"Synth Yang Qin"},
{0:"Timpani"},
{0:"Strings",1:"Bright Strings:",2:"Chamber Strings",3:"Cello section",4:"Bright Strings 2",5:"Bright Strings 3",6:"Quad Strings",7:"Mild Strings",8:"Orchestra",9:"Orchestra 2",10:"Tremolo Orchestra",11:"Choir Strings",12:"Strings + Horn",13:"Strings + Flute",14:"Choir Strings 2",15:"Choir Strings 3",16:"Synth Strings",17:"Synth Strings 2",18:"Synth Strings 3",19:"Orchestra 3",20:"Orchestra 4",24:"Velo Strings",32:"Octave Strings 1",33:"Octave Strings 2",34:"Contrabass Section",40:"60s Strings"},
{0:"Slow Strings",1:"Slow Strings 2",2:"Slow Strings 3",8:"Legato Strings",9:"Warm Strings",10:"Synth Slow Strings",11:"Synth Slow Strings 2",12:"Synth Strings + Choir",13:"Synth Strings + Choir 2"},
{0:"Synth Strings 1",1:"OB Strings",2:"Stack Strings",3:"JP Strings",4:"Chorus Strings",8:"Synth Strings 3",9:"Synth Strings 4",10:"Synth Strings 6",11:"Synth Strings 7",12:"LoFi Strings",16:"High Strings",17:"Hybrid Strings",24:"Tron Strings",25:"Noiz Strings"},
{0:"Synth Strings 2",1:"Synth Strings 5",2:"JUNO Strings",3:"Filtered Orch",4:"JP Saw Strings",5:"Hybrid Strings 2",6:"Distortion Strings",7:"JUNO Full Strings",8:"Air Strings",9:"Attack Synth Strings",10:"Straight Strings"},
{0:"Choir Aahs",8:"Synth Choir Aahs",9:"Melted Choir",10:"Church Choir",11:"Boys Choir 1",12:"Boys Choir 2",13:"Synth Boys Choir",14:"Rich Choir",16:"Choir Hahs",24:"Chorus Lahs",32:"Chorus Aahs 2",33:"Male Aah + Strings"},
{0:"Voice Oohs",1:"Chorus Oohs",2:"Voice Oohs 2",3:"Chorus Oohs 2",4:"Oohs Code Maj7",5:"Oohs Code Sus4",6:"Jazz Scat",8:"Voice Dahs",9:"Jazz Voice Dat",10:"Jazz Voice Bap",11:"Jazz Voice Dow",12:"Jazz Voice Thum",16:"Voice Lah Female",17:"Chorus Lah Female",18:"Voice Luh Female",19:"Chorus Luh Female",20:"Voice Lan Female",21:"Chorus Lan Female",22:"Voice Aah Female",23:"Voice Uuh Female",24:"Female Lah & Lan",32:"Voice Wah Male",33:"Chorus Wah Male",34:"Voice Woh Male",35:"Chorus Woh Male",36:"Voice Aah Male",37:"Voice Ooh Male",40:"Humming"},
{0:"Synth Vox",1:"Synth Vox 2",2:"Synth Vox 3",8:"Synth Voice",9:"Silent Night",10:"Synth Voice 2",16:"VP330 Choir",17:"Vinyl Choir",18:"JX8P Vox",19:"Analog Voice"},
{0:"Orchestra Hit",1:"Bass Hit",2:"6th Hit",3:"Euro Hit",8:"Impact Hit",9:"Philly Hit",10:"Double Hit",11:"Percussion Hit",12:"Shock Wave",13:"Bounce Hit",14:"Drill Hit",15:"Thrill Hit",16:"Lo Fi Rave",17:"Techno Hit",18:"Distortion Hit",19:"Bam Hit",20:"Bit Hit",21:"Bim Hit",22:"Technorg Hit",23:"Rave Hit",24:"Strings Hit",25:"Stack Hit",26:"Industry Hit",27:"Clap Hit"},
{0:"Trumpet",1:"Trumpet 2",2:"Trumpet:",3:"Dark Trumpet",4:"Trumpet & Noise",8:"Flugel Horn",16:"4th Trumpets",24:"Bright Trumpet",25:"Warm Trumpet",26:"Warm Trumpet 2",27:"Twin Trumpet",32:"Synth Trumpet"},
{0:"Trombone",1:"Trombone 2",2:"Twin Trombones",3:"Trombones & Tuba",4:"Bright Trombone",8:"Bass Trombone",16:"Euphonium"},
{0:"Tuba",1:"Tuba 2",8:"Tuba + Horn"},
{0:"Muted Trumpet",1:"Cup Muted Trumpet",2:"Muted Trumpet 2",3:"Muted Trumpet 3",8:"Muted Horns"},
{0:"French Horns",1:"French Horn 2",2:"Horn + Orchestra",3:"Wide French Horns",8:"French Horn Slow:",9:"Dual Horns",16:"Synth Horn",24:"French Horn Rip"},
{0:"Brass 1",1:"Brass Fortissimo",2:"Bones Section",3:"Synth Brass Fortissimo",4:"Quad Brass1",5:"Quad Brass2",8:"Brass 2",9:"Brass 3",10:"Brass Sforzando",12:"Brass Sforzando 2",14:"Fat Pop Brass",16:"Brass Fall",17:"Trumpet Fall",24:"Octave Brass",25:"Brass + Reed",26:"Fat + Reed",32:"Orchestra Brass",33:"Orchestra Brass 2",35:"Section Fat Pop Brass",36:"Section Orchestra Brass",37:"Section Orchestra Brass 2",38:"Section Orchestra Brass 3"},
{0:"Synth Brass 1",1:"JUNO Brass",2:"Stack Brass",3:"SH-5 Brass",4:"MKS Brass",5:"Jump Brass",8:"Pro Brass",9:"P5 Brass",10:"Orchestra Synth Brass",16:"Octave Synth Brass",17:"Hybrid Brass",18:"Octave Synth Brass 2",19:"BPF Brass"},
{0:"Synth Brass 2",1:"Soft Brass",2:"Warm Brass",3:"Synth Brass 3",4:"Sync Brass",5:"Fat Synth Brass",6:"Deep Synth Brass",8:"Synth Brass sfz",9:"OB Brass",10:"Resonant Brass",11:"Distortion Square Brass",12:"JP8000 Saw Brass",16:"Velo Brass 1",17:"Transbrass"},
{0:"Soprano Sax",8:"Soprano Sax Expressive"},
{0:"Alto Sax",8:"Alto Sax Expressive",9:"Grow Sax",16:"Alto Sax + Trumpet",17:"Sax Section"},
{0:"Tenor Sax",1:"Tenor Sax:",8:"Breathy Tenor Sax:",9:"Synth Tenor Sax"},
{0:"Baritone Sax",1:"Baritone Sax:",8:"Baritone & Tenor Sax"},
{0:"Oboe",8:"Oboe Expressive",16:"Multi Reed"},
{0:"English Horn"},
{0:"Bassoon"},
{0:"Clarinet",8:"Bs Clarinet",16:"Multi Wind",17:"Quad Wind"},
{0:"Piccolo",1:"Piccolo:",8:"Nay",9:"Nay Tremolo",16:"Di"},
{0:"Flute",1:"Flute 2:",2:"Flute Expressive",3:"Flute Travelso",8:"Flute + Violin",9:"Pipe & Reed",16:"Tron Flute",17:"Indian Flute"},
{0:"Recorder"},
{0:"Pan Flute",8:"Kawala",16:"Zampona",17:"Zampona Attack",24:"Tin Whistle",25:"Tin Whtstle Nm",26:"Tin Whtstle Or"},
{0:"Bottle Blow"},
{0:"Shakuhachi",1:"Shakuhachi:"},
{0:"Whistle",1:"Whistle 2"},
{0:"Ocarina"},
{0:"Square Wave",1:"MG Square",2:"Hollow Mini",3:"Mellow FM",4:"CC Solo",5:"Shmoog",6:"LM Square",7:"JP8000 TWM",8:"2600 Sine",9:"Sine Lead",10:"KG Lead",11:"Twin Sine",16:"P5 Square",17:"OB Square",18:"JP-8 Square",19:"Distortion Square",20:"303 Square Distortion 1",21:"303 Square Distortion 2",22:"303 Mix Square",23:"Dual Square & Saw",24:"Pulse Lead",25:"JP8 Pulse Lead 1",26:"JP8 Pulse Lead 2",27:"MG Resonant Pulse",28:"JP8 Pulse Lead 3",29:"260 Ring Lead",30:"303 Distortion Lead",31:"JP8000 Distortion Lead",32:"HipHop Sin Lead",33:"HipHop Square Lead",34:"HipHop Pulse Lead",35:"Flux Pulse"},
{0:"Saw Wave",1:"OB2 Saw",2:"Pulse Saw",3:"Feline GR",4:"Big Lead",5:"Velo Lead",6:"GR-300",7:"LA Saw",8:"Doctor Solo",9:"Fat Saw Lead",10:"JP8000 Saw",11:"D-50 Fat Saw",12:"OB Double Saw",13:"JP Double Saw",14:"Fat Saw Lead 2",15:"JP Super Saw",16:"Waspy Synth",17:"PM Lead",18:"CS Saw Lead",24:"MG Saw 1",25:"MG Saw 2",26:"OB Saw 1",27:"OB Saw 2",28:"D-50 Saw",29:"SH-101 Saw",30:"CS Saw",31:"MG Saw Lead",32:"OB Saw Lead",33:"P5 Saw Lead",34:"MG unison",35:"Octave Saw Lead",36:"Natural Lead",40:"Sequence Saw 1",41:"Sequence Saw 2",42:"Resonant Saw",43:"Cheese Saw 1",44:"Cheese Saw 2",45:"Rhythmic Saw",46:"Sequenced Saw",47:"Techno Saw"},
{0:"Synth Calliope",1:"Vent Synth",2:"Pure Pan Lead",8:"LM Pure Lead",9:"LM Blow Lead"},
{0:"Chiffer Lead",1:"TB Lead",2:"Hybrid Lead",3:"Unison Square Lead",4:"Fat Solo Lead",5:"Forceful Lead",6:"Octave Unison Lead",7:"Unison Saw Lead",8:"Mad Lead",9:"Crowding Lead",10:"Double Square"},
{0:"Charang",1:"Wire Lead",2:"FB. Charang",3:"Fat GR Lead",4:"Windy GR Lead",5:"Mellow GR Lead",6:"GR & Pulse",8:"Distortion Lead",9:"Acid Guitar 1",10:"Acid Guitar 2",11:"Dance Distortion Guitar",12:"Dance Distortion Guitar 2",16:"P5 Sync Lead",17:"Fat SyncLead",18:"Rock Lead",19:"5th Deca Sync",20:"Dirty Sync",21:"Dual Sync Lead",22:"LA Brass Ld",24:"JUNO Sub Oscillator",25:"2600 Sub Oscillator",26:"JP8000 Fd Oscillator"},
{0:"Solo Vox",1:"Solo Vox 2",8:"Vox Lead",9:"LFO Vox",10:"Vox Lead 2"},
{0:"5th Saw Wave",1:"Big Fives",2:"5th Lead",3:"5th Ana.Clav",4:"5th Pulse",5:"JP 5th Saw",6:"JP8000 5th FB",8:"4th Lead"},
{0:"Bass & Lead",1:"Big & Raw",2:"Fat & Perky",3:"JUNO Rave",4:"JP8 Bass Lead 1",5:"JP8 Bass Lead 2",6:"SH-5 Bass Lead",7:"Delayed Lead"},
{0:"Fantasia",1:"Fantasia 2",2:"New Age Pad",3:"Bell Heaven",4:"Fantasia 3",5:"Fantasia 4",6:"After D !",7:"260 Harm Pad"},
{0:"Warm Pad",1:"Thick Matrix",2:"Horn Pad",3:"Rotary Strng",4:"OB Soft Pad",5:"Sine Pad",6:"OB Soft Pad2",8:"Octave Pad",9:"Stack Pad",10:"Human Pad",11:"Sync Brs. Pad",12:"Octave PWM Pad",13:"JP Soft Pad"},
{0:"Polysynth",1:"80's Polysynth",2:"Polysynth 2",3:"Polysynth King",4:"Super Polysynth",8:"Power Stack",9:"Octave Stack",10:"Resonant Stack",11:"Techno Stack",12:"Pulse Stack",13:"Twin Octave Rave",14:"Octave Rave",15:"Happy Synth",16:"Forward Sweep",17:"Reverse Sweep",24:"Minor Rave"},
{0:"Space Voice",1:"Heaven II",2:"SC Heaven",3:"Itopia",4:"Water Space",5:"Cold Space",6:"Noise Peaker",7:"Bamboo Hit",8:"Cosmic Voice",9:"Auh Vox",10:"AuhAuh",11:"Vocorderman"},
{0:"Bowed Glass",1:"Soft Bell Pad",2:"JP8 Square Pad",3:"7th Bell Pad",4:"Steel Glass",5:"Bottle Stack"},
{0:"Metal Pad",1:"Tine Pad",2:"Panner Pad",3:"Steel Pad",4:"Special Rave",5:"Metal Pad 2"},
{0:"Halo Pad",1:"Vox Pad",2:"Vox Sweep",8:"Horror Pad",9:"SynVox Pad",10:"SynVox Pad 2",11:"Breath & Rise",12:"Tears Voices"},
{0:"Sweep Pad",1:"Polar Pad",2:"Ambient BPF",3:"Sync Pad",4:"Warriors",8:"Converge",9:"Shwimmer",10:"Celestial Pad",11:"Bag Sweep",12:"Sweep Pipe",13:"Sweep Stack",14:"Deep Sweep",15:"Stray Pad"},
{0:"Ice Rain",1:"Harmo Rain",2:"African wood",3:"Anklung Pad",4:"Rattle Pad",5:"Saw Impulse",6:"Strange Str.",7:"FastFWD Pad",8:"Clavi Pad",9:"EP Pad",10:"Tambra Pad",11:"CP Pad"},
{0:"Soundtrack",1:"Ancestral",2:"Prologue",3:"Prologue 2",4:"Hols Strings",5:"History Wave",8:"Rave"},
{0:"Crystal",1:"Synth Mallet",2:"Soft Crystal",3:"Round Glock",4:"Loud Glock",5:"Glocken Chime",6:"Clear Bells",7:"Christmas Bells",8:"Vibra Bells",9:"Digi Bells",10:"Music Bells",11:"Analog Bells",12:"Blow Bells",13:"Hyper Bells",16:"Choral Bells",17:"Air Bells",18:"Bell Harp",19:"Gamelimba",20:"JUNO Bells",21:"JP Bells",22:"Pizz Bells",23:"Bottom Bells"},
{0:"Atmosphere",1:"Warm Atmosphere",2:"Nylon Harp",3:"Harpvox",4:"Hollow Releas",5:"Nylon + Rhodes",6:"Ambient Pad",7:"Invisible",8:"Pulsey Key",9:"Noise Piano",10:"Heaven Atmosphere",11:"Tambra Atmosphere"},
{0:"Brightness",1:"Shining Star",2:"OB Stab",3:"Brass Star",4:"Choir Stab",5:"D-50 Retour",6:"Southern Wind",7:"Symbolic Bell",8:"Org Bell"},
{0:"Goblin",1:"Goblinson",2:"50's Sci-Fi",3:"Abduction",4:"Auhbient",5:"LFO Pad",6:"Random Str",7:"Random Pad",8:"Low Birds Pad",9:"Falling Down",10:"LFO RAVE",11:"LFO Horror",12:"LFO Techno",13:"Alternative",14:"UFO FX",15:"Gargle Man",16:"Sweep FX",17:"LM Has Come",18:"Fallin Insect",19:"LFO OctaveRave",20:"Just Before",21:"RND Fl. Chord",22:"Random Ending",23:"Random Sine",24:"Eating Filter",25:"Noise & Saw Hit",26:"Pour Magic",27:"Dancing Drill",28:"Dirty Stack",29:"Big Blue",30:"Static Hit",31:"Atl. Mod. FX",32:"Acid Copter"},
{0:"Echo Drops",1:"Echo Bell",2:"Echo Pan",3:"Echo Pan 2",4:"Big Panner",5:"Resonant Panner",6:"Water Piano",7:"Echo SynBass",8:"Pan Sequence",9:"Aqua",10:"Panning Lead",11:"Panning Brass"},
{0:"Star Theme",1:"Star Theme 2",2:"Star Mind",3:"Star Dust",4:"Rep. Trance",5:"Etherality",6:"Mystic Pad",8:"Dream Pad",9:"Silky Pad",10:"Dream Pad 2",11:"Silky Pad 2",16:"New Century",17:"7th Atmosphere",18:"Galaxy Way",19:"Rising Oscillator"},
{0:"Sitar",1:"Sitar 2",2:"Detune Sitar",3:"Sitar 3",4:"Sitar/Drone",5:"Sitar 4",8:"Tambra",16:"Tamboura"},
{0:"Banjo",1:"Muted Banjo",8:"Rabab",9:"San Xian",16:"Gopichant",24:"Oud",28:"Oud + Strings",32:"Pi Pa"},
{0:"Shamisen",1:"Tsugaru",8:"Synth Shamisen"},
{0:"Koto",1:"Gu Zheng",8:"Taisho Koto",16:"Kanoon",19:"Kanoon + Choir",24:"Octave Harp"},
{0:"Kalimba",8:"Sanza",9:"Bodhran",10:"Bodhran Mute"},
{0:"Bagpipe",8:"Didgeridoo",9:"Uilleann Pipe",10:"Uilleann Pipe Nm",11:"Uilleann Pipe Or"},
{0:"Fiddle",8:"Er Hu",9:"Gao Hu"},
{0:"Shanai",1:"Shanai 2",8:"Pungi",16:"Hichiriki",24:"Mizmar",32:"Suona",33:"Suona 2"},
{0:"Tinkle Bell",8:"Bonang",9:"Gender",10:"Gamelan Gong",11:"Synth Gamelan",12:"Jang Gu",13:"Jegogan",14:"Jublag",15:"Pemade",16:"RAMA Cymbal",17:"Kajar",18:"Kelontuk",19:"Kelontuk Mt",20:"Kelontuk Sid",21:"Kopyak Op",22:"Kopyak Mt",23:"Ceng Ceng",24:"Reyoung",25:"Kempur",32:"Jungle Crash",40:"Crash Menu",41:"Ride Cymbal Menu",42:"Ride Bell Menu"},
{0:"Agogo",8:"Atarigane",16:"Tambourine"},
{0:"Steel Drums",1:"Island Mlt"},
{0:"Woodblock",8:"Castanets",16:"Angklung",17:"Angklung Rhythm",24:"Finger Snaps",32:"909 Hand Clap",40:"Hand Clap Menu"},
{0:"Taiko",1:"Small Taiko",8:"Concert Bass Drum",9:"Concert Bass Drum Mt",16:"Jungle Bass Drum",17:"Techno Bass Drum",18:"Bounce",24:"Kendang Wadon",25:"Bebarongan",26:"Pelegongan",27:"Dholak 1",28:"Dholak 2",32:"Jungle Bass Drum Roll",40:"Kick Menu 1",41:"Kick Menu 2",42:"Kick Menu 3",43:"Kick Menu 4"},
{0:"Melodic Tom 1",1:"Real Tom",2:"Real Tom 2",3:"Jazz Tom",4:"Brush Tom",8:"Melodic Tom 2",9:"Rock Tom",16:"Rash Snare Drum",17:"House Snare Drum",18:"Jungle Snare Drum",19:"909 Snare Drum",24:"Jungle Snare Drum Roll",40:"Snare Drum Menu 1",41:"Snare Drum Menu 2",42:"Snare Drum Menu 3",43:"Snare Drum Menu 4",44:"Snare Drum Menu 5"},
{0:"Synth Drum",8:"808 Tom",9:"Elec Perc",10:"Sine Percussion",11:"606 Tom",12:"909 Tom",13:"606 Distortion Tom"},
{0:"Reverse Cymbal",1:"Reverse Cymbal 2",2:"Reverse Cymbal 3",3:"Reverse Cymbal 4",8:"Reverse Snare 1",9:"Reverse Snare 2",16:"Reverse Kick 1",17:"Reverse Con Bass Drum",24:"Reverse Tom 1",25:"Reverse Tom 2",26:"Reverse Tom 3",27:"Reverse Tom 4",40:"Reverse Snare Drum Menu1",41:"Reverse Snare Drum Menu2",42:"Reverse Snare Drum Menu3",43:"Reverse Bass Drum Menu1",44:"Reverse Bass Drum Menu2",45:"Reverse Bass Drum Menu3",46:"Reverse Clap Menu"},
{0:"Guitar Fret Noise",1:"Guitar Cut Noise",2:"String Slap",3:"Guitar Cut Noise 2",4:"Distortion Cut Noise",5:"Bass Slide",6:"Pick Scrape",8:"Guitar FX Menu",9:"Bartok Pizzicato",10:"Guitar Slap",11:"Chord Stroke",12:"Biwa Stroke",13:"Biwa Tremolo",16:"Acoustic Bass Noise Menu",17:"Distortion Guitar Noise Menu",18:"Electric Guitar Noise Menu 1",19:"Electric Guitar Noise Menu 2",20:"Guitar Stroke Menu",21:"Guitar Slide Menu",22:"Acoustic Bass Mute Noise",23:"Acoustic Bass Touch Noise",24:"Acoustic Bass Atack Noise",25:"Telecaster Up Noise",26:"Telecaster Down Muted Noise",27:"Telecaster Up Muted Noise",28:"Telecaster Down Noise",29:"Distortion Guitar Up Noise",30:"Distortion Guitar Down Noise 1",31:"Distortion Guitar Down Noise 2",32:"Distortion Guitar Mute Noise",34:"Guitar Stroke Noise 5",35:"Steel Guitar Slide Noise 1",36:"Steel Guitar Slide Noise 2",37:"Steel Guitar Slide Noise 3",38:"Steel Guitar Slide Noise 4",39:"Guitar Stroke Noise 1",40:"Guitar Stroke Noise 2",41:"Guitar Stroke Noise 3",42:"Guitar Stroke Noise 4"},
{0:"Breath Noise",1:"Flute Key Click",2:"Breath Noise Menu",3:"Flute Breath 1",4:"Flute Breath 2",5:"Flute Breath 3",6:"Vox Breath 1",7:"Vox Breath 2",8:"Trombone Noise",9:"Trumpet Noise"},
{0:"Seashore",1:"Rain",2:"Thunder",3:"Wind",4:"Stream",5:"Bubble",6:"Wind 2",7:"Cricket",16:"Pink Noise",17:"White Noise"},
{0:"Bird",1:"Dog",2:"Horse-Gallop",3:"Bird 2",4:"Kitty",5:"Growl",6:"Growl 2",7:"Fancy Animal",8:"Seal"},
{0:"Telephone 1",1:"Telephone 2",2:"Door Creaking",3:"Door",4:"Scratch",5:"Wind Chimes",7:"Scratch 2",8:"Scratch Key",9:"Tape Rewind",10:"Phono Noise",11:"MC-500 Beep",12:"Scratch 3",13:"Scratch 4",14:"Scratch 5",15:"Scratch 6",16:"Scratch 7"},
{0:"Helicopter",1:"Car-Engine",2:"Car-Stop",3:"Car-Pass",4:"Car-Crash",5:"Siren",6:"Train",7:"Jetplane",8:"Starship",9:"Burst Noise",10:"Calculating",11:"Percussion Bang",12:"Burner",13:"Glass & Glam",14:"Ice Ring",15:"Over Blow",16:"Crack Bottle",17:"Pour Bottle",18:"Soda",19:"Open CD Tray",20:"Audio Switch",21:"Key Typing",22:"Steam Locomotive 1",23:"Steam Locomotive 2",24:"Car Engine 2",25:"Car Horn",26:"Boeeeen",27:"Railway Crossing",28:"Compresser",29:"Sword Boom!",30:"Sword Cross",31:"Stab! 1",32:"Stab! 2"},
{0:"Applause",1:"Laughing",2:"Screaming",3:"Punch",4:"Heart Beat",5:"Footsteps",6:"Applause 2",7:"Small Club",8:"Applause Wave",9:"Baby Laughing",16:"Voice One",17:"Voice Two",18:"Voice Three",19:"Voice Tah",20:"Voice Whey",22:"Voice Kikit",23:"Voice ComeOn",24:"Voice Aou",25:"Voice Oou",26:"Voice Hie"},
{0:"Gun Shot",1:"Machine Gun",2:"Lasergun",3:"Explosion",4:"Eruption",5:"Big Shot",6:"Explosion 2"}
];
var _gm2 = [
{0:"Acoustic Grand Piano",1:"Acoustic Grand Piano (wide)",2:"Acoustic Grand Piano (dark)"},
{0:"Bright Acoustic Piano",1:"Bright Acoustic Piano (wide)"},
{0:"Electric Grand Piano",1:"Electric Grand Piano (wide)"},
{0:"Honky-tonk Piano",1:"Honky-tonk Piano (wide)"},
{0:"Electric Piano 1",1:"Detuned Electric Piano 1",2:"Electric Piano 1 (velocity mix)",3:"60's Electric Piano"},
{0:"Electric Piano 2",1:"Detuned Electric Piano",2:"Electric Piano 2 (velocity mix)",3:"EP Legend",4:"EP Phase"},
{0:"Harpsichord",1:"Harpsichord (octave mix)",2:"Harpsichord (wide)",3:"Harpsichord (with key off)"},
{0:"Clavinet",1:"Pulse Clavinet"},
{0:"Celesta"},
{0:"Glockenspiel"},
{0:"Music Box"},
{0:"Vibraphone",1:"Vibraphone (wide)"},
{0:"Marimba",1:"Marimba (wide)"},
{0:"Xylophone"},
{0:"Tubular Bells",1:"Church Bell",2:"Carillon"},
{0:"Dulcimer"},
{0:"Drawbar Organ",1:"Detuned Drawbar Organ",2:"Italian 60's Organ",3:"Drawbar Organ 2"},
{0:"Percussive Organ",1:"Detuned Percussive Organ",2:"Percussive Organ 2"},
{0:"Rock Organ"},
{0:"Church Organ",1:"Church Organ (octave mix)",2:"Detuned Church Organ"},
{0:"Reed Organ",1:"Puff Organ"},
{0:"Accordion",1:"Accordion 2"},
{0:"Harmonica"},
{0:"Tango Accordion"},
{0:"Acoustic Guitar (nylon)",1:"Ukulele",2:"Acoustic Guitar (nylon + key off)",3:"Acoustic Guitar (nylon 2)"},
{0:"Acoustic Guitar (steel)",1:"12-Strings Guitar",2:"Mandolin",3:"Steel Guitar with Body Sound"},
{0:"Electric Guitar (jazz)",1:"Electric Guitar (pedal steel)"},
{0:"Electric Guitar (clean)",1:"Electric Guitar (detuned clean)",2:"Mid Tone Guitar"},
{0:"Electric Guitar (muted)",1:"Electric Guitar (funky cutting)",2:"Electric Guitar (muted velo-sw)",3:"Jazz Man"},
{0:"Overdriven Guitar",1:"Guitar Pinch"},
{0:"Distortion Guitar",1:"Distortion Guitar (with feedback)",2:"Distorted Rhythm Guitar"},
{0:"Guitar Harmonics",1:"Guitar Feedback"},
{0:"Acoustic Bass"},
{0:"Electric Bass (finger)",1:"Finger Slap Bass"},
{0:"Electric Bass (pick)"},
{0:"Fretless Bass"},
{0:"Slap Bass 1"},
{0:"Slap Bass 2"},
{0:"Synth Bass 1",1:"Synth Bass (warm)",2:"Synth Bass 3 (resonance)",3:"Clavi Bass",4:"Hammer"},
{0:"Synth Bass 2",1:"Synth Bass 4 (attack)",2:"Synth Bass (rubber)",3:"Attack Pulse"},
{0:"Violin",1:"Violin (slow attack)"},
{0:"Viola"},
{0:"Cello"},
{0:"Contrabass"},
{0:"Tremolo Strings"},
{0:"Pizzicato Strings"},
{0:"Orchestral Harp",1:"Yang Chin"},
{0:"Timpani"},
{0:"String Ensembles",1:"Strings and Brass",2:"60s Strings"},
{0:"String Ensembles"},
{0:"Synth Strings 1",1:"Synth Strings 3"},
{0:"Synth Strings 2"},
{0:"Choir Aahs",1:"Choir Aahs"},
{0:"Voice Oohs",1:"Humming"},
{0:"Synth Voice",1:"Analog Voice"},
{0:"Orchestra Hit",1:"Bass Hit Plus",2:"6th Hit",3:"Euro Hit"},
{0:"Trumpet",1:"Dark Trumpet Soft"},
{0:"Trombone",1:"Trombone 2",2:"Bright Trombone"},
{0:"Tuba"},
{0:"Muted Trumpet",1:"Muted Trumpet 2"},
{0:"French Horn",1:"French Horn 2 (warm)"},
{0:"Brass Section",1:"Brass Section 2 (octave mix)"},
{0:"Synth Brass 1",1:"Synth Brass 3",2:"Analog Synth Brass 1",3:"Jump Brass"},
{0:"Synth Brass 2",1:"Synth Brass 4",2:"Analog Synth Brass 2"},
{0:"Soprano Sax"},
{0:"Alto Sax"},
{0:"Tenor Sax"},
{0:"Baritone Sax"},
{0:"Oboe"},
{0:"English Horn"},
{0:"Bassoon"},
{0:"Clarinet"},
{0:"Piccolo"},
{0:"Flute"},
{0:"Recorder"},
{0:"Pan Flute"},
{0:"Blown Bottle"},
{0:"Shakuhachi"},
{0:"Whistle"},
{0:"Ocarina"},
{0:"Lead 1 (square)",1:"Lead 1a (square 2)",2:"Lead 1b (sine)"},
{0:"Lead 2 (sawtooth)",1:"Lead 2a (sawtooth 2)",2:"Lead 2b (saw + pulse)",3:"Lead 2c (double sawtooth)",4:"Lead 2d (sequenced analog)"},
{0:"Lead 3 (calliope)"},
{0:"Lead 4 (chiff)"},
{0:"Lead 5 (charang)",1:"Lead 5a (wire lead)"},
{0:"Lead 6 (voice)"},
{0:"Lead 7 (fifths)"},
{0:"Lead 8 (bass + lead)",1:"Lead 8a (soft wrl)"},
{0:"Pad 1 (new age)"},
{0:"Pad 2 (warm)",1:"Pad 2a (sine pad)"},
{0:"Pad 3 (polysynth)"},
{0:"Pad 4 (choir)",1:"Pad 4a (itopia)"},
{0:"Pad 5 (bowed)"},
{0:"Pad 6 (metallic)"},
{0:"Pad 7 (halo)"},
{0:"Pad 8 (sweep)"},
{0:"FX 1 (rain)"},
{0:"FX 2 (soundtrack)"},
{0:"FX 3 (crystal)",1:"FX 3a (synth mallet)"},
{0:"FX 4 (atmosphere)"},
{0:"FX 5 (brightness)"},
{0:"FX 6 (goblins)"},
{0:"FX 7 (echoes)",1:"FX 7a (echo bell)",2:"FX 7b (echo pan)"},
{0:"FX 8 (sci-fi)"},
{0:"Sitar",1:"Sitar 2 (bend)"},
{0:"Banjo"},
{0:"Shamisen"},
{0:"Koto",1:"Taisho Koto"},
{0:"Kalimba"},
{0:"Bag pipe"},
{0:"Fiddle"},
{0:"Shanai"},
{0:"Tinkle Bell"},
{0:"Agogo"},
{0:"Steel Drums"},
{0:"Woodblock",1:"Castanets"},
{0:"Taiko Drum",1:"Concert Bass Drum"},
{0:"Melodic Tom",1:"Melodic Tom 2 (power)"},
{0:"Synth Drum",1:"Rhythm Box Tom",2:"Electric Drum"},
{0:"Reverse Cymbal"},
{0:"Guitar Fret Noise",1:"Guitar Cutting Noise",2:"Acoustic Bass String Slap"},
{0:"Breath Noise",1:"Flute Key Click"},
{0:"Seashore",1:"Rain",2:"Thunder",3:"Wind",4:"Stream",5:"Bubble"},
{0:"Bird Tweet",1:"Dog",2:"Horse Gallop",3:"Bird Tweet 2"},
{0:"Telephone Ring",1:"Telephone Ring 2",2:"Door Creaking",3:"Door",4:"Scratch",5:"Wind Chime"},
{0:"Helicopter",1:"Car Engine",2:"Car Stop",3:"Car Pass",4:"Car Crash",5:"Siren",6:"Train",7:"Jetplane",8:"Starship",9:"Burst Noise"},
{0:"Applause",1:"Laughing",2:"Screaming",3:"Punch",4:"Heart Beat",5:"Footsteps"},
{0:"Gunshot",1:"Machine Gun",2:"Lasergun",3:"Explosion"}
];
var _xg = [
{0:"Grand Piano",1:"Grand Piano KSP",2:"Grand Piano Dark",18:"Mellow Grand Piano",40:"Piano Strings",41:"Dream Piano",64:"Concert Grand Piano",65:"Concert Grand Piano KSP",66:"Double Concert Grand",67:"MIDI Grand Piano 1",68:"MIDI Grand Piano 2",69:"Oldest Acoustic Piano"},
{0:"Bright Piano",1:"Bright Piano KSP",3:"Stereo Bright Piano",20:"Resonant Bright Piano",32:"Detuned Bright Piano",40:"Synth Pad Piano",64:"Bright Concert Grand",65:"Bright Concert Grand KSP",66:"MIDI Grand Piano 3",67:"MIDI Grand Piano 4",68:"Old Piano"},
{0:"Electric Grand Piano",1:"Electric Grand Piano KSP",32:"Detuned CP80",35:"Synth CP",40:"Layered CP 1",41:"Layered CP 2"},
{0:"Honky-tonk Piano",1:"Honky-tonk Piano KSP"},
{0:"Electric Piano 1",1:"Electric Piano 1 KSP",18:"Mellow Electric Piano 1",32:"Chorus Electric Piano 1",40:"Hard Electric Piano",45:"Velocity Crossfade Electric Piano 1",64:"60's Electric Piano 1",65:"Old Electric Piano",66:"Tribecca",67:"Diploid 1",68:"Flops",69:"Soho",70:"Flops Detuned",71:"Diploid 2",72:"Brooklyn",73:"Diploid 3",74:"Phunky DX",75:"Nasal DX",76:"Nasal DX Detuned",77:"Din",78:"4 Way Electric Piano",79:"Easy Electric Piano",80:"Sine Electric Piano",81:"Cheap Electric Piano"},
{0:"Electric Piano 2",1:"Electric Piano 2 KSP",12:"Chorus Electric Piano Decay",32:"Chorus Electric Piano 2",33:"DX Electric Piano Hard",34:"DX Legend",40:"DX Phase Electric Piano",41:"DX + Analog Electric Piano",42:"DX Koto Electric Piano",45:"Velocity Crossfade Electric Piano 2",48:"Chorus Electric Piano KSP",52:"DX Mallet",64:"Shirakawa",65:"Old Electric Piano Tine",66:"Flips",67:"Flips Detuned",68:"Flicks",69:"Flicks Detuned",70:"Bright DX",71:"Bright DX Detuned",72:"Kitayama",73:"Turnpike 1",74:"Turnpike 2",75:"Cerritos",76:"Sunset",77:"Soft DX",78:"Resonant DX",79:"Piercing DX",80:"Shivering DX",81:"Shivering DX Plus",82:"Rattling DX",83:"Rattling DX Plus",84:"Tinker DX",85:"Tinker DX Plus"},
{0:"Harpsichord",1:"Harpsichord KSP",25:"Harpsichord 2",32:"Harpsichord Detune",35:"Harpsichord 3",40:"Electric Harpsichord",64:"Synth Harpsichord"},
{0:"Clavi",1:"Clavi KSP",27:"Clavi Wah",40:"Cosmic Clavi",64:"Pulse Clavi",65:"Pierce Clavi",66:"Clear Clavi",67:"Sweep Clavi",68:"Synth Clavi",69:"Super Clavi",70:"Guitar Clavi",71:"Hardy Pluck",72:"Hardy Pluck Plus",73:"FM Clavi Double",74:"Robot Clavi"},
{0:"Celesta",64:"FM Celesta"},
{0:"Glockenspiel"},
{0:"Music Box",64:"Orgel",65:"Small Orgel"},
{0:"Vibraphone",1:"Vibraphone KSP",45:"Hard Vibraphone"},
{0:"Marimba",1:"Marimba KSP",64:"Sine Marimba",96:"Balafon",97:"Balimba",98:"Log Drums"},
{0:"Xylophone"},
{0:"Tubular Bells",96:"Church Bells",97:"Carillon"},
{0:"Dulcimer",35:"Dulcimer 2",96:"Cimbalom",97:"Santur",98:"Yang Qin"},
{0:"Drawbar Organ",3:"Stereo Drawbar Organ",32:"Detuned Drawbar Organ",33:"60's Drawbar Organ 1",34:"60's Drawbar Organ 2",35:"70's Drawbar Organ 1",36:"Drawbar Organ 2",37:"60's Drawbar Organ 3",38:"Even Bar Organ",40:"16+2\"2/3 Organ",64:"Organ Bass",65:"70's Drawbar Organ",66:"Cheezy Organ",67:"Drawbar Organ 3",68:"Stadium Organ",69:"Stadium Organ 2",70:"Gospel Organ",71:"Click Gospel Organ",72:"Chapel Organ",73:"Dim Chorus Organ",74:"Dawn Organ",75:"Mellorgan",76:"Fuzzorgan",77:"FM Organ",78:"70's Drawbar Organ 3",79:"Mood Organ"},
{0:"Percussive Organ",24:"70's Percussive Organ 1",32:"Detuned Percussive Organ",33:"Light Organ",37:"Percussive Organ 2",64:"Jazz Organ",65:"Warm Jazz Organ",66:"Click Organ",67:"Grace Organ",68:"Crunchy Grace",69:"Dim Click Organ",70:"Dusk Organ",71:"FM Click Organ",72:"Spoony Organ",73:"Super Rotary Organ",74:"Lo Fi Organ",75:"Beep Organ",76:"Belief Organ",77:"Snap Organ"},
{0:"Rock Organ",64:"Rotary Organ",65:"Slow Rotary Organ",66:"Fast Rotary Organ",67:"Glacial Rotary Organ"},
{0:"Church Organ",32:"Church Organ 3",35:"Church Organ 2",40:"Notre Dame Organ",64:"Organ Flute",65:"Tremolo Organ Flute"},
{0:"Reed Organ",32:"Reed Organ Detuned",40:"Puff Organ",64:"Synth Reed Dark Organ"},
{0:"Accordion",32:"Accord It"},
{0:"Hamonica",32:"Harmonica 2"},
{0:"Tango Accordion",64:"Tango Accordion 2",65:"Tight Accordion",66:"Tight Accordion Detuned"},
{0:"Nylon Guitar",16:"Nylon Guitar 2",25:"Nylon Guitar 3",32:"Nylon Guitar Detuned",40:"Wayside",43:"Velocity Guitar Harmonics",64:"Spanish Guitar",65:"Spanish Guitar Hard",66:"Spanish Guitar Mellow",67:"Spanish Guitar Decay",96:"Ukulele"},
{0:"Steel Guitar",16:"Steel Guitar 2",32:"Steel Guitar Detuned",35:"12-string Guitar",40:"Nylon & Steel Guitar",41:"Steel Guitar with Body Sound",64:"Nashville Guitar",65:"Nashville Resonant Guitar",66:"Nashville 12 Guitar",67:"Old Sample Guitar",96:"Mandolin",97:"Mandolin Ensemble"},
{0:"Jazz Guitar",18:"Mellow Guitar",32:"Jazz Amp Guitar",40:"Organ Guitar",41:"Octave Plate",64:"Super Jazz Middle Guitar",65:"Super Jazz Bridge Guitar",66:"Super Jazz Detuned Guitar",67:"Super Jazz Resonant Guitar",68:"DX Jazz Guitar",69:"DX Jazz Guitar Detuned",70:"Pulse Jazz Guitar",71:"Roughcaster Neck Guitar",72:"Roughcaster Middle Guitar",96:"Pedal Steel Guitar"},
{0:"Clean Guitar",32:"Chorus Guitar",33:"Chorus Guitar Light",64:"Clean Guitar 2",65:"Mid Tone Guitar",66:"Mid Tone Guitar Stereo",67:"Nasal Guitar",68:"Nasal Guitar Stereo",69:"Hammer Middle Guitar",70:"Hammer Bridge Guitar",71:"Hammer Double Guitar",72:"Hammer Stereo Guitar",73:"FM Chorus Guitar",74:"FM Chorus Guitar Soft",75:"Pesky Guitar",76:"Clavi Guitar"},
{0:"Muted Guitar",40:"Funk Guitar 1",41:"Muted Steel Guitar",43:"Funk Guitar 2",45:"Jazz Man Guitar",64:"Wrench Guitar",65:"Wrench Heavy Guitar",66:"Wrench Double Guitar",67:"Tin Guitar",68:"Groovey Muted Guitar",96:"Muted Distortion Guitar"},
{0:"Overdriven Guitar",32:"Overdriven Guitar Detuned",40:"Parallel Guitar",43:"Guitar Pinch",64:"Manhattan Middle Guitar",65:"Manhattan Bridge Guitar",66:"Manhattan Detuned Guitar",67:"Manhattan Powered Guitar"},
{0:"Distortion Guitar",12:"Distorted Rhythm Guitar",24:"Distortion Guitar 2",35:"Distortion Guitar 3",36:"Power Guitar 2",37:"Power Guitar 1",38:"Distorted Fifths Guitar",40:"Feedback Guitar",41:"Feedback Guitar 2",42:"Twin Distortion Guitar",43:"Rock Rhythm Guitar 2",45:"Rock Rhythm Guitar 1",64:"Bite Guitar",65:"Bite Resonant Guitar",66:"Bite Detuned Guitar",67:"Bite Plus Guitar",68:"Burnout Guitar",69:"Bombay Guitar",70:"Bombay Sustained Guitar",71:"Jaipur"},
{0:"Guitar Harmonics",64:"Acoustic Harmonics",65:"Guitar Feedback",66:"Guitar Harmonics 2",67:"Shimla"},
{0:"Acoustic Bass",40:"Jazz Rhythm",41:"Pick Acoustic Bass",43:"Blink Bass",45:"Velocity Crossfade Upright Bass",64:"Boston Bass",65:"Boston Bright Bass",66:"Coolth Bass",67:"Coolth Bright Bass",96:"Walking Synth Bass",97:"Dim & Cool Bass"},
{0:"Finger Bass",18:"Finger Dark Bass",27:"Flange Bass",32:"Finger Bass Detuned",40:"Bass & Distorted Electric Guitar",43:"Finger Slap Bass",45:"Finger Bass 2",64:"Jazzy Bass",65:"Modulated Bass",66:"Chase Bass",67:"Chase Resonant Bass",68:"Blue Bass",69:"Jazzy Bass 2"},
{0:"Pick Bass",6:"Pick Bass 2",28:"Muted Pick Bass",40:"Pick Bass & Muted Guitar",64:"Hard Pick Bass",65:"Hard Pick Resonant Bass",66:"Pick Bass Plus",67:"Pick Bass 4"},
{0:"Fretless Bass",32:"Fretless Bass 2",33:"Fretless Bass 3",34:"Fretless Bass 4",64:"Powered Fretless Bass",65:"Powered Fretless Resonant Bass",66:"Talking Bass",67:"Noisy Fretless Bass",96:"Synth Fretless Bass",97:"Smooth Fretless Bass"},
{0:"Slap Bass 1",21:"Cosmic Slap",27:"Resonant Slap",32:"Punch Thumb Bass",64:"Slapper Bass",65:"Thumb & Slap Bass",66:"Glitzy Slap Bass",67:"FM Slap Bass",68:"FM Slap Detuned Bass"},
{0:"Slap Bass 2",16:"Bright Slap Split Bass",22:"Wah Slap Bass",43:"Velocity Switch Slap Bass"},
{0:"Synth Bass 1",18:"Synth Bass 1 Dark",20:"Fast Resonant Bass",21:"TL66",24:"Acid Bass",27:"Resonant Bass",28:"Muted Pulse Bass",29:"Slow Attack",35:"Clavi Bass",40:"Techno Synth Bass",41:"Kick'n'Bass",42:"NEP",64:"Orbiter",65:"Square Bass",66:"Rubber Bass",67:"Fish",68:"Hard Resonance",69:"Wah Saw",70:"Pluto",71:"Pluto Plus",72:"Stimuli",73:"Running Pulse",74:"Talking Pulse",75:"Node",76:"Stainer",77:"Stainer Attack",78:"Sweep Square",79:"Sweep Square Plus",80:"Stinks",81:"Stinks Resonant",82:"Resonant Square",83:"Dagger",84:"Zinc",85:"SweePWM",86:"SweePWM Stereo",87:"Slow Wah",88:"Crook",89:"Fast Fretless Bass",90:"Rubber30",91:"Fast Resonant Bass 2",92:"Minneapolis Bass",93:"Miami Bass",94:"Resonace Talking Box",96:"Hammer"},
{0:"Synth Bass 2",6:"Mellow Synth Bass",12:"Sequenced Bass",18:"Click Synth Bass",19:"Synth Bass 2 Dark",22:"Zealot",32:"Smooth Synth Bass",40:"Modular Synth Bass",41:"DX Bass",42:"DX Bass Bright",64:"X Wire Bass",65:"Attack Pulse",66:"CS Light",67:"Metal Bass",68:"Forced Oscillation Bass",69:"Cubit",70:"Cubit Plus",71:"Keel",72:"Keel Powered",73:"Plain Pulse",74:"Powered Pulse",75:"Powered Pulse Bright",76:"Powered Sawtooth",77:"Smooth Bass",78:"Synth Attack"},
{0:"Violin",8:"Slow Violin",40:"Unison Violin",64:"Cadenza Violin",65:"Cadenza Dark Violin",66:"Violin Section",67:"Hard Attack Violin Section",68:"Slow Attack Violin Section"},
{0:"Viola",40:"Viola Double",64:"Sonata Viola",65:"Viola Section",66:"Hard Attack Viola Section",67:"Slow Attack Viola Section"},
{0:"Cello",64:"Cello Section",65:"Hard Attack Cello Section",66:"Slow Attack Cello Section"},
{0:"Contrabass",64:"Contrabass Section",65:"Hard Attack Contrabass Section",66:"Slow Attack Contrabass Section"},
{0:"Tremolo Strings",8:"Slow Tremolo Strings",45:"Suspense Strings",64:"Fear Strings",65:"Fear Detuned Strings",66:"Apocalypse Strings",67:"Bright Tremolo Strings"},
{0:"Pizzicato Strings",35:"Pizzicato Octave",40:"Sleep",64:"Collegno"},
{0:"Orchestral Harp",40:"Yang Chin",64:"Electric Harp",96:"Violin Harp",97:"Violin Harp Detuned"},
{0:"Timpani",43:"Roll & Hit"},
{0:"Strings 1",3:"Stereo Strings",8:"Slow Strings",14:"Sforzando Strings",24:"Arco Strings",35:"60's Strings",40:"Orchestra Strings",41:"Orchestra Strings 2",42:"Tremolo Orchestra",45:"Velocity Strings",52:"Lento Strings",64:"Super Strings",65:"Super Strings Stereo",66:"Triste Strings",67:"Basso Strings",68:"Staccato High Strings",69:"Staccato Low Strings",70:"Hall Strings",71:"Strings + French Horn",72:"Solid Strings",73:"Swell Strings",74:"Strings + Brass Section",75:"3 Octave Strings",76:"5 Part Strings"},
{0:"Strings 2",3:"Stereo Slow Strings",8:"Legato Strings",40:"Warm Strings",41:"Kingdom Strings",64:"70's Strings",65:"String Ensemble 3"},
{0:"Synth Strings 1",8:"Memory",18:"Zephyr",27:"Resonant Strings",35:"Synth Strings 3",39:"Monarchy",40:"Grand Pad",41:"Sweep Strings",42:"Sweep Strings Octave",64:"Synth Strings 4",65:"Synth Strings 5",66:"Solitude",67:"Fate",68:"Thulium",69:"Brook",70:"Brook Stereo",71:"Old Syhth Strings"},
{0:"Synth Strings 2",21:"Trade Wind",39:"Worm Hole",64:"Hope",65:"Virgo",66:"Platinum",67:"Octave PWM",68:"Taurus",69:"Frost",70:"Leo",71:"Solar Plexus",72:"Sun Rise"},
{0:"Choir Aahs",3:"Stereo Choir",16:"Choir Aahs 2",32:"Mellow Choir",39:"Gasp",40:"Choir Strings",41:"Dead Sea",64:"Strings & Choir Aahs",65:"Male Choir Aahs",66:"Scroll",67:"Scroll Plus",68:"Aah Stereo",69:"Aah Mix",70:"Aah with Orchestra"},
{0:"Voice Oohs",64:"Voice Doo",65:"Hmn",66:"Whirl Choir",67:"Ooh Stereo",96:"Voice Humming"},
{0:"Synth Voice",40:"Synth Voice 2",41:"Choral",64:"Analog Voice",65:"Aspirate",66:"Aspirate Detuned",67:"Facula"},
{0:"Orchestra Hit",12:"Lo-Fi Hit",35:"Orchestra Hit 2",40:"Throne",54:"Impact",65:"Brass Stab",66:"Double Hit",67:"Brass Stab 80",68:"Bass Hit",69:"Bass Hit Plus",70:"6th Hit",71:"6th Hit Plus",72:"Euro Hit",73:"Euro Hit Plus",74:"Blowout",75:"Triceratops"},
{0:"Trumpet",16:"Trumpet 2",17:"Bright Trumpet",32:"Warm Trumpet",64:"Dark Trumpet",65:"Dark Trumpet Soft",66:"Soft Trumpet",67:"Blow",68:"Blow Double",69:"4th Trumpet",70:"Synth Trumpet",71:"Sweet Trumpet",72:"Mewllow Sweet Trumpet",73:"Normal Trumpets",74:"Brilliant Trumpet",75:"Fanfare",96:"Flugel Horn",97:"Cornet"},
{0:"Trombone",18:"Trombone 2",64:"Bright Trombone",65:"Mellow Trombone",66:"JJJ",67:"Brilliant Trombone",68:"Hard Attack Trombone",69:"Bright Bass Trombone",70:"Hard Attack Bass Trombone"},
{0:"Tuba",16:"Tuba 2",64:"Hard Attack Tuba",65:"Slow Attack Tuba",66:"Euphonium"},
{0:"Muted Trumpet",40:"Backyard",64:"Muted Trumpet 2",65:"Backstairs"},
{0:"French Horn",6:"French Horn Solo",32:"French Horn 2",37:"Horn Orchestra",64:"Synth Horn",65:"Horn Orchestra 2",66:"Bright French Horn",67:"Hard Attack French Horn"},
{0:"Brass Section",3:"Stereo Brass Section",14:"Sforzando Brass",18:"Mild Brass",35:"Trumpet & Trombone Section",36:"Trumpet & Trombone Section 2",39:"Brass Fall",40:"Brass Section 2",41:"High Brass",42:"Mellow Brass",52:"Bund",53:"Fake Horns",54:"Fake Horns Octave",64:"Super Brass",65:"Super Brass Cut",66:"Super Brass Blown",67:"Powered Sforzando",68:"Powered Sforzando Bright",69:"Alto & Trumpet",70:"Tenor & Trumpet",71:"Brass Brothers",72:"Vague Brothers",73:"Brass Section 3",74:"Sforzando Brass 2",75:"Octave Brass",76:"Alps",77:"Symphonic Brass Ensemble",78:"Phoenix"},
{0:"Synth Brass 1",12:"Quack Brass",20:"Resonant Synth Brass",27:"Synth Brass 3",29:"Analog Sforzando",32:"Jump Brass",40:"Synth Brass with Sub Oscillator",45:"Analog Velocity Brass 1",64:"Analog Brass 1",65:"Synth Then",66:"Sync Brass",67:"Sync Brass Stereo",68:"Analog Horns 1",69:"Analog Horns 2",70:"Analog Horns Octave",71:"Sawtooth Brass Powered"},
{0:"Synth Brass 2",18:"Soft Brass",24:"Poly Brass",40:"Synth Brass 4",41:"Choir Brass",42:"Analog Horns Rich",45:"Analog Velocity Brass 2",64:"Analog Brass 2",65:"Soft Cut",66:"Analog Horns Soft"},
{0:"Soprano Sax",8:"Vague Soprano Sax",64:"Meditation",65:"Meditation Resonant"},
{0:"Alto Sax",18:"Alto Sax Legato",40:"Sax Section",43:"Hyper Alto Sax",64:"Alto Sax Powered",65:"Fake Alto",66:"Fake Alto Plus",67:"Fake Alto Detuned"},
{0:"Tenor Sax",40:"Breathy Tenor Sax",41:"Soft Tenor Sax",64:"Tenor Sax 2",65:"Super Tenor",66:"Super Tenor Plus",67:"Super Tenor Stereo",68:"Tenor & Alto"},
{0:"Baritone Sax"},
{0:"Oboe",64:"Heinz",65:"Heinz Unison",66:"Oboe Expressive"},
{0:"English Horn"},
{0:"Bassoon"},
{0:"Clarinet",40:"Synth & Clarinet",96:"Bass Clarinet"},
{0:"Piccolo",96:"Bang Di"},
{0:"Flute",40:"Neat Breath",64:"Boehm",65:"Boehm Breathy",66:"Pastorale",67:"Shepherd",96:"Qu Di"},
{0:"Recorder",64:"Piplith",65:"Home"},
{0:"Pan Flute",64:"Pan Flute 2",65:"Meadow",96:"Kawala"},
{0:"Blown Bottle",64:"Bottle Legato"},
{0:"Shakuhachi"},
{0:"Whistle",64:"Reverie"},
{0:"Ocarina",64:"Opalina"},
{0:"Square Lead",6:"Square Lead 2",8:"LM Square",18:"Hollow",19:"Shroud",35:"2 Oscillators",64:"Mellow",65:"Solo Sine",66:"Sine Lead",67:"Pulse Lead",68:"Sync Lead",69:"Forced Oscillation",70:"Accent",71:"Brick",72:"Alum",73:"Query",74:"FM Slow Sweep",75:"Sync Lead Double",76:"Curse",77:"Octave Beep",78:"Sine Lead 2",79:"Square Lead 3",80:"Square Lead 4"},
{0:"Sawtooth Lead",6:"Sawtooth Lead 2",8:"Thick Sawtooth",18:"Dynamic Sawtooth",19:"Digital Sawtooth",20:"Big Lead",24:"Heavy Synth",25:"Waspy Synth",26:"Mondo",27:"Rezzy Sawtooth",32:"Double Sawtooth",35:"Toy Lead",36:"Dim Sawtooth",40:"Pulse Sawtooth",41:"Dr. Lead",45:"Velocity Lead",64:"Digger",65:"Dunce",66:"Brass Sawtooth",67:"Sawtooth River",68:"Brass Pulse Double",69:"Sawtooth Trumpet",70:"Hue",71:"Straight Sawtooth",72:"Straight Pulse",73:"PWMania",74:"Mod Saw",75:"Toad",76:"Fat Octave",77:"Overdose",78:"PWM Decay",79:"Saw Decay",80:"Fat Saw Lead",81:"Duck Lead",82:"Boost Saw",83:"Mr. Saw",84:"Thin Saw Lead",85:"Mouth Saw",86:"Dr. Lead 2",87:"Saw Unison",88:"Octave Saw Lead",89:"Sequenced Saw 1",90:"Sequenced Saw 2",91:"Simple Saw Lead",96:"Sequenced Analog"},
{0:"Calliope Lead",40:"Novice",64:"Vent Synth",65:"Pure Lead",66:"Electro Primitive"},
{0:"Chiff Lead",40:"Salt Lead",64:"Rubby",65:"Hard Sync"},
{0:"Charang Lead",64:"Distorted Lead",65:"Wire Lead",66:"Synth Pluck",67:"The Sync Lead"},
{0:"Voice Lead",24:"Synth Aahs",64:"Vox Lead",65:"Breathy Layer",66:"Cypher 1",67:"Cypher 2",68:"Cypher 3",69:"Super Cypher"},
{0:"Fifths Lead",8:"Fifths Lead Soft",35:"Big Five"},
{0:"Bass & Lead",16:"Big & Low",64:"Fat & Perky",65:"Soft Whirl",66:"Cant",67:"Mogul",68:"Distance",69:"Sync B&L",70:"Bass Lead"},
{0:"New Age Pad",64:"Fantasy",65:"Libra",66:"Bell Pad"},
{0:"Warm Pad",16:"Thick Pad",17:"Soft Pad",18:"Sine Pad",40:"Vishnu",64:"Horn Pad",65:"Rotary Strings",66:"Light Pad"},
{0:"Poly Synth Pad",64:"Poly Pad 80",65:"Click Pad",66:"Analog Pad",67:"Square Pad",68:"Snow Pad",69:"Pixie",70:"Pisces",71:"Spiral",72:"Poly Synth Pad 2",73:"Poly Synth Pad King"},
{0:"Choir Pad",64:"Heaven",65:"Light Pad",66:"Itopia",67:"CC Pad",68:"Cosmic Pad",69:"Aah Pad",70:"Ooh Pad",71:"Ooh Aah"},
{0:"Bowed Pad",64:"Glacier",65:"Glass Pad",66:"Square Twang",67:"Square Pad 8"},
{0:"Metallic Pad",64:"Tine Pad",65:"Pan Pad",66:"Queever"},
{0:"Halo Pad",40:"Tiu",64:"Aries",65:"Chorus Pad"},
{0:"Sweep Pad",20:"Shwimmer",27:"Converge",64:"Polar Pad",65:"Sweepy",66:"Celestial",67:"Monsoon",68:"Io"},
{0:"Rain",45:"Clavi Pad",64:"Harmo Rain",65:"African Wind",66:"Carib"},
{0:"Sound Track",27:"Prologue",64:"Ancestral",65:"Rave",66:"Fairy",67:"Hermit"},
{0:"Crystal",12:"Synth Drum Comp",14:"Popcorn",18:"Tiny Bells",35:"Round Glockenspiel",40:"Glockenspiel Chimes",41:"Clear Bells",42:"Chorus Bells",64:"Synth Mallet",65:"Soft Crystal",66:"Loud Glockenspiel",67:"Christmas Bells",68:"Vibraphone Bells",69:"Digital Bells",70:"Air Bells",71:"Bell Harp",72:"Gamelimba",73:"Bounce",74:"Analog Bell"},
{0:"Atmosphere",18:"Warm Atmosphere",19:"Hollow Release",40:"Nylon Electric Piano",64:"Nylon Harp",65:"Harp Vox",66:"Atmosphere Pad",67:"Planet",68:"Lyra",69:"Akasaka",70:"Digital Bermuda",71:"Cloud Pad",72:"Pulse Key",73:"Noise Piano"},
{0:"Brightness",64:"Fantasy Bells",65:"Shining Star",66:"Bright Stab",96:"Smokey"},
{0:"Goblins",64:"Goblins Synth",65:"Creeper",66:"Ring Pad",67:"Ritual",68:"To Heaven",69:"Milky Way",70:"Night",71:"Glisten",72:"Puffy",73:"Mimicry",74:"Parasite",75:"Cicada",76:"Beacon",77:"Goblins' Talk",78:"Temple",96:"Bell Choir",97:"Dharma"},
{0:"Echoes",8:"Echoes 2",14:"Echo Pan",64:"Echo Bells",65:"Big Pan",66:"Synth Piano",67:"Creation",68:"Star Dust",69:"Resonant & Panning",70:"Analog Echo"},
{0:"Sci-Fi",64:"Starz",65:"Odin"},
{0:"Sitar",32:"Detuned Sitar",35:"Sitar 2",40:"Bhuj",64:"Raga Synth",96:"Tambra",97:"Tamboura"},
{0:"Banjo",28:"Muted Banjo",64:"Electric Banjo",96:"Rabab",97:"Gopichant",98:"Oud",99:"Pi Pa"},
{0:"Shamisen",96:"Tsugaru"},
{0:"Koto",64:"FM Koto",96:"Taisho-kin",97:"Kanoon",98:"Zheng"},
{0:"Kalimba",64:"Big Kalimba"},
{0:"Bagpipe",64:"Thistle",96:"Sheng"},
{0:"Fiddle",96:"Er Hu",97:"Ban Hu",98:"Jing Hu"},
{0:"Shanai",64:"Shanai 2",96:"Pungi",97:"Hichiriki",98:"Suo Na"},
{0:"Tinkle Bell",64:"Tickle Bell",96:"Bonang",97:"Altair",98:"Gamelan Gongs",99:"Stereo Gamelan Gongs",100:"Rama Cymbal",101:"Asian Bells"},
{0:"Agogo",96:"Atarigane"},
{0:"Steel Drums",96:"Tablas",97:"Glass Percussion",98:"Thai Bells"},
{0:"Woodblock",96:"Castanets"},
{0:"Taiko Drum",96:"Gran Cassa"},
{0:"Melodic Tom",64:"Melodic Tom 2",65:"Real Tom",66:"Rock Tom",67:"Tim's Set"},
{0:"Synth Drum",64:"Analog Tom",65:"Electronic Percussion",66:"Synth Percussion"},
{0:"Reverse Cymbal",64:"Reverse Cymbal 2",65:"Reverse Cymbal 3",96:"Reverse Snare 1",97:"Reverse Snare 2",98:"Reverse Kick 1",99:"Reverse Concert Bass Drum",100:"Reverse Tom 1",101:"Reverse Tom 2"},
{0:"Fret Noise"},
{0:"Breath Noise"},
{0:"Seashore"},
{0:"Bird Tweet"},
{0:"Telephone Ring"},
{0:"Helicopter"},
{0:"Applause"},
{0:"Gunshot"}
];
var _gm2dr = {
0:"Standard Drum Kit",8:"Room Drum Kit",16:"Power Drum Kit",24:"Electro Drum Kit",25:"Analog Drum Kit",32:"Jazz Drum Kit",40:"Brush Drum Kit",48:"Orchestra Drum Kit",56:"SFX Kit"
};
var _xg64 = {
0:"Cutting Noise",1:"Cutting Noise 2",2:"Distorted Cutting Noise",3:"String Slap",4:"Bass Slide",5:"Pick Scrape",16:"Flute Key Click",32:"Shower",33:"Thunder",34:"Wind",35:"Stream",36:"Bubble",37:"Feed",38:"Cave",48:"Dog",49:"Horse",50:"Bird Tweet 2",51:"Kitty",52:"Growl",53:"Haunted",54:"Ghost",55:"Maou",56:"Insects",57:"Bacteria",64:"Phone Call",65:"Door Squeak",66:"Door Slam",67:"Scratch Cut",68:"Scratch Split",69:"Wind Chime",70:"Telephone Ring 2",71:"Another Scratch",72:"Turn Table",80:"Car Engine Ignition",81:"Car Tires Squeal",82:"Car Passing",83:"Car Crash",84:"Siren",85:"Train",86:"Jet Plane",87:"Starship",88:"Burst",89:"Roller Coaster",90:"Submarine",91:"Connectivity",92:"Mystery",93:"Charging",96:"Laugh",97:"Scream",98:"Punch",99:"Heartbeat",100:"Footsteps",101:"Applause 2",112:"Machine Gun",113:"Laser Gun",114:"Explosion",115:"Firework",116:"Fireball"
};
var _xg126 = {
0:"SFX Kit 1",1:"SFX Kit 2",16:"Techno SFX Kit K/S",17:"Techno SFX Kit Hi",18:"Techno SFX Kit Lo",32:"Sakura SFX Kit",33:"Small Latin SFX Kit",34:"China SFX Kit",35:"Arabic Kit",40:"Live! AfroCuban SFX Kit",41:"Live! AfroCuban SFX Kit 2",42:"Live! Brazilian SFX Kit",43:"Live! PopLatin SFX Kit"
};
var _xg127 = {
0:"Standard Drum Kit",1:"Standard Drum Kit 2",2:"Dry Drum Kit",3:"Bright Drum Kit",4:"Skim Drum Kit",5:"Slim Drum Kit",6:"Rogue Drum Kit",7:"Hob Drum Kit",8:"Room Drum Kit",9:"Dark Room Drum Kit",16:"Rock Drum Kit",17:"Rock Drum Kit 2",24:"Electro Drum Kit",25:"Analog Drum Kit",26:"Analog Drum Kit 2",27:"Dance Drum Kit",28:"Hip Hop Drum Kit",29:"Jungle Drum Kit",30:"Apogee Drum Kit",31:"Perigee Drum Kit",32:"Jazz Drum Kit",33:"Jazz Drum Kit 2",40:"Brush Drum Kit",41:"Brush Drum Kit 2",48:"Symphony Drum Kit",56:"Natural Drum Kit",57:"Natural Funk Drum Kit",64:"Tramp Drum Kit",65:"Amber Drum Kit",66:"Coffin Drum Kit",80:"Live! Standard Drum Kit",81:"Live! Funk Drum Kit",82:"Live! Brush Drum Kit",83:"Live! Standard + Percussion Kit",84:"Live! Funk + Percussion Kit",85:"Live! Brush + Percussion Kit"
};
//#end

function _strip(s) {
  if (typeof s == 'undefined') s = '';
  return ' ' + s.toString().toLowerCase().replace(/\W+/g, ' ').trim() + ' ';
}

var _program = {};
for (i = 0; i < _instr.length; i++) _program[_strip(_instr[i])] = i;
for (i = 0; i < _group.length; i++) _program[_strip(_group[i])] = i * 8;
for (i in _more) {
  /* istanbul ignore else */
  if (_more.hasOwnProperty(i)) _program[_strip(i)] = _more[i];
}

var _percussion = {};
for (i = 0; i < _perc.length; i++) _percussion[_strip(_perc[i])] = i + 27;

function _score(a, b) {
  var c, i, j, x, y, z;
  if (a.length > b.length) { c = a; a = b; b = c; }
  var m = [];
  for (i = 0; i < a.length; i++) {
    m[i] = [];
    if (!i) {
      for (j = 0; j < b.length; j++) {
        m[i][j] = a[i] == b[j] ? 2 : 0;
      }
    }
    else {
      m[i][0] = a[i] == b[0] ? 2 : 0;
      for (j = 1; j < b.length; j++) {
        x = m[i - 1][j] - (a[i] == ' ' ? 1 : 2);
        y = m[i][j - 1] - (b[j] == ' ' ? 1 : 2);
        z = m[i - 1][j - 1] + (a[i] == b[j] ? 2 : -2);
        if (x < 0) x = 0;
        if (x < y) x = y;
        if (x < z) x = z;
        m[i][j] = x;
      }
    }
  }
  for (i = 0; i < a.length; i++) for (j = 0; j < b.length; j++) m[i][j] = m[i][j] > 2 ? m[i][j] - 2 : 0;
  c = 0;
  while (m.length) {
    x = 0; y = 0; z = 0;
    for (i = 0; i < m.length; i++) for (j = 0; j < m[0].length; j++) {
      if (z < m[i][j]) {
        x = i; y = j; z = m[i][j];
      }
    }
    if (!z) break;
    c += z;
    m.splice(x, 1);
    for (i = 0; i < m.length; i++) m[i].splice(y);
  }
  return c;
}

function _search(h, s) {
  var k, l, m, n, q;
  l = 0; m = 0; n = 0;
  for (k in h) {
    /* istanbul ignore else */
    if (h.hasOwnProperty(k)) {
      q = _score(s, k);
      if (q > n || q == n && k.length < l) {
        l = k.length; m = h[k]; n = q;
      }
    }
  }
  return [n, m];
}

var _noteValue = JZZ.MIDI.noteValue;

JZZ.MIDI.programName = function(n, m, l) {
  var s;
  if (n >= 0 && n <= 127) {
    if (typeof m == 'undefined' && typeof l == 'undefined') return _instr[n];
    if (m == 0 && l) {
      s = _xg[n][l];
      if (s) return s;
    }
    if (m == 0x40 && !l) {
      s = _xg64[n];
      if (s) return s;
    }
    if (m == 0x79) {
      s = _gm2[n][l];
      if (s) return s;
    }
    if (m == 0x78) {
      if (!l) s = _gm2dr[n];
      return s || 'Drum Kit *';
    }
    if (m == 0x7e) {
      if (!l) s = _xg126[n];
      return s || 'SFX Kit *';
    }
    if (m == 0x7f) {
      if (!l) s = _xg127[n];
      return s || 'Drum Kit *';
    }
    if (!l) {
      s = _gs[n][m];
      if (s) return s;
    }
    return _instr[n] + ' *';
  }
};
JZZ.MIDI.groupName = function(n) { if (n >= 0 && n <= 127) return _group[n >> 3]; };
JZZ.MIDI.percussionName = function(n) { if (n >= 27 && n <= 87) return _perc[n - 27]; };

JZZ.MIDI.programValue = function(x) {
  if (x == parseInt(x)) return x;
  var s = _strip(x);
  var n = _program[s];
  if (typeof n != 'undefined') return n;
  var guess = _search(_program, s);
  return guess[1];
};

JZZ.MIDI.noteValue = function(x) {
  var n = _noteValue(x);
  if (typeof n != 'undefined') return n;
  var s = _strip(x);
  n = _percussion[s];
  if (typeof n != 'undefined') return n;
  var guess = _search(_percussion, s);
  return guess[1];
};

JZZ.MIDI.guessValue = function(x) {
  if (x == parseInt(x) && x >= 0 && x <= 127) return x;
  var n = _noteValue(x);
  if (typeof n != 'undefined') return -n;
  var s = _strip(x);
  n = _program[s];
  if (typeof n != 'undefined') return n;
  n = _percussion[s];
  if (typeof n != 'undefined') return -n;
  var a = _search(_program, s);
  var b = _search(_percussion, s);
  return b[0] > a[0] ? -b[1] : a[1];
};

JZZ.MIDI.GM = {};
JZZ.MIDI.GM.allGM2 = function() {
  var ret = [];
  var i, k;
  for (i = 0; i < 128; i++) {
    for (k in _gm2[i]) {
      /* istanbul ignore else */
      if (_gm2[i].hasOwnProperty(k)) ret.push([i, 121, parseInt(k)]);
    }
  }
  for (k in _gm2dr) {
    /* istanbul ignore else */
    if (_gm2dr.hasOwnProperty(k)) ret.push([parseInt(k), 120, 0]);
  }
  return ret;
};
JZZ.MIDI.GM.allGS = function() {
  var ret = [];
  var i, k;
  for (i = 0; i < 128; i++) {
    for (k in _gs[i]) {
      /* istanbul ignore else */
      if (_gs[i].hasOwnProperty(k)) ret.push([i, parseInt(k), 0]);
    }
  }
  return ret;
};
JZZ.MIDI.GM.allXG = function() {
  var ret = [];
  var i, k;
  for (i = 0; i < 128; i++) {
    for (k in _xg[i]) {
      /* istanbul ignore else */
      if (_xg[i].hasOwnProperty(k)) ret.push([i, 0, parseInt(k)]);
    }
  }
  for (k in _xg64) {
    /* istanbul ignore else */
    if (_xg64.hasOwnProperty(k)) ret.push([parseInt(k), 64, 0]);
  }
  for (k in _xg126) {
    /* istanbul ignore else */
    if (_xg126.hasOwnProperty(k)) ret.push([parseInt(k), 126, 0]);
  }
  for (k in _xg127) {
    /* istanbul ignore else */
    if (_xg127.hasOwnProperty(k)) ret.push([parseInt(k), 127, 0]);
  }
  return ret;
};

});