Digger = CoatlicaAbility:new()

function Digger:init()
	setHeadType("digger")
end
function Digger:uninit()
	setHeadType()
end

function Digger:update(dt, dir, shiftHeld) end