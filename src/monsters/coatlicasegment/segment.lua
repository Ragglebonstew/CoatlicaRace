require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/messageutil.lua"
require "/scripts/coatlica/util.lua"

function init()
	self.playerId = config.getParameter("playerId")
	self.ownerId = config.getParameter("ownerId")
    self.segmentsLeft = config.getParameter("segmentsLeft", 0)
	self.directives = config.getParameter("directives")
	self.isFirst = config.getParameter("isFirst")
	
	self.segmentSize = config.getParameter("segmentSize", 2)
	self.btype = self.segmentsLeft == 0 and "tail" or "body"
	self.passTimer = 0
	self.animTimer = 0

    --status.setPersistentEffects("invulerability", {{stat="invulnerable",amount=1}})
	status.setPrimaryDirectives(self.directives)
	monster.setInteractive(false)
	monster.setDamageBar("none")
	if self.btype == "tail" then animator.setAnimationState("body", "tail") end
	if self.isFirst then animator.setAnimationState("end", "on") end
	
	message.setHandler("updateCommon", simpleHandler(updateCommon))
	message.setHandler("updateLength", simpleHandler(updateLength))
	message.setHandler("die", simpleHandler(die))
	message.setHandler("swallow", simpleHandler(swallow))
	message.setHandler("regurgitate", simpleHandler(regurgitate))
	message.setHandler("requestHold", simpleHandler(requestHold))
	message.setHandler("replyHold", simpleHandler(replyHold))
	message.setHandler("updateFlying", simpleHandler(updateFlying))
end
function update(dt)
	if self.passTimer > 0 then self.passTimer = self.passTimer - dt
	elseif carryingId then passEntity() end
	
	if carryingId and world.entityExists(carryingId) then
		world.sendEntityMessage(carryingId, "applyStatusEffect", "coatlicaDigest", 1, entity.id())
	end
	
	--In ground handling 
	if self.inGround or (self.isHolding and not (self.isPivot and (self.isPivot.num <= 1))) or self.isFlying then
		mcontroller.controlParameters({
			collisionEnabled = not self.inGround, 
			gravityEnabled = false
		})
		mcontroller.setVelocity({0,0})
	end
	
	if self.isPivot and self.isPivot.hold then
		if not self.inGround and not mcontroller.isColliding() then
			world.sendEntityMessage(self.childId, "requestHold", true, self.isPivot.num-1)
			self.isPivot = nil
		end
	end
end

function followOwner(ownerPos, coilPer)
	animator.resetTransformationGroup("body")
	
	local segmentLength = self.segmentSize * coilPer
	local dirV = vec2.norm(world.distance(ownerPos, mcontroller.position()))
	local target = vec2.sub(ownerPos, vec2.mul(dirV, segmentLength))
	
	local animV = {math.abs(dirV[1]), dirV[2]}
	animator.setFlipped(dirV[1] < 0)
	animator.rotateTransformationGroup("body", vec2.angle(animV))
	
	if world.magnitude(ownerPos, mcontroller.position()) > segmentLength then
		mcontroller.setPosition(target)
		animator.translateTransformationGroup("body", vec2.mul(animV, segmentLength/2))
	else
		local midpt = vec2.mul(animV, world.magnitude(ownerPos, mcontroller.position())/2)
		animator.translateTransformationGroup("body", midpt)
	end
	
	self.inGround = world.lineCollision(mcontroller.position(), ownerPos, {"Block", "Dynamic", "Slippery", "Null", "Platform"})
	
	world.debugPoint(mcontroller.position(), (inGround) and "white" or "blue")
	if self.isHolding then
		world.debugPoint(vec2.add(mcontroller.position(),{0,1}), "red")
	end
	
	if self.btype == "body" then
		if world.magnitude(self.lastPos or mcontroller.position(), mcontroller.position()) > 0.02 then
			animator.setAnimationRate(0.3)
		else
			animator.setAnimationRate(0)
		end
		if mcontroller.onGround() then
			animator.setAnimationState("body", "walk")
		else
			animator.setAnimationState("body", "idle")
		end
		self.lastPos = mcontroller.position()
	end
	
	
