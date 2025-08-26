require "/scripts/vec2.lua"

function applyDamageRequest(damageRequest)
	return {}
	if world.getProperty("nonCombat") then
		return {}
	end
	if world.getProperty("invinciblePlayers") then
		return {}
	end
	local playerId = status.statusProperty("playerId")
	
	if damageRequest.damageType == "Knockback" then
		return {}
	end
  
	if playerId then
		world.sendEntityMessage(playerId, "takeDamage", damageRequest)
	end

	local damage = 0
	if damageRequest.damageType == "Damage" then
		damage = damage + root.evalFunction2("protection", damageRequest.damage, status.stat("protection"))
	elseif damageRequest.damageType == "IgnoresDef" then
		damage = damage + damageRequest.damage
	elseif damageRequest.damageType == "Status" then
		-- only apply status effects
		status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)
		return {}
	elseif damageRequest.damageType == "Environment" then
		return {}
	end
	
	if status.resourcePositive("shieldHealth") then
		local shieldAbsorb = math.min(damage, status.resource("shieldHealth"))
		status.modifyResource("shieldHealth", -shieldAbsorb)
		damage = damage - shieldAbsorb
	end
	
	local hitType = damageRequest.hitType
	local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
	local resistance = status.stat(elementalStat)
	damage = damage - (resistance * damage)
	if resistance ~= 0 and damage > 0 then
		hitType = resistance > 0 and "weakhit" or "stronghit"
	end
	
	status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)
	
	local knockbackFactor = (1 - status.stat("grit"))
	local momentum = knockbackMomentum(vec2.mul(damageRequest.knockbackMomentum, knockbackFactor))
	if status.resourcePositive("health") and vec2.mag(momentum) > 0 then
		if vec2.mag(momentum) > status.stat("knockbackThreshold") then
			status.setResource("stunned", math.max(status.resource("stunned"), status.stat("knockbackStunTime")))
		end
	end
	return {}
end

function knockbackMomentum(momentum)
  local knockback = vec2.mag(momentum)
  if mcontroller.baseParameters().gravityEnabled and math.abs(momentum[1]) > 0  then
    local dir = momentum[1] > 0 and 1 or -1
    return {dir * knockback / 1.41, knockback / 1.41}
  else
    return momentum
  end
end

function update(dt)
	if mcontroller.atWorldLimit(true) then
		status.setResourcePercentage("health", 0)
	end
end
