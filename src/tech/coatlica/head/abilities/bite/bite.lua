Bite = CoatlicaAbility:new()

function Bite:init()
	self.cooldown = 0
end
function Bite:uninit()
	status.clearPersistentEffects("coatlica_bite_ability")
end
function Bite:update(dt, dir, shiftHeld)
	if self.cooldown > 0 then
		self.cooldown = math.max(self.cooldown - dt, 0)
		if self.cooldown == 0 then
			status.clearPersistentEffects("coatlica_bite_ability")
		end
		mcontroller.setVelocity(vec2.mul(mcontroller.velocity(), self.cooldown+0.7))
	end
end
function Bite:fire() end
function Bite:hold(dt) end
function Bite:release(headId)
	--lunge forward
	local maxHeight = 6
	if self.cooldown == 0
			and (status.statusProperty("isHolding", false) or distanceToGround(maxHeight) ~= maxHeight)
			and not status.resourceLocked("energy") then
		
		local maxVel = 10
		local dir = world.distance(tech.aimPosition(), mcontroller.position())
		if vec2.mag(dir) > maxVel then
			dir = vec2.mul(vec2.norm(dir), maxVel)
		end
		mcontroller.setVelocity(vec2.mul(dir, 10))
		status.overConsumeResource("energy", self.energyCost)
		world.sendEntityMessage(headId, "setDamageOnTouch", true)
		status.setPersistentEffects("coatlica_bite_ability", {{stat = "invulnerable", amount = 1}})
		self.cooldown = 0.3
	end
end