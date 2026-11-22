class_name SpineConverterTest
extends SceneTree
## Run by bindings/godot/tests/run.sh and android.sh, calls with every argument typed take ptrcall and the others take call

const JSON_38 := '{"skeleton":{"spine":"3.8.99","hash":""},"bones":[]}'
const PHYSICS := '{"skeleton":{"spine":"4.2.43","referenceScale":50},"bones":[{"name":"root"}],"physics":[{"name":"p","bone":"root"}]}'
const ATLAS := "\na.png\nsize: 64,64\nformat: RGBA8888\nfilter: Linear,Linear\nrepeat: none\nr\n  rotate: false\n  xy: 2, 2\n  size: 20, 30\n  orig: 32, 40\n  offset: 5, 3\n  index: -1\n"
const STRIPPED := '{"skeleton":{"spine":"3.6.53"},"bones":[{"name":"root"}],"slots":[{"name":"s","bone":"root"}],"skins":{"default":{"s":{"r":{"type":"mesh","uvs":[0,0,1,0,1,1,0.25,0.7],"triangles":[0,1,2,0,2,3],"vertices":[0,0,10,0,10,10,0,10],"hull":4}}}}}'

var failures := 0


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", what)


func _init() -> void:
	check(ClassDB.class_exists(&"SpineConverter"), "class registered")
	check(SpineConverter.library_version().begins_with("1."), "library_version")
	check(SpineConverter.describe(SpineConverter.STATUS_OK) == "ok", "describe")
	typed()
	untyped()
	errors()
	print("spine-converter godot test: ", "passed" if failures == 0 else "%d failed" % failures)
	quit(1 if failures else 0)


func typed() -> void:
	var json: PackedByteArray = JSON_38.to_utf8_buffer()
	var d: Dictionary = SpineConverter.detect(json)
	check(d.status == SpineConverter.STATUS_OK and d.format == SpineConverter.FORMAT_JSON, "typed detect format")
	check(d.version == "3.8.99" and d.major == 3 and d.minor == 8 and d.patch == 99, "typed detect version")
	check(SpineConverter.detect("PNG".to_utf8_buffer()).format == SpineConverter.FORMAT_UNKNOWN, "typed detect unknown")
	check(SpineConverter.detect(PackedByteArray()).format == SpineConverter.FORMAT_UNKNOWN, "typed detect empty")

	var same: Dictionary = SpineConverter.convert(json)
	check(same.status == SpineConverter.STATUS_OK and same.error == "", "typed keeps status")
	check(same.data == json and same.report.is_empty() and same.loss_count == 0, "typed keeps the source")
	check(same.max_impact == SpineConverter.IMPACT_NONE, "typed keeps impact")

	var physics: PackedByteArray = PHYSICS.to_utf8_buffer()
	var lossy: Dictionary = SpineConverter.convert(physics, "4.1")
	check(lossy.loss_count == 2 and lossy.max_impact == SpineConverter.IMPACT_POSE, "typed losses")
	check(lossy.report.any(func(e: Dictionary) -> bool: return e.code == "physics.dropped" and e.remedy == "none"), "typed report")
	check(lossy.report.all(func(e: Dictionary) -> bool: return e.keys() == ["code", "severity", "impact", "step", "path", "message", "remedy"]), "typed report fields")

	var skel: Dictionary = SpineConverter.convert(json, "4.3", SpineConverter.FORMAT_BINARY)
	check(SpineConverter.detect(skel.data).format == SpineConverter.FORMAT_BINARY, "typed to binary")
	var back: Dictionary = SpineConverter.convert(skel.data, "", SpineConverter.FORMAT_JSON, SpineConverter.FLAG_PRETTY_JSON)
	check(SpineConverter.detect(back.data).version.begins_with("4.3"), "typed back to json")
	check(back.data.get_string_from_utf8().contains("\n"), "typed pretty json")

	var stripped: PackedByteArray = STRIPPED.to_utf8_buffer()
	check(SpineConverter.convert(stripped, "3.7").loss_count == 1, "typed without atlas")
	var version: String = "3.7"
	var format: int = SpineConverter.FORMAT_UNKNOWN
	var flags: int = 0
	var atlas: PackedByteArray = ATLAS.to_utf8_buffer()
	var kept: Dictionary = SpineConverter.convert(stripped, version, format, flags, atlas)
	check(kept.loss_count == 0 and kept.data.get_string_from_utf8().contains("0.15625,0.175"), "typed with atlas")
	var status: int = SpineConverter.STATUS_LOSSY_REJECTED
	var message: String = SpineConverter.describe(status)
	check(message == "conversion would lose data", "typed describe")


func untyped() -> void:
	var json = JSON_38.to_utf8_buffer()
	var version = "4.1"
	var d = SpineConverter.detect(json)
	check(d.format == SpineConverter.FORMAT_JSON and d.version == "3.8.99", "untyped detect")
	var same = SpineConverter.convert(json)
	check(same.data == json and same.status == SpineConverter.STATUS_OK, "untyped default arguments")
	var lossy = SpineConverter.convert(PHYSICS.to_utf8_buffer(), version)
	check(lossy.loss_count == 2 and lossy.report.size() == 2, "untyped losses")
	var format = SpineConverter.FORMAT_UNKNOWN
	var flags = 0
	var atlas = ATLAS.to_utf8_buffer()
	var kept = SpineConverter.convert(STRIPPED.to_utf8_buffer(), "3.7", format, flags, atlas)
	check(kept.loss_count == 0, "untyped with atlas")
	var status = SpineConverter.STATUS_MALFORMED
	check(SpineConverter.describe(status) == "malformed skeleton data", "untyped describe")
	var many = 0
	for i in 200:
		many += SpineConverter.convert(PHYSICS.to_utf8_buffer(), version).report.size()
	check(many == 400, "untyped repeated calls")


func errors() -> void:
	var physics: PackedByteArray = PHYSICS.to_utf8_buffer()
	var cases := [
		["4.1", SpineConverter.FORMAT_UNKNOWN, SpineConverter.FLAG_FAIL_ON_LOSS, SpineConverter.STATUS_LOSSY_REJECTED],
		["3.4", SpineConverter.FORMAT_UNKNOWN, 0, SpineConverter.STATUS_UNSUPPORTED_VERSION],
		["not a version", SpineConverter.FORMAT_UNKNOWN, 0, SpineConverter.STATUS_INVALID_ARGUMENT],
		["4.1", SpineConverter.FORMAT_UNKNOWN, 1 << 3, SpineConverter.STATUS_INVALID_ARGUMENT],
		["4.1", 99, 0, SpineConverter.STATUS_INVALID_ARGUMENT],
		["4.1", SpineConverter.FORMAT_UNKNOWN, -1, SpineConverter.STATUS_INVALID_ARGUMENT],
	]
	for c in cases:
		var r: Dictionary = SpineConverter.convert(physics, c[0], c[1], c[2])
		check(r.status == c[3] and r.error != "" and r.data.is_empty(), "error %s" % [c])
	var png: Dictionary = SpineConverter.convert("PNG".to_utf8_buffer())
	check(png.status == SpineConverter.STATUS_UNKNOWN_FORMAT and png.error != "", "error unknown format")
