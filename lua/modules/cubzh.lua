Modules = {
	bundle = "bundle",
}

Client.OnStart = function()
	Screen.Orientation = "portrait" -- force portrait

	Clouds.On = false

	ease = require("ease")
	particles = require("particles")

	drawerHeight = 0

	avatarCameraFocus = "body" -- body / head
	avatarCameraTarget = nil

	backgroundCamera = Camera()
	backgroundCamera.Projection = ProjectionMode.Orthographic
	backgroundCamera.On = true
	backgroundCamera.Layers = { 6 }
	World:AddChild(backgroundCamera)

	backgroundCamera.ViewOrder = 1
	Camera.ViewOrder = 2

	function getAvatarCameraTargetPosition(h, w)
		if avatarCameraTarget == nil then
			return nil
		end

		local _w = Camera.TargetWidth
		local _h = Camera.TargetHeight

		Camera.TargetHeight = h
		Camera.TargetWidth = w
		Camera.Height = h
		Camera.Width = w
		Camera.TargetX = 0
		Camera.TargetY = 0

		local box = Box()
		local pos = Camera.Position:Copy()
		if avatarCameraFocus == "body" then
			box:Fit(avatarCameraTarget, { recursive = true })
			Camera:FitToScreen(box, 0.7)
		elseif avatarCameraFocus == "head" then
			box:Fit(avatarCameraTarget.Head, { recursive = true })
			Camera:FitToScreen(box, 0.5)
		elseif avatarCameraFocus == "eyes" then
			box:Fit(avatarCameraTarget.Head, { recursive = true })
			Camera:FitToScreen(box, 0.6)
		elseif avatarCameraFocus == "nose" then
			box:Fit(avatarCameraTarget.Head, { recursive = true })
			Camera:FitToScreen(box, 0.6)
		end

		local targetPos = Camera.Position:Copy()

		-- restore
		Camera.TargetHeight = _h
		Camera.TargetWidth = _w
		Camera.Height = _h
		Camera.Width = _w
		Camera.TargetX = 0
		Camera.TargetY = 0
		Camera.Position:Set(pos)

		return targetPos
	end

	local avatarCameraState = {}
	function layoutCamera(config)
		local h = Screen.Height - drawerHeight

		if
			avatarCameraState.h == h
			and avatarCameraState.screenWidth == Screen.Width
			and avatarCameraState.focus == avatarCameraFocus
			and avatarCameraState.target == avatarCameraTarget
		then
			-- nothing changed, early return
			return
		end

		local p = getAvatarCameraTargetPosition(h, Screen.Width)
		if p == nil then
			return
		end

		avatarCameraState.h = h
		avatarCameraState.screenWidth = Screen.Width
		avatarCameraState.focus = avatarCameraFocus
		avatarCameraState.target = avatarCameraTarget

		ease:cancel(Camera)

		if config.noAnimation then
			Camera.TargetHeight = h
			Camera.TargetWidth = Screen.Width
			Camera.Height = h
			Camera.Width = Screen.Width
			Camera.TargetX = 0
			Camera.TargetY = 0
			Camera.Position:Set(p)
			return
		end

		local anim = ease:inOutSine(Camera, 0.2, {
			onDone = function()
				avatarCameraState.animation = nil
			end,
		})

		anim.TargetHeight = h
		anim.TargetWidth = Screen.Width
		anim.Height = h
		anim.Width = Screen.Width
		anim.TargetX = 0
		anim.TargetY = 0
		anim.Position = p
	end

	Camera:SetModeFree()
	Camera:SetParent(World)

	Sky.AbyssColor = Color(120, 0, 178)
	Sky.HorizonColor = Color(106, 73, 243)
	Sky.SkyColor = Color(121, 169, 255)
	Sky.LightColor = Color(100, 100, 100)

	titleScreen():show()

	LocalEvent:Listen("signup_flow_avatar_preview", function()
		titleScreen():hide()
		avatar():show({ mode = "demo" })
	end)

	LocalEvent:Listen("signup_flow_avatar_editor", function()
		titleScreen():hide()
		avatar():show({ mode = "user" })
	end)

	LocalEvent:Listen("signup_flow_dob", function()
		avatarCameraFocus = "body"
		layoutCamera()
	end)

	LocalEvent:Listen("signup_flow_start_or_login", function()
		titleScreen():show()
		avatar():hide()
	end)

	LocalEvent:Listen("signup_drawer_height_update", function(height)
		drawerHeight = height
		layoutCamera()
	end)

	LocalEvent:Listen("signup_flow_login_success", function(height)
		drawerHeight = 0
		titleScreen():hide()
		layoutCamera({ noAnimation = true })
	end)

	light = Light()
	light.Color = Color(150, 150, 200)
	light.Intensity = 1.0
	light.CastsShadows = true
	light.On = true
	light.Type = LightType.Directional
	World:AddChild(light)
	light.Rotation:Set(math.rad(5), math.rad(-20), 0)

	Light.Ambient.SkyLightFactor = 0.2
	Light.Ambient.DirectionalLightFactor = 0.5

	local logoTile = bundle:Data("images/logo-tile-rotated.png")

	backgroundQuad = Quad()
	backgroundQuad.IsUnlit = true
	backgroundQuad.IsDoubleSided = true
	backgroundQuad.Color = { gradient = "V", from = Color(166, 96, 255), to = Color(72, 102, 209) }
	backgroundQuad.Width = Screen.RenderWidth
	backgroundQuad.Height = Screen.RenderHeight
	backgroundQuad.Anchor = { 0.5, 0.5 }
	backgroundQuad.Layers = { 6 }
	World:AddChild(backgroundQuad)
	backgroundQuad.Position.Z = 2

	backgroundLogo = Quad()
	backgroundLogo.IsUnlit = true
	backgroundLogo.IsDoubleSided = true
	backgroundLogo.Color = Color(255, 255, 255, 0.1)
	backgroundLogo.Image = logoTile
	backgroundLogo.Width = math.max(Screen.RenderWidth, Screen.RenderHeight)
	backgroundLogo.Height = backgroundLogo.Width
	backgroundLogo.Tiling = backgroundLogo.Width / Number2(100, 100)
	backgroundLogo.Anchor = { 0.5, 0.5 }
	backgroundLogo.Layers = { 6 }
	World:AddChild(backgroundLogo)
	backgroundLogo.Position.Z = 1

	local delta = Number2(-1, 1)
	speed = 0.2
	LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
		backgroundLogo.Offset = backgroundLogo.Offset + delta * dt * speed
	end)
