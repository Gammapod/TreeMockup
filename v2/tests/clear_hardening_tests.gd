extends SceneTree

const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
const MODEL = preload("res://progression.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func fixture() -> Dictionary:
	var doc: Dictionary = STORE.new().new_project()
	doc.dungeon.initial_capacity = 3
	doc.dungeon.nodes.append(STORE.new().new_node("second", "empty"))
	doc.dungeon.links.append({"id": "passage", "a": "start", "b": "second", "a_port": "east", "b_port": "west", "activate_from": ["start", "second"]})
	return doc

func _run() -> void:
	# CL5: all immediate roots contribute to the initial build, not just start.
	var doc := fixture()
	doc.dungeon.base_hp = 0
	doc.dungeon.nodes[1].modifiers = {"max_hp_bonus": 2}
	var result: Dictionary = ADAPTER.new().compile(doc)
	_expect(result.ok, "CL5: initial-health validation includes every immediate root")
	if result.ok:
		_expect(MODEL.new(result.data).capabilities().max_hp == 2, "CL5: compiled initial health matches active root capabilities")
	doc.dungeon.nodes[1].modifiers.max_hp_bonus = 0
	_expect(not ADAPTER.new().compile(doc).ok, "CL5: zero total initial health is still rejected")
	var data: Dictionary = ADAPTER.new().compile(fixture()).data
	for kind in ["root", "door", "defeat"]:
		var game = load("res://main.tscn").instantiate()
		game.data_override = data
		root.add_child(game)
		await process_frame
		match kind:
			"root": game._request_root_travel("second")
			"door": game._request_travel("second", "west")
			"defeat": game._defeat()
		game._open_studio()
		game._play_document(data)
		var fresh_room = game.room
		game.room.player.hp = 2
		await process_frame
		_expect(game.room == fresh_room and game.current == "start" and game.room.player.hp == 2, "LIFE1: stale %s callback cannot alter a fresh playtest" % kind)
		game.queue_free()
		await process_frame
	# A queued transition must preserve the editor's pause boundary.
	var game = load("res://main.tscn").instantiate()
	game.data_override = data
	root.add_child(game)
	await process_frame
	game._request_root_travel("second")
	game._open_studio()
	await process_frame
	_expect(game.room.process_mode == Node.PROCESS_MODE_DISABLED and not game.room.visible, "LIFE2: deferred arrival cannot resume gameplay behind the editor")
	game._close_studio()
	_expect(game.room.process_mode == Node.PROCESS_MODE_INHERIT and game.room.visible, "LIFE2: editor resume restores the current room")
	# Door travel revalidates too, and cannot carry a dead player into a room.
	game._enter_room("start", "", 5)
	game._request_travel("second", "west")
	game.progression.active.erase("second")
	await process_frame
	_expect(game.current == "start" and not game.transition_pending, "TR2: stale door eligibility rejects without entering an inactive room")
	game.progression.active.second = true
	game._request_travel("second", "west")
	game.room.player.hp = 0
	await process_frame
	await process_frame
	_expect(game.current == "start" and game.room.player.hp == game.room.player.max_hp, "TR2: death before door arrival follows defeat rather than restoring captured HP")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("All clearing baseline hardening contracts passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
