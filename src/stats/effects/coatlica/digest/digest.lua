local bodyId
local immune = false

function init()
	bodyId = effect.sourceEntity()
	effect.setParentDirectives("?multiply=ffffff00")
	local immuneSpecies = config.getParameter("immuneSpecies")
	for k = 1, #immuneSpecies do
		if world.entitySpecies(entity.id()) == immuneSpecies[k] then 
			immune = true
			break
		end
	end
	effect.addStatModifierGroup({
		{stat = "arrested", amount = 1},
		{stat = "invulnerable", amount = 1},
		{stat = "healingStatusImmunity", amount = 1},
		{stat = "fireStatusImmunity", amount = 1},
		{stat = "iceStatusImmunity", amount = 1},
		{stat = "electricStatusImmunity", amount = 1},
		{stat = "poisonStatusImmunity", amount = 1},
		{stat = "specialStatusImmunity", amount = 1},
		{stat = "powerMultiplier", effectiveMultiplier = 0},
		{stat = "energyRegenPercentageRate", effectiveMultiplier = 0},
		{stat = "healthRegen", effectiveMultiplier = 0}
	})
end

function update(dt)
	if bodyId and world.entityExists(bodyId) then
		mcontroller.setPosition(world.entityPosition(bodyId))
	else
		effect.expire()
	end
	if not immune then
		status.modifyResource("health", -0.1)
	end
end