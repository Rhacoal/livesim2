Dark Enegy Processor Live Simulator
===================================

DEPLS (pronounced **Deep Less**) is a Love Live! School Idol Festival Live Show Simulator written in Lua meant to be run under LOVE2D framework.

You need LOVE2D v0.10.1 or above to run this live simulator.

How to run
==========

Start LOVE2D with this command-line

    love <current directory> livesim <beatmap_name>

There are 2 example beatmap which you can specify in `beatmap_name` argument.

* `::1` - Daydream Warrior beatmap made by yuyu

* `::2` - MOMENT RING beatmap made by yuyu (including fancy colored notes)

Put your beatmap in `<DEPLS Save Directory>/beatmap` folder and the audio in `<DEPLS Save Directory>/audio`.
Beatmap name and audio name must match, but the extension doesn't need to, and will try to load WAV or OGG, in order.

Save directory can be seen if `lovec` is invoked (in Windows) or running `love` from terminal (Ubuntu and Mac OS X)

Status
======

You can play with keyboard or just view beatmap, although installing beatmaps is bit tricky.

At the moment, only desktop operating system are supported (Windows, Mac OS X, and Ubuntu).
Running it under Android is possible, but the audio delay is unacceptable, and will refuse to run under iOS

Controls
========

* A, S, D, F, Space, J, K, L, Semicolon = Tap notes

* Left Shift = Show debug information (FPS, Elapsed time, ...)

* Left Ctrl = Toggle Autoplay On/Off

* Left Alt = Show note distance

* F5 = Turn the song volume down by 5% (default is 80%)

* F6 = Turn the song volume up by5%

* Backspace = Restart live simulator

Supported Beatmaps
==================

* Raw SIF beatmap, this is main beatmap format that DEPLS uses.

* Sukufesu Simulator beatmap, yuyu live simulator beatmap.  Conversion will be done on load.

* Custom Beatmap Festival project folder. Conversion will be done on load

* MIDI, specialized MIDI file. MIDI is loaded and converted on-the-fly.

Disclaimer
==========

This live simulator uses some assets from Sukufesu Simulator made by yuyu, like the different note color.
This live simulator also uses many ssets from Love Live! School Idol Festival game (background, header, ...)
