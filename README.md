# OtisFX
A small set of effects for [Reshade](http://reshade.me). 

### Prerequisites
You should have [Reshade](http://reshade.me) v1.0 or higher.


### How to install

Copy all files in `src` into the `Reshade` folder in your game's bin folder. This `Reshade` folder should already be there and it already should have a bunch of .cfg files, like `Pipeline.cfg`. 

Once the files are in place, open `Pipeline.cfg` in a text editor, e.g. Notepad++, and add the line:
``` java
#include EFFECT(OtisFX, Util)
```

near the top of the file, with the other lines with `Util`. 

At the bottom, add:
``` java
#include EFFECT(OtisFX, Emphasize)
```

This makes sure the effect code is embedded in the [Reshade](http://reshade.me) pipeline.

### Configuring and enabling effects
By default all effects are disabled. To enable the effects and configure the parameters used in the effects, open the file `OtisFX.cfg` in a text editor, e.g. Notepad++. 

To enable an effect, change the `0` value for a USE_*effectname* define to `1`. Change any other values you might want to configure as well and save the file. [Reshade](http://reshade.me) should now compile the shaders when you run your game again and the effect should be compiled into the shaders. To activate the effect, you have to press the hotkey, see the list below. 

#### Enabling in-game
To enable the effects in-game, press the assigned hotkey of the effect. These are described below.

 * Emphasize: F8

