Tunnel = CoatlicaAbility:new()

function Tunnel:init() end
function Tunnel:uninit() end

function Tunnel:update(dt, dir, shiftHeld)

	local headPoly = { {0.75, 1.0}, {1.0, 0.75}, {1.0, -0.75}, {0.75, -1.0}, {-0.75, -1.0}, {-1.0, -0.75}, {-1.0, 0.75}, {-0.75, 1.0} }
	local playerPos = mcontroller.position()
	inGround = world.polyCollision(headPoly, playerPos, {"Block", "Platform", "Dynamic", "Slippery", "Null"})
	if inGround then
		mcontroller.controlParameters({gravityEnabled = true})
	end
	
	mcontroller.controlParameters({
		collisionEnabled = false,
		airFriction = 0.1,
		liquidFriction = 0.1,
		liquidBuoyancy = 0.1
	})
end