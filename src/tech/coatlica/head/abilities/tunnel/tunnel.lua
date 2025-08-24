Tunnel = CoatlicaAbility:new()

function Tunnel:init() end
function Tunnel:uninit() end

function Tunnel:update(dt, dir, shiftHeld)

	local playerPos = mcontroller.position()
	local inGround = false
	
	if world.gravity(playerPos) == 0 or world.type() == "unknown" then
		inGround = true
	else
		local headPoly = { {0.75, 1.0}, {1.0, 0.75}, {1.0, -0.75}, {0.75, -1.0}, {-0.75, -1.0}, {-1.0, -0.75}, {-1.0, 0.75}, {-0.75, 1.0} }
		inGround = world.polyCollision(headPoly, playerPos, {"Block", "Platform", "Dynamic", "Slippery", "Null"})
		if not inGround and world.liquidAt({math.floor(playerPos[1]+0.5), math.floor(playerPos[2]+0.5)}) then
			inGround = config.getParameter("treatLiquidAsGround", false)
		end
	end
	
	mcontroller.controlParameters({
		gravityEnabled = not inGround,
		collisionEnabled = false,
		airFriction = 0,
		liquidFriction = 0,
		liquidBuoyancy = 0.0
	})
end