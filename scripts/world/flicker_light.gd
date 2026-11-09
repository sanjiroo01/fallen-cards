class_name FlickerLight
extends OmniLight3D
## Luce che trema come le candele che la producono. Si spegne e riaccende col buio.

var base_energy := 1.0
var _factor := 1.0
var _noise := FastNoiseLite.new()
var _t := 0.0
var _home := Vector3.ZERO


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0
	_t = randf() * 50.0
	_home = position


func _process(delta: float) -> void:
	_t += delta
	var n1 := _noise.get_noise_1d(_t * 6.0)
	var n2 := _noise.get_noise_1d(_t * 11.0 + 40.0)
	light_energy = base_energy * (1.0 + 0.09 * n1 + 0.05 * n2) * _factor
	position = _home + Vector3(n2, n1, -n2) * 0.004
	visible = _factor > 0.005


func blow_out(delay := 0.0) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "_factor", 0.0, 0.3)


func relight(delay := 0.0) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "_factor", 1.2, 0.15)
	tw.tween_property(self, "_factor", 1.0, 0.4)


func set_lit_instant(on: bool) -> void:
	_factor = 1.0 if on else 0.0
