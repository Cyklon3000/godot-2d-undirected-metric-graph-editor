extends Node2D

var nodes: Array[SimpleGraphNode] = []
var selected_nodes: Array[SimpleGraphNode] = []
var hovered_node: SimpleGraphNode = null

const HOVER_COLOR: Color = Color(Color.DIM_GRAY, 0.6)
const SELECTED_COLOR: Color = Color(Color.GRAY, 0.6)
const SELECTED_BOUNDS_COLOR: Color = Color(Color.DIM_GRAY, 0.4)

enum QueueableActions {
	ADD_NODE,
	ADD_CONNECTED_NODE,
	ADD_FULLY_CONNECTED_NODE,
	MOVE_NODE,
	NONE
}

var queued_action: QueueableActions = QueueableActions.NONE
var is_function_key_pressed: bool = false
var is_panning_key_pressed: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

enum EdgeRenderingModes {
	RENDER_ALL_EDGES,
	RENDER_SELECTED_EDGES
}

var edge_rendering_mode: EdgeRenderingModes = EdgeRenderingModes.RENDER_ALL_EDGES

func _ready() -> void:
	nodes.append_array(spawn_random_fully_connected_graph(8, 6))

func _process(delta: float) -> void:
	queue_redraw()
	last_mouse_position = get_global_mouse_position()
	update_hovered_node()

func update_hovered_node() -> void:
	hovered_node = null
	var mouse_position: Vector2 = get_global_mouse_position()
	for node: SimpleGraphNode in nodes:
		if node.is_node_hidden: continue
		var lowest_distance = 15
		if (node.position - mouse_position).length() <= lowest_distance:
			hovered_node = node
			lowest_distance = (node.position - mouse_position).length

func select_node(node: SimpleGraphNode) -> void:
	print("ACTION: graph_select_node")
	deselect_all_nodes()
	select_additional_node(node)

func select_additional_node(node: SimpleGraphNode) -> void:
	print("ACTION: graph_select_additional_node")
	queued_action = QueueableActions.NONE
	if selected_nodes.has(node): return
	selected_nodes.append(node)
	if edge_rendering_mode == EdgeRenderingModes.RENDER_SELECTED_EDGES:
		reveal_node_edges(node)

func select_all_nodes() -> void:
	print("ACTION: graph_select_all")
	selected_nodes = nodes.duplicate()
	if edge_rendering_mode == EdgeRenderingModes.RENDER_SELECTED_EDGES:
		for node: SimpleGraphNode in nodes:
			reveal_node_edges(node)
	queued_action = QueueableActions.NONE

func deselect_node(node: SimpleGraphNode) -> void:
	print("ACTION: graph_deselect")
	selected_nodes.erase(node)
	if edge_rendering_mode == EdgeRenderingModes.RENDER_SELECTED_EDGES:
		hide_node_edges(node)
	queued_action = QueueableActions.NONE

func deselect_all_nodes() -> void:
	print("ACTION: graph_deselect_all")
	selected_nodes = []
	if edge_rendering_mode == EdgeRenderingModes.RENDER_SELECTED_EDGES:
		for node: SimpleGraphNode in nodes:
			hide_node_edges(node)
	queued_action = QueueableActions.NONE

func add_single_node() -> void:
	print("ACTION: graph_add_node")
	spawn_node(get_global_mouse_position())
	queued_action = QueueableActions.NONE

func add_fully_connected_node() -> void:
	print("ACTION: graph_add_fully_connected_node")
	var node: SimpleGraphNode = spawn_node(get_global_mouse_position())
	connect_single_node(node, nodes)
	queued_action = QueueableActions.NONE

func add_node_connected_to_selected() -> void:
	print("ACTION: graph_add_node_connected_to_selected")
	var node: SimpleGraphNode = spawn_node(get_global_mouse_position())
	connect_single_node(node, selected_nodes)
	queued_action = QueueableActions.NONE

func connect_selected_nodes() -> void:
	print("ACTION: graph_connect_nodes")
	connect_node_group(selected_nodes)
	queued_action = QueueableActions.NONE

func connect_selected_to_all() -> void:
	print("ACTION: graph_connect_to_all_other")
	for node: SimpleGraphNode in selected_nodes:
		connect_single_node(node, nodes)
	queued_action = QueueableActions.NONE