end

Screen.DidResize = function()
	if backgroundQuad then
		backgroundQuad.Width = Screen.RenderWidth
		backgroundQuad.Height = Screen.RenderHeight
		backgroundLogo.Width = math.max(Screen.RenderWidth, Screen.RenderHeight)
		backgroundLogo.Height = backgroundLogo.Width
		backgroundLogo.Tiling = backgroundLogo.Width / Number2(100, 100)
	end
end

local _titleScreen
function titleScreen()
	if _titleScreen then
		return _titleScreen
	end

	_titleScreen = {}

	local root
	local didResizeFunction
	local didResizeListener
	local tickListener

	_titleScreen.show = function()
		if root ~= nil then
			return
		end
		root = Object()
		root:SetParent(World)

		drawerHeight = 0
		layoutCamera({ noAnimation = true })

		local logo = Object()
		local c = bundle:Shape("shapes/cubzh_logo_c")
		c.Shadow = true
		c.Pivot:Set(c.Width * 0.5, c.Height * 0.5, c.Depth * 0.5)
		c:SetParent(logo)

		local u = bundle:Shape("shapes/cubzh_logo_u")
		u.Pivot:Set(u.Width * 0.5, u.Height * 0.5, u.Depth * 0.5)
		u:SetParent(logo)

		local b = bundle:Shape("shapes/cubzh_logo_b")
		b.Pivot:Set(b.Width * 0.5, b.Height * 1.5 / 4.0, b.Depth * 0.5)
		b:SetParent(logo)

		local z = bundle:Shape("shapes/cubzh_logo_z")
		z.Pivot:Set(z.Width * 0.5, z.Height * 0.5, z.Depth * 0.5)
		z:SetParent(logo)

		local h = bundle:Shape("shapes/cubzh_logo_h")
		h.Pivot:Set(h.Width * 0.5, h.Height * 1.5 / 4.0, h.Depth * 0.5)
		h:SetParent(logo)

		local titleShapes = {}

		local function addShape(name, config)
			local s = bundle:Shape(name)
			s:SetParent(root)
			s.Pivot:Set(s.Size * 0.5)
			s.Scale = config.scale or 1
			s.LocalPosition:Set(config.position or Number3.Zero)
			s.rot = config.rotation or Rotation(0, 0, 0)
			s.Rotation:Set(s.rot)
			table.insert(titleShapes, s)
			return s
		end

		addShape(
			"shapes/giraffe_head",
			{ scale = 1, position = Number3(0, 0, 12), rotation = Rotation(0, 0, math.rad(20)) }
		)

		local chest = addShape(
			"shapes/chest",
			{ scale = 0.7, position = Number3(7, -18, -7), rotation = Rotation(0, math.rad(25), math.rad(-5)) }
		)
		local chestLid = chest.Lid
		chest.Coins.IsUnlit = true
		local chestLidRot = chest.Lid.LocalRotation:Copy()

		addShape(
			"shapes/pezh_coin_2",
			{ scale = 0.7, position = Number3(-5, -12, -7), rotation = Rotation(0, 0, math.rad(20)) }
		)

		addShape(
			"shapes/cube",
			{ scale = 0.7, position = Number3(18, -9, -12), rotation = Rotation(0, 0, math.rad(20)) }
		)

		addShape("shapes/paint_set", {
			scale = 0.7,
			position = Number3(-22, 12, 6),
			rotation = Rotation(math.rad(-60), math.rad(20), math.rad(-20)),
		})

		addShape(
			"shapes/pizza_slice",
			{ scale = 0.7, position = Number3(12, 8, -5), rotation = Rotation(math.rad(-40), math.rad(-20), 0) }
		)

		addShape("shapes/smartphone", {
			scale = 0.7,
			position = Number3(30, 8, 20),
			rotation = Rotation(math.rad(10), math.rad(30), math.rad(-20)),
		})

		addShape(
			"shapes/sword",
			{ scale = 0.7, position = Number3(-14, -12, 7), rotation = Rotation(0, 0, math.rad(-45)) }
		)

		addShape("shapes/spaceship_2", {
			scale = 0.5,
			position = Number3(-15, -22, -14),
			rotation = Rotation(math.rad(-10), math.rad(-30), math.rad(-30)),
		})

		local space = 2
		local totalWidth = c.Width + u.Width + b.Width + z.Width + h.Width + space * 4

		c.LocalPosition.X = -totalWidth * 0.5 + c.Width * 0.5
		u.LocalPosition:Set(
			c.LocalPosition.X + c.Width * 0.5 + space + u.Width * 0.5,
			c.LocalPosition.Y,
			c.LocalPosition.Z
		)
		b.LocalPosition:Set(
			u.LocalPosition.X + u.Width * 0.5 + space + b.Width * 0.5,
			c.LocalPosition.Y,
			c.LocalPosition.Z
		)
		z.LocalPosition:Set(
			b.LocalPosition.X + b.Width * 0.5 + space + z.Width * 0.5,
			c.LocalPosition.Y,
			c.LocalPosition.Z
		)
		h.LocalPosition:Set(
			z.LocalPosition.X + z.Width * 0.5 + space + h.Width * 0.5,
			c.LocalPosition.Y,
			c.LocalPosition.Z
		)

		cRot = Rotation(0, 0, math.rad(10))
		uRot = Rotation(0, 0, math.rad(-10))
		bRot = Rotation(0, 0, math.rad(10))
		zRot = Rotation(0, 0, math.rad(-10))
		hRot = Rotation(0, 0, math.rad(10))

		c.Rotation = cRot
		u.Rotation = uRot
		b.Rotation = bRot
		z.Rotation = zRot
		h.Rotation = hRot

		local t = 0
		local t2 = 1
		local d1, d2, d3, d4, d5

		local modifiers = {}
		local nbModifiers = 5
		local modifier
		local r
		for i = 1, nbModifiers do
			r = math.random(1, 2)
			modifier = {
				t = 0,
				dtCoef = 1 + math.random() * 0.10,
				amplitude = math.rad(math.random(5, 10)),
			}
			if r == 1 then
				modifier.fn1 = math.cos
				modifier.fn2 = math.sin
			else
				modifier.fn1 = math.sin
				modifier.fn2 = math.cos
			end
			modifiers[i] = modifier
		end

		tickListener = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
			t = t + dt
			t2 = t2 + dt * 1.05
			d1 = math.sin(t) * math.rad(10)
			d2 = math.cos(t2) * math.rad(10)
			d3 = math.sin(t2) * math.rad(10)
			d4 = math.cos(t) * math.rad(10)

			d5 = math.sin(t) * math.rad(5)

			c.Rotation = cRot * Rotation(d1, d2, 0)
			u.Rotation = uRot * Rotation(d2, d1, 0)
			b.Rotation = bRot * Rotation(d3, d4, 0)
			z.Rotation = zRot * Rotation(d4, d3, 0)
			h.Rotation = hRot * Rotation(d1, d3, 0)

			chestLid.LocalRotation = chestLidRot * Rotation(d5, 0, 0)

			for _, modifier in ipairs(modifiers) do
				modifier.t = t + dt * modifier.dtCoef
				modifier.rot = Rotation(
					modifier.fn1(modifier.t) * modifier.amplitude,
					modifier.fn2(modifier.t) * modifier.amplitude,
					0
				)
			end

			for i, s in ipairs(titleShapes) do
				modifier = modifiers[(i % nbModifiers) + 1]
				s.Rotation = s.rot * modifier.rot
			end
		end)

		logo:SetParent(root)

		didResizeFunction = function()
			layoutCamera({ noAnimation = true })
			local box = Box()
			box:Fit(logo, { recursive = true })
			Camera:FitToScreen(box, 0.8)
		end

		didResizeListener = LocalEvent:Listen(LocalEvent.Name.ScreenDidResize, didResizeFunction)
		didResizeFunction()
	end

	_titleScreen.hide = function()
		-- Camera.On = false
		if root == nil then
			return
		end
		tickListener:Remove()
		tickListener = nil
		didResizeListener:Remove()
		didResizeFunction = nil

		root:RemoveFromParent()
		root = nil
	end

	return _titleScreen
