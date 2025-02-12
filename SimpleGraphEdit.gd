extends Node2D

var nodes: Array[SimpleGraphNode] = []

var selected_nodes: Array[SimpleGraphNode] = []
var hovered_node: SimpleGraphNode = null

const HOVER_COLOR: Color = Color(Color.DIM_GRAY, 0.6)
const SELECTED_COLOR: Color = Color(Color.GRAY, 0.6)

var is_function_key_pressed: bool = false
var is_panning_key_pressed: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#spawn_random_fully_connected_graph(20, 50)
	nodes.append_array(spawn_random_fully_connected_graph(8, 6))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Find hovered node (closest within selection distance)
	hovered_node = null
	var mouse_position: Vector2 = get_global_mouse_position()
	for node: SimpleGraphNode in nodes:
		var lowest_distance = 15 # Also acts as min distance required to hover
		if (node.position - mouse_position).length() <= lowest_distance:
			hovered_node = node
			lowest_distance = (node.position - mouse_position).length
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("graph_select_node"):
		print("ACTION: graph_select_node")
		if not selected_nodes.has(hovered_node) and hovered_node != null:
			selected_nodes.append(hovered_node)
	
	if event.is_action_pressed("graph_select_all") and not is_function_key_pressed:
		print("ACTION: graph_select_all")
		selected_nodes = nodes.duplicate()
	
	if event.is_action_pressed("graph_deselect") and not is_function_key_pressed:
		print("ACTION: graph_deselect")
		selected_nodes.erase(hovered_node)
	
	if event.is_action_pressed("graph_deselect_all"):
		print("ACTION: graph_deselect_all")
		selected_nodes = []
	
	if event.is_action_pressed("graph_add_node"):
		print("ACTION: graph_add_node")
		spawn_node(get_global_mouse_position())
	
	if event.is_action_pressed("graph_add_fully_connected_node"):
		print("ACTION: graph_add_fully_connected_node")
		var node: SimpleGraphNode = spawn_node(get_global_mouse_position())
		connect_single_node(node, nodes)
	
	if event.is_action_pressed("graph_add_node_connected_to_selected"):
		print("ACTION: graph_add_node_connected_to_selected")
		var node: SimpleGraphNode = spawn_node(get_global_mouse_position())
		connect_single_node(node, selected_nodes)
	
	if event.is_action_pressed("graph_connect_nodes") and not is_function_key_pressed:
		print("ACTION: graph_connect_nodes")
		connect_node_group(selected_nodes)
	
	if event.is_action_pressed("graph_connect_to_all_other"):
		print("ACTION: graph_connect_to_all_other")
		for node: SimpleGraphNode in selected_nodes:
			connect_single_node(node, nodes)
	
	if event.is_action_pressed("graph_disconnect_nodes_from_eachother") and not is_function_key_pressed:
		print("ACTION: graph_disconnect_nodes_from_eachother")
		for node: SimpleGraphNode in selected_nodes:
			disconnect_edges(node, selected_nodes)
	
	if event.is_action_pressed("graph_disconnect_nodes_from_everything"):
		print("ACTION: graph_disconnect_nodes_from_everything")
		for node: SimpleGraphNode in selected_nodes:
			disconnect_edges(node, nodes)
	
	if event.is_action_pressed("graph_remove_nodes"):
		print("ACTION: graph_remove_nodes")
		for node: SimpleGraphNode in selected_nodes:
			delete_node(node)
		selected_nodes = []
	
	if event.is_action_pressed("graph_move_node"):
		print("ACTION: graph_move_node")
		if len(selected_nodes) >= 1:
			selected_nodes[-1].position = get_global_mouse_position()
	
	if event.is_action_pressed("graph_zoom_in"):
		print("ACTION: graph_zoom_in")
		$Camera2D.target_zoom *= 1.1
	
	if event.is_action_pressed("graph_zoom_out"):
		print("ACTION: graph_zoom_out")
		$Camera2D.target_zoom *= 0.9
	
	if is_panning_key_pressed:
		print("ACTION: graph_pan")
		$Camera2D.target_position += last_mouse_position - get_global_mouse_position()
	last_mouse_position = get_global_mouse_position()
		
	if event.is_action_pressed("graph_print_node_info"):
		print("Now printing info for %s nodes:" % str(len(selected_nodes)))
		for node: SimpleGraphNode in selected_nodes:
			node.print_info()
	
	is_function_key_pressed = is_function_key_pressed or event.is_action_pressed("graph_function_key")
	is_function_key_pressed = is_function_key_pressed and not event.is_action_released("graph_function_key")
	
	is_panning_key_pressed = is_panning_key_pressed or event.is_action_pressed("graph_pan")
	is_panning_key_pressed = is_panning_key_pressed and not event.is_action_released("graph_pan")
	
	queue_redraw()
	

