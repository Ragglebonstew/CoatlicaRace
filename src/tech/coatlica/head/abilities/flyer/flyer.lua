Flyer = CoatlicaAbility:new()

function Flyer:init()
	setHeadType("flyer")
end
function Flyer:uninit()
	setHeadType()
end

function Flyer:update(dt, dir, shiftHeld)end