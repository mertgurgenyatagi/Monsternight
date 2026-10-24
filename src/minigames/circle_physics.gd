class_name CirclePhysics
extends RefCounted
## Small static helpers for round things that bounce: two circles, or a circle against a round wall.
## Masses are plain numbers; a velocity is changed in place through the returned values.


## Collides two circles. Pushes them apart (the lighter moves more) and, when they were closing, bounces
## them with `restitution`. Returns `[new_a_velocity, new_b_velocity, new_a_position, new_b_position,
## closing_speed, contact_point]`, where `closing_speed` is 0 when they did not touch or were parting.
static func collide(pos_a: Vector2, vel_a: Vector2, radius_a: float, mass_a: float,
		pos_b: Vector2, vel_b: Vector2, radius_b: float, mass_b: float, restitution: float) -> Array:
	var offset := pos_b - pos_a
	var dist := offset.length()
	var reach := radius_a + radius_b
	if dist >= reach:
		return [vel_a, vel_b, pos_a, pos_b, 0.0, pos_a]
	var n := offset / dist if dist > 0.0001 else Vector2.RIGHT
	var inv_a := 1.0 / mass_a
	var inv_b := 1.0 / mass_b
	var push := reach - dist
	pos_a -= n * push * inv_a / (inv_a + inv_b)
	pos_b += n * push * inv_b / (inv_a + inv_b)
	var closing := (vel_a - vel_b).dot(n)
	if closing <= 0.0:
		return [vel_a, vel_b, pos_a, pos_b, 0.0, pos_a + n * radius_a]
	var j := (1.0 + restitution) * closing / (inv_a + inv_b)
	vel_a -= n * j * inv_a
	vel_b += n * j * inv_b
	return [vel_a, vel_b, pos_a, pos_b, closing, pos_a + n * radius_a]


## Bounces a circle moving inside a round wall centred on the origin (a ball in a bowl). Returns
## `[velocity, position]`.
static func bounce_in_ring(pos: Vector2, vel: Vector2, radius: float, ring_radius: float, restitution: float) -> Array:
	var dist := pos.length()
	if dist <= ring_radius - radius or dist < 0.0001:
		return [vel, pos]
	var n := pos / dist
	pos = n * (ring_radius - radius)
	var out := vel.dot(n)
	if out > 0.0:
		vel -= n * out * (1.0 + restitution)
	return [vel, pos]


## Bounces a circle off a box (a crossbar). Returns `[velocity, position, impact_speed]`, where
## `impact_speed` is 0 when the circle did not touch the box or was moving away from it.
static func bounce_off_box(pos: Vector2, vel: Vector2, radius: float, box: Rect2, restitution: float) -> Array:
	var closest := pos.clamp(box.position, box.end)
	var offset := pos - closest
	var dist := offset.length()
	if dist >= radius:
		return [vel, pos, 0.0]
	var n := offset / dist if dist > 0.0001 else Vector2.UP
	pos = closest + n * radius
	var into := -vel.dot(n)
	if into <= 0.0:
		return [vel, pos, 0.0]
	vel += n * into * (1.0 + restitution)
	return [vel, pos, into]
