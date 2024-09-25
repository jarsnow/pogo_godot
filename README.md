# pogo_godot
The project can be ran by running the /scenes/main.tscn scene in either the genetic_algorithm or player_controlled folder in Godot.

The simulation is based on Hendrik Felix Pohl’s Pogostuck: Rage With Your Friends, a 2D platforming game.
The controls are simple, turning left or right (or none), and holding the jump key.
For the genetic algorithm, this is simplified down to rotating left, right, or none. The jump key is assumed to be held down at all times.

There is both a player controlled mode (that I developed first for testing and fun) and a genetic algorithm mode.
The player controlled version can be started by running the player_controlled/scenes/main.tscn scene in godot.

The genetic algorithm implemented encourages agents to follow a path through an environment that can also be changed by the player, with the following steps:

`1. Create a new scene for your map, preferably in the /genetic_algorithm/scenes/ directory`

`2. Create the collision for the map with any amount of Polygon2D nodes.`

`3. Add a Path2D node that you intend on having your agents follow. The direction that the Path2D node points should be the same as the direction your agents should move.`

`4. Add a Node2D and move it to the starting location for your agents to spawn at.`

`5. Rename the Node2D from step 4 to 'SpawnPoint'`

`6. Save the new scene`

`7. Navigate to the main scene, then to its AgentContainer child node.`

`8. Under the AgentContainer node, in the inspector on the far right, select your new map scene as the 'Map' variable.`

`9. OPTIONAL: Adjust parameters (mutation rate, which agents are selected for reproduction, how fast the simulation runs, runtime).`

`10. Run the main scene.`

I am currently actively working on this project, and I plan to adjust the parameters for the genetic algorithm around until the agents can go through a small set of maps in a reasonable time.
I also plan on adding simple GUI to display the current generation amount, as well as some way to display past agent fitness values for each simulation.