func disconnect_selected_nodes() -> void:
	print("ACTION: graph_disconnect_nodes_from_eachother")
	for node: SimpleGraphNode in selected_nodes:
		disconnect_edges(node, selected_nodes)
	queued_action = QueueableActions.NONE

func disconnect_selected_from_all() -> void:
	print("ACTION: graph_disconnect_nodes_from_everything")
	for node: SimpleGraphNode in selected_nodes:
		disconnect_edges(node, nodes)
	queued_action = QueueableActions.NONE

func remove_selected_nodes() -> void:
	print("ACTION: graph_remove_nodes")
	for node: SimpleGraphNode in selected_nodes:
		delete_node(node)
	selected_nodes = []
	queued_action = QueueableActions.NONE

func hide_selected_nodes() -> void:
	print("ACTION: hide_selected_nodes")
	for node: SimpleGraphNode in selected_nodes:
		hide_node(node)
	selected_nodes = []

func reveal_hidden_nodes() -> void:
	print("ACTION: reveal_hidden_nodes")
	for node: SimpleGraphNode in nodes:
		reveal_node(node)

func toggle_edge_rendering_mode() -> void:
	edge_rendering_mode = (edge_rendering_mode + 1) % len(EdgeRenderingModes)
	print("ACTION: toggle_edge_rendering_mode -> %s" % str(EdgeRenderingModes.keys()[edge_rendering_mode]))
	match edge_rendering_mode:
		EdgeRenderingModes.RENDER_ALL_EDGES:
			for node: SimpleGraphNode in nodes:
				node.is_edges_hidden = false
		EdgeRenderingModes.RENDER_SELECTED_EDGES:
			for node: SimpleGraphNode in nodes:
				node.is_edges_hidden = !selected_nodes.has(node)

func move_selected_nodes() -> void:
	print("ACTION: graph_move_node")
	var selection_center: Vector2 = get_bounding_box(selected_nodes).get_center()
	var move_vector: Vector2 = get_global_mouse_position() - selection_center
	
	for node: SimpleGraphNode in selected_nodes:
		node.position += move_vector
	
	queued_action = QueueableActions.NONE

func zoom_in() -> void:
	print("ACTION: graph_zoom_in")
	$Camera2D.zoom *= 1.1
	queued_action = QueueableActions.NONE

func zoom_out() -> void:
	print("ACTION: graph_zoom_out")
	$Camera2D.zoom *= 0.9
	queued_action = QueueableActions.NONE

func pan_camera() -> void:
	print("ACTION: graph_pan")
	if is_panning_key_pressed:
		$Camera2D.position += last_mouse_position - get_global_mouse_position()
	queued_action = QueueableActions.NONE

func print_selected_nodes_info() -> void:
	print("Now printing info for %s nodes:" % str(len(selected_nodes)))
	for node: SimpleGraphNode in selected_nodes:
		node.print_info()
	queued_action = QueueableActions.NONE

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("graph_select_node") and not is_function_key_pressed:
		if queued_action == QueueableActions.NONE:
			if hovered_node:
				select_node(hovered_node)
			elif get_global_mouse_position().x - $Camera2D.position.x + get_viewport().get_visible_rect().size.x / 2 > 50:
				deselect_all_nodes()
		else:
			match queued_action:
				QueueableActions.ADD_NODE:
					add_single_node()
				QueueableActions.ADD_CONNECTED_NODE:
					add_node_connected_to_selected()
				QueueableActions.ADD_FULLY_CONNECTED_NODE:
					add_fully_connected_node()
				QueueableActions.MOVE_NODE:
					move_selected_nodes()
	
	if event.is_action_pressed("graph_select_additional_node"):
		if hovered_node:
			select_additional_node(hovered_node)
	
	if event.is_action_pressed("graph_deselect_node"):
		if hovered_node:
			deselect_node(hovered_node)
	
	if event.is_action_pressed("graph_select_all") and not is_function_key_pressed:
		select_all_nodes()
	
	if event.is_action_pressed("graph_add_node"):
		add_single_node()
	
	if event.is_action_pressed("graph_add_fully_connected_node"):
		add_fully_connected_node()
	
	if event.is_action_pressed("graph_add_node_connected_to_selected"):
		add_node_connected_to_selected()
	
	if event.is_action_pressed("graph_connect_nodes") and not is_function_key_pressed:
		connect_selected_nodes()
	
	if event.is_action_pressed("graph_connect_to_all_other"):
		connect_selected_to_all()
	
	if event.is_action_pressed("graph_disconnect_nodes_from_eachother"):
		disconnect_selected_nodes()
	
	if event.is_action_pressed("graph_disconnect_nodes_from_everything"):
		disconnect_selected_from_all()
	
	if event.is_action_pressed("graph_remove_nodes"):
		remove_selected_nodes()
	
	if event.is_action_pressed("graph_hide_selected") and not is_function_key_pressed:
		hide_selected_nodes()
	
	if event.is_action_pressed("graph_reset_hidden"):
		reveal_hidden_nodes()
	
	if event.is_action_pressed("graph_toggle_edge_rendering_mode"):
		toggle_edge_rendering_mode()
	
	if event.is_action_pressed("graph_move_node"):
		move_selected_nodes()
	
	if event.is_action_pressed("graph_zoom_in"):
		zoom_in()
	
	if event.is_action_pressed("graph_zoom_out"):
		zoom_out()
	
	if is_panning_key_pressed:
		pan_camera()
	
	if event.is_action_pressed("graph_print_node_info"):
		print_selected_nodes_info()
	
	update_input_states(event)
	update_cursor_state()