func _draw() -> void:
	for selected_node: SimpleGraphNode in selected_nodes:
		draw_circle(selected_node.position, 20, SELECTED_COLOR, true, -1, true)
	
	if hovered_node == null:
		draw_circle(get_global_mouse_position(), 10, HOVER_COLOR, true, -1, true)
	else:
		draw_circle(hovered_node.position, 20, HOVER_COLOR, true, -1, true)

func spawn_node(position: Vector2) -> SimpleGraphNode:
	var node: SimpleGraphNode = SimpleGraphNode.new(position)
	add_child(node)
	
	nodes.append(node)
	return node

func connect_single_node(node: SimpleGraphNode, others: Array[SimpleGraphNode]) -> void:
	for other: SimpleGraphNode in others:
		node.add_adjacent_node(other)
		other.add_adjacent_node(node)

func connect_node_group(nodes: Array[SimpleGraphNode]) -> void:
	for node: SimpleGraphNode in nodes:
		node.add_adjacent_nodes(nodes)

func disconnect_edge(node_1: SimpleGraphNode, node_2: SimpleGraphNode) -> void:
	node_1.remove_adjacent_node(node_2)
	node_2.remove_adjacent_node(node_1)

func disconnect_edges(node: SimpleGraphNode, others: Array[SimpleGraphNode]) -> void:
	for other: SimpleGraphNode in others:
		disconnect_edge(node, other)

func delete_node(node: SimpleGraphNode) -> void:
	disconnect_edges(node, nodes)
	remove_child(node)
	nodes.erase(node)
	# Cannot be done, because potentially iterating over selected_nodes to delete node
	# selected_nodes.erase(node)
	hovered_node = null if hovered_node == node else hovered_node


func spawn_random_fully_connected_graph(amount: int, maximum_distance_search_depth: int = 1) -> Array[SimpleGraphNode]:
	const VIEWPORT_MARGIN: int = 50
	
	# Generate list of positions. 
	# Each attempt records the distance to the closest node.
	# The most "off-shore" node is chosen.
	var positions: Array[Vector2] = []
	for i in range(amount):
		var farthest_position: Vector2 = -Vector2.ONE
		var farthest_distance: float = 0
		
		for j in range(maximum_distance_search_depth):
			var new_position: Vector2 = get_random_viewport_position(VIEWPORT_MARGIN)
			
			var minimum_distance: float = INF
			for position: Vector2 in positions:
				minimum_distance = min(minimum_distance, (position - new_position).length())
				
			
			if minimum_distance > farthest_distance:
				farthest_position = new_position
				farthest_distance = minimum_distance
		
		positions.append(farthest_position)
	
	# Instantiate and connect Nodes
	# Then add them to scene_tree
	var nodes: Array[SimpleGraphNode] = []
	for position: Vector2 in positions:
		nodes.append(spawn_node(position))
	
	connect_node_group(nodes)
	
	return nodes

func get_random_viewport_position(margin: float = 0) -> Vector2:
	# Get the viewport rect
	var viewport_size = get_viewport_rect().size
	var viewport_rect: Rect2 = Rect2($Camera2D.position - viewport_size / 2, viewport_size)
	
	# Calculate the usable area with margins
	var min_x: float = viewport_rect.position.x + margin
	var max_x: float = viewport_rect.end.x - margin
	var min_y: float = viewport_rect.position.y + margin
	var max_y: float = viewport_rect.end.y - margin
	
	# Generate random x and y within the constrained area
	var random_x: float = randf_range(min_x, max_x)
	var random_y: float = randf_range(min_y, max_y)
	
	return Vector2(random_x, random_y)
