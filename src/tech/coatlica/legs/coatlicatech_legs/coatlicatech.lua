require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"
require "/scripts/coatlica/util.lua"

function init()
	
	sb.logError("Deprecated Coalitca Leg Tech being used")

	self.coilPer = 1
	self.coiled = false
	self.coilSpeed = 0.02
	
	self.updateTimer = 0
	self.length = 0
	self.liftMul = 15
	
end
function uninit() end
function update(args)
	local dt = script.updateDt()
	self.updateTimer = self.updateTimer - dt
	if self.updateTimer <= 0 then
		self.updateTimer = 1
		updateStatus()
	end
	
	if not status.statPositive("activeMovementAbilities") then 
		coilAbility(args.moves["down"])
		liftAbility(args.moves, dt)
		holdAbility(not args.moves["run"])
	end
	
end

--abilities----------
local holdLast = false
function holdAbility(button)
	if button ~= holdLast then
		holdLast = button
		world.sendEntityMessage(entity.id(), "setHold", button)
	elseif button then
		world.sendEntityMessage(entity.id(), "setHold", button)
	end
end
function liftAbility(control, dt)
	local gravity = world.gravity(mcontroller.position())
	local maxHeight = self.length*3/2
	local distance = distanceToGround(maxHeight)
	
	local speed = 8
	local velX = control["right"] and 1 or control["left"] and -1 or 0
	local velY = control["up"] and 1 or control["down"] and -1 or 0
	--local vel = vec2.mul(vec2.norm({velX,velY}), speed)
	--mcontroller.controlApproachXVelocity(velX*speed, 95)
	if distance > 3.0 and distance < maxHeight then
		mcontroller.controlApproachVelocity({velX*speed*1.8,velY*speed*1.1}, gravity*3)
		tech.setParentState("Fly")
	else
		tech.setParentState()
	end
end
function coilAbility(button)
	local lastCoilPer = self.coilPer
	if tech.parentLounging() then
		--if self.coilPer > 0.5 then self.coilPer = self.coilPer - self.coilSpeed*5 end
	else
		if button and mcontroller.onGround() then
			if self.coilPer > 0.5 then self.coilPer = self.coilPer - self.coilSpeed
			else self.coiled = true end
		elseif self.coilPer < 1 then
			self.coilPer = self.coilPer + self.coilSpeed*5
			if self.coilPer > 1 then self.coilPer = 1 end
		end
		if self.coiled and not button then
			if mcontroller.onGround() then
				local targetV = vec2.mul(vec2.norm(world.distance(tech.aimPosition(), mcontroller.position())), 5*self.length)
				targetV[2] = targetV[2] + 10*self.length
				mcontroller.setVelocity(vec2.add(mcontroller.velocity(), targetV))
			end
			self.coiled = false
		end
	end
	--update master coil percent
	if lastCoilPer ~= self.coilPer then
		world.sendEntityMessage(entity.id(), "setCoil", self.coilPer)
	end
end
--util----------
function updateStatus()
	self.length = status.statusProperty("coatlica_length")
end