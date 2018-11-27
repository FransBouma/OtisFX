# OtisFX
A small set of effects for [Reshade](http://reshade.me). 

Most of these shaders are in the [official reshade shader library](https://github.com/crosire/reshade-shaders), in some form/version but that library is tied to a 
given version of reshade and modified to use controls which are less precise or not compatible with e.g. v3. So I forked my shaders and shaders from others 
not in the reshade repo I use myself to this repository. 

### Prerequisites
You should have [Reshade](http://reshade.me) v3.4.x or higher and at least reshade.fxh present in the `reshade-shaders\shaders` folder

### How to install
Download the zip using the button on the right which says 'Download ZIP'. This will give you a file called 'Master.zip', which contains all code. 
Unpack the zip and go to the `src` folder. Copy all files and folders inside the `src` folder into the `Reshade` folder in your game's bin folder. 
This `Reshade` folder should already be there. If you downloaded all files from the reshade shader repository when you installed reshade, it might be you get the 
warning from Windows that you're about to overwrite some files. That's ok, just overwrite the ones in the repository with the ones here.

### Effects included
The following effects are currently included: 

#### Cinematic DOF
The state of the art depth of field effect I wrote which has all the features you want and need from a depth of field effect: near plane bleed, configurable highlights, 
high performance, easy to use focusing code and great bokeh. 

#### Emphasize
Emphasize is an effect which allows you to make a part of the scene pop out more while other parts are de-emphasized. This is done by using the 
depth buffer of the 3D engine, and by default it desaturates the areas which are not 'in focus'. Additionally you can specify a blend color which 
allows you to e.g. make what's not important much darker so the not-in-focus parts of the scene are way darker than the area which should be 
emphasized which is left as-is. 

#### PandaFX
This effect is written by Jukka Korhonen aka Loadus. I fixed a set of bugs and optimized the code and kept the source here. For details
[see this thread](https://reshade.me/forum/shader-presentation/4727-cinematic-effects-for-reshade).

#### Depth Haze
This effect is a simple depth-blur which makes far away objects look slightly blurred. It's more subtle than a Depth of Field effect as it's not based on a lens, 
but on how the human eye sees far away objects outdoors: detail is lost and the farther away an object, e.g. a tower, the less sharp the human eye sees it. 
Modern render engines tend to render far away objects crisp and sharp which makes the far away objects too sharp to look natural. 
Additionally Depth Haze also includes fog based on depth and screen position, which is configurable through parameters. It currently fogs more around the middle 
line of the screen and gradiently lowers the fog intensity towards the top/bottom of the screen, to avoid fog on the sky.   

#### Multi LUT
A LUT (Look Up Tables for color toning) shader which offers multiple LUTs in one shader to easily change the color toning in-game. The color toning options available
are based on hand-tuned LUTs and also presets from Adobe Lightroom.

#### Adaptive Fog
This shader combines bloom with depth fog to add more atmosphere to a scene. It offers a color option to make sure the fog matches the color tone used by the game engine.



