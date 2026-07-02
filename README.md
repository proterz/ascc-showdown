# ascc-showdown
AHK macro made for farming Anime Showdown minigame for the Roblox game Anime Stars Card Collection. It first forces focus on Roblox and resize the window to 1280 x 720 to standardize the coordinates (for mouse position, OCR, etc). Next, it automatically loads cards using the Strong Card + 2 Weak Card team composition, then constantly clicks the "Next Level" button until the desired level is reached which will end the run and claim rewards, then repeat. It uses OCR to determine the current level and imagesearch function to detect certain parts of the game. [EXAMPLE](https://www.youtube.com/watch?v=aHTuHOTrpFk)

This macro has the ability to navigate to Anime Showdown area by itself. If the game's server updated or restarted, the macro will leave the game, rejoin the game, navigate to Anime Showdown area, then resume the farm. ([EXAMPLE](https://www.youtube.com/watch?v=QMLBkeZjEE8))
If the player experiences disconnection, the macro will test and wait for internet connectivity, rejoin the game, then navigate to Anime Showdown area. ([EXAMPLE](https://www.youtube.com/watch?v=AVYvJCEaBYw))

Tick the "Repeat Showdown" checkbox to constantly repeat the load card -> farm -> claim cycle. "AutoSetup" checkbox currently does nothing (kinda lazy to remove too)

(Note: If you want to modify the mouse positions, use the AutoHotkey Window Spy program that comes with the installation of AutoHotkey, then copy the Client mouse positions specifically!)

Hotkeys:
- Insert = stop farming
- End = force close the macro
- Home = pause the whole macro

Requirements:
- AHK v2 installed
- Movement Mode in Roblox Settings set to "Click To Move"
- Turned off Use Upgraded Walkspeed in ingame settings
- Atleast more than 720p monitor resolution
