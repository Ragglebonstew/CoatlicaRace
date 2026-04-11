Small = CoatlicaAbility:new()

function Small:init()
	self.isSet = false
	setHeadType(self.type)
end
function Small:uninit(params)
	setHeadType()
	--world.sendEntityMessage(entity.id(), "setGlobalTag", "/monsters/coatlicasegment/body_images/default.png")
	--world.sendEntityMessage(entity.id(), "setCoil", 1.0)

	params.body_image = "/monsters/coatlicasegment/body_images/default.png"
	params.coilPer = 1.0
end
function Small:update(dt, dir, shiftHeld, params)
	--world.sendEntityMessage(entity.id(), "setGlobalTag", "/monsters/coatlicasegment/body_images/micro.png")
	--world.sendEntityMessage(entity.id(), "setCoil", 0.7)

	params.body_image = "/monsters/coatlicasegment/body_images/micro.png"
	params.movementParameters = self.segmentPoly
	params.coilPer = 0.7


	mcontroller.controlParameters(self.movementParameters)
end
