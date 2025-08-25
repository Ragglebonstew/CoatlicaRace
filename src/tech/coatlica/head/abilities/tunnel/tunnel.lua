Tunnel = CoatlicaAbility:new()

function Tunnel:init() end
function Tunnel:uninit() end

function Tunnel:update(dt, dir, shiftHeld)

	local inGround = false
	
	if mcontroller.zeroG() then
		inGround = true
	else
		local headPoly = { {0.75, 1.0}, {1.0, 0.75}, {1.0, -0.75}, {0.75, -1.0}, {-0.75, -1.0}, {-1.0, -0.75}, {-1.0, 0.75}, {-0.75, 1.0} }
		local playerPos = mcontroller.position()
		inGround = world.polyCollision(headPoly, playerPos, {"Block", "Platform", "Dynamic", "Slippery", "Null"})
	end
	
	mcontroller.controlParameters({
		gravityEnabled = not inGround,
		collisionEnabled = false,
		airFriction = 0,
		liquidFriction = 0,
		liquidBuoyancy = 0.0
	})
end