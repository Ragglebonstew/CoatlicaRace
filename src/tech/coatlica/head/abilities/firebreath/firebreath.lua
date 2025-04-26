FireBreath = CoatlicaAbility:new()

function FireBreath:init() end
function FireBreath:uninit() end
function FireBreath:update(dt, dir, shiftHeld) end
function FireBreath:fire()
	local dir = vec2.norm(world.distance(tech.aimPosition(), mcontroller.position()))
	mcontroller.setVelocity(vec2.mul(dir, -10))
end
function FireBreath:hold(dt)
	if not status.resourceLocked("energy") then
		local angle = (math.random()-0.5)*math.pi*0.05
		local dir = vec2.norm(world.distance(tech.aimPosition(), mcontroller.position()))
		local offset = vec2.mul(dir,2)
		mcontroller.controlApproachVelocity(vec2.mul(dir, -10), 2)
		dir = vec2.rotate(dir, angle)
		local projectileId = world.spawnProjectile(
			self.projectileType,
			vec2.add(mcontroller.position(), offset),
			entity.id(),
			dir,
			false,
			{speed = vec2.dot(mcontroller.velocity(), dir)+30}
		)
		status.overConsumeResource("energy", self.energyCost)
	end
end
function FireBreath:release() end