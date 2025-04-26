Fly = CoatlicaAbility:new()

function Fly:init()
	self.active = false
	self.timer = 0
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
		self.timer = math.max(self.timer - dt, 0)
		if dir[1] == 0 and dir[2] == 0 then
			dir = vec2.norm(world.distance(tech.aimPosition(), mcontroller.position()))
		end
		mcontroller.controlApproachVelocity(vec2.mul(dir, 30), 120)
	end
end

function Fly:hold(dt)
	self.timer = math.min(self.timer + dt*6, 60)
end
function Fly:release()
	self.active = true
	world.sendEntityMessage(entity.id(), "setFly", self.active)
end