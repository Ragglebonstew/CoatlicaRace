require "/scripts/util.lua"
require "/scripts/interp.lua"

local abilityTablePath = "/tech/coatlica/head/abilities/coatlicaabilities.config"
local abilityTypes = nil

function init()
  self.techList = "techScrollArea.techList"

  self.selectorHeights = config.getParameter("selectorHeights")
  self.selectorTime = config.getParameter("selectorTime")
  self.techLockedIcon = config.getParameter("techLockedIcon")
  self.slotLabelText = config.getParameter("slotLabelText")
  self.suitImagePath = config.getParameter("suitImagePath")
  self.suitSelectedPath = config.getParameter("suitSelectedPath")
  self.selectionPulse = config.getParameter("selectionPulse")
  
	self.suitImagePath = self.suitImagePath..getBodyDirectives()..getHairDirectives()

	widget.setImage("imgSuit", self.suitImagePath)

	abilityTypes = root.assetJson(abilityTablePath)
	self.techs = {}
	for abilityName, abilitySource in pairs(abilityTypes) do
		self.techs[abilityName] = root.assetJson(abilitySource).ability
	end
	
	for _,abilityName in ipairs(getEnabledAbilities()) do
		if not abilityTypes[abilityName] then
			player.setProperty("coatlica_enabledAbilities."..abilityName, nil)
		end
	end

	self.animationTimer = 0

	setSelectedSlot("Primary")
	updateEquippedIcons()
end

function update(dt)
  if self.tweenSelector then self.tweenSelector(dt) end

  animateSelection(dt)

  if self.selectedTech then
    local currentChips = player.hasCountOfItem("techcard")
    if not player.getProperty("coatlica_enabledAbilities."..self.selectedTech) then
      local cost = techCost(self.selectedTech)
      widget.setText("lblChipsCount", string.format("%s / %s", currentChips, cost))
      widget.setButtonEnabled("btnEnable", currentChips >= cost)
    else
      widget.setText("lblChipsCount", string.format("%s / --", currentChips))
    end
  else
      widget.setButtonEnabled("btnEnable", false)
  end
end

function techCost(techName)
	if player.isAdmin() then
		return 0
	else
		return self.techs[techName].chipCost or config.getParameter("defaultCost")
	end
end

function populateTechList(slot)
  widget.clearListItems(self.techList)

  -- Show enabled techs at the top of the list
	local techs = getEnabledAbilities()
	local disabled = util.filter(util.keys(self.techs), function(a) return not contains(techs, a) end)
	util.appendLists(techs, disabled)
	for _,techName in pairs(techs) do
		local config = self.techs[techName]
		
		--Why I can't do (slot == "Passive") == self.techs[techName].isPassive... only god knows ToT
		if (slot ~= "Passive") == not self.techs[techName].isPassive then
			local listItem = widget.addListItem(self.techList)
			widget.setText(string.format("%s.%s.techName", self.techList, listItem), config.shortDescription)
			widget.setData(string.format("%s.%s", self.techList, listItem), techName)
	
			if player.getProperty("coatlica_enabledAbilities."..techName) then
				widget.setImage(string.format("%s.%s.techIcon", self.techList, listItem), config.icon)
			else
				widget.setImage(string.format("%s.%s.techIcon", self.techList, listItem), self.techLockedIcon)
			end
	
			if status.statusProperty("coatlica_"..slot.."Ability") == techName then
				widget.setListSelected(self.techList, listItem)
			end
		end
	end
end

