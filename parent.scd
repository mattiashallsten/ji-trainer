// =====================================================================
// SuperCollider Workspace
// =====================================================================

(
s.waitForBoot{
	// * Variables
	// ** Path
	var path = PathName(thisProcess.nowExecutingPath).pathOnly;
	var ratios, selectableRatios;

	var routine, notes; 				// used in `playSines' function
	var crNote;
	
	// ** Settings
	var globalRoot = 330, waitTime = 40;

	var currentLimits = Dictionary.newFrom([1, true]);
	var selectableLimits;
	
	var sortByFav = [0,1], sortByLimit = false;
	var selectedClass = \pyth, selectedRatio;
	var selectedWaveform = \sine;
	var isRunning = false;

	var playRoot = true, playFifth = true;

	// ** GUI: create variables
	var window = Window("Just intonation trainer", Rect(200,200,350,100));

	var outDevices = ServerOptions.outDevices;
	var outputDevice = outDevices[0];
	var selectOutput, rebootServerBtn;
	
	var selectRatio, selectRoot, selectWaitTime, goButton, stopButton, button2;
	var selectLimit, selectTonality, selectSortByFav;
	var selectNote, selectOctave;
	var openCrButton;
	var openErButton;

	var selectWaveform;

	var playRootBt, playFifthBt;

	var standardfont = Font.monospace(12);

	// ** GUI: cr variables
	var crWindow, crDown, crUp, crDisplay;
	var crOpen = false;

	// ** GUI: er variables
	var erWindow;
	var erOpen = false;
	var erLines, erAddButton;

	// ** FUNCTIONS
	// *** Function: playSines

	var playSines  = {|note=1.25, root=329.62755691287|
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

	// *** Function: updateSelectableRatios
	var updateSelectableRatios  = {
		selectableRatios = [];
		sortRatios.();

		// loop through all the selectable ratios
		ratios.do{|item|
			var correctFav = false;

			// if sorting by fav, listen for the value 1. if not,
			// listen for the values 0 and 1
			sortByFav.do{|favVal|
				//if(item.fav == favVal, {
				if(item.fav == favVal, {
					correctFav = true
				});
			};

			// if both are true, add to the list of selectable ratios
			if(currentLimits[item.limit] && correctFav, {
				//if(correctFav, {
				selectableRatios = selectableRatios.add(item)
			});
		};

		selectRatio.items_(selectableRatios.collect{|item|
			item.print ++ ": " ++ item.description;
		});
	};

	// *** Function: sortRatios
	var sortRatios = {
		var len = ratios.size - 1;

		len.do{|i|
			len.do{|i|
				var x = ratios[i];
				var y = ratios[i + 1];

				if(x.asNum > y.asNum, {
					ratios[i] = y;
					ratios[i + 1] = x
				})
			}
		};
	};

	// *** Function: getSelectableLimits
	var getSelectableLimits = {
		var limits = Dictionary.new();
		var limitsA = [];

		(0..20).do{|i| limits[i.nthPrime.asSymbol] = 0};
		
		ratios.do{|r|
			limits[r.limit.asSymbol] = 1
		};

		limits.keysDo{|l| if(limits[l] == 1, {limitsA = limitsA.add(l.asInteger)})};
		limitsA = limitsA.sort;
		selectableLimits = [0] ++ limitsA;
		// limitsA.do{|l|
		// 	if(l == 3, {
		// 		selectableLimits = selectableLimits.add()
		// 	}, {
		// 		selectableLimits = selectableLimits.add(l.asString ++ "-limit")
		// 	});
		// };

		if(selectLimit.notNil, {
			selectLimit.items = selectableLimits.collect{|l|
				if(l == 0, {
					"All"
				}, {
					if(l == 3, {
						"Pythagorean"
					}, {
						l.asString ++ "-limit"
					})
				})
			}
		});
	};

	// *** Function: loadRatios
	var loadRatios = {
		if(File.exists(path ++ "ratios.json"), {
			var r = File(path ++ "ratios.json", "r").readAllString.parseJSON;
			var ratios = [];
			r.do{|item, i|
				if(item["ratio"].notNil, {
					if(item["ratio"].split($/).size > 1, {
						ratios = ratios.add(Ratio(
							description: item["description"] ? "",
							fav: item["fav"].asInteger ? 0,
							ratioAsString: item["ratio"]
						))
					}, {
						format("ratio \"%\" not in a/b format!", item["description"]).error;
					})
				}, {
					format("ratio \"%\" does not contain a ratio!", item["description"]).error;
				})
			};
			ratios;
		}, {
			[Ratio(1,1, description: "Prime unity")]
		})
	};

	// *** Function: calculateRoot
	var calculateRoot = {
		var r = selectOctave.value * 12 + selectNote.value;
		r = r.midicps.round(0.01);
		selectRoot.valueAction_(r);
	};

	// *** Function: init
	var initVariables = {
		ratios = loadRatios.();
		selectableRatios = ratios.collect{|i| i};
		(0..20).do{|i| currentLimits[i.nthPrime] = true};
		getSelectableLimits.();
	};

	// *** Function: initGUI
	var initGUI = {
		// *** GUI: layout
		window.layout = VLayout(
			// * GUI: Title
			StaticText()
			.string_("Just Intonation Trainer")
			.font_(Font.monospace(size: 30))
			.align_(\center),

			StaticText()
			.string_("Mattias Hållsten, 2020-2021")
			.font_(Font.monospace(size: 14))
			.align_(\right),

			HLayout(
				StaticText()
				.string_("Select output:")
				.font_(standardfont),

				[selectOutput = PopUpMenu()
				.items_(outDevices.collect{|d| d.asString})
				.font_(standardfont)
				.action_{|menu|
					outputDevice = outDevices[menu.value];
					s.options.outDevice = outputDevice;
				}, stretch: 1],

				rebootServerBtn = Button()
				.states_([["Reboot audio server"]])
				.font_(standardfont)
				.action_{ s.reboot }

				
			),

			HLayout(
				// *** GUI: openCrButton
				openCrButton = Button()
				.font_(standardfont)
				.states_([["Calibrate root"]])
				.action_{
					openCrFunc.()
				},
				// *** GUI: openErButton
				openErButton = Button()
				.font_(standardfont)
				.states_([["Ratio editor (EXPERIMENTAL)"]])
				.action_{
					openErFunc.()
				}
			),


			HLayout(
				[StaticText().string_("Select limit:").font_(standardfont), stretch: 0.4],

				// * GUI: selectLimit
				[selectLimit = PopUpMenu()
					//.items_(["All", "Pythagorean", "5-limit", "7-limit", "11-limit"])
					.items_(selectableLimits.collect{|l|
						if(l == 0, {
							"All"
						}, {
							if(l == 3, {
								"Pythagorean"
							}, {
								l.asString ++ "-limit"
							})
						})
					})
					.allowsReselection_(true)
					.font_(standardfont)
					.action_{|field|
						var val = field.value;

						(0..20).do{|i| currentLimits[i.nthPrime] = false};
						if(val == 0, {
							(0..20).do{|i| currentLimits[i.nthPrime] = true};
						}, {
							currentLimits[selectableLimits[val]] = true
						});

						updateSelectableRatios.value();

					},
					stretch: 1],

				// * GUI: Select sort by fav
				[selectSortByFav = CheckBox()
					.string_("Sort by favourite?")
					.font_(standardfont)
					.action_{
						var val = selectSortByFav.value;
						
						sortByFav = switch(val,
							false, {[0,1]},
							true, {[1]}
						);

						updateSelectableRatios.value()
					},
					stretch: 0
				]
				
			),
			HLayout(
				// * GUI: Select ratio
				selectRatio = PopUpMenu()
				.items_(selectableRatios.collect{|item|
					item.asString ++ ": " ++ item.description;
				})
				.allowsReselection_(true)
				.minSize_(Size(200, 0))
				.font_(standardfont)
				.action_{|field|
					var val = field.value;
					//var compiled = this.compile(selectableRatios[val].ratio);
					var compiled = this.compile(selectableRatios[val].print);

					selectedRatio = compiled.value;
				},

				StaticText().string_("Root:" ).font_(standardfont),

				// * GUI: selectRoot
				selectRoot = TextField()
				.minSize_(Size(50,0)).font_(standardfont)
				.action_{|field|
					var val = this.compile(field.value).value;
					var m = val.cpsmidi.round(1).asInteger;
					var o = m.div(12).asInteger;
					var n = m % 12;

					selectOctave.value_(o);
					selectNote.value_(n);

					globalRoot = val
				},

				StaticText().string_("Octave:" ).font_(standardfont),

				// * GUI: selectOctave
				selectOctave = PopUpMenu()
				.items_((0..9).collect{|i| i.asString})
				.font_(standardfont)
				.action_{calculateRoot.()},

				StaticText().string_("Note:" ).font_(standardfont),

				// * GUI: selectNote
				selectNote = PopUpMenu()
				.items_([
					"C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G",
					"G#/Ab", "A", "A#/Bb", "B"
				])
				.font_(standardfont)
				.action_{calculateRoot.()},

				StaticText().string_("Wait time: ").font_(Font.monospace),

				// * GUI: Select Wait Time
				selectWaitTime = TextField()
				.minSize_(Size(40,0))
				.font_(standardfont)
				.action_{|field|
					var val = this.compile(field.value).value;

					waitTime = val
				},

				StaticText().string_("Waveform:").font_(standardfont),

				// * GUI: Select waveform
				selectWaveform = PopUpMenu()
				.items_(["Sine wave", "Sawtooth save"])
				.allowsReselection_(true)
				.font_(standardfont)
				.action_{
					var val = selectWaveform.value;

					selectedWaveform = switch(val,
						0, {\sine},
						1, {\saw}
					);
				}
			),
			HLayout(
				[VLayout(
					// * GUI: Go button
					goButton = Button()
					.states_([
						["--- GO ---", Color.black, Color.green],
						["--- STOP ---", Color.black, Color.red]
					])
					.minSize_(Size(200, 100))
					.font_(Font.monospace(25))
					.action_{
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
					}
				), stretch: 3],
				VLayout(
					// * GUI: Play root button
					playRootBt = CheckBox()
					.string_("Play root?")
					.font_(standardfont)
					.action_{
						var val = playRootBt.value;

						playRoot = val
					},
					// * GUI: Play fifth button
					playFifthBt = CheckBox()
					.string_("Play fifth?")
					.font_(standardfont)
					.action_{
						var val = playFifthBt.value;

						playFifth = val
					}
				)
			)
		);
		// *** GUI: init values
		playRootBt.valueAction = 1;
		playFifthBt.valueAction = 0;

		selectWaveform.valueAction = 0;

		selectRatio.valueAction = 0;
		selectRoot.valueAction_(globalRoot);
		selectWaitTime.valueAction_(waitTime);

		selectOctave.value_(6);

		window.front
	};

	// *** Function: openCrFunc
	var openCrFunc = {
		if(crOpen, {
			"Already open".postln;
		}, {
			crNote = Synth(selectedWaveform, [
				\freq, globalRoot * 1,
				\atk, 2,
				\rel, 2
			]);
			
			crWindow = Window.new("Calibrate root", Rect(400, 600, 400, 200))
			.onClose_{
				if(crNote.notNil, { crNote.set(\gate, 0); crNote = nil } );
				crOpen = false;
			};

			crWindow.layout = VLayout(
				crDisplay = TextField()
				.font_(Font.monospace(20))
				.string_(globalRoot.asString)
				.align_(\center)
				.action_{|field|
					var val = this.compile(field.value).value;
					crNote.set(\freq, val);
					selectRoot.valueAction_(val);
				},

				HLayout(
					crDown = Button()
					.font_(Font.monospace(20))
					.states_([["<"]])
					.action_{
						crDisplay.valueAction_(globalRoot - 1);
					},

					crUp = Button()
					.font_(Font.monospace(20))
					.states_([[">"]])
					.action_{
						crDisplay.valueAction_(globalRoot + 1);
					},
				)

					
			);
			
			crWindow.front;
			crOpen = true;
		});
	};

	// *** Function: openErFunc
	var openErFunc = {|reset=false|
		if(erOpen || reset, {
			"ratio editor was already open, closing...".postln;
			erWindow.close;
			erOpen = false;
			openErFunc.();
		}, {
			"ratio editor was close. opening...".postln;
			erOpen = true;
			erWindow = Window.new("Ratio editor", Rect(400, 400, 400, 600), scroll: true)
			.onClose_{
				erOpen = false;
			};

			StaticText(
				erWindow,
				Rect(
					30,
					40,
					erWindow.bounds.width * 0.3,
					20
				)
			)
			.string_("Ratio")
			.font_(standardfont);

			StaticText(
				erWindow,
				Rect(
					erWindow.bounds.width * 0.32,
					40,
					erWindow.bounds.width * 0.3,
					20
				)
			)
			.string_("Description")
			.font_(standardfont);

			StaticText(
				erWindow,
				Rect(
					erWindow.bounds.width * 0.9,
					40,
					erWindow.bounds.width * 0.3,
					20
				)
			)
			.string_("Fav?")
			.font_(standardfont);

			updateErLayout.();

			

			erWindow.front;
			format("ratio editor is open: %", erOpen.asString).postln;
		});
	};
	// *** Function: updateErLayout
	var updateErLayout = {
		if(erLines.notNil, {
			erLines.do{|l|
				l[\ratio].remove;
				l[\description].remove;
				l[\fav].remove;
				l[\remove].remove;
			};
			erLines = nil;
		});

		if(erAddButton.notNil, { erAddButton.remove; erAddButton = nil });

		erLines = ratios.collect{|r, i|
			(
				remove: Button(
					erWindow,
					Rect(
						5,
						(i + 2) * 30 + 5,
						20,
						20
					)
				)
				.states_([["-"]])
				.font_(standardfont)
				.action_{
					ratios.removeAt(i);
					getSelectableLimits.();
					updateSelectableRatios.();
					updateErLayout.();
				},
				// ratio
				ratio: TextField(erWindow, Rect(
					30,
					(i + 2) * 30 + 5,
					erWindow.bounds.width * 0.2,
					20
				))
				.font_(standardfont)
				.string_(r.asString)
				.action_{|field|
					ratios[i].setRatioWithString(field.value);
					getSelectableLimits.();
					updateSelectableRatios.();
					updateErLayout.();
				},
				
				description:
				// description
				TextField(erWindow, Rect(
					erWindow.bounds.width * 0.32,
					(i + 2) * 30 + 5,
					erWindow.bounds.width * 0.6,
					20
				))
				.font_(standardfont)
				.string_(r.description)
				.action_{|field|
					ratios[i].setDescription(field.value);
					getSelectableLimits.();
					updateSelectableRatios.();
				},

				// fav
				fav:
				CheckBox(erWindow, Rect(
					erWindow.bounds.width * 0.95,
					(i + 2) * 30 + 5,
					20,
					20
				))
				.font_(standardfont)
				.value_(r.fav)
				.action_{|checkbox|
					r.setFav(checkbox.value);
					updateSelectableRatios.();
				};
			)
		};

		erAddButton = Button(
			erWindow,
			Rect(
				erWindow.bounds.width * 0.1,
				10,
				erWindow.bounds.width * 0.8,
				20
			)
		)
		.font_(standardfont)
		.states_([["+"]])
		.action_{
			ratios = ratios.add(Ratio(1,1));
			getSelectableLimits.();
			updateSelectableRatios.();
			updateErLayout.();
		};
	};

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
	
	initVariables.();
	initGUI.();
}
)

// Local variables:
// eval: (outshine-mode t)
// End: