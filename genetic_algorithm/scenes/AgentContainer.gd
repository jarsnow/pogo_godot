extends Node2D

const Player = preload("res://scenes/player.tscn")

const gene_choices = ['l', 'r', 'n']

var physics_frame_generation_started: int

var player_agents = []

@export var agent_count: int = 8

@export var physics_speed: float = 1.0

@export var map: Node2D
@export var runtime_seconds: int = 1

@export var top_rank_survivors: int = 16
@export var random_bottom_survivors: int = 8

@export var mutation_rate: float = 0.05

var chromosome_length: int = 120 * runtime_seconds

# Called when the node enters the scene tree for the first time.
func _ready():
	physics_frame_generation_started = 0
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	# check if generation is done
	var physics_frames_passed = Engine.get_physics_frames() - physics_frame_generation_started
	
	if physics_frames_passed >= chromosome_length - 1:
		end_generation()
		return
	
	print("frames passed: ", physics_frames_passed)
	print("chromosome length: ", chromosome_length)
	print("agents in list: ", len(player_agents))
	update_agents_max_path_distances()

func start():
	
	set_physics_speed(physics_speed)
	
	if agent_count % 4 != 0:
		printerr("agent count must be divisible by 4")
	
	initialize_agents(null) # null for random chromosomes

# make new agents with given chromosomes
# if chromosomes is null, then
func initialize_agents(chromosomes): # should be a list of strings (chromosomes)
	physics_frame_generation_started = Engine.get_physics_frames()
	
	if chromosomes != null and agent_count != len(chromosomes):
		printerr("not enough chromosomes provided")
	
	var spawn_point: Vector2 = map.get_node("SpawnPoint").get_position()
	
	for i in range(agent_count):
		
		var new_agent = Player.instantiate()
		player_agents.append(new_agent.get_node("Player"))
		
		# assign chromosome
		if chromosomes == null:
			generate_new_chromosome(new_agent.get_node("Player"))
		else:
			new_agent.get_node("Player").chromosome = chromosomes[i]
		
		# move to spawnpoint
		new_agent.set_position(spawn_point)
		
		# add to scene
		add_child(new_agent)

func generate_new_chromosome(player_agent):
	
	var new_chromosome: String = ""
	for i in range(chromosome_length):
		new_chromosome = new_chromosome + gene_choices.pick_random()
		
	player_agent.chromosome = new_chromosome
	
func get_agent_fitness(player_agent):
	var fitness: int = 0
	
	var final_dist = get_agent_path_distance(player_agent)
	
	# reward 2 * max dist, 1 * final distance
	
	# represents the pixel distance along the path 
	fitness += 5 * player_agent.max_path_dist
	fitness += 1 * final_dist
	
	# give a slight reward for agents who do a boosted jump
	fitness += player_agent.boosted_jump_count * 500
	
	return fitness
	
func get_agent_path_distance(player_agent):
	var path: Path2D = map.get_node("Path2D")
	var agent_pos: Vector2 = player_agent.get_global_position()
	var path_dist = path.curve.get_closest_offset(path.to_local(agent_pos))
	
	return path_dist

# sort by fitness, take the top 12.5%, random choice 12.5% from the remaining 3/4's of the population
func get_surviving_agents():
	var survivors = []
	var eighth: int = agent_count / 8
	player_agents.sort_custom(sorting_helper_descending)
	survivors.append_array(player_agents.slice(0, eighth)) # get the top 25% of agent players
	
	# get the remaining 3/4, shuffle to get randomness
	var losers = player_agents.slice(eighth)
	losers.shuffle()
	survivors.append_array(losers.slice(0, eighth)) # add another quarter of the losers
	
	return survivors

func sorting_helper_descending(a, b):
	return get_agent_fitness(a) > get_agent_fitness(b)
	
func update_agents_max_path_distances():
	print("agents before counting: ", len(player_agents))
	# update max path dist for each
	for player_agent in player_agents:
		
		var curr_dist = get_agent_path_distance(player_agent)
		player_agent.max_path_dist = max(curr_dist, player_agent.max_path_dist)

# agent_a gets the first section of their genes, and the latter section of agent_b
# agent_b gets the first section of their genes, and the latter section of agent_a
func get_spliced_chromosome_from_parent_chromosomes(chromosome_a: String, chromosome_b: String):
	
	var splicing_index: int = randi() % chromosome_length
	
	var new_a: String = chromosome_a.substr(0, splicing_index) + chromosome_b.substr(splicing_index)
	var new_b: String = chromosome_b.substr(0, splicing_index) + chromosome_a.substr(splicing_index)
	
	# return a random spliced chromosome from each parent
	if randi() % 2 == 0:
		return new_a
	return new_b

func get_mutated_chromosome(chromosome: String):
	
	var new_chromosome: String = chromosome
	for i in range(len(chromosome)):
		if randf() <= mutation_rate:
			new_chromosome[i] = gene_choices[randi() % 3] # get a random gene from the choices
			
	return new_chromosome

func get_chromosomes_from_player_agents(player_agents):
	var chromosomes: Array[String] = []
	for player_agent in player_agents:
		chromosomes.append(player_agent.chromosome)
		
	return chromosomes

func end_generation():

	var survivors = get_surviving_agents()
	var new_chromosomes: Array[String] = []
	
	var old_chromosomes = get_chromosomes_from_player_agents(survivors)
	
	# keep the population size constant
	while len(new_chromosomes) < agent_count:
		
		# pick two random parents (not the same)
		old_chromosomes.shuffle() # this is probably slow, shuffling it each time, but I do not care
		var parents: Array[String] = old_chromosomes.slice(0, 2)
		
		var parent_a: String = parents[0]
		var parent_b: String = parents[1]
		
		# get the child from the two parents
		var child: String = get_spliced_chromosome_from_parent_chromosomes(parent_a, parent_b)
		
		# mutate
		child = get_mutated_chromosome(child)
		
		# add to new population
		new_chromosomes.append(child)
	
	for player_agent in player_agents:
		player_agent.queue_free()
		await player_agent.tree_exited
		print("agent exited")
	
	# delete old survivors
	update_player_agents()
		
	# make new survivors, and go again
	initialize_agents(new_chromosomes)

func update_player_agents():
	
	player_agents = []
	for node in get_children():
		if is_instance_valid(node) and node != null and node.get_name() == "AgentBase":
			player_agents.append(node.get_node("Player"))
	
	print(len(player_agents))
	
func set_physics_speed(new_speed: float):
	Engine.set_time_scale(new_speed) # set simulation speed
	Engine.physics_ticks_per_second = int(120 * Engine.time_scale) # also necessary
