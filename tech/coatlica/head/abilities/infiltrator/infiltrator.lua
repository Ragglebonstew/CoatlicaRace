Infiltrator = CoatlicaAbility:new()

function Infiltrator:init()
	setHeadType(self.type)
	
	self.progress = 0
	local snakeDirectives = "?replace"
	local scaleDirectives = string.sub(getBodyDirectives(),65,114)
	local scaleDirective1 = string.sub(scaleDirectives,17,22)
	local scaleDirective2 = string.sub(scaleDirectives,31,36)
	local scaleDirective3 = string.sub(scaleDirectives,45,50)
	local items = {
		scaleDirective1, scaleDirective2, scaleDirective3, 
		"FFFFF4", "F4F1E1", "C9C2B1"
	}
	
	for _,color_old in ipairs(items) do
		snakeDirectives = snakeDirectives..";"..color_old.."=00000000"
	end
	self.snakeDirectives = snakeDirectives
	
	tech.setToolUsageSuppressed(false)
	tech.setParentHidden(false)
	setMovementOverride(true)
end
function Infiltrator:uninit(params)
	setHeadType()

	tech.setParentDirectives()
	tech.setToolUsageSuppressed(true)
	tech.setParentHidden(true)
	params.directives = ""
	setMovementOverride(false)
end
function Infiltrator:update(dt, dir, shiftHeld, params)
	tech.setParentDirectives(self.snakeDirectives)
	params.directives = "?multiply=FFFFFF00"
end
