Default = CoatlicaAbility:new()

function Default:init()
	setHeadType("flyer")
end
function Default:uninit()
	setHeadType()
end

function Default:update(dt, dir, shiftHeld)end