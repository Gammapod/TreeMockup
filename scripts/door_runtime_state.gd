class_name DoorRuntimeState
extends RefCounted

var open: bool = false
var sealed_reason: String = ""
var propped: bool = false

func is_sealed() -> bool:
	return sealed_reason != ""
