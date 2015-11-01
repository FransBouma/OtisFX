# OtisFX
A small set of effects for [Reshade](http://reshade.me). 

### Prerequisites
You should have [Reshade](http://reshade.me) v1.0 or higher.

### How to install
Download the zip using the button on the right which says 'Download ZIP'. This will give you a file called 'Master.zip', which contains all code. Unpack the zip and go to the `src` folder. Copy all files and folders inside the `src` folder into the `Reshade` folder in your game's bin folder. This `Reshade` folder should already be there and it already should have a bunch of .cfg files, like `Pipeline.cfg`. If you're using the Reshade Mediator tool, you should copy the contents of the `src` folder to the local source folder of your profile in Mediator. 

Once the files are in place, open `Pipeline.cfg` in a text editor, e.g. Notepad++, and add the line:
``` java
#include EFFECT(OtisFX, Util)
```

near the top of the file, with the other lines with `Util`. 

At the bottom, add:
``` java
#include EFFECT(OtisFX, Emphasize)
#include EFFECT(OtisFX, GoldenRatio)
```

This makes sure the effect code is embedded in the [Reshade](http://reshade.me) pipeline.

### Configuring and enabling effects
By default all effects are enabled in code, but not activated. You should configure the keybindings to your liking, I've added keybindings which work for me, but it might be they conflict with e.g. your game's keybindings for save/load. To enable the effects and configure the parameters used in the effects, open the file `OtisFX.cfg` in a text editor, e.g. Notepad++. 

To enable an effect, change the `0` value for a USE_*effectname* define to `1`. Change any other values you might want to configure as well and save the file. [Reshade](http://reshade.me) should now compile the shaders when you run your game again and the effect should be compiled into the shaders. To activate the effect, you have to press the hotkey, see the list below. 

#### Enabling in-game
To enable the effects in-game, press the assigned hotkey of the effect. These are described below.

 * Emphasize: F8
 * GoldenRatio: F6
 
### Effects included
The following effects are currently included: 

#### Emphasize
Emphasize is an effect which allows you to make a part of the scene pop out more while other parts are de-emphasized. This is done by using the depth buffer of the 3D engine, and by default it desaturates the areas which are not 'in focus'. Additionally you can specify a blend color which allows you to e.g. make what's not important much darker so the not-in-focus parts of the scene are way darker than the area which should be emphasized which is left as-is. 

#### GoldenRatio
This effect is rather simple, but can be a great help for taking screenshots with proper composition. It displays 4 so called 'golden ratio' fibonacci spirals on the screen, blended on top of the actual scene. You can then position your camera and zoom level to meet the lines on screen to have everything aligned according to the 'golden ratio'. For more information about the golden ratio and how it's used in photography, see e.g. [Composition with Fibonacci's ratio](http://digital-photography-school.com/divine-composition-with-fibonaccis-ratio-the-rule-of-thirds-on-steroids/) and [Golden ratio](https://en.wikipedia.org/wiki/Golden_ratio)

