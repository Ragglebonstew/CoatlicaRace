Small = CoatlicaAbility:new()

function Small:init()
	--world.sendEntityMessage(entity.id(), "setGlobalTag", "/monsters/coatlicasegment/body_images/micro.png")
	self.isSet = false
end
function Small:uninit()
	world.sendEntityMessage(entity.id(), "setGlobalTag", "/monsters/coatlicasegment/body_images/default.png")
end
function Small:update(dt, dir, shiftHeld)
	--world.sendEntityMessage(entity.id(), "setCoil", 0.5)
	world.sendEntityMessage(entity.id(), "setGlobalTag", "/monsters/coatlicasegment/body_images/micro.png")
end
