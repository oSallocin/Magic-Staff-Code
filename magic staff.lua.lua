local Debris = game:GetService("Debris") -- removes objects after time
local TweenService = game:GetService("TweenService") -- smooth transitions
local Staff = script.Parent -- tool
local attackEvent = Staff:WaitForChild("AttackEvent") -- remote event
local canAttack = true -- debounce
local debounceTime = 3 -- cooldown

local function addToDebris(instance: Instance, delayTime: number)
	Debris:AddItem(instance, delayTime) -- after delay, remove instance
end

local function setCountdown()
	task.delay(debounceTime, function() -- after delay, executes function
		canAttack = true -- can attack again
	end)
end

local function setFireEffect(part: BasePart, destroyAfter: boolean, timeToDestroy: number?)
	local fire = Instance.new("Fire") -- creates fire
	fire.Color = Color3.new(1, 0.333, 0) -- set color
	fire.Size = 10 -- set size
	fire.Parent = part -- set parent to part

	if destroyAfter then -- if destroyAfter is true then
		addToDebris(fire, timeToDestroy or 3) -- remove fire after 3 seconds
	end
end

local function setSmokeEffect(part: BasePart, destroyAfter: boolean, timeToDestroy: number?)
	local smoke = Instance.new("Smoke") -- creates smoke
	smoke.Color = Color3.new(1, 0.333, 0) -- set color
	smoke.Size = 20 -- set size
	smoke.Opacity = 0.5 -- set opacity
	smoke.Parent = part -- set parent to part

	if destroyAfter then -- if destroyAfter is true then
		addToDebris(smoke, timeToDestroy or 3) -- remove smoke after 3 seconds
	end
end

local function setLinearVelocity(part: BasePart, direction: Vector3, destroyAfter: boolean?, timeToDestroy: number?)
	local velocity = Instance.new("LinearVelocity") -- creates linear velocity
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World -- set velocity to world relative
	velocity.Attachment0 = Instance.new("Attachment", part) -- create attachment for linear velocity
	velocity.MaxForce = math.huge -- set max force to the maximum possible
	velocity.VectorVelocity = direction -- set direction of velocity
	velocity.Parent = part -- set parent to part

	if destroyAfter then -- if destroyAfter is true then
		addToDebris(velocity, timeToDestroy or 0.1) -- remove velocity after 0.1 seconds
	end
end

local function dealDamageOnce(enemyChar: Model, damage: number, hitList: {Model})
	if table.find(hitList, enemyChar) then return end -- if enemyChar is already in the list, return

	local humanoid = enemyChar:FindFirstChildOfClass("Humanoid") -- get humanoid
	if not humanoid then return end -- if humanoid doesn't exist, return

	table.insert(hitList, enemyChar) -- insert enemyChar in the list
	humanoid:TakeDamage(damage) -- deal damage to humanoid	
end

local function touchedProjectile(player: Player, projectile: BasePart, damage: number)
	local character = player.Character or player.CharacterAdded:Wait() -- get player character
	local hitList = {} -- list of hit characters
	local connection -- creates connection variable, so we can disconnect it after to prevent memory leak

	connection = projectile.Touched:Connect(function(hit) -- when projectile touches something, connect it a function
		if hit:IsDescendantOf(character) then return end -- if the object touched is a descendant of the player's character, return

		for _, part in ipairs(projectile:GetTouchingParts()) do -- loop through all the touching parts of the projectile
			local enemyChar = part.Parent -- get enemy character
			if enemyChar and enemyChar:FindFirstChild("Humanoid") and enemyChar.Name ~= player.Name then -- if enemyChar is not nil and has a humanoid and is not the player then
				dealDamageOnce(enemyChar, damage, hitList) -- deal damage to enemyChar
				projectile:Destroy() -- destroy projectile
				if connection then -- if connection exists then
					connection:Disconnect() -- disconnect connection
					connection = nil -- set connection to nil
				end
				return
			end
		end

		projectile:Destroy() -- destroy projectile
		if connection then -- if connection exists then
			connection:Disconnect() -- disconnect connection
			connection = nil -- set connection to nil
		end
	end)

	task.delay(3, function() -- after 3 seconds, executes function
		if projectile and projectile.Parent then -- if projectile exists then
			projectile:Destroy() -- destroy projectile
		end
		if connection then -- if connection exists then
			connection:Disconnect() -- disconnect connection
			connection = nil -- set connection to nil
		end
	end)
