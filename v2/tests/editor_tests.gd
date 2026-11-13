extends SceneTree

# C1/C2/C6 at the editor boundary: accepted edits round-trip; rejected edits
# retain both the working document and the user's unapplied inspector text.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._open_studio()
	await process_frame
	var editor = game.studio
	_expect(not game.room.visible and game.room.process_mode == Node.PROCESS_MODE_DISABLED, "Opening editors suspends gameplay")
	var before: Dictionary = editor.document.duplicate(true)
	editor.inspector.text = "{bad"
	_expect(not editor._apply() and editor.document == before and editor.inspector.text == "{bad", "Invalid edits preserve source and inspector")
	editor._refresh()
	editor._add_room()
	editor.preview.brush = "enemy"
	editor._place(Vector2(300, 200))
	var selected: int = editor.room_index
	_expect(editor.document.rooms[selected].objects.size() == 1, "Room editor places template objects")
	editor._add_node()
	var node: Dictionary = editor.document.dungeon.nodes.back()
	_expect(node.template == editor.document.rooms[selected].id, "Tree editor assigns selected template")
	editor._move(node.id, Vector2(100, 100))
	var path := "user://editor_contract_test.json"
	editor._save_to(path)
	_expect(not editor.dirty, "Successful save clears dirty state")
	var result: Dictionary = editor.store.load_document(path)
	_expect(result.ok and result.document.dungeon.nodes.back().id == node.id, "Authored nodes survive reopening")
	editor.document.extensions["editor_test"] = {"preserve": true}
	editor.dirty = true
	editor._refresh()
	editor._save_to(path)
	result = editor.store.load_document(path)
	_expect(result.ok and result.document.extensions.editor_test.preserve, "Overwriting save retains extension data")
	editor._play()
	_expect(not editor.visible and game.data.nodes.has(node.id), "Playtest uses authored graph, closes editor")
	game._open_studio()
	_expect(editor.document.extensions.editor_test.preserve, "Returning from playtest preserves authoring document")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("All editor boundary tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
