Bite = CoatlicaAbility:new()

function Bite:init() end
function Bite:uninit() end
function Bite:update(dt, dir, shiftHeld) end
function Bite:fire() end
function Bite:hold(dt) end
function Bite:release()
	--lunge forward
	if not status.resourceLocked("energy") then
		mcontroller.setVelocity(vec2.mul(world.distance(tech.aimPosition(), mcontroller.position()), 5))
		status.overConsumeResource("energy", self.energyCost)
	end
end