end

function shuffle(array)
	local n = #array
	for i = n, 2, -1 do
		local j = math.random(i)
		array[i], array[j] = array[j], array[i]
	end
end

local _avatar
function avatar()
	if _avatar then
		return _avatar
	end

	_avatar = {}

	local bundle = require("bundle")
	local avatarModule = require("avatar")

	local hairs = {
		bundle:Shape("shapes/signup_demo/air_goggles"),
		bundle:Shape("shapes/signup_demo/hair_pink_blue"),
		bundle:Shape("shapes/signup_demo/lofi_girl_head"),
		bundle:Shape("shapes/signup_demo/pink_pop_hair"),
		bundle:Shape("shapes/signup_demo/pirate_captain_hat"),
		bundle:Shape("shapes/signup_demo/santa_hair"),
		bundle:Shape("shapes/signup_demo/elf_hair"),
		bundle:Shape("shapes/signup_demo/sennin_head"),
		bundle:Shape("shapes/signup_demo/geek_long_hair"),
		bundle:Shape("shapes/signup_demo/elvis"),
		bundle:Shape("shapes/signup_demo/wolf_cut"),
		bundle:Shape("shapes/signup_demo/luffy_hair"),
		bundle:Shape("shapes/signup_demo/crown"),
		bundle:Shape("shapes/signup_demo/raccoon_head"),
		bundle:Shape("shapes/signup_demo/just_hair"),
		bundle:Shape("shapes/signup_demo/grass_cubzh"),
	}
	local hairsCurrentIndex = 0
	local hairsRandomIndexes = {}
	for i = 1, #hairs do
		table.insert(hairsRandomIndexes, i)
	end
	shuffle(hairsRandomIndexes)

	local jackets = {
		bundle:Shape("shapes/signup_demo/astronaut_top"),
		bundle:Shape("shapes/signup_demo/cute_top"),
		bundle:Shape("shapes/signup_demo/lab_coat"),
		bundle:Shape("shapes/signup_demo/princess_dresstop"),
		bundle:Shape("shapes/signup_demo/red_robot_suit"),
		bundle:Shape("shapes/signup_demo/sweater"),
		bundle:Shape("shapes/signup_demo/jedi_tunic"),
	}

	local jacketsCurrentIndex = 0
	local jacketsRandomIndexes = {}
	for i = 1, #jackets do
		table.insert(jacketsRandomIndexes, i)
	end
	shuffle(jacketsRandomIndexes)

	local pants = {
		bundle:Shape("shapes/signup_demo/overalls_pants"),
		bundle:Shape("shapes/signup_demo/jorts"),
		bundle:Shape("shapes/signup_demo/red_crewmate_pants"),
		bundle:Shape("shapes/signup_demo/stripe_pants2"),
	}

	local pantsCurrentIndex = 0
	local pantsRandomIndexes = {}
	for i = 1, #pants do
		table.insert(pantsRandomIndexes, i)
	end
	shuffle(pantsRandomIndexes)

	local boots = {
		bundle:Shape("shapes/signup_demo/astronaut_shoes"),
		bundle:Shape("shapes/signup_demo/flaming_boots"),
		bundle:Shape("shapes/signup_demo/kids_shoes"),
		bundle:Shape("shapes/signup_demo/pirate_boots_01"),
	}

	local bootsCurrentIndex = 0
	local bootsRandomIndexes = {}
	for i = 1, #boots do
		table.insert(bootsRandomIndexes, i)
	end
	shuffle(bootsRandomIndexes)

	local defaultHair = bundle:Shape("shapes/default_hair")
	local defaultJacket = bundle:Shape("shapes/default_jacket")
	local defaultPants = bundle:Shape("shapes/default_pants")
	local defaultShoes = bundle:Shape("shapes/default_shoes")

	local yaw = math.rad(-190)
	local pitch = 0

	local root
	local listeners = {}

	local function drag(dx, dy)
		yaw = yaw - dx * 0.01
		pitch = math.min(math.rad(45), math.max(math.rad(-45), pitch + dy * 0.01))
		if root then
			root.LocalRotation = Rotation(pitch, 0, 0) * Rotation(0, yaw, 0)
		end
	end

	local mode = "demo" -- demo / user

	local emitter
	local particlesColor = Color(0, 0, 0)

	_avatar.show = function(self, config)
		if root ~= nil then
			if mode == config.mode then
				return
			end
			self:hide()
		end

		if emitter == nil then
			emitter = particles:newEmitter({
				acceleration = -Config.ConstantAcceleration,
				velocity = function()
					local v = Number3(0, 0, math.random(40, 50))
					v:Rotate(math.random() * math.pi * 2, math.random() * math.pi * 2, 0)
					return v
				end,
				life = 3.0,
				scale = function()
					return 0.7 + math.random() * 1.0
				end,
				color = function()
					return particlesColor
				end,
			})
		end

		mode = config.mode

		root = Object()

		local eyeBlinks = true
		if mode == "demo" then
			eyeBlinks = false
		end

		local avatar = avatarModule:get({
			usernameOrId = "",
			-- size = math.min(Screen.Height * 0.5, Screen.Width * 0.75),
			-- ui = ui,
			eyeBlinks = eyeBlinks,
		})

		avatar:SetParent(root)
		root.avatar = avatar

		avatar.Animations.Walk:Stop()
		avatar.Animations.Idle:Play()

		local b = Box()
		b:Fit(avatar, { recursive = true, ["local"] = true })
		avatar.LocalPosition.Y = -b.Size.Y * 0.5

		if mode == "demo" then
			avatar:loadEquipment({ type = "hair", shape = hairs[1] })
			avatar:loadEquipment({ type = "jacket", shape = jackets[1] })
			avatar:loadEquipment({ type = "pants", shape = pants[1] })
			avatar:loadEquipment({ type = "boots", shape = boots[1] })
		else
			avatar:loadEquipment({ type = "hair", shape = defaultHair })
			avatar:loadEquipment({ type = "jacket", shape = defaultJacket })
			avatar:loadEquipment({ type = "pants", shape = defaultPants })
			avatar:loadEquipment({ type = "boots", shape = defaultShoes })
		end

		local l = LocalEvent:Listen(LocalEvent.Name.PointerDrag, function(pe)
			drag(pe.DX, pe.DY)
		end)
		drag(0, 0)
		table.insert(listeners, l)

		l = LocalEvent:Listen(LocalEvent.Name.ScreenDidResize, function()
			layoutCamera()
		end)

		table.insert(listeners, l)

		l = LocalEvent:Listen("avatar_editor_should_focus_on_head", function()
			avatarCameraFocus = "head"
			layoutCamera()
		end)
		table.insert(listeners, l)

		l = LocalEvent:Listen("avatar_editor_should_focus_on_eyes", function()
			avatarCameraFocus = "eyes"
			layoutCamera()
		end)
		table.insert(listeners, l)

		l = LocalEvent:Listen("avatar_editor_should_focus_on_nose", function()
			avatarCameraFocus = "nose"
			layoutCamera()
		end)
		table.insert(listeners, l)

		l = LocalEvent:Listen("avatar_editor_should_focus_on_body", function()
			avatarCameraFocus = "body"
			layoutCamera()
		end)
		table.insert(listeners, l)

		l = LocalEvent:Listen("signup_flow_avatar_preview", function()
			avatarCameraFocus = "body"
			layoutCamera()
		end)
		table.insert(listeners, l)

		local didAttachEquipmentParts = function(equipmentParts)
			for _, part in ipairs(equipmentParts) do
				ease:cancel(part)
				local scale = part.Scale:Copy()
				part.Scale = part.Scale * 0.8
				ease:outBack(part, 0.2).Scale = scale
			end
		end

		l = LocalEvent:Listen("avatar_editor_update", function(config)
			if config.skinColorIndex then
				local colors = avatarModule.skinColors[config.skinColorIndex]
				local avatar = root.avatar
				avatar:setColors({
					skin1 = colors.skin1,
					skin2 = colors.skin2,
					nose = colors.nose,
					mouth = colors.mouth,
				})

				ease:cancel(root)
				root.Scale = 0.8
				ease:outBack(root, 0.2).Scale = Number3(1.0, 1.0, 1.0)

				particlesColor = colors.skin1
				emitter.Position = root.Position
				emitter:spawn(10)
			end
			if config.eyesIndex then
				avatar:setEyes({
					index = config.eyesIndex,
				})
			end
			if config.eyesColorIndex then
				avatar:setEyes({
					color = avatarModule.eyeColors[config.eyesColorIndex],
				})
			end
			if config.noseIndex then
				avatar:setNose({ index = config.noseIndex })
			end
			if config.jacket then
				avatar:loadEquipment({
					type = "jacket",
					item = config.jacket,
					didAttachEquipmentParts = didAttachEquipmentParts,
				})
			end
			if config.hair then
				avatar:loadEquipment({
					type = "hair",
					item = config.hair,
					didAttachEquipmentParts = didAttachEquipmentParts,
				})
			end
			if config.pants then
				avatar:loadEquipment({
					type = "pants",
					item = config.pants,
					didAttachEquipmentParts = didAttachEquipmentParts,
				})
			end
			if config.boots then
				avatar:loadEquipment({
					type = "boots",
					item = config.boots,
					didAttachEquipmentParts = didAttachEquipmentParts,
				})
			end
		end)
		table.insert(listeners, l)

		local i = 8
		local r
		local eyesIndex = 1
		local eyesCounter = 1
		local eyesTrigger = 3
		if mode == "demo" then
			changeTimer = Timer(0.3, true, function()
				r = math.random(1, #avatarModule.skinColors)
				if r == i then
					r = i + 1
					if r > #avatarModule.skinColors then
						r = 1
					end
				end
				i = r
				local colors = avatarModule.skinColors[i]
				local avatar = root.avatar
				avatar:setColors({
					skin1 = colors.skin1,
					skin2 = colors.skin2,
					nose = colors.nose,
					mouth = colors.mouth,
				})
				eyesCounter = eyesCounter + 1
				if eyesCounter >= eyesTrigger then
					eyesCounter = 0
					eyesIndex = eyesIndex + 1
					if eyesIndex > #avatarModule.eyes then
						eyesIndex = 1
					end
					avatar:setEyes({
						index = eyesIndex,
						color = avatarModule.eyeColors[math.random(1, #avatarModule.eyeColors)],
					})
					avatar:setNose({
						index = math.random(1, #avatarModule.noses),
					})
				end

				hairsCurrentIndex = hairsCurrentIndex + 1
				if hairsCurrentIndex > #hairsRandomIndexes then
					shuffle(hairsRandomIndexes)
					hairsCurrentIndex = 1
				end

				avatar:loadEquipment({
					type = "hair",
					shape = hairs[hairsRandomIndexes[hairsCurrentIndex]],
					didAttachEquipmentParts = didAttachEquipmentParts,
				})

				jacketsCurrentIndex = jacketsCurrentIndex + 1
				if jacketsCurrentIndex > #jacketsRandomIndexes then
					shuffle(jacketsRandomIndexes)
					jacketsCurrentIndex = 1
				end

				avatar:loadEquipment({
					type = "jacket",
					shape = jackets[jacketsRandomIndexes[jacketsCurrentIndex]],
					didAttachEquipmentParts = didAttachEquipmentParts,
				})

				pantsCurrentIndex = pantsCurrentIndex + 1
				if pantsCurrentIndex > #pantsRandomIndexes then
					shuffle(pantsRandomIndexes)
					pantsCurrentIndex = 1
				end

				avatar:loadEquipment({
					type = "pants",
					shape = pants[pantsRandomIndexes[pantsCurrentIndex]],
					didAttachEquipmentParts = didAttachEquipmentParts,
				})

				bootsCurrentIndex = bootsCurrentIndex + 1
				if bootsCurrentIndex > #bootsRandomIndexes then
					shuffle(bootsRandomIndexes)
					bootsCurrentIndex = 1
				end

				avatar:loadEquipment({
					type = "boots",
					shape = boots[bootsRandomIndexes[bootsCurrentIndex]],
					didAttachEquipmentParts = didAttachEquipmentParts,
				})
			end)
		end

		avatarCameraTarget = nil

		root:SetParent(World)
		root.IsHidden = true

		Timer(0.03, function()
			root.IsHidden = false
			avatarCameraTarget = root
			layoutCamera({ noAnimation = true })
		end)

		return root
	end

	_avatar.hide = function()
		if root == nil then
			return
		end

		local avatar = root.avatar
		avatar:loadEquipment({ type = "jacket", item = "" })
		avatar:loadEquipment({ type = "hair", item = "" })
		avatar:loadEquipment({ type = "pants", item = "" })
		avatar:loadEquipment({ type = "boots", item = "" })

		if changeTimer then
			changeTimer:Cancel()
			changeTimer = nil
		end

		for _, l in ipairs(listeners) do
			l:Remove()
		end
		listeners = {}
		root:RemoveFromParent()
		root = nil

		emitter:RemoveFromParent()
		emitter = nil
	end

	return _avatar
end

Client.DirectionalPad = nil
