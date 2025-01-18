# Grip
*Generate Recursive Interesting Planets*

[Try in browser](https://troido.nl/grip/) or download the [latest release](https://github.com/jmdejong/grip/releases/latest)

Procedural generation experiment to create planets that generate generating higher level of detail on the fly as distance to area decreases.

Goals of this experiment:
- Planet looks good from afar
- Planet looks good from the surface; you can walk around it in first person and see an interesting world around you
- At all distances the performance is good and memory usage is low
- The world is connected and features at one location affect features at another location (for example: rivers that flow from mountains to the sea, and erosion)

## Controls
- Mouse: look around
- WASD/arrow keys: move horizonally (distance to the center of the planet remains approximately equal
- Space and C: move up and down (away from / towards center of planet)
- Shift: holding shift while moving makes you much faster
- Ctrl: holding ctrl while moving makes you even faster
- M: place a marker at the current position
- P: cycle through the debug rendering modes (not all rendering modes work in the web version)
