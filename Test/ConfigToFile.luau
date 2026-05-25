local Serde = require("@lune/serde")
local FileSystem = require("@lune/fs")

local Config = {
	ProjectName = "TestProject",
	TargetOwnerID = 4446965,
	Environments = {
		{
			Name = "DEV_ND",
		},
		{
			Name = "DEV_Spathi",
		},
		{
			Name = "Test",
		},
		{
			Name = "Production",
			IsProduction = true,
		},
	},

	Resources = {
		UniverseSettings = {
			Settings = {
				allowPrivateServers = false,
				name = "IAC Testing",
				description = "Universe used for IAC testing",
				isArchived = false,
				playableDevices = { 1, 2 },
				engineAvatarSettings = Serde.encode("json", {
					AvatarAnimationRules = {
						CustomJumpAnimationEnabled = false,
						CustomJumpAnimationId = 0,
						CustomRunAnimationEnabled = false,
						CustomRunAnimationId = 0,
						CustomIdleAnimationEnabled = false,
						CustomIdleAnimationId = 0,
						CustomClimbAnimationEnabled = false,
						CustomClimbAnimationId = 0,
						CustomIdleAlt1AnimationEnabled = false,
						CustomIdleAlt1AnimationId = 0,
						CustomIdleAlt2AnimationEnabled = false,
						CustomIdleAlt2AnimationId = 0,
						CustomSwimIdleAnimationEnabled = false,
						CustomSwimIdleAnimationId = 0,
						CustomSwimAnimationEnabled = false,
						CustomSwimAnimationId = 0,
						CustomWalkAnimationEnabled = false,
						CustomWalkAnimationId = 0,
						CustomFallAnimationEnabled = false,
						CustomFallAnimationId = 0,
						AnimationClipsMode = 0, -- Determines if custom animation clips are enabled. 0 = player choice, 1 = custom clips.
						AnimationPacksMode = 0, -- Determines a preset animation pack. 0 = player choice, 1 = standard R15, 2 = Standard R6.
					},
					AvatarClothingRules = {
						CustomJacketAccessoryEnabled = false,
						CustomJacketAccessoryId = 0,
						CustomShirtAccessoryEnabled = false,
						CustomShirtAccessoryId = 0,
						CustomTShirtAccessoryEnabled = false,
						CustomTShirtAccessoryId = 0,
						CustomSweaterAccessoryEnabled = false,
						CustomSweaterAccessoryId = 0,
						CustomDressSkirtAccessoryEnabled = false,
						CustomDressSkirtAccessoryId = 0,
						CustomPantsAccessoryEnabled = false,
						CustomPantsAccessoryId = 0,
						CustomShortsAccessoryEnabled = false,
						CustomShortsAccessoryId = 0,
						CustomLeftShoesAccessoryEnabled = false,
						CustomLeftShoesAccessoryId = 0,
						CustomRightShoesAccessoryEnabled = false,
						CustomRightShoesAccessoryId = 0,
						CustomClassicShirtsAccessoryEnabled = false,
						CustomClassicShirtsAccessoryId = 0,
						CustomClassicTShirtsAccessoryEnabled = false,
						CustomClassicTShirtsAccessoryId = 0,
						CustomClassicPantsAccessoryEnabled = false,
						CustomClassicPantsAccessoryId = 0,
						CustomClothingMode = 0, -- Determines if player's clothing is replaced with custom clothing. 0 = Player choice, 1 = custom clothing.
						ClothingMode = 0, -- Determines whether or not the clothing `LimitBounds` setting is used. 0 = no limit bounds, 1 = limit bounds.
						LimitBounds = { 0, 0, 0 }, -- Removes or scales clothing that exceeds the limit bounds. Limit bounds are based on a % of padding around the avatar.
					},
					AvatarAccessoryRules = {
						EnableSound = true,
						EnableVFX = true,
						CustomAccessoryMode = 0, -- Determines if player's clothing is replaced with custom clothing. 0 = Player choice, 1 = custom clothing.
						AccessoryMode = 0, -- Determines whether or not the accessory `LimitBounds` setting is used. 0 = no limit bounds, 1 = limit bounds.
						LimitMethod = 1, -- Determines if accessories that exceed the limit bounds are removed or scaled down. 0 = scaled down, 1 = removed.
						LimitBounds = { 0, 0, 0 }, -- Removes or scales accessories that exceeds the limit bounds. Limit bounds are based on a % of padding around the avatar.
						CustomBackAccessoryEnabled = false,
						CustomBackAccessoryId = 0,
						CustomFaceAccessoryEnabled = false,
						CustomFaceAccessoryId = 0,
						CustomFrontAccessoryEnabled = false,
						CustomFrontAccessoryId = 0,
						CustomHairAccessoryEnabled = false,
						CustomHairAccessoryId = 0,
						CustomHeadAccessoryEnabled = false,
						CustomHeadAccessoryId = 0,
						CustomNeckAccessoryEnabled = false,
						CustomNeckAccessoryId = 0,
						CustomShoulderAccessoryEnabled = false,
						CustomShoulderAccessoryId = 0,
						CustomWaistAccessoryEnabled = false,
						CustomWaistAccessoryId = 0,
					},
					AvatarCollisionRules = {
						CollisionMode = 1, -- Determines the type of collision avatars will have by default. 0 = "Default" / outerbox, 1 = "Single Collider", 2 = "Legacy" / innerbox.
						HitAndTouchDetectionMode = 0, -- Determines if colliders or avatar geometry is used for touch events. 0 = avatar geometry, 1 = colliders.
						LegacyCollisionMode = 1, --! Unknown what this does. It's always set to a value of 1.
						SingleColliderSize = { 2, 3, 1 }, -- Determines the size of the collider used if CollisionMode is set to single collider.
					},
					AvatarBodyRules = {
						BuildMode = 0, -- Determines whether or not avatars are forced to a specific, non-uniform scale. 0 = player choice, 1 = forced rigid scale.
						CustomBodyTypeScale = { 0, 0 }, -- Sets the min & max "rthro" scale for avatars. Valid value ranges are 0 through 1.
						CustomHeadScale = { 1, 1 }, -- Sets the min & max scale that avatar heads can have if BuildMode is set to forced scale. Valid value ranges are 0 through 1.
						CustomHeightScale = { 1, 1 }, -- Controls the min & max height that avatars can be if BuildMode is set to forced scale. Valid value ranges are 0 through 1.
						CustomProportionsScale = { 1, 1 }, -- Sets the min & max proportion scales for avatars. Valid value ranges are 0 through 1.
						CustomWidthScale = { 1, 1 }, -- Controls the min & max width that avatars can be if BuiildMode is set to forced scale. Valid value ranges are 0 through 1.
						ScaleMode = 1, -- Determines whether or not avatars are uniformly scaled to a certain height. 0 = player choice, 1 = forced height.
						CustomHeight = { 5.5, 5.5 }, -- Controls the min & max height (in studs) that avatars can be if ScaleMode is set to forced height.
						AppearanceMode = 0, -- Determines whether or not player avatars have custom body parts. 0 = player choice, 1 = custom body parts.
						KeepPlayerHead = true,
						CustomBodyType = 0,
						CustomBodyBundleId = 0,
						CustomEyebrowEnabled = false,
						CustomEyebrowId = 0,
						CustomEyelashEnabled = false,
						CustomEyelashId = 0,
						CustomFaceEnabled = false,
						CustomFaceId = 0,
						CustomHeadEnabled = false,
						CustomHeadId = 0,
						CustomLeftArmEnabled = false,
						CustomLeftArmId = 0,
						CustomLeftLegEnabled = false,
						CustomLeftLegId = 0,
						CustomMoodEnabled = false,
						CustomMoodId = 0,
						CustomRightArmEnabled = false,
						CustomRightArmId = 0,
						CustomRightLegEnabled = false,
						CustomRightLegId = 0,
						CustomTorsoEnabled = false,
						CustomTorsoId = 0,
					},
					AvatarRules = {
						AvatarType = 1, -- Determines whether R6, R15, or both rig types are allowed. 0 = R6, 1 = R15, 2 = R6 & R15.
					},
					version = 1, -- The current schema version of the avatar settings.
				}),
			},
		},
		Places = {
			MainPlace = {
				IsRoot = true,
				File = "./Test/SomeDatamodel.rbxl",
				Settings = {
					name = "IAC Testing",
					description = "This is the root place!",
					maxPlayerCount = 3,
					socialSlotType = "Automatic",
				},
			},
			ASubPlace = {
				File = "./Test/SomeDatamodel.rbxl",
				Settings = {
					name = "Sub place",
					description = "This is a sub-place!",
					maxPlayerCount = 2,
					socialSlotType = "Automatic",
				},
			},
		},
		SocialLinks = {
			Links = {
				twitterSocialLink = {
					title = "News & updates!",
					uri = "https://twitter.com/Phoenix_Devs",
				},
				discordSocialLink = {
					title = "Join our community server!",
					uri = "https://discord.gg/QUDbRGadAF",
				},
				robloxGroupSocialLink = {
					title = "Join our group!",
					uri = "https://www.roblox.com/groups/4446965",
				},
			},
		},
		GamePasses = {
			TestPass1 = {
				File = "./Test/Assets/Web/GamePass.png",
				Settings = {
					name = "VIP",
					description = "Makes you cool ingame!",
					isForSale = false,
					price = 100,
					isRegionalPricingEnabled = false,
				},
			},
		},
		DevProducts = {
			TestProduct1 = {
				File = "./Test/Assets/Web/DevProduct.png",
				Settings = {
					name = "Add Time",
					description = "Adds more time to the round!",
					isForSale = false,
					price = 100,
					isRegionalPricingEnabled = false,
				},
			},
		},
		Badges = {
			TestBadge1 = {
				File = "./Test/Assets/Web/Badge.png",
				Settings = {
					name = "A cool badge",
					description = "This is a cool badge you get for doing something awesome!",
					enabled = false,
				},
			},
		},
	},
}

FileSystem.writeFile("Environments.json", (Serde.encode("json", Config, true)))
