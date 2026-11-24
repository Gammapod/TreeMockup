extends RefCounted

# Inputs are validated before use. This module composes snapshots, not actions.
const STATS := {
	"move_speed": {"base": 220.0, "min": 1.0, "max": 2000.0, "requires": ""},
	"sword_range": {"base": 92.0, "min": 1.0, "max": 1000.0, "requires": "sword"},
	"sword_arc": {"base": 1.8, "min": 0.01, "max": TAU, "requires": "sword"},
	"sword_damage": {"base": 1.0, "min": 0.0, "max": 100000.0, "requires": "sword"},
	"sword_cooldown": {"base": 0.16, "min": 0.0, "max": 60.0, "requires": "sword"},
	"dash_distance": {"base": 104.0, "min": 1.0, "max": 1000.0, "requires": "dash"},
	"dash_recharge": {"base": 0.49, "min": 0.0, "max": 60.0, "requires": "dash"},
	"max_hp": {"base": 5.0, "min": 1.0, "max": 100000.0, "requires": ""}
}
const QUALITIES := {
	"sword": "", "dash": "", "water_pass": "",
	"sword_root": "sword", "dash_root": "dash", "phase_teleport": "dash"
}

static func compose(definition: Dictionary, selected: Dictionary) -> Dictionary:
	var sources: Array = []
	var node_ids: Array = selected.keys()
	node_ids.sort()
	for node_id in node_ids:
		var entries: Array = definition.nodes[node_id].get("contributions", []).duplicate(true)
		entries.sort_custom(func(a, b): return a.id < b.id)
		for entry in entries:
			sources.append({"node_id": node_id, "contribution": entry})
	var granted := {}
	for quality in QUALITIES:
		granted[quality] = sources.any(func(item): return item.contribution.kind == "quality" and item.contribution.quality == quality)
	var qualities := {}
	for quality in QUALITIES:
		var requirement: String = QUALITIES[quality]
		qualities[quality] = {
			"granted": granted[quality],
			"effective": granted[quality] and (requirement == "" or granted[requirement]),
			"requires": requirement,
			"sources": sources.filter(func(item): return item.contribution.kind == "quality" and item.contribution.quality == quality).duplicate(true)
		}
	var stats := {}
	for stat in STATS:
		var spec: Dictionary = STATS[stat]
		var base: float = float(definition.get("base_hp", spec.base)) if stat == "max_hp" else spec.base
		var additions := 0.0
		var multiplier := 1.0
		var stat_sources: Array = sources.filter(func(item): return item.contribution.kind == "stat" and item.contribution.stat == stat)
		for source in stat_sources:
			var item: Dictionary = source.contribution
			if item.op == "add":
				additions += float(item.value)
			else:
				multiplier *= float(item.value)
		var raw := (base + additions) * multiplier
		var rounded: float = floor(raw) if stat == "max_hp" else raw
		var value: float = clampf(rounded, spec.min, spec.max)
		var requirement: String = spec.requires
		var is_effective: bool = requirement == "" or granted[requirement]
		stats[stat] = {
			"base": base, "additions": additions, "multiplier": multiplier,
			"raw": raw, "value": int(value) if stat == "max_hp" else value,
			"effective": (int(value) if stat == "max_hp" else value) if is_effective else null,
			"requires": requirement, "clamped": value != rounded,
			"min": spec.min, "max": spec.max, "sources": stat_sources.duplicate(true)
		}
	return {"model": "unified_1", "stats": stats, "qualities": qualities}