func update_input_states(event: InputEvent) -> void:
	is_function_key_pressed = is_function_key_pressed or event.is_action_pressed("graph_function_key")
	is_function_key_pressed = is_function_key_pressed and not event.is_action_released("graph_function_key")
	
	is_panning_key_pressed = is_panning_key_pressed or event.is_action_pressed("graph_pan")
	is_panning_key_pressed = is_panning_key_pressed and not event.is_action_released("graph_pan")

func update_cursor_state() -> void:
	if is_panning_key_pressed:
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	elif hovered_node:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _draw() -> void:
	# Draw outlines for selected nodes
	for selected_node: SimpleGraphNode in selected_nodes:
		draw_circle(selected_node.position, 20, SELECTED_COLOR, true, -1, true)
	
	# Draw outline and center for selection box
	if len(selected_nodes) > 1:
		var selection_bounds: Rect2 = get_bounding_box(selected_nodes, 20)
		draw_rect(selection_bounds, SELECTED_BOUNDS_COLOR, false, 3, true)
		# Draw X using two lines / and \
		var selection_center = selection_bounds.get_center()
		draw_circle(selection_center, 5, SELECTED_BOUNDS_COLOR, false, 3, true)

	# Draw hover circle around node or at cursor
	if hovered_node == null:
		draw_circle(get_global_mouse_position(), 10, HOVER_COLOR, true, -1, true)
	else:
		draw_circle(hovered_node.position, 20, HOVER_COLOR, true, -1, true)

# Helper functions (unchanged)
func spawn_node(position: Vector2) -> SimpleGraphNode:
	# print("OPERATION: Spawning node")
	var node: SimpleGraphNode = SimpleGraphNode.new(position)
	add_child(node)
	nodes.append(node)
	return node

func connect_single_node(node: SimpleGraphNode, others: Array[SimpleGraphNode]) -> void:
	# print("OPERATION: Connecting node to other nodes")
	for other: SimpleGraphNode in others:
		node.add_adjacent_node(other)
		other.add_adjacent_node(node)

func connect_node_group(nodes: Array[SimpleGraphNode]) -> void:
	# print("OPERATION: Fully connecting node group")
	for node: SimpleGraphNode in nodes:
		node.add_adjacent_nodes(nodes)

func disconnect_edge(node_1: SimpleGraphNode, node_2: SimpleGraphNode) -> void:
	# print("OPERATION: Disconnecting nodes from eachother")
	node_1.remove_adjacent_node(node_2)
	node_2.remove_adjacent_node(node_1)

func disconnect_edges(node: SimpleGraphNode, others: Array[SimpleGraphNode]) -> void:
	# print("OPERATION: Disconnecting node from other nodes")
	for other: SimpleGraphNode in others:
		disconnect_edge(node, other)

func delete_node(node: SimpleGraphNode) -> void:
	# print("OPERATION: Deleting node")
	disconnect_edges(node, nodes)
	remove_child(node)
	nodes.erase(node)
	hovered_node = null if hovered_node == node else hovered_node

