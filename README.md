# FBar

This mutator adds a health and status bar above each player and monster. This mutator is useful for team and cooperative play. This mutator is especially useful for the MonsterHunt mod.

For players it shows their nick name, current health in green (0-100) and blue (100-200) and armor amount (0-150) in yellow.

For monsters it shows their entity name (usually numbered), health in green (0-initial health). Monsters considered to be bosses by the mutator will get a significantly larger bar.

## Installation

1. Place the compiled  `FBar.u` in the System folder of the server.
2. Add `FBar.u` to the server packages of the server's `UnrealTournament.ini`  (at `[Engine.GameEngine]`  add  `ServerPackages=FBar` )
3. Configure the mutator (optional) 

## Configuration

| Property    | Default             | Description                                                  |
| ----------- | ------------------- | ------------------------------------------------------------ |
| GreyColor   | (R=127,G=127,B=127) | color of the body of the bar                                 |
| WhiteColor  | (R=255,G=255,B=255) | color of the name label                                      |
| RedColor    | (R=255)             | color of the depleted health                                 |
| GreenColor  | (G=255)             | color of the remaining health                                |
| BlueColor   | (B=255)             | color of boosted health                                      |
| YellowColor | (R=219,G=146)       | color of the armor amount                                    |
| BarWidth    | 64                  | width of the bar (px)                                        |
| BarHeight   | 8                   | height of the bar (px)                                       |
| BossHealth  | 1000                | health a monster should have initially to be considered a boss character |

