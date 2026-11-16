extends SceneTree
## Shared completion protocol. The runner also checks process exit and engine errors.

var assertion_count := 0

func _complete(code: int) -> void:
	var failures: Array = get("failures")
	var suite: String = get_script().resource_path.get_file().trim_suffix("_tests.gd")
	print("V2_TEST_RESULT " + JSON.stringify({
		"schema_version": 1,
		"suite": suite,
		"assertions": assertion_count,
		"failures": failures,
	}))
	quit(code)
