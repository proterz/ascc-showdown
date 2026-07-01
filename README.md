# ascc-showdown
AHK macro made for farming Anime Showdown minigame for the roblox game ASCC. It first forces focus on Roblox and resize the window to 1280 x 720 to standardize the coordinates (for mouse position, OCR, etc). Next, it automatically loads cards using the Strong Card + 2 Weak Card team composition, then constantly clicks the "Next Level" button until the desired level is reached which will end the run and claim rewards, then repeat. It uses OCR to determine the current level and imagesearch function to detect certain parts of the game. [EXAMPLE](https://www.youtube.com/watch?v=aHTuHOTrpFk)



This macro has the ability to navigate to Anime Showdown area by itself. If the game's server updated or restarted, the macro will leave the game, rejoin the game, navigate to Anime Showdown area, then resume the farm. ([EXAMPLE](https://www.youtube.com/watch?v=QMLBkeZjEE8))
If the player experiences disconnection, the macro will test and wait for internet connectivity, rejoin the game, then navigate to Anime Showdown area. ([EXAMPLE](https://www.youtube.com/watch?v=AVYvJCEaBYw))

Requirements:
- AHK v2 installed
- Movement Mode in Roblox Settings set to "Click To Move"
- Turned off Use Upgraded Walkspeed in ingame settings
- Atleast more than 720p monitor resolution
