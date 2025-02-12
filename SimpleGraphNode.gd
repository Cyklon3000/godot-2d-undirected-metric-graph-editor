class_name SimpleGraphNode
extends Node2D

var adjacent_nodes: Array[SimpleGraphNode] = []
var distance_lookup: Dictionary[int, float] = {} # hash(self.hash() + other.hash()) -> distance

var node_color: Color

const NODE_RADIUS: int = 15
const EDGE_WIDTH: int = 2

func _init(position : Vector2 = Vector2.ZERO) -> void:
	self.position = position
	
	self.node_color = Color.WHITE
	#self.node_color = get_node_color()

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 15, self.node_color, true, -1.0, true)
	draw_edges()

func draw_edges(draw_all: bool = false) -> void:
	for adjacent_node: SimpleGraphNode in adjacent_nodes:
		# Avoid drawing edges twice (adjacent will draw edge instead) 
		# Avoid drawing edge from self to self
		if (not draw_all) and (adjacent_node.hash() >= self.hash()):
			continue
		
		draw_line(Vector2.ZERO, adjacent_node.position - self.position, Color(Color.WHITE, 0.5), EDGE_WIDTH, true)

func get_distance_to(other: SimpleGraphNode) -> float:
	var distance_key = hash(self.hash() + other.hash())
	if not (distance_lookup.has(distance_key)):
		distance_lookup[distance_key] = (other.position - self.position).length()
	
	return distance_lookup[distance_key]

# Add node to list of adjacent nodes (can be self!, can be duplicate!)
func add_adjacent_node(other: SimpleGraphNode, do_exclude_self: bool = true, do_exclude_duplicate: bool = true) -> void:
	if (do_exclude_self and other.get_instance_id() == self.get_instance_id()) or \
	   (do_exclude_duplicate and adjacent_nodes.has(other)):
		return
	
	self.adjacent_nodes.append(other)

# Add nodes to list of adjacent nodes (can be self!, can be duplicate!)
func add_adjacent_nodes(others: Array[SimpleGraphNode], do_exclude_self: bool = true, do_exclude_duplicate: bool = true) -> void:
	for other: SimpleGraphNode in others:
		add_adjacent_node(other, do_exclude_self, do_exclude_duplicate)

func remove_adjacent_node(node: SimpleGraphNode) -> void:
	adjacent_nodes.erase(node)

func remove_adjacent_nodes(nodes: Array[SimpleGraphNode]) -> void:
	for node: SimpleGraphNode in nodes:
		remove_adjacent_node(node)

func print_info() -> void:
	print("\n--- NODE (%s) INFO ---" % [str(get_readable_node_id())])
	print("Node ID = %s; \tNode Pos = %s" % [str(get_instance_id()), str(position)])
	print("This Node has %s adjacent nodes:" % [str(len(adjacent_nodes))])
	for adjacent_node: SimpleGraphNode in adjacent_nodes:
		print("\t- NODE (%s): dst = %s" % \
			[str(adjacent_node.get_readable_node_id()), str(snappedf(get_distance_to(adjacent_node), 0.01))])

func hash() -> int:
	return hash([get_instance_id(), position])

func get_readable_node_id() -> String:
	const ANIMAL_EMOJIS: Array[String] = [
	"🐱", "🐶", "🐭", "🐹", "🐰", "🐺", "🐸", "🐯", "🐨", "🐻", "🐷", "🐽", "🐮", 
	"🐗", "🐵", "🐒", "🐴", "🐎", "🐫", "🐑", "🐘", "🐼", "🐍", "🐦", "🐤", 
	"🐥", "🐣", "🐔", "🐧", "🐢", "🐛", "🐝", "🐜", "🪲", "🐌", "🐙", "🐠", 
	"🐟", "🐳", "🐋", "🐬", "🐄", "🐏", "🐀", "🐃", "🐅", "🐇", "🐉", "🐐", 
	"🐓", "🐕", "🐖", "🐁", "🐂", "🐲", "🐡", "🐊", "🐪", "🐆", "🐈", "🐩", 
	]
	
	var readable_node_id: String = ANIMAL_EMOJIS[hash(get_instance_id()) % len(ANIMAL_EMOJIS)]
	readable_node_id += ANIMAL_EMOJIS[hash(get_instance_id()+1) % len(ANIMAL_EMOJIS)]
	
	return readable_node_id

func get_node_color() -> Color:
	return Color.from_hsv(randf(), 0.75, 0.9)
