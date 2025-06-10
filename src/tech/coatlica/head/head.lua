require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"
require "/scripts/versioningutils.lua"
require "/scripts/coatlica/util.lua"

local abilityTablePath = "/tech/coatlica/head/abilities/coatlicaabilities.config"
local abilityTypes = nil
local transformed = false
local regTimer = 0

function init()
	
	--build(directory, config, parameters, level, seed)
	
	self.headType = config.getParameter("headtype", "coatlicahead_base")

	self.stomach = {}
	self.movementParameters = config.getParameter("movementParameters")
	self.energyCost = config.getParameter("energyCost", 50)
	self.jerkMul = config.getParameter("jerkMul", 0.005)
	message.setHandler("regurgitate", simpleHandler(regurgitate))
	
	self.mouthPer = 0
	self.updateTimer = 0
	
	message.setHandler("replyHold", simpleHandler(replyHold))
	
	message.setHandler("addAbility", simpleHandler(addAbility))
end

function uninit()
	self.stomach = {}
	if transformed then deactivate() end
end
function update(args)
	self.updateTimer = self.updateTimer - script.updateDt()
	if self.updateTimer <= 0 then
		self.updateTimer = 5
		updateStatus()
	end
	
	--toggles the transformation state
	if args.moves["special1"] ~= self.specialLast then
		self.specialLast = args.moves["special1"]
		if args.moves["special1"] then
			if not transformed then
				activate()
			else
				deactivate()
			end
		end
	end
	
	if transformed then run(args) end
end
function activate()
	mcontroller.setVelocity(vec2.mul(world.distance(tech.aimPosition(), mcontroller.position()), 3))
	world.spawnProjectile("clustermineexplosion", mcontroller.position())
	tech.setParentHidden(true)
	tech.setToolUsageSuppressed(true)
	status.setPersistentEffects("coatlica_consumerstats", {
		{stat = "maxHealth", effectiveMultiplier = 3.0},
		{stat = "activeMovementAbilities", amount = 1}
	})
	spawnHead()
	transformed = true
	world.sendEntityMessage(entity.id(), "setTransformed", true)
	
	abilityInit()
end
function deactivate()
	mcontroller.setRotation(0)
	world.spawnProjectile("clustermineexplosion", mcontroller.position())
	tech.setParentHidden(false)
	tech.setToolUsageSuppressed(false)
	status.clearPersistentEffects("coatlica_consumerstats")
	killHead()
	transformed = false
	world.sendEntityMessage(entity.id(), "setTransformed", false)
	
	if self.isHolding then
		world.sendEntityMessage(entity.id(), "setHold", false)
	end
	
	abilityUninit()
end
function spawnHead()
	local params = {directives = getBodyDirectives()..getHairDirectives(), playerId = entity.id()}
	self.headId = world.spawnMonster(self.headType, mcontroller.position(), params)
end
function killHead()
	if self.headId and world.entityExists(self.headId) then
		world.callScriptedEntity(self.headId, "die")
	end
	self.headId = nil
end

function run(args)
	tech.setVisible(true)
	
	mcontroller.controlParameters(self.movementParameters)
	
	
	movementUpdate(args)
	abilityUpdate(args)
	headUpdate()
end
function abilityInit()
	local abilityConfig, parameters = build(directory, root.assetJson("/tech/coatlica/head/head.tech"), {}, level, seed)
	
	self.primaryAbility = getAbility("Primary", abilityConfig.PrimaryAbility)
	self.secondaryAbility = getAbility("Secondary", abilityConfig.SecondaryAbility)
	
	if self.primaryAbility then
		self.primaryAbility:init()
	end
	if self.secondaryAbility then
		self.secondaryAbility:init()
	end
end
function abilityUninit()
	if self.primaryAbility then
		self.primaryAbility:uninit()
	end
	if self.secondaryAbility then
		self.secondaryAbility:uninit()
	end
end
function abilityUpdate(args)

	local x = args.moves["right"] and 1 or args.moves["left"] and -1 or 0
	local y = args.moves["up"] and 1 or args.moves["down"] and -1 or 0
	local dir = vec2.norm({x, y})

	if self.primaryAbility then
		self.primaryAbility:update(script.updateDt(), dir, not args.moves["run"])
	end
	if self.secondaryAbility then
		self.secondaryAbility:update(script.updateDt(), dir, not args.moves["run"])
	end
	
	--for _,ability in pairs(self.passiveAbilities) do
		--ability:update(args.moves)
	--end
	
	updateAbilityFire(args, "primaryFire", self.primaryAbility)
	updateAbilityFire(args, "altFire", self.secondaryAbility)
	
end

