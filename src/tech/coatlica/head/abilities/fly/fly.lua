Fly = CoatlicaAbility:new()

function Fly:init()
	self.active = false
	self.timer = 0
	self.cooldown = 0.05
end
function Fly:uninit()
	self.active = false
	world.sendEntityMessage(entity.id(), "setFly", self.active)
end

function Fly:update(dt, dir, shiftHeld)
	if self.timer == 0 then
		self.active = false
		world.sendEntityMessage(entity.id(), "setFly", self.active)
		timer = -1
	elseif self.active then
		self.timer		= math.max(self.timer - dt, 0)
		self.cooldown	= math.max(self.cooldown - dt,0)
		if dir[1] == 0 and dir[2] == 0 then
			dir = vec2.norm(world.distance(tech.aimPosition(), mcontroller.position()))
		end
		mcontroller.controlApproachVelocity(vec2.mul(dir, 30), 120)
		
		if self.cooldown <= 0 and false then
			local angle = (math.random()-0.5)*math.pi*0.05 + math.pi/2*(dir[1] > 0 and 1 or -1)
			local offset = vec2.mul(vec2.rotate(dir, angle),2)
			local projectileId = world.spawnProjectile(
				self.projectileType,
				vec2.add(mcontroller.position(), offset),
				entity.id(),
				vec2.withAngle(angle + vec2.angle(dir)),
				false,
				{
					speed = 10
				}
			)
		self.cooldown = 0.05
		end
	end
end

function Fly:fire()
	world.sendEntityMessage(entity.id(), "setAnimationState", "halo", "activate")
end
function Fly:hold(dt)
	self.timer = math.min(self.timer + dt*6, 60)
end
function Fly:release()
	self.active = true
	world.sendEntityMessage(entity.id(), "setFly", self.active)
end