function setSelectedSlot(slot)
  self.selectedSlot = slot
  widget.setText("lblDescription", config.getParameter("selectTechDescription"))
  widget.setText("lblSlot", self.slotLabelText[slot])
  populateTechList(slot)

  self.tweenSelector = coroutine.wrap(function(dt)
    local position = widget.getPosition("imgSlotSelect")
    local timer = 0
    while timer < self.selectorTime do
      timer = math.min(timer + dt, self.selectorTime)
      local ratio = timer / self.selectorTime
      widget.setPosition("imgSlotSelect", {position[1], interp.sin(ratio, position[2], self.selectorHeights[slot])})
      coroutine.yield()
    end
    self.tweenSelector = nil
  end)

  self.selectionImage = string.format(self.suitSelectedPath, status.statusProperty("coatlica_PassiveAbility","default"))
  self.animationTimer = 0

  widget.setVisible("imgSelectedPrimary", slot == "Primary")
  widget.setVisible("imgSelectedSecondary", slot == "Secondary")
  widget.setVisible("imgSelectedPassive", slot == "Passive")
end

function animateSelection(dt)
  self.animationTimer = self.animationTimer + dt
  while self.animationTimer > self.selectionPulse do
    self.animationTimer = self.animationTimer - self.selectionPulse
  end

  local ratio = (self.animationTimer / self.selectionPulse) * 2
  local opacity = interp.sin(ratio, 0, 1)
  local highlightDirectives = string.format("?multiply=FFFFFF%2x", math.floor(opacity * 255))
  widget.setImage("imgSelected", self.selectionImage..getBodyDirectives())
end

function enableTech(techName)
  local cost = techCost(techName)
  if player.consumeItem({name = "techcard", count = cost}) then
    --enable ability
	if not contains(getEnabledAbilities(), techName) then
		player.setProperty("coatlica_enabledAbilities."..techName, true)
	end
	--update tech and tech list
    equipTech(techName)
    populateTechList(self.selectedSlot)
  end
end

function updateEquippedIcons()
  for _,slot in pairs({"Primary", "Secondary", "Passive"}) do
    local tech = status.statusProperty("coatlica_"..slot.."Ability", {})
    if tech and self.techs[tech] then
      widget.setImage(string.format("techIcon%s", slot), self.techs[tech].icon)
    else
      widget.setImage(string.format("techIcon%s", slot), "")
    end
  end
end

function equipTech(techName)
	status.setStatusProperty("coatlica_"..self.selectedSlot.."Ability", techName)
	player.makeTechAvailable("coatlica_tech_head")
	updateEquippedIcons()
end

function setSelectedTech(techName)
  widget.setText("lblDescription", self.techs[techName].description)
  self.selectedTech = techName

  if player.getProperty("coatlica_enabledAbilities."..techName) then
    widget.setButtonEnabled("btnEnable", false)
    equipTech(techName)
  else
    local affordable = player.hasCountOfItem("techcard") >= techCost(techName)
    widget.setButtonEnabled("btnEnable", affordable)
  end
end

function getEnabledAbilities()
	local enabledAbilities = {}
	for abilityName, _ in pairs(abilityTypes) do
		if player.getProperty("coatlica_enabledAbilities."..abilityName) then
			table.insert(enabledAbilities, abilityName)
		end
	end
	return enabledAbilities
end
function getBodyDirectives()
	local bodyDirectives = ""
	for _,v in ipairs(world.entityPortrait(player.id(), "fullnude")) do
		if string.find(v.image, "body.png") then
			bodyDirectives = string.sub(v.image,(string.find(v.image, "?")))
			break
		end
	end
	return bodyDirectives
end
function getHairDirectives()
	local directives = ""
	for _,v in ipairs(world.entityPortrait(player.id(), "fullnude")) do
		if string.find(v.image, "hair") then
			local stringStart = string.find(v.image, "?")
			local stringEnd   = string.find(v.image, "?addmask")
			directives = string.sub(v.image, stringStart, stringEnd)
			break
		end
	end
	return directives
end

-- callbacks
function techSelected()
  local listItem = widget.getListSelected(self.techList)
  if listItem then
    local techName = widget.getData(string.format("%s.%s", self.techList, listItem))
    setSelectedTech(techName)
  end
end

function techSlotGroup(button, slot)
  setSelectedSlot(slot)
end

function doEnable()
  if self.selectedSlot then --and not player.getProperty("coatlica_enabledAbilities."..self.selectedTech) then
    enableTech(self.selectedTech)
  end
end