func hide_node(node: SimpleGraphNode) -> void:
	# print("OPERATION: Hiding node")
	node.is_node_hidden = true
	# selected_nodes.erase(node) # Avoid editing array currently looped over
	if hovered_node == node: hovered_node = null

func reveal_node(node: SimpleGraphNode) -> void:
	# print("OPERATION: Revealing node")
	node.is_node_hidden = false

func hide_node_edges(node: SimpleGraphNode) -> void:
	# print("OPERATION: Hiding nodes edges")
	node.is_edges_hidden = true

func reveal_node_edges(node: SimpleGraphNode) -> void:
	# print("OPERATION: Revealing nodes edges")
	node.is_edges_hidden = false

func spawn_random_fully_connected_graph(amount: int, maximum_distance_search_depth: int = 1) -> Array[SimpleGraphNode]:
	# print("OPERATION: Spawning fully connected graph out of %s node" % str(amount))
	const VIEWPORT_MARGIN: int = 50
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
	
	var nodes: Array[SimpleGraphNode] = []
	for position: Vector2 in positions:
		nodes.append(spawn_node(position))
	
	connect_node_group(nodes)
	return nodes


func get_random_viewport_position(margin: float = 0) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var viewport_rect: Rect2 = Rect2($Camera2D.position - viewport_size / 2, viewport_size)
	
	var min_x: float = viewport_rect.position.x + margin
	var max_x: float = viewport_rect.end.x - margin
	var min_y: float = viewport_rect.position.y + margin
	var max_y: float = viewport_rect.end.y - margin
	
	var random_x: float = randf_range(min_x, max_x)
	var random_y: float = randf_range(min_y, max_y)
	
	return Vector2(random_x, random_y)

func get_bounding_box(nodes: Array[SimpleGraphNode], margin: float = 0) -> Rect2:
	var top_left: Vector2 = INF * Vector2.ONE
	var bottom_right: Vector2 = -INF * Vector2.ONE
	
	for node: SimpleGraphNode in selected_nodes:
		top_left = Vector2(min(top_left.x, node.position.x), min(top_left.y, node.position.y))
		bottom_right = Vector2(max(bottom_right.x, node.position.x), max(bottom_right.y, node.position.y))
	
	return Rect2(top_left - margin * Vector2.ONE, bottom_right - top_left + 2 * margin * Vector2.ONE)

# Button event handlers
func _on_select_all_pressed() -> void:
	queued_action = QueueableActions.NONE
	select_all_nodes()

func _on_deselect_all_pressed() -> void:
	queued_action = QueueableActions.NONE
	deselect_all_nodes()

func _on_add_node_pressed() -> void:
	queued_action = QueueableActions.ADD_NODE

func _on_add_connected_node_pressed() -> void:
	queued_action = QueueableActions.ADD_CONNECTED_NODE

func _on_add_fully_connected_node_pressed() -> void:
	queued_action = QueueableActions.ADD_FULLY_CONNECTED_NODE

func _on_remove_nodes_pressed() -> void:
	queued_action = QueueableActions.NONE
	remove_selected_nodes()

func _on_move_node_pressed() -> void:
	queued_action = QueueableActions.MOVE_NODE

func _on_connect_nodes_pressed() -> void:
	queued_action = QueueableActions.NONE
	connect_selected_nodes()

func _on_connect_to_all_pressed() -> void:
	queued_action = QueueableActions.NONE
	connect_selected_to_all()

func _on_disconnect_node_pressed() -> void:
	queued_action = QueueableActions.NONE
	disconnect_selected_nodes()

func _on_disconnect_from_all_pressed() -> void:
	queued_action = QueueableActions.NONE
	disconnect_selected_from_all()

func _on_print_node_info_pressed() -> void:
	queued_action = QueueableActions.NONE
	print_selected_nodes_info()


func _on_hide_selected_nodes_pressed() -> void:
	queued_action = QueueableActions.NONE
	hide_selected_nodes()


func _on_reveal_hidden_nodes_pressed() -> void:
	queued_action = QueueableActions.NONE
	reveal_hidden_nodes()


func _on_toggle_edge_rendering_mode_pressed() -> void:
	queued_action = QueueableActions.NONE
	toggle_edge_rendering_mode()
