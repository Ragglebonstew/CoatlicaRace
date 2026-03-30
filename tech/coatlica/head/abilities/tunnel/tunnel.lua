Tunnel = CoatlicaAbility:new()

function Tunnel:init()
	self.maxTunnelSpeed = self.maxTunnelSpeed or 1
end
function Tunnel:uninit() end

function Tunnel:update(dt, dir, shiftHeld)

	--local headPoly = { {0.75, 1.0}, {1.0, 0.75}, {1.0, -0.75}, {0.75, -1.0}, {-0.75, -1.0}, {-1.0, -0.75}, {-1.0, 0.75}, {-0.75, 1.0} }
	local playerPos = mcontroller.position()
	local inGround = world.pointCollision(playerPos, {"Block", "Platform", "Dynamic", "Slippery", "Null"})
	if inGround then
		local vel = mcontroller.velocity()
		if vec2.mag(vel) > self.maxTunnelSpeed then
			limVel = vec2.mul(vec2.norm(vel), self.maxTunnelSpeed)
			mcontroller.setVelocity(limVel)
		end
	end
	
	mcontroller.controlParameters({
		collisionEnabled = false
	})
end