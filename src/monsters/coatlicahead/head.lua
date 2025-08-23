require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/status.lua"
require "/scripts/messageutil.lua"
require "/scripts/actions/movement.lua"
require "/scripts/actions/animator.lua"

local carryingId
local isSwallowing

function init()
	self.playerId = config.getParameter("playerId")
	self.directives = config.getParameter("directives")
	self.updateTimer = 0
	
	status.setPrimaryDirectives(self.directives)
	monster.setInteractive(false)
	monster.setDamageBar("none")
	monster.setDamageTeam(world.entityDamageTeam(self.playerId))
	monster.setDamageParts({"body"})
	monster.setDamageOnTouch(false)
	message.setHandler("updateAnim", simpleHandler(updateAnim))
	message.setHandler("die", simpleHandler(die))
	message.setHandler("setHeadType", simpleHandler(setHeadType))
	message.setHandler("setDamageOnTouch", simpleHandler(monster.setDamageOnTouch))
end
function update(dt)
	self.updateTimer = self.updateTimer - dt
	if self.updateTimer <= 0 then
		self.updateTimer = 5
		updateStatus()
	end
end
function updateAnim(pos, headRot, jawRot)
	mcontroller.setPosition(pos)
	
	local rotVec = {math.abs(headRot[1]), headRot[2]}
	angle = vec2.angle(rotVec)
	mcontroller.setRotation(vec2.angle(headRot))
	animator.resetTransformationGroup("head")
	animator.resetTransformationGroup("jaw")
	animator.rotateTransformationGroup("head", angle)
	if jawRot == 0 then
		animator.setAnimationState("head", "idle")
		animator.setAnimationState("jaw", "invisible")
		monster.setDamageOnTouch(false)
	else
		animator.setAnimationState("head", "mouthopen")
		animator.setAnimationState("jaw", "visible")
		local offset = vec2.rotate({-0.125, 0.125}, angle)
		world.debugPoint(vec2.add(pos, offset), "red")
		animator.rotateTransformationGroup("jaw", jawRot, offset)
	end
	animator.setFlipped(headRot[1] < 0)
end
--util----------
function updateStatus()
	if not self.playerId or not world.entityExists(self.playerId) then
		die()
	end
end
function die()
	status.setResource("health", 0)
end
function setHeadType(headType)
	local headImage = "/monsters/coatlicahead/head_images/"..(headType or "default.png")
	animator.setGlobalTag("headImage", headImage)
end