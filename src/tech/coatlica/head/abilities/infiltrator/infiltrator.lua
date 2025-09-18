Infiltrator = CoatlicaAbility:new()

function Infiltrator:init()
	self.progress = 0
	local snakeDirectives = "?replace"
	local items = {
		"dc1f00", "be1b00", "951500", 
		"FFFFF4", "F4F1E1", "C9C2B1"
	}
	for _,color_old in ipairs(items) do
		snakeDirectives = snakeDirectives..";"..color_old.."=00000000"
	end
	
	tech.setParentHidden(false)
	setMovementOverride(true)
end
function Infiltrator:uninit()
	tech.setParentDirectives()
	tech.setParentHidden(true)
	setDirectives()
	setMovementOverride(false)
end
function Infiltrator:update(dt, dir, shiftHeld)
	tech.setParentDirectives(snakeDirectives)
	setDirectives("?multiply=FFFFFF00")
end
function Infiltrator:fire()end
function Infiltrator:hold(dt) end
function Infiltrator:release(headId)end
