extends RefCounted

const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")

static func create(path: String = "res://examples/branching.json") -> Dictionary:
	var source: Dictionary = STORE.new().load_document(path)
	assert(source.ok, str(source.errors))
	var result: Dictionary = ADAPTER.new().compile(source.document)
	assert(result.ok, str(result.errors))
	return result.data
