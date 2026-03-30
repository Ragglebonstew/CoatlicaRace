Shadow = CoatlicaAbility:new()

function Shadow:init()
	self.progress = 0
end
function Shadow:uninit()
	setDirectives()
	self.active = false
	status.clearPersistentEffects("coatlica_shadow_ability")
end
function Shadow:update(dt, dir, shiftHeld)
	if self.active then
		self.progress = math.min(self.progress+dt*50,100)
		--energy
		status.overConsumeResource("energy", self.energyCost*dt)
	else
		self.progress = math.max(self.progress-dt*50,0)
	end
	local brightnessDirective = "?brightness=-"..math.floor(self.progress*0.8)
	local transparntDirective = "?multiply=FFFFFF"..string.format("%X", math.floor((1-self.progress/100*0.8)*255))
	setDirectives(brightnessDirective..transparntDirective)

end
function Shadow:fire()
	self.active = true
	status.setPersistentEffects("coatlica_shadow_ability", {{stat = "invulnerable", amount = 1}})
end
function Shadow:hold(dt) end
function Shadow:release(headId)
	self.active = false
	status.clearPersistentEffects("coatlica_shadow_ability")
end
