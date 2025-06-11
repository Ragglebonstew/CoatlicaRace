require "/scripts/vec2.lua"

function distanceToGround(maxSearch)
	local startPoint = mcontroller.position()
	local endPoint = vec2.add(startPoint, {0, -maxSearch})

	local intPoint = world.lineCollision(startPoint, endPoint, {"Block", "Platform", "Dynamic", "Slippery", "Null"})

	if intPoint then
		return startPoint[2] - intPoint[2]
	else
		return maxSearch
	end
end
function positionOffset()
  return minY(self.movementParameters.collisionPoly) - minY(self.basePoly)
end
function minY(poly)
  local lowest = 0
  for _,point in pairs(poly) do
    if point[2] < lowest then
      lowest = point[2]
    end
  end
  return lowest
end
function contains(set, element)
	for k = 1, #set do
		if set[k] == element then
			return true
        end
    end
	return false
end
function getBodyDirectives()
	local bodyDirectives = ""
	for _,v in ipairs(world.entityPortrait(entity.id(), "fullnude")) do
		if string.find(v.image, "body.png") then
			bodyDirectives = string.sub(v.image,(string.find(v.image, "?")))
			break
		end
	end
	return bodyDirectives
end
function getHairDirectives()
	local headDirectives = ""
	for _,v in ipairs(world.entityPortrait(entity.id(), "fullnude")) do
		if string.find(v.image, "hair") then
			headDirectives = string.sub(v.image,(string.find(v.image, "?")))
			break
		end
	end
	return headDirectives
end