local fire_last = {}
function updateAbilityFire(args, fireType, ability)
	if not ability then return end
	
	if args.moves[fireType] then
		if not fire_last[fireType] then
			ability:fire()
		end
		ability:hold(script.updateDt())
		if ability.holdParameters then
			for entry, param in pairs(ability.holdParameters) do
				self[entry] = param
			end
		end
	else
		if fire_last[fireType] then
			ability:release()
			if ability.releaseParameters then
				for entry, param in pairs(ability.releaseParameters) do
					self[entry] = param
				end
			end
		end
	end
	fire_last[fireType] = args.moves[fireType]
end
function headUpdate()
	--head rotation
	local pos = mcontroller.position()
	local headRot
	local jawRot
	
	if self.jawOpen or vec2.mag(mcontroller.velocity()) < 2.0 or self.headLocked then
		headRot = world.distance(tech.aimPosition(), mcontroller.position())
	else
		headRot = vec2.add(mcontroller.velocity(),{0,2})
	end
	world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(), headRot), "blue")
	
	--jaw rotation
	if regTimer > 0 then regTimer = regTimer - 1 end
	if self.mouthPer < 1 and (self.jawOpen or regTimer > 0) then
		self.mouthPer = self.mouthPer + 0.2
	elseif self.mouthPer > 0 and not (self.jawOpen or regTimer > 0) then
		if self.mouthPer > 1 then
			self.mouthPer = self.mouthPer + vec2.dot(mcontroller.velocity(), vec2.norm(headRot)) * self.jerkMul
		end
		self.mouthPer = self.mouthPer - 0.4
		if self.mouthPer > 2 then self.mouthPer = 2 end
		bite()
	end
	
	if self.mouthPer <= 0 then jawRot = 0
	else jawRot = -math.pi/5 * self.mouthPer end
	if self.headId and world.entityExists(self.headId) then
		world.sendEntityMessage(self.headId, "updateAnim", pos, headRot, jawRot)
	end
	
	self.jawOpen = false
end

-- ABILITY CLASS  -------------------------------------------------------------------------

CoatlicaAbility = {}

function CoatlicaAbility:new(abilityConfig)
  local newAbility = abilityConfig or {}
  newAbility.stances = newAbility.stances or {}
  setmetatable(newAbility, extend(self))
  return newAbility
end

function CoatlicaAbility:init() end
function CoatlicaAbility:uninit() end
function CoatlicaAbility:update(dt, dir, shiftHeld) end
function CoatlicaAbility:fire() end
function CoatlicaAbility:hold(dt) end
function CoatlicaAbility:release() end

-- ABILITY CREATION  -------------------------------------------------------------------------

function getAbility(abilitySlot, abilityConfig)
	if not abilityConfig then return end
	
	for _, script in ipairs(abilityConfig.scripts) do
		require(script)
	end
	local class = _ENV[abilityConfig.class]
	return class:new(abilityConfig)
end
function build(directory, config, parameters, level, seed)
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  -- select, load and merge abilities
  setupAbility(config, parameters, "Primary")
  setupAbility(config, parameters, "Secondary")

  -- elemental type
  local elementalType = parameters.elementalType or config.elementalType or "physical"
  replacePatternInData(config, nil, "<elementalType>", elementalType)

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  config.tooltipFields = {}
  if elementalType ~= "physical" then
    config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
  end

  -- set price
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end


-- ABILITY UTIL -------------------------------------------------------------------------

function getAbilitySourceFromType(abilityType)
  if not abilityType then return nil end
  if not abilityTypes then
	abilityTypes = root.assetJson(abilityTablePath)
  end
  return abilityTypes[abilityType]
end

-- abilitySlot is either "Primary" or "Secondary"
function getAbilitySource(config, parameters, abilitySlot)
	local typeKey = "coatlica_"..abilitySlot.."Ability"
	local abilityType = player.getProperty(typeKey)

	return getAbilitySourceFromType(abilityType)
end

-- Determines ability from config/parameters and then adds it.
-- abilitySlot is either "alt" or "primary"
-- If builderConfig is given, it will randomly choose an ability from
-- builderConfig if the ability is not specified in the config/parameters.
function setupAbility(config, parameters, abilitySlot, builderConfig, seed)
  seed = seed or parameters.seed or config.seed or 0

  local abilitySource = getAbilitySource(config, parameters, abilitySlot)
  if not abilitySource and builderConfig then
    local abilitiesKey = abilitySlot .. "Abilities"
    if builderConfig[abilitiesKey] and #builderConfig[abilitiesKey] > 0 then
      local abilityType = randomFromList(builderConfig[abilitiesKey], seed, abilitySlot .. "AbilityType")
      abilitySource = getAbilitySourceFromType(abilityType)
    end
  end

  if abilitySource then
    addAbility(config, parameters, abilitySlot, abilitySource)
  end
