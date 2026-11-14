extends RefCounted

# The original six-room experiment, kept independent of the evolving default
# scenario so established model/integration contracts retain their evidence.
static func create() -> Dictionary:
	var data := {
		"root": "start", "initial_capacity": 4,
		"templates": {
			"empty": {"obstacles": [], "enemies": [], "pickups": []},
			"practice": {"obstacles": [], "enemies": [Vector2(560, 350)], "pickups": [{"id": "capacity", "position": Vector2(590, 180), "kind": "capacity"}]}
		},
		"nodes": {}, "links": [], "interactions": []
	}
	for id in ["start", "sword", "boots", "sword_landing", "boots_landing", "prize"]:
		data.nodes[id] = {"id": id, "name": id, "template": "practice" if id in ["sword", "boots"] else "empty", "cost": 0 if id == "start" else 1, "requires_all": [], "requires_any": [], "abilities": []}
	data.nodes.sword.abilities = ["sword"]
	data.templates.home = data.templates.empty.duplicate(true)
	data.templates.home.clear = {"conditions": [], "effects": [{"kind": "become_root"}]}
	data.nodes.start.template = "home"
	data.nodes.boots.abilities = ["dash"]
	data.nodes.sword_landing.requires_all = ["sword"]
	data.nodes.boots_landing.requires_all = ["boots"]
	data.nodes.prize.requires_all = ["sword_landing", "boots_landing"]
	for pair in [["start", "sword", "west", "east"], ["start", "boots", "east", "west"], ["sword", "sword_landing", "north", "south"], ["boots", "boots_landing", "north", "south"], ["sword_landing", "prize", "east", "west"], ["boots_landing", "prize", "west", "east"]]:
		data.links.append({"a": pair[0], "b": pair[1], "a_port": pair[2], "b_port": pair[3], "activate_from": [pair[0], pair[1]]})
	return data
