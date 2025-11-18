FireBreath = CoatlicaAbility:new()

function FireBreath:init(fireType)
	self.cooldown = 0.05
	self.audiocooldown = 0
	animator.setSoundPool(fireType, self.sounds.fire)
	animator.setSoundPool(fireType.."Hold", self.sounds.hold)
	animator.setSoundPool(fireType.."Release", self.sounds.release)
end
function FireBreath:uninit() end
function FireBreath:update(dt, dir, shiftHeld)
	self.cooldown = math.max(self.cooldown - dt,0)
end
function FireBreath:fire(fireType)
	if not status.resourceLocked("energy") then
		local dir = vec2.norm(world.distance(tech.aimPosition(), mcontroller.position()))
		mcontroller.controlApproachVelocity(vec2.mul(dir, -50), 400)
		animator.playSound(fireType)
	end
end
function FireBreath:hold(dt, fireType)
	if not status.resourceLocked("energy") and self.cooldown <= 0 then
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
			{
				speed = vec2.dot(mcontroller.velocity(), dir)+30,
				power = 1*status.stat("powerMultiplier")
			}
		)
		self.cooldown = 0.05
		self.audiocooldown = math.max(self.audiocooldown - 1,0)
		if self.audiocooldown <= 0 then
			animator.playSound(fireType.."Hold")
			self.audiocooldown = 140
		end
		status.overConsumeResource("energy", self.energyCost)
	end
end
function FireBreath:release(fireType)
	animator.stopAllSounds(fireType)
	animator.stopAllSounds(fireType.."Hold")
	animator.playSound(fireType.."Release")
	self.audiocooldown = 0
end