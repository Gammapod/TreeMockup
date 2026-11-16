extends RefCounted

# Source snapshots deliberately retain extension fields. UI context is restored
# with an edit, but selecting/panning alone never creates a history entry.
const LIMIT := 100
var undo_stack: Array = []
var redo_stack: Array = []

func record(label: String, before: Dictionary, after: Dictionary) -> void:
	if before.document == after.document:
		return
	undo_stack.append({"label": label, "before": before.duplicate(true), "after": after.duplicate(true)})
	if undo_stack.size() > LIMIT:
		undo_stack.pop_front()
	redo_stack.clear()

func undo() -> Dictionary:
	if undo_stack.is_empty():
		return {}
	var entry: Dictionary = undo_stack.pop_back()
	redo_stack.append(entry)
	return entry.before.duplicate(true)

func redo() -> Dictionary:
	if redo_stack.is_empty():
		return {}
	var entry: Dictionary = redo_stack.pop_back()
	undo_stack.append(entry)
	return entry.after.duplicate(true)

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()
