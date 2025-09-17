HeadType = CoatlicaAbility:new()

function HeadType:init()
	setHeadType(self.type)
end
function HeadType:uninit()
	setHeadType()
end

function HeadType:update(dt, dir, shiftHeld)end