end
function spawnSegment()
    local params = {
		playerId = self.playerId,
		ownerId = entity.id(),
		segmentsLeft = self.segmentsLeft - 1,
		directives = self.directives,
		level = monster.level(),
		isFirst = false
	}
    self.childId = world.spawnMonster("coatlicasegment", mcontroller.position(), params)
end
function updateCommon(ownerPos, coilPer)
	if not (self.ownerId and world.entityExists(self.ownerId)) then
		die()
		return
	end
	
	followOwner(ownerPos, coilPer)
	
	if self.childId and world.entityExists(self.childId) then
		world.callScriptedEntity(self.childId, "updateCommon", mcontroller.position(), coilPer)
	elseif self.segmentsLeft > 0 then -- segmentsLeft of 0 refers to the tail, the last body segment
        spawnSegment()
	end
end
function updateLength(segments)
	if segments == self.segmentsLeft then return end
	self.segmentsLeft = segments
	if segments == 0 then
		self.btype = "tail"
		animator.setAnimationState("body", "tail")
		if self.childId and world.entityExists(self.childId) then
			world.callScriptedEntity(self.childId, "die")
			self.childId = nil
		end
	else
		self.btype = "body"
		if self.childId and world.entityExists(self.childId) then
			world.callScriptedEntity(self.childId, "updateLength", segments-1)
		else
			spawnSegment()
		end
		animator.setAnimationState("body", "idle")
	end
end
function die()
	status.setResource("health", 0)
	if self.childId and world.entityExists(self.childId) then
		world.callScriptedEntity(self.childId, "die")
	end
end

--consumer functions
--receive functions
function swallow(entityId)
	if self.btype == "tail" then
		regurgitate(entityId)
		return
	end
	if not entityId or not world.entityExists(entityId) then return end
	self.passTimer = 2
	if carryingId and world.entityExists(carryingId) then
		world.sendEntityMessage(self.childId, "swallow", carryingId)
	end
	carryingId = entityId
	isSwallowing = true
	animator.setAnimationState("bulge", "on")
end
function regurgitate(entityId)
	if self.btype == "tail" then
		world.sendEntityMessage(self.ownerId, "regurgitate", entityId)
		return
	end
	self.passTimer = 0.5
	if carryingId and world.entityExists(carryingId) then
		world.sendEntityMessage(self.ownerId, "regurgitate", carryingId)
	end
	carryingId = entityId
	isSwallowing = false
	if entityId and world.entityExists(entityId) then animator.setAnimationState("bulge", "on") end
end
--pass function
function passEntity()
	if isSwallowing then
		if carryingId and world.entityExists(carryingId) then
			world.sendEntityMessage(self.childId, "swallow", carryingId)
			carryingId = nil
		end
	else
		world.sendEntityMessage(self.ownerId, "regurgitate", carryingId)
		carryingId = nil
	end
	animator.setAnimationState("bulge", "off")
end

function requestHold(isHolding, num)
	if num == 0 or self.btype == "tail" then
		world.sendEntityMessage(self.ownerId, "replyHold", false)
		return
	end
	if isHolding then
		if self.inGround or mcontroller.isColliding() then
			self.isHolding = true
			self.isPivot = {hold = true, num = num}
			world.sendEntityMessage(self.ownerId, "replyHold", isHolding)
		else
			world.sendEntityMessage(self.childId, "requestHold", isHolding, num-1)
		end
	else
		self.isHolding = false
		self.isPivot = {hold = false, num = num}
		world.sendEntityMessage(self.childId, "requestHold", isHolding, -1)
	end
end
function replyHold(isHolding)
	self.isHolding = isHolding
	world.sendEntityMessage(self.ownerId, "replyHold", isHolding)
end
function updateFlying(drop)
	if drop then
		self.isFlying = false
	else
		local maxHeight = 5
		local distance = distanceToGround(maxHeight)
		self.isFlying = distance == maxHeight
	end
	if self.btype ~= "tail" and self.childId then
		world.sendEntityMessage(self.childId, "updateFlying", drop)
	end
end