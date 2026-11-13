extends RefCounted

# Editor-facing definitions: templates contain local geometry, nodes contain progression.
# IDs, rather than scene instances or display names, connect the two documents.
static func create() -> Dictionary:
	return {
		"root": "start", "initial_capacity": 4,
		"templates": {
			"sanctuary": {"obstacles": [], "enemies": [], "pickups": []},
			"practice": {"obstacles": [Rect2(330, 220, 110, 70)], "enemies": [Vector2(560, 350)], "pickups": [{"id": "capacity", "position": Vector2(590, 180), "kind": "capacity"}]},
			"landing": {"obstacles": [], "enemies": [], "pickups": [{"id": "capacity", "position": Vector2(400, 240), "kind": "capacity"}]},
			"treasure": {"obstacles": [Rect2(290, 200, 50, 170)], "enemies": [Vector2(530, 260), Vector2(530, 380)], "pickups": [{"id": "prize", "position": Vector2(620, 300), "kind": "gold"}]}
		},
		"nodes": {
			"start": {"name": "Sanctuary", "template": "sanctuary", "cost": 0, "requires_all": [], "requires_any": [], "abilities": [], "map_position": Vector2(0, 0)},
			"sword": {"name": "Sword", "template": "practice", "cost": 1, "requires_all": ["start"], "requires_any": [], "abilities": ["sword"], "map_position": Vector2(-1, 0)},
			"boots": {"name": "Boots", "template": "practice", "cost": 1, "requires_all": ["start"], "requires_any": [], "abilities": ["dash"], "map_position": Vector2(1, 0)},
			"sword_landing": {"name": "Sword Landing", "template": "landing", "cost": 1, "requires_all": ["sword"], "requires_any": [], "abilities": [], "map_position": Vector2(-1, -1)},
			"boots_landing": {"name": "Boots Landing", "template": "landing", "cost": 1, "requires_all": ["boots"], "requires_any": [], "abilities": [], "map_position": Vector2(1, -1)},
			"prize": {"name": "Prize", "template": "treasure", "cost": 1, "requires_all": ["sword_landing", "boots_landing"], "requires_any": [], "abilities": [], "map_position": Vector2(0, -1)}
		},
		# Physical travel is bidirectional; activation direction is authored separately.
		"links": [
			{"a": "start", "b": "sword", "a_port": "west", "b_port": "east", "activate_from": ["start", "sword"]},
			{"a": "start", "b": "boots", "a_port": "east", "b_port": "west", "activate_from": ["start", "boots"]},
			{"a": "sword", "b": "sword_landing", "a_port": "north", "b_port": "south", "activate_from": ["sword"]},
			{"a": "boots", "b": "boots_landing", "a_port": "north", "b_port": "south", "activate_from": ["boots"]},
			{"a": "sword_landing", "b": "prize", "a_port": "east", "b_port": "west", "activate_from": ["sword_landing"]},
			{"a": "boots_landing", "b": "prize", "a_port": "west", "b_port": "east", "activate_from": ["boots_landing"]}
		],
		# Future switches address node + object IDs, never loaded scene paths.
		"interactions": []
	}
