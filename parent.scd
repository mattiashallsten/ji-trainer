// =====================================================================
// SuperCollider Workspace
// =====================================================================

(
s.waitForBoot{
	// * Variables
	// ** Path
	var path = PathName(thisProcess.nowExecutingPath).pathOnly;
	
	// ** Settings
	var globalRoot = 330, waitTime = 40;
	var currentLimit = [3,5,7,11];
	var sortByFav = [0,1], sortByLimit = false;
	var selectedClass = \pyth, selectedRatio;
	var selectedWaveform = \sine;
	var isRunning = false;

	var playRoot = true, playFifth = true;

	// ** GUI
	var window = Window("Just intonation trainer", Rect(200,200,350,100));

	var selectRatio, selectRoot, selectWaitTime, goButton, stopButton, button2;
	var selectLimit, selectTonality, selectSortByFav;

	var selectWaveform;

	var playRootBt, playFifthBt;

	var standardfont = Font.monospace(12);

	// ** FUNCTIONS
	var playSines, routine, notes;
	
	var updateSelectableRatios;

	var ratios, selectableRatios;

	

	// ** ratio constructor function
	~ratioConstructor = {|ratio="", description="", limit=3, fav=0|
		var obj = (
			ratio: ratio,
			description: description,
			limit: limit,
			fav: fav,
		);

		obj
	};

	(path ++ "ratios.scd").load;

	// ** Ratios
	ratios = ~ratios;

	// ** Selectable ratios
	selectableRatios = ratios.collect{|i| i};

	// * SynthDef
	SynthDef(\sine, {
		|
		freq=440, gate=1, pan=0, atk=0.01, rel=1, lagTime=0.01
		|
		var env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction:2);
		var sig = SinOsc.ar(freq.varlag(lagTime, 2));

		sig = Pan2.ar(sig, pan);
		sig = sig * 0.2 * env;

		Out.ar(0,sig);
	}).add;

	SynthDef(\saw, {
		|
		freq=440, gate=1, pan=0, atk=0.01, rel=1, lagTime=0.01, cutoff=8
		|
		var env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction:2);
		var sig = Saw.ar(freq.varlag(lagTime, 2));

		sig = BLowPass.ar(sig, freq * cutoff);
		sig = Pan2.ar(sig, pan);
		sig = sig * 0.15 * env;

		Out.ar(0,sig)
	}).add;



	// * LAYOUT
	window.layout = VLayout(
		StaticText()
		.string_("Just Intonation Trainer")
		.font_(Font.monospace(size: 30))
		.align_(\center),
		HLayout(
			[StaticText().string_("Select limit:").font_(standardfont), stretch: 0.4],
			
			[selectLimit = PopUpMenu()
				.items_(["All", "Pythagorean", "5-limit", "7-limit", "11-limit"])
				.allowsReselection_(true)
				.font_(standardfont),
				stretch: 1],


			[selectSortByFav = CheckBox().string_("Sort by favourite?").font_(standardfont), stretch: 0]
			
		),
		HLayout(
			selectRatio = PopUpMenu()
			.items_(selectableRatios.collect{|item|
				item.ratio + ": " + item.description
			})
			.allowsReselection_(true)
			.minSize_(Size(200, 0))
			.font_(standardfont),

			StaticText().string_("Root:" ).font_(standardfont),
			
			selectRoot = TextField().minSize_(Size(50,0)).font_(standardfont),

			StaticText().string_("Wait time: ").font_(Font.monospace),

			selectWaitTime = TextField().minSize_(Size(40,0)).font_(standardfont),

			StaticText().string_("Waveform:").font_(standardfont),

			selectWaveform = PopUpMenu()
			.items_(["Sine wave", "Sawtooth save"])
			.allowsReselection_(true)
			.font_(standardfont)
		),
		HLayout(
			[VLayout(
				goButton = Button()
				.states_([
					["--- GO ---", Color.black, Color.green],
					["--- STOP ---", Color.black, Color.red]
				])
				.minSize_(Size(200, 100))
				.font_(Font.monospace(25)),
			), stretch: 3],
			VLayout(
				playRootBt = CheckBox().string_("Play root?").font_(standardfont),
				playFifthBt = CheckBox().string_("Play fifth?").font_(standardfont)
			)
		)
	);

	// * Update ratios function
	updateSelectableRatios = {
		selectableRatios = [];

		// loop through all the selectable ratios
		ratios.do{|item|
			var correctLimit = false, correctFav = false;

			// loop through the current limit(s)
			currentLimit.do{|limit|
				if(item.limit == limit, {
					correctLimit = true
				})
			};

			// if sorting by fav, listen for the value 1. if not,
			// listen for the values 0 and 1
			sortByFav.do{|favVal|
				if(item.fav == favVal, {
					correctFav = true
				});
			};

			// if both are true, add to the list of selectable ratios
			if(correctLimit && correctFav, {
				selectableRatios = selectableRatios.add(item)
			});
		};

		selectRatio.items_(selectableRatios.collect{|item|
			item.ratio + ": " + item.description
		});

		// selectRatio.valueAction = 0;
	};

	// * Actions for GUI elements
	// ** Select Limit
	selectLimit.action = {|field|
		var val = field.value;

		currentLimit = switch(val,
			0, {[3,5,7,11]},
			1, {[3]},
			2, {[5]},
			3, {[7]},
			4, {[11]}
		);

		updateSelectableRatios.value();

	};

	// ** Select if to sort by favorite
	selectSortByFav.action = {
		//		sortByFav = selectSortByFav.value;

		var val = selectSortByFav.value;

		val.postln;
		
		sortByFav = switch(val,
			false, {[0,1]},
			true, {[1]}
		);

		sortByFav.postln;

		updateSelectableRatios.value()
	};

	// ** Select ratio
	selectRatio.action = {|field|
		var val = field.value;
		var compiled = this.compile(selectableRatios[val].ratio);

		selectedRatio = compiled.value;
	};

	// ** Select root frequency
	selectRoot.action = {|field|
		var val = this.compile(field.value).value;

		globalRoot = val
	};

	// ** Select wait time
	selectWaitTime.action = {|field|
		var val = this.compile(field.value).value;

		waitTime = val
	};


	// ** Go Button
	goButton.action = {
		var val = goButton.value;

		switch(val,
			1, {
				"button pressed".postln;
				if((selectedRatio.notNil) && (isRunning == false), {
					playSines.value(selectedRatio, globalRoot);
					isRunning == true;
				})
			},
			0, {
				if(routine.notNil, {routine.stop});
				if(notes.notNil, {
					notes.do(_.set(\rel, 0.1, \gate, 0))
				});
				isRunning = false;
			};
		);
	};

	playRootBt.action = {
		var val = playRootBt.value;

		playRoot = val
	};

	playFifthBt.action = {
		var val = playFifthBt.value;

		playFifth = val
	};

	playRootBt.valueAction = 1;
	playFifthBt.valueAction = 1;

	selectWaveform.action = {
		var val = selectWaveform.value;

		selectedWaveform = switch(val,
			0, {\sine},
			1, {\saw}
		);
	};

	selectWaveform.valueAction = 0;

	// * Play function
	playSines = {|note=1.25, root=329.62755691287|
		notes = [];

		if(playRoot, {
			notes = notes.add(
				Synth(selectedWaveform, [
					\freq, root * 1,
					\atk, 4,
					\rel, 7
				])
			)
		});
		if(playFifth, {
			notes = notes.add(
				Synth(selectedWaveform, [
					\freq, root * 3/2,
					\atk, 4,
					\rel, 7
				])
			)
		});
		// notes = [1, 3/2].collect{|item|
		// 	Synth(\sine, [
		// 		\freq, root * item,
		// 		\atk, 4,
		// 		\rel, 7
		// 	]);
		// };

		routine = Routine {
			wait(waitTime);
			notes = notes.add(
				Synth(selectedWaveform, [
					\freq, root * note,
					\atk, 4,
					\rel, 7
				])
			);
			wait(20);
			notes.do(_.set(\gate, 0));
			isRunning = false;
			wait(5);
			goButton.valueAction = 0;
		};

		AppClock.play(routine);
	};

	// * Init values
	selectRatio.valueAction = 0;
	selectRoot.valueAction_(globalRoot);
	selectWaitTime.valueAction_(waitTime);

	window.front
}
)