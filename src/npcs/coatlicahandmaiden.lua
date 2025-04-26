local satisfied = false
local headId
local length = 10
local tailId

local _interact = interact
function interact(args)
	if satisfied then 
		local bodyDirectives = getBodyDirectives(args.sourceId)
		local legsItem = {name = "coatlicawanabelegs", count=1}
		legsItem.parameters = {directives = bodyDirectives, price = 0, rarity = "essential"}
		world.spawnItem(legsItem, mcontroller.position())
	else 
		world.callScriptedEntity(status.statusProperty("coatlica_bodyId"), "swallow", args.sourceId)
		npc.setInteractive(false)
	end
	
	return _interact(args)
end

local _init = init
function init(...)
	_init(...)
	message.setHandler("tailId", function(_,_, id) tailId = id end)
	message.setHandler("regurgitate", simpleHandler(regurgitate))
end

local _update = update
function update(args)
	_update(args)
end

local _damage = damage
function damage(args)
	_damage(args)
	if tailId and world.entityExists(tailId) then
		world.sendEntityMessage(tailId, "regurgitate")
	end
end

function regurgitate(carryingId)
	world.sendEntityMessage(carryingId, "applyStatusEffect", "wet")
	satisfied = true 
	npc.setInteractive(true)
end
function getBodyDirectives(entityId)
	local bodyDirectives = ""
	for _,v in ipairs(world.entityPortrait(entityId, "fullnude")) do
		if string.find(v.image, "body.png") then
			bodyDirectives = string.sub(v.image,(string.find(v.image, "?")))
			break
		end
	end
	return bodyDirectives
end