end

-- Adds the new ability to the config (modifying it)
-- abilitySlot is either "Primary" or "Secondary"
function addAbility(config, parameters, abilitySlot, abilitySource)
  if abilitySource then
    local abilityConfig = root.assetJson(abilitySource)

    -- Rename "ability" key to primaryAbility or altAbility
    local abilityType = abilityConfig.ability.type
    abilityConfig[abilitySlot .. "Ability"] = abilityConfig.ability
    abilityConfig.ability = nil

    -- Allow parameters in the activeitem's config to override the abilityConfig
    local newConfig = util.mergeTable(abilityConfig, config)
    util.mergeTable(config, newConfig)

    parameters[abilitySlot .. "AbilityType"] = abilityType
  end
end

function movementUpdate(args)
	drag()
	move(args.moves)
end

function regurgitate(carryingId)
	world.sendEntityMessage(carryingId, "applyStatusEffect", "wet")
	
	for k = 1, #self.stomach do
		if self.stomach[k] == carryingId then
			table.remove (self.stomach, k)
			break
		end
	end
	
	--local bodyDirectives = getBodyDirectives()
	--local legsItem = {name = "coatlicawanabelegs", count=1}
	--legsItem.parameters = {directives = bodyDirectives, price = 0, rarity = "essential"}
	--world.spawnItem(legsItem, mcontroller.position())
	regTimer = 10
end

--util----------
function updateStatus()
	self.bodyId = status.statusProperty("coatlica_bodyId")
end
function replyHold(isHolding)
	self.isHolding = isHolding
end

--abilities (temp till can be moved to own files)

function move(control)

	local maxHeight = 6
	local distance = distanceToGround(maxHeight)
	local gravity = world.gravity(mcontroller.position())
	--control
	local speed = 24
	local velX = control["right"] and 1 or control["left"] and -1 or 0
	local velY = control["up"] and 1 or control["down"] and -1 or 0
	local vel = vec2.mul(vec2.norm({velX,velY}),speed)
	
	if not control["run"] then
		mcontroller.controlApproachVelocity(vel, 95)
	elseif distance ~= maxHeight then
		--mcontroller.controlApproachVelocity({velX*speed, velY*speed + (1-distance/maxHeight)*3.8}, gravity*3)
		mcontroller.controlApproachXVelocity(velX*speed, 95)
		mcontroller.controlApproachYVelocity(velY*speed + (1-distance/maxHeight)*3.8, gravity ~= 0 and gravity*3 or 95)
	end
end
function lift(control)
	local gravity = world.gravity(mcontroller.position())
	if gravity and gravity ~= 0 then
		local maxHeight = 6
		local distance = distanceToGround(maxHeight)
		if maxHeight ~= distance then
			--mcontroller.controlApproachYVelocity(maxHeight-distance, gravity*3.8)
		end
		if maxHeight - distance < 0.25 then
			--mcontroller.controlParameters({gravityEnabled = false})
		end
	end
end
function drag()
	local dragMult = world.pointCollision(mcontroller.position(), {"Block", "Dynamic", "Slippery", "Null", "Platform"}) and 0.9 or 0.4
	--mcontroller.controlApproachVelocity({0,0}, vec2.mag(mcontroller.velocity())*dragMult)
end

function bite() end
--[[
function attemptConsume()
	local consumeTarget
	local mouthPos = vec2.add(mcontroller.position(), vec2.rotate({1, -0.125}, mcontroller.rotation()))
	world.debugPoint(mouthPos, "red")
	local nearbyNpcs = world.npcQuery(mouthPos, 1.5, {order = "nearest"})
	for i in ipairs(nearbyNpcs) do
		if not contains(self.stomach, nearbyNpcs[i]) and world.entityExists(nearbyNpcs[i])  then
			consumeTarget = nearbyNpcs[i]
			break
		end
	end
	if not consumeTarget then
		local nearbyMonsters = world.monsterQuery(mcontroller.position(), 1.5, {order = "nearest"})
		for i in ipairs(nearbyMonsters) do
			local entityType = world.monsterType(nearbyMonsters[i])
			local iscoatlica = entityType == "coatlicasegment" or entityType == "coatlicahead_base"
			if not iscoatlica and not contains(self.stomach, nearbyMonsters[i]) and world.entityExists(nearbyMonsters[i]) then
				consumeTarget = nearbyMonsters[i]
				break
			end
		end
	end
	if consumeTarget and world.entityExists(self.bodyId) then 
		table.insert(self.stomach, consumeTarget)
		world.sendEntityMessage(self.bodyId, "swallow", consumeTarget)
	end
end
]]--