end

local function touchedRadius(player: Player, damage: number)
	local character = player.Character or player.CharacterAdded:Wait() -- get player character
	local rootPart = character:WaitForChild("HumanoidRootPart") -- get player root part

	local hitList = {} -- list of hit characters
	local params = OverlapParams.new() -- create a new overlap params
	params.FilterDescendantsInstances = {character} -- player character will not be considered, because it will be in the filter
	params.FilterType = Enum.RaycastFilterType.Exclude -- set filter type

	local touchingParts = workspace:GetPartBoundsInRadius(rootPart.Position + Vector3.new(0, -2, 0), 15, params) -- get all the parts in the radius
	for _, part in ipairs(touchingParts) do -- loop through all the touching parts of the projectile
		local enemyChar = part.Parent -- get enemy character
		if enemyChar and enemyChar:FindFirstChild("Humanoid") then -- if enemyChar is not nil and has a humanoid then
			dealDamageOnce(enemyChar, damage, hitList) -- deal damage to enemyChar
		end
	end
end

local function touchedPart(player: Player, part: BasePart, damage: number)
	local character = player.Character or player.CharacterAdded:Wait() -- get player character

	local hitList = {} -- list of hit characters
	local params = OverlapParams.new() -- create a new overlap params
	params.FilterDescendantsInstances = {character} -- player character will not be considered, because it will be in the filter
	params.FilterType = Enum.RaycastFilterType.Exclude -- set filter type

	local touchingParts = workspace:GetPartsInPart(part, params) -- get all the parts in the radius
	for _, p in ipairs(touchingParts) do -- loop through all the touching parts of the projectile
		local enemyChar = p.Parent -- get enemy character
		if enemyChar and enemyChar:FindFirstChild("Humanoid") then -- if enemyChar is not nil and has a humanoid then
			dealDamageOnce(enemyChar, damage, hitList) -- deal damage to enemyChar
		end
	end
end

local Attacks = {

["Click"]  = function(player: Player, mousePos: Vector3)
	if not canAttack then return end -- if canAttack is false then return
	canAttack = false -- set canAttack to false

	local character = player.Character or player.CharacterAdded:Wait() -- get player character
	local rootPart = character:WaitForChild("HumanoidRootPart") -- get player root part

	local ball = Instance.new("Part") -- create a new part
	ball.Size = Vector3.new(1, 1, 1) -- set the size of the part
	ball.CFrame = rootPart.CFrame -- set the cframe of the part
	ball.Shape = Enum.PartType.Ball -- set the shape of the part
	ball.CanCollide = false -- set the collision of the part
	ball.Color = Color3.new(1, 0.333, 0) -- set the color of the part
	ball.Parent = workspace -- set parent to workspace

	setFireEffect(ball, false) -- set fire effect to the part
	touchedProjectile(player, ball, 10) -- deal damage to the player
	setLinearVelocity(ball, mousePos.Unit * 35) -- set the velocity of the part

	setCountdown() -- set the countdown
end,

["FireCircle"] = function(player: Player)
	if not canAttack then return end -- if canAttack is false then return
	canAttack = false -- set canAttack to false

	local character = player.Character or player.CharacterAdded:Wait() -- get player character
	local rootPart = character:WaitForChild("HumanoidRootPart") -- get player root part

	local fireCircle = Instance.new("Part") -- create a new part
	fireCircle.Size = Vector3.new(1, 30, 30) -- set the size of the part
	fireCircle.Shape = Enum.PartType.Cylinder -- set the shape of the part
	fireCircle.Anchored = true -- set the anchor of the part
	fireCircle.CanCollide = false -- set the collision of the part
	fireCircle.Transparency = 1 -- set the transparency of the part
	fireCircle.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(90)) + Vector3.new(0, -3, 0) -- set the cframe of the part
	fireCircle.Parent = workspace -- set parent to workspace

	local emitter = Instance.new("ParticleEmitter") -- create a new particle emitter
	emitter.Rate = 1000 -- set the rate of the emitter
	emitter.Color = ColorSequence.new(Color3.new(1, 0.333, 0)) -- set the color of the emitter
	emitter.Speed = NumberRange.new(0) -- set the speed of the emitter
	emitter.Lifetime = NumberRange.new(0.1) -- set the lifetime of the emitter
	emitter.Shape = Enum.ParticleEmitterShape.Cylinder -- set the shape of the emitter
	emitter.Parent = fireCircle -- set parent to the fire circle

	addToDebris(emitter, 0.5) -- add the emitter to the debris
	addToDebris(fireCircle, 0.5) -- add the fire circle to the debris

	touchedRadius(player, 30) -- deal damage to the player
	setCountdown() -- set the countdown
