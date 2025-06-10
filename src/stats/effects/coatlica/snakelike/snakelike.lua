require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"
require "/scripts/coatlica/util.lua"

function init()
	message.setHandler("setDisabled", simpleHandler(setDisabled))
	message.setHandler("setHold", simpleHandler(setHold))
	message.setHandler("replyHold", simpleHandler(replyHold))
	message.setHandler("setCoil", simpleHandler(setCoil))
	message.setHandler("setTransformed", simpleHandler(setTransformed))
	message.setHandler("setFly", simpleHandler(setFly))
	self.length = 1
	self.coilPer = 1
	self.transformed = false
	self.disabled = false
	self.movementParameters = effect.getParameter("movementParameters")
	--effect.setParentDirectives("?addmask=/humanoid/coatlica/tailmask.png")
	
	effect.addStatModifierGroup({
		{stat = "jumpModifier", amount = -1.0}
	})
end
function uninit()
	killBody()
end

function update(dt)
	if not self.transformed then
		mcontroller.controlParameters(self.movementParameters)
	end
	
	if self.disabled then
		killBody()
		return
	end
		
		--[[
		local pantsDirectory
		for _,v in ipairs(world.entityPortrait(entity.id(), "fullnude")) do
			sb.logInfo("stuff: "..v.image)
			--local pantsCheck = string.find(v.image, "pants.png")
			--if pantsCheck then
				--pantsDirectory = string.sub(v.image, 1, pantsCheck-1)
				--break
			--end
		end
		---[[
		if pantsDirectory then
			local size = root.imageSize(pantsDirectory.."coatlicamask.png")
			if size[1] ~= 64 then
				effect.setParentDirectives("?addmask="..pantsDirectory.."coatlicamask.png")
			else
				effect.setParentDirectives()
			end
		end
		]]--
	
	
	if not self.bodyId or not world.entityExists(self.bodyId) then
		spawnBody()
		return
	end
	--check for length change
	local newlength = math.floor(status.stat("maxHealth")/25)
	if newlength ~= self.length then
		self.length = newlength
		world.sendEntityMessage(self.bodyId, "updateLength", newlength)
		status.setStatusProperty("coatlica_length", newlength)
	end
	if self.isFlying then
		world.sendEntityMessage(self.bodyId, "updateFlying")
		mcontroller.controlParameters({gravityEnabled = false})
	end

	
	local pos = mcontroller.position()
	if not self.transformed then
		pos = vec2.add(pos, {0,-2.1875})
	end
	local inGround = world.pointCollision(pos, {"Block", "Dynamic", "Slippery", "Null", "Platform"})
	world.sendEntityMessage(self.bodyId, "updateCommon", pos, self.coilPer)
	
	if self.isHolding or inGround then
		mcontroller.controlParameters({gravityEnabled = false})
	end
end

function spawnBody()
	local params = { 
		playerId = entity.id(),
		ownerId = entity.id(),
		ownerHealth = status.resourcePercentage("health"),
		segmentsLeft = self.length,
		level = math.floor(status.stat("powerMultiplier")),
		directives = getBodyDirectives(),
		isFirst = true
	}
    self.bodyId = world.spawnMonster("coatlicasegment", mcontroller.position(), params)
	status.setStatusProperty("coatlica_bodyId", self.bodyId)
end
function killBody()
	if self.bodyId and world.entityExists(self.bodyId) then
		world.sendEntityMessage(self.bodyId, "die")
	end
	self.bodyId = nil
end
--util----------
function setDisabled(isDisabled)
	self.disabled = isDisabled
end
function setHold(isHolding)
	local segCheck = math.floor(self.length * 2/3)
	world.sendEntityMessage(self.bodyId, "requestHold", isHolding, segCheck)
end
function replyHold(isHolding)
	self.isHolding = isHolding
end
function setCoil(per)
	self.coilPer = per
end
function setTransformed(state)
	self.transformed = state
end
function setFly(isFlying)
	self.isFlying = isFlying
	if self.bodyId and not isFlying then
		world.sendEntityMessage(self.bodyId, "updateFlying", true)
	end
end