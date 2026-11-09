class_name Geo
extends RefCounted
## Aiuti per costruire la geometria: primitive, superfici parametriche, torni e tubi.


static func add(parent: Node, mesh: Mesh, mat: Material = null, pos := Vector3.ZERO,
		rot := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat != null:
		mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func box(s: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = s
	return m


static func cyl(top: float, bottom: float, h: float, seg := 24, caps := true) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	m.cap_top = caps
	m.cap_bottom = caps
	return m


static func sphere(r: float, seg := 24, rings := 12) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = rings
	return m


static func capsule(r: float, h: float, seg := 12) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0 + 0.0001)
	m.radial_segments = seg
	m.rings = 4
	return m


static func torus(inner: float, outer: float, seg := 32, ring_seg := 10) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = seg
	m.ring_segments = ring_seg
	return m


## Superficie parametrica: f(s, t) -> Vector3, con s e t da 0 a 1.
## keep(s, t) -> bool scarta dei quadrati (per i buchi degli occhi).
## col(s, t) -> Color finisce in COLOR, uvf(s, t) -> Vector2 in UV.
static func surface(nu: int, nv: int, f: Callable, keep: Callable = Callable(),
		col: Callable = Callable(), uvf: Callable = Callable(), flip := false,
		with_tangents := false) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var tans := PackedFloat32Array()
	var idx := PackedInt32Array()
	var e := 0.0008
	for j in nv + 1:
		var t := float(j) / nv
		for i in nu + 1:
			var s := float(i) / nu
			var p: Vector3 = f.call(s, t)
			var ds: Vector3 = f.call(minf(s + e, 1.0), t) - f.call(maxf(s - e, 0.0), t)
			var dt: Vector3 = f.call(s, minf(t + e, 1.0)) - f.call(s, maxf(t - e, 0.0))
			var n := dt.cross(ds)
			if n.length_squared() < 1e-16:
				var t2 := clampf(t + (e * 25.0 if t < 0.5 else -e * 25.0), 0.0, 1.0)
				ds = f.call(minf(s + e, 1.0), t2) - f.call(maxf(s - e, 0.0), t2)
				dt = f.call(s, minf(t2 + e, 1.0)) - f.call(s, maxf(t2 - e, 0.0))
				n = dt.cross(ds)
			n = n.normalized()
			if flip:
				n = -n
			verts.append(p)
			norms.append(n)
			uvs.append(uvf.call(s, t) if uvf.is_valid() else Vector2(s, t))
			cols.append(col.call(s, t) if col.is_valid() else Color.WHITE)
			if with_tangents:
				var tg := ds.normalized()
				tans.append_array([tg.x, tg.y, tg.z, 1.0])
	var row := nu + 1
	for j in nv:
		for i in nu:
			if keep.is_valid() and not keep.call((i + 0.5) / nu, (j + 0.5) / nv):
				continue
			var a := j * row + i
			var b := a + 1
			var c := a + row
			var d := c + 1
			if flip:
				idx.append_array([a, c, b, b, c, d])
			else:
				idx.append_array([a, b, c, b, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_COLOR] = cols
	if with_tangents:
		arr[Mesh.ARRAY_TANGENT] = tans
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


## Tornio: profilo di punti (raggio, altezza) dal basso verso l'alto.
static func lathe(profile: PackedVector2Array, seg := 32, jitter := 0.0) -> ArrayMesh:
	var n := profile.size()
	var lens := PackedFloat32Array([0.0])
	for i in range(1, n):
		lens.append(lens[i - 1] + profile[i].distance_to(profile[i - 1]))
	var total := lens[n - 1]
	var sample := func(t: float) -> Vector2:
		var d := t * total
		for i in range(1, n):
			if d <= lens[i] or i == n - 1:
				var seg_len := lens[i] - lens[i - 1]
				var k := 0.0 if seg_len <= 0.0 else clampf((d - lens[i - 1]) / seg_len, 0.0, 1.0)
				return profile[i - 1].lerp(profile[i], k)
		return profile[n - 1]
	var f := func(s: float, t: float) -> Vector3:
		var p: Vector2 = sample.call(t)
		var a := s * TAU
		var r := p.x
		if jitter > 0.0:
			r *= 1.0 + jitter * sin(a * 3.0 + p.y * 40.0) * sin(a * 7.0)
		return Vector3(r * cos(a), p.y, r * sin(a))
	var steps := maxi(n * 3, 12)
	return surface(seg, steps, f, Callable(), Callable(),
			func(s: float, t: float) -> Vector2: return Vector2(s, t * total))


## Tubo lungo una curva. path(t) -> Vector3, radius(t) -> float, squash schiaccia la sezione.
static func tube(path: Callable, radius: Callable, seg := 16, steps := 24, squash := Vector2.ONE,
		up_hint := Vector3.UP) -> ArrayMesh:
	var f := func(s: float, t: float) -> Vector3:
		var c: Vector3 = path.call(t)
		var t0: float = maxf(t - 0.01, 0.0)
		var t1: float = minf(t + 0.01, 1.0)
		var tan: Vector3 = (path.call(t1) - path.call(t0)).normalized()
		var side := tan.cross(up_hint)
		if side.length_squared() < 1e-6:
			side = tan.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(tan).normalized()
		var a := s * TAU
		var r: float = radius.call(t)
		return c + side * cos(a) * r * squash.x + up * sin(a) * r * squash.y
	return surface(seg, steps, f)


## Superellissoide: tra una sfera e un cubo arrotondato.
static func superellipsoid(size: Vector3, e1 := 0.5, e2 := 0.5, seg := 24, rings := 16) -> ArrayMesh:
	var sp := func(x: float, e: float) -> float: return signf(x) * pow(absf(x), e)
	var f := func(s: float, t: float) -> Vector3:
		var phi := (t - 0.5) * PI
		var th := s * TAU
		var cp: float = sp.call(cos(phi), e1)
		return Vector3(size.x * 0.5 * cp * sp.call(cos(th), e2),
				size.y * 0.5 * sp.call(sin(phi), e1),
				size.z * 0.5 * cp * sp.call(sin(th), e2))
	return surface(seg, rings, f)


## Mette un nodo in modo che il suo asse Y vada da a a b.
static func orient_between(node: Node3D, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var len := dir.length()
	if len < 1e-5:
		return
	var y := dir / len
	var x := y.cross(Vector3.FORWARD)
	if x.length_squared() < 1e-6:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	node.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