end,

["FireBall"] = function(player: Player, mousePos: Vector3) 
	if not canAttack then return end -- if canAttack is false then return
	canAttack = false -- set canAttack to false

	local character = player.Character or player.CharacterAdded:Wait() -- get player character
	local rootPart = character:WaitForChild("HumanoidRootPart") -- get player root part

	local fireBall = Instance.new("Part") -- create a new part
	fireBall.Size = Vector3.new(5, 5, 5) -- set the size of the part
	fireBall.Color = Color3.new(1, 0.333, 0) -- set the color of the part
	fireBall.Transparency = 0.5 -- set the transparency of the part
	fireBall.Shape = Enum.PartType.Ball -- set the shape of the part
	fireBall.CanCollide = false -- set the collision of the part
	fireBall.CFrame = rootPart.CFrame -- set the cframe of the part
	fireBall.Parent = workspace -- set parent to workspace

	setFireEffect(fireBall, false) -- set the fire effect
	setSmokeEffect(fireBall, false) -- set the smoke effect

	touchedProjectile(player, fireBall, 45) -- deal damage to the player
	setLinearVelocity(fireBall, mousePos.Unit * 75) -- set the linear velocity of the part

	setCountdown() -- set the countdown
end,

["Dash"] = function(player: Player)
	if not canAttack then return end -- if canAttack is false then return

	local character = player.Character or player.CharacterAdded:Wait() -- get player character
	local rootPart = character:WaitForChild("HumanoidRootPart") -- get player root part

	setLinearVelocity(rootPart, rootPart.CFrame.LookVector * 90, true, 0.1) -- set the linear velocity of the part
end,

["FireExplosion"] = function(player: Player)
	if not canAttack then return end -- if canAttack is false then return
	canAttack = false -- set canAttack to false

	local character = player.Character or player.CharacterAdded:Wait() -- get player character
	local rootPart = character:WaitForChild("HumanoidRootPart") -- get player root part

	local explosion = Instance.new("Part") -- create a new part
	explosion.Size = Vector3.new(1, 1, 1) -- set the size of the part
	explosion.Color = Color3.new(1, 0.666, 0) -- set the color of the part
	explosion.Material = Enum.Material.Neon -- set the material of the part
	explosion.Transparency = 0.5 -- set the transparency of the part
	explosion.Shape = Enum.PartType.Ball -- set the shape of the part
	explosion.CanCollide = false -- set the collision of the part
	explosion.Anchored = true -- set the part to anchored
	explosion.CFrame = rootPart.CFrame -- set the cframe of the part
	explosion.Parent = workspace -- set parent to workspace

	local tweenInfo = TweenInfo.new(0.5) -- create a new tween info
	local goal = {Size = Vector3.new(30, 30, 30)} -- set the goal of the tween
	TweenService:Create(explosion, tweenInfo, goal):Play() -- play the tween

	task.delay(0.45, function() -- after 0.5 seconds, execute function
		touchedPart(player, explosion, 50) -- deal damage to the player
		explosion:Destroy() -- destroy explosion
	end)

	setCountdown() -- set the countdown
end,
}
attackEvent.OnServerEvent:Connect(function(player: Player, attackName: string, mousePos: Vector3)
	if not canAttack then -- if canAttack is false then
		warn("Can't attack yet.") -- warn the player
		return -- return
	end

	local attack = Attacks[attackName] -- get the attack function
	if attack then -- if the attack exists then
		attack(player, mousePos) -- execute the attack function
	end
end)
