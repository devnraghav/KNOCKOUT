-- KNOCKOUT for neverlose

-- loading some great libraries from marketplace. I do NOT take any credit for these libraries. All thanks to their developers.
local base64 = require("neverlose/base64")
local clipboard = require ("neverlose/clipboard")
local pui = require("neverlose/pui") 
local ffi = require("ffi")

ffi.cdef[[
    typedef void* HWND;
    HWND FindWindowA(const char* lpClassName, const char* lpWindowName);
    int FlashWindow(HWND hWnd, int bInvert);
]]


local cheatmenu = {
    -- Ragebot
    rage_main = ui.find("Aimbot", "Ragebot", "Main", "Enabled"),
    Hide_shot = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
    Double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
    get_autopeek = ui.find("Aimbot", "Ragebot", "Main", "Peek Assist"),

	-- setts
	min_dmg = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
	safepoint = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points"),

    -- Anti Aim
    get_antiaim = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled"),
    get_pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
    get_yawbase = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
    get_yawbase_angle = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
    get_yawbase_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),

    get_yaw_mod = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
    get_yaw_mod_degree = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
    get_fakeangles_enabled = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
    inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
    leftlimit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
    rightlimit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
    get_fakeangles_options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
    get_freestanding_options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
    get_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
    get_fakelag = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
    get_fakeduck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
    get_slowwalk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
    get_legmovement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement"),
    
	-- Misc
    clantag_nl = ui.find("Miscellaneous", "Main", "In-Game", "Clan Tag"),
	scope_overlay = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay"),

	-- for removing models
	self_chams = ui.find("Visuals", "Players", "Self", "Chams", "Model"),
	teammates_chams = ui.find("Visuals", "Players", "Teammates", "Chams", "Model"),
	teammates_weapon_chams = ui.find("Visuals", "Players", "Teammates", "Chams", "Weapon"),
}



local definitions = {

	-- globals
	lua_build = "Build: LIVE v0.7",
    localplayer = entity.get_local_player,
    screen_size = render.screen_size,
    username = common.get_username,
    white = "\aFFFFFFFF",
    hitboxes = {[0] = 'GENERIC','HEAD', 'CHEST', 'STOMACH','LEFT ARM', 'RIGHT ARM','LEFT LEG', 'RIGHT LEG','NECK', 'GENERIC', 'GEAR'},
	clantag = "KNOCKOUT",
    clantag_index = 0,

	-- killsays
	killsays = {
		"No fucking lua will ever save your ass from that pathetic playstyle.",
		"Fuck your cheat, fuck your lua. You're either using KNOCKOUT.lua or you're not. Choice is always yours.",
		"You LOST because you're simply incompetent. Should've used KNOCKOUT.lua.",
		"Out cold. Knockout delivered. Just use knockout already bro. It's literally FREE.",
		"You just met the knockout punch.",
		"Lights out. Better luck next time.",
		"Resolved. Knocked out.",
		"KO'd like a champ.",
		"Knocked out of the fucking game.",
		"Sleep tight. You've been knocked out.",
		"Game over. KNOCKOUT.lua victory?",
		"Consider yourself knocked the fuck out.",
		"Avoid the loss. Use KNOCKOUT.lua at github.com/devnrk/KNOCKOUT",
	},

	default_primary_theme = color(86, 145, 255),
	default_secondary_theme = color(255, 110, 110),

	-- some random vars
    jitter_side = 1,
    target,
    i_shot,
    aimbot_shot_to_enemy = true,
    alreadypulledtaser = 0,

	-- for player dormancy state
    player_dormancies = {
		CHEAT_CONFIDENCE = "Dormant - Cheat 100% confidence",
		SOUNDS = "Dormant - Sounds",
		DATA_EXPIRED = "Dormant - Data expired"
    },

	-- for player state
    player_states = {
		STAND = "Standing",
		WALK = "Walking",
		RUN = "Running",
		CROUCH = "Ducking",
		AIR_CROUCH = "Air Ducking",
		AIR = "In Air",
    },
    enemy_states = {
		STAND,
		WALK,
		RUN,
		CROUCH,
		AIR_CROUCH,
		AIR
    },

	-- for auto tp
	tp_once = true,
	our_trace_z_offset = 0,
	check_for_tp_after_air_duration = 0.2, -- how long after we jump or are in air that the teleport logic should run.
	
	-- for hitmarker
	new_lines_from_random_directions = {},
	new_random_directions = {},
	render_impact = false,
	extending = true,
	aim_points = nil,
	num_of_lines = 15,
	start_line_offset = 2,
	start_line_length = 0,
	end_line_length = 0,
	shot_hitbox = nil,

	-- for ui and configs
	current_configs = {},
	get_menu_alpha = ui.get_alpha,
	get_menu_size = ui.get_size,
	get_menu_pos = ui.get_position,

	-- for fps mtigations
	localplayer_materials = materials.get_materials("neverlose/self"),
	team8s_materials = materials.get_materials("neverlose/teammates"),
	enemies_materials = materials.get_materials("neverlose/enemies"),
	team8s_weapon_materials = materials.get_materials("neverlose/teammates/weapon"),

	-- for non desync custom anti aim
	sway_add_desync = 0,
	sway_add_factor = 5,
	old_angles = {},
	jitter_idx = 1,
	distortion_minmax = {-40, 40},
	distortion_cur_angle = 0,
	swing_right = false,
	spin_factor = 0,

	-- To keep track ofdefensive spin yaw
	spin_angle = 0,

	-- for anti bruteforce
	bruteforce_counter = 0,
	anti_bruteforce_shots = {},
	entity_that_shot = nil,
	vec_from_enemy_to_me = nil,
	magnitude_from_enemy_to_me = nil,
	bullet_start_pos = nil,
	bullet_end_pos = nil,
	log_angle_once = nil,
	who_we_met_first = nil,
	set_who_we_met_first = true,
	render_lc_indicator = false
}


-- MENU
ui.sidebar("KNOCKOUT", ui.get_icon("boxing-glove"))
local main_info_group = pui.create("Main", "Script Info", 1)
local group_home = pui.create("Main", "Helpers", 2)
local group_ragehelpers = pui.create("Rage", "Helpers", 1)
-- local group_defensive = pui.create("Defensive", "Defensive Anti-Aim Options", 1)
-- local group_defensive_autopull = pui.create("Defensive", "Tazer and Knife Saftey", 2)

local group_EXPLOITS = pui.create("Exploits", "Defensive Anti-Aim Options", 1)
local group_EXPLOITS_2 = pui.create("Exploits", "Automatic-Teleport", 2)
local group_EXPLOITS_3 = pui.create("Exploits", "Tazer and Knife Saftey", 1)
local group_EXPLOITS_4 = pui.create("Exploits", "Break LC", 2)



local group_conditional_states = pui.create("Conditional-AA","Player States", 1)
-- local group_aa_stealer = pui.create("Anti-Aim Stealer","Steal Enemy Anti-Aim", 1)
-- local group_aa_experiment = pui.create("Experimental Anti-Aim","---", 1)

local group_visuals = pui.create("Visuals [lite]", "A", 1)
local group_misc_main = pui.create("Miscellaneous","Main", 1)
local group_misc_logging = pui.create("Miscellaneous","Logging", 2)
local group_configs_create_delete = ui.create("Configuration", "Create or Delete Configs", 1)
local group_configs_list = ui.create("Configuration","All Configs", 2)
local group_configs_save_load = ui.create("Configuration","", 2)
local group_configs_import_export = ui.create("Configuration","Import or Export your currently loaded config.", 1)

local menuitems = {
    -- home
    notice_build = main_info_group:label(definitions.lua_build),
    more_label = main_info_group:label('Have any bugs/issues you would like to report? Send me a DM on discord  @devnrk'),
	
	configs_list = group_configs_list:combo("Found Configs", definitions.current_configs),
	configs_currently_loaded = group_configs_list:label("Currently loaded: None"),
	
	configs_name = group_configs_create_delete:input("Config name"),
	configs_create = group_configs_create_delete:button("Create"),
	configs_delete = group_configs_create_delete:button("Delete"),
	
	configs_save = group_configs_save_load:button("Save"),
	configs_load = group_configs_save_load:button("Load"),
	
    export_button = group_configs_import_export:button(ui.get_icon("floppy-disk") .. " Export Config"),
	import_button = group_configs_import_export:button(ui.get_icon("disc-drive") .. " Import Config"),
    flashCSGO = group_home:switch("Flash CS:GO taskbar icon on round start", false),
	nade_fix = group_home:switch("Grenade Throw Bug Fix", false),
	nade_fix_about = group_home:label("Neverlose causes issues with throwing grenades. For example sometimes it would throw them at your feet and cause you to lose an important battle. This feature tries to resolve this by disabling double tap before you throw a nade."),
	nade_fix_about_btn = group_home:button("What's this?"),
	
	fps_fix = group_home:switch("FPS Enhancement", false, function(gear)
		local elements = {
			mitigations = gear:listable('Mitigate', {"Reduced target scanning", "Disable localplayer rendering", "Disable teammate rendering"}),
		}
		return elements, true
	end),

	aspect_ratio = group_home:slider('Aspect Ratio', 0, 50, 0.0, 0.1),
	
	-- rage_helpers = group_ragehelpers:switch("Enhance Ragebot", false),

    exploit_l1 = group_EXPLOITS_4:label("Attempts to break LC on enemy peek. Double Tap must be enabled while you're in air. Lower ping is preferred."),
	-- exploit_tutorial = group_EXPLOITS:button(ui.get_icon("youtube") .." Exploit Showcase", function()
    --     require("neverlose/mtools").Panorama:OpenLink("https://www.youtube.com/watch?v=TBAvlJlRaq4&pp=ygUKdmFuaXR5IGh2aA%3D%3D")
    -- end),
    ourexploit = group_EXPLOITS_4:switch("LC On Peek", false, function(gear)
		local elements = {
			only_safe_head = gear:switch("Only when safe head (duck/duck in air)", false)
		}
		
		return elements, true
	end),
	
	auto_tp = group_EXPLOITS_2:switch("Teleport", false, function(gear)
		local elements = {
			type_of_tp = gear:list('Type', {"Default", "DT Slam"}),
		}
		
		return elements, true
	end),
	auto_tp_about = group_EXPLOITS_2:label("Attempts to automatically 'DT SLAM' for you which basically means teleporting you to the ground if you peek an enemy while being in air. This helps break lag compensation and instantly shoot them before their cheat reacts."),
	auto_tp_about_btn = group_EXPLOITS_2:button("What's this?"),
	
    defensive_aa = group_EXPLOITS:switch("Defensive AA", false, function(gear)
		local elements = {
			disablers = gear:listable('Disable', {"On Knife", "On Fakelag", "On Taser"}),
			force_defensive = gear:switch('Force Defensive', true),
		}
		
		return elements, true
	end),
	
    defensive_aa_triggers = group_EXPLOITS:listable("Triggers", {"In air", "Threat Detected (recommended)"}),
	defensive_aa_pitch_enable = group_EXPLOITS:switch("Modify Pitch", false, function(gear)
		local elements = {
			defensive_aa_pitch_angle = gear:combo('Flick Angle', {'Disabled', 'Down', 'Fake Up', 'Random', 'Custom'}),
			defensive_aa_pitch_custom_angle = gear:slider('Custom angle', -89.0, 89.0, 0.0, 1.0)
		}
		return elements, true
	end),
	defensive_aa_yaw_enable = group_EXPLOITS:switch("Modify Yaw", false, function(gear)
		local elements = {
			defensive_aa_yaw_angle = gear:combo('Flick Angle', {'45', '90', '180', 'Spin', 'Random', 'Custom'}),
			defensive_aa_yaw_custom_angle = gear:slider('Custom angle', -180, 180, 0, 1),
		}
		return elements, true
	end),
	
    -- switch_safe_taser = group_EXPLOITS_3:switch("Saftey", false, function(gear)
	-- 	local elements = {
	-- 		equip_items = gear:combo("Item to equip", {"Taser (falls back to secondary if not available)", "Next Available (any weapon)"}),
	-- 		range = gear:slider("Range within", 10, 2000, 500, 1),
	-- 	}
	-- 	return elements, true
	-- end),
	-- switch_safe_taser_about = group_EXPLOITS_3:label("This is a safety feature which tries to pull out a taser or your secondary weapon if a nearby enemy (depending on the range set) has their knife or taser pulled out. Basically an attempt to save you from being tased or shanked."),
	-- switch_safe_taser_about_btn = group_EXPLOITS_3:button("What's this?"),
	clan_taga = group_misc_main:switch("Clantag (custom)", false, function(gear)
		local elements = {
			custom_clan_taga = gear:input("Clantag", "KNOCKOUT")
		}
		
		return elements, true
	end),
	killsay_enable = group_misc_main:switch("Kill Say", false),
	yallah_yallah = group_misc_main:switch("Ideal Tick on shift", false),
    leg_fucker = group_misc_main:switch("Break LBY", false),

	logs_enable = group_misc_logging:switch("Aimbot Logging", false, function(gear)
		local elements = {
			aimbot = gear:switch("Ragebot", false),
			death = gear:switch("Death", false),
			complexity = gear:combo('Detail', {"Default", "Detailed"}),
			location = gear:selectable('Location', {"Log", "Console"}),
		}

		return elements, true
	end),

	enable_conditional_aa = group_conditional_states:switch("Conditional-AA", false),
    select_aa_state = group_conditional_states:combo("State", {"None", definitions.player_states.STAND, definitions.player_states.WALK, definitions.player_states.RUN, definitions.player_states.CROUCH, definitions.player_states.AIR_CROUCH, definitions.player_states.AIR}),
	_builder_aa = {},
	
	under_crosshair = group_visuals:switch("Under Crosshair", false, function(gear)
		local elements = {
			name_color = gear:color_picker("Lua name", definitions.default_primary_theme),
		}
		return elements, true
	end),
	
	
	world_hitmarker = group_visuals:switch("World Hitmarker", false, function(gear)
		local elements = {
			world_hitmarker_width = gear:slider('Width', 1, 5, 0.3, 0.1),
			world_hitmarker_speed = gear:slider('Fade Time', 1, 5, 0.1, 0.1),
			world_hitmarker_length = gear:slider('Length', 1, 500, 200, 1),
			world_hitmarker_color = gear:color_picker("Color", definitions.default_primary_theme),
			world_hitmarker_glow = gear:switch("Glow", false),
			
		}
		return elements, true
	end),
	
	custom_scope_overlay = group_visuals:switch("Custom Scope Overlay", false, function(gear)
		local elements = {
			scope_color = gear:color_picker("Color", definitions.default_primary_theme),
			gapx = gear:slider('Offset X', 0, definitions.screen_size().x/2, 10, 1),
			gapy = gear:slider('Offset Y', 0, definitions.screen_size().y/2, 10, 1),
			offset = gear:slider('Width', 10, 500, 142, 1),
			sync_gap = gear:button("Automatic Alignment"),
		}
		return elements, true
	end),
	
	--aa_steal = group_aa_stealer:switch('Steal Enemy Anti Aim', false),
	-- aa_experiment = group_aa_experiment:switch("Enable Experimental AA", false, function(gear)
	-- 	local elements = {
	-- 		Type = gear:list("Preset Type", {"Distort", "Jitter", "Spin", "Sway Desync", "Randomized Desync"})
	-- 	}
	-- 	return elements, true
	-- end),
}

menuitems.fps_fix:set_callback(function(self)
	if not self:get() then
		for _, mat in ipairs(definitions.localplayer_materials) do
			mat:var_flag(2, false)
		end
		
		for _, mat in ipairs(definitions.team8s_materials) do
			mat:var_flag(2, false)
		end
		
		
		for _, mat in ipairs(definitions.team8s_weapon_materials) do
			mat:var_flag(2, false)
		end
		
		cheatmenu.self_chams:override()
		cheatmenu.teammates_chams:override()
		cheatmenu.teammates_weapon_chams:override()
	end
end)


menuitems.aspect_ratio:set_callback(function(self)
	cvar.r_aspectratio:float(self:get()/10)
end)

-- menuitems.switch_safe_taser_about:visibility(false)
-- menuitems.switch_safe_taser_about_btn:visibility(true)
-- menuitems.switch_safe_taser_about_btn:set_callback(function(self)
-- 	menuitems.switch_safe_taser_about:visibility(menuitems.switch_safe_taser_about:visibility() and false or true)
-- 	self:visibility(false)
-- end)


menuitems.nade_fix_about:visibility(false)
menuitems.nade_fix_about_btn:visibility(true)
menuitems.nade_fix_about_btn:set_callback(function(self)
	menuitems.nade_fix_about:visibility(menuitems.nade_fix_about:visibility() and false or true)
	self:visibility(false)
end)


menuitems.auto_tp_about:visibility(false)
menuitems.auto_tp_about_btn:visibility(true)
menuitems.auto_tp_about_btn:set_callback(function(self)
	menuitems.auto_tp_about:visibility(menuitems.auto_tp_about:visibility() and false or true)
	self:visibility(false)
end)

local logging_shot_color = menuitems.logs_enable.aimbot:color_picker(definitions.default_primary_theme)
local logging_death_color = menuitems.logs_enable.death:color_picker(definitions.default_secondary_theme)

-- extra menu items for sub tabs or gear icons"

menuitems.defensive_aa.disablers:set(1, 2) -- by default they are on
menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_custom_angle:visibility(false)
menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_custom_angle:visibility(false)


menuitems.defensive_aa_triggers:visibility(false)
menuitems.defensive_aa_pitch_enable:visibility(false)
menuitems.defensive_aa_yaw_enable:visibility(false)
menuitems.defensive_aa:set_callback(function(self)
	if self:get() then
		menuitems.defensive_aa_triggers:visibility(true)
		menuitems.defensive_aa_pitch_enable:visibility(true)
		menuitems.defensive_aa_yaw_enable:visibility(true)
	else
		menuitems.defensive_aa_triggers:visibility(false)
		menuitems.defensive_aa_pitch_enable:visibility(false)
		menuitems.defensive_aa_yaw_enable:visibility(false)
	end
end)

menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_angle:set_callback(function()
	menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_custom_angle:set_visible(menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_angle:get() == 'Custom' and true or false)
end, false)

menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_angle:set_callback(function()
	menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_custom_angle:set_visible(menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_angle:get() == 'Custom' and true or false)
end, false)

function update_list_for_configs()
	local result = require("neverlose/mtools").FileSystem:ReadFolder("nl\\scripts\\knockout",true)
	definitions.current_configs = result
	-- lil extension fix
	for key, config_name in ipairs(definitions.current_configs) do
		definitions.current_configs[key] = config_name:match("(.+)%..+$")
	end
	menuitems.configs_list:update(definitions.current_configs)
	
	if #menuitems.configs_list:get() <= 0 then
		menuitems.configs_list:visibility(false)
	else
		menuitems.configs_list:visibility(true)
	end
end
	
update_list_for_configs() -- initial call needed

menuitems.export_button:set_callback(function()
	local config = pui.save()
    clipboard.set(json.stringify(config))
end)

menuitems.import_button:set_callback(function()
	local config = clipboard.get()
    pui.load(json.parse(config))
end)

-- create and save config
menuitems.configs_create:set_callback(function()
	if menuitems.configs_name:get() == "" or #menuitems.configs_name:get() <= 0 then
		local say_on_error = "KNOCKOUT ERROR: Please enter a valid config name"
		print_error(say_on_error)
		common.add_notify("KNOCKOUT ERROR", say_on_error)
		return
	end
    --clipboard.set(json.stringify(pui.save()))
	files.write("nl\\scripts\\knockout\\" .. menuitems.configs_name:get() .. ".txt", "", false)
	update_list_for_configs()
	
	menuitems.configs_name:set("")
end)

menuitems.configs_save:set_callback(function()
	if menuitems.configs_list:get() == "" then
		local say_on_error = "KNOCKOUT ERROR: Please select a valid config"
		print_error(say_on_error)
		common.add_notify("KNOCKOUT ERROR", say_on_error)
		return
	end
	
    clipboard.set(json.stringify(pui.save()))
	files.write("nl\\scripts\\knockout\\" .. menuitems.configs_list:get() .. ".txt", clipboard.get(), false)
	update_list_for_configs()
end)

-- delete config
menuitems.configs_delete:set_callback(function()
	if menuitems.configs_list:get() == "" or #menuitems.configs_list:get() <= 0 then
		local say_on_error = "KNOCKOUT ERROR: No configs to delete."
		print_error(say_on_error)
		common.add_notify("KNOCKOUT ERROR", say_on_error)
		return
	end

	require("neverlose/mtools").FileSystem:DeleteFile("nl\\scripts\\knockout\\", menuitems.configs_list:get() .. ".txt", true)
	update_list_for_configs()
end)

-- load config
menuitems.configs_load:set_callback(function()
	if menuitems.configs_list:get() == "" or #menuitems.configs_list:get() <= 0 then
		local say_on_error = "KNOCKOUT ERROR: Please load a config that exists already."
		print_error(say_on_error)
		common.add_notify("KNOCKOUT ERROR", say_on_error)
		return
	end
	
	local file_path = "nl\\scripts\\knockout\\" .. menuitems.configs_list:get() .. ".txt"
	
	local config_content = files.read(file_path)
	
	clipboard.set(config_content)
	
	local load_config = json.parse(clipboard.get())
	
	pui.load(load_config)

	local say_on_load = "Loaded '" .. menuitems.configs_list:get() .. "' lua configuration."
	
	print(say_on_load)
	common.add_notify("KNOCKOUT", say_on_load)
	
	menuitems.configs_currently_loaded:name("Currently loaded: " .. menuitems.configs_list:get())
end)


menuitems.custom_scope_overlay.sync_gap:set_callback(function(self)
	menuitems.custom_scope_overlay.gapx:set(menuitems.custom_scope_overlay.gapy:get())
end)

-- aa builder
for _, state_aa in pairs(definitions.player_states) do

        local state_aa_group = pui.create("Conditional-AA", state_aa, 2)
		
        menuitems._builder_aa[state_aa] = {
            Pitch = state_aa_group:combo("Pitch", {"Disabled", "Down", "Fake Down", "Fake Up"}),
            Yaw_base = state_aa_group:combo("Yaw Base", {"Disabled", "Backward", "Static"}),
            Yaw_direction = state_aa_group:combo("Yaw Direction", {"Local View", "At Target"}),
            Yaw = state_aa_group:slider("Yaw Offset", -180, 180, 0, 1),
            Yaw_mod = state_aa_group:combo("Jitter Type", {"Disabled", "Center", "Offset", "Random", "Spin", "3-Way", "5-Way"}),
            jitter_range = state_aa_group:slider("Range", -180, 180, 0, 1),
            Desync = state_aa_group:switch("Desync", false),
            Inverter = state_aa_group:switch("Inverter", false),
            left_limit = state_aa_group:slider("Left Desync Angle", 0, 60, 60, 1),
            right_limit = state_aa_group:slider("Right Desync Angle", 0, 60, 60, 1),
            Options = state_aa_group:selectable("Desync Options", {"Avoid Overlap", "Jitter", "Randomize Jitter", "Anti Bruteforce"}),
            Freestand = state_aa_group:combo("Freestanding Options", {"Off", "Peek Fake", "Peek Real"})
        }
		
        --pui.setup(menuitems._builder_aa[state_aa])
end

-- create lua dir
files.create_folder("nl\\scripts\\knockout")

-- setup pui
menuitems.flashCSGO:tooltip("When tabbed out, CS:GO icon in the taskbar will flash indicating a round's beginning.")
pui.setup(menuitems)

-- welcome message
common.add_notify("Welcome " .. definitions.username(), "Let's get you up and ready for your next fight.")

-- clear table
local function clear_table(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

-- Flash the CSGO window when round starts
local function flashCSGOWindow()
    if not menuitems.flashCSGO:get() then return end
    local className = "Valve001"
    local windowName = "Counter-Strike: Global Offensive - Direct3D 9"

    -- Find the CSGO window
    local csgoWindow = ffi.C.FindWindowA(className, windowName)
    if csgoWindow == nil then
        print("CSGO window not found!")
        return
    end
    -- Flash the window indicating round start
    ffi.C.FlashWindow(csgoWindow, 1)
end

-- getting closest enemy function
local function getclosestenemy()
    local camera_position = render.camera_position()
	local camera_angles = render.camera_angles()
	local direction = vector():angles(camera_angles)

    local closest_distance, closest_enemy = math.huge
    for _, enemy in ipairs(entity.get_players(true)) do
        local ray_distance = enemy:get_hitbox_position(1):dist_to_ray(camera_position, direction)
        if ray_distance < closest_distance then
                closest_distance = ray_distance
				if not enemy:is_alive() then return end
				
				closest_enemy = enemy
        end
    end
    return closest_enemy
end

local function get_network_state(player)
    if not player then return end
    local _player_dormancy
    if player:get_network_state() == 0 then
        _player_dormancy = definitions.player_dormancies.NOT_DORMANT
    elseif player:get_network_state() == 1 then
        _player_dormancy = definitions.player_dormancies.CHEAT_CONFIDENCE
    elseif player:get_network_state() == 2 then
        _player_dormancy = definitions.player_dormancies.SHARED_ESP
    elseif player:get_network_state() == 3 then
        _player_dormancy = definitions.player_dormancies.SOUNDS
    elseif player:get_network_state() == 4 then
        _player_dormancy = definitions.player_dormancies.NOT_UPDATED
    elseif player:get_network_state() == 5 then
        _player_dormancy = definitions.player_dormancies.DATA_EXPIRED
    end
    return _player_dormancy
end


local function get_player_state(player)
    -- enemy data we need for our anti aim and ragebot
    local e_onground = player:get_anim_state().on_ground
    local e_crouching = player:get_anim_state().anim_duck_amount
    local e_landing = player:get_anim_state().landing
    local e_feet_crossed = player:get_anim_state().feet_crossed
    local e_velocity = math.floor(player:get_anim_state().speed_as_portion_of_run_top_speed * 10) -- this at least gives us stand, walk and run velocity
    local e_eye_pitch = player:get_anim_state().eye_pitch
    local e_eye_yaw = player:get_anim_state().eye_yaw
	
	local get_state_render = nil

    if (e_onground) and (e_velocity < 2) and not (e_velocity >= 9) and not (e_velocity == 3) and (e_crouching == 0) then get_state_render = definitions.player_states.STAND
    elseif e_onground and e_crouching > 0.5 then get_state_render = definitions.player_states.CROUCH
    elseif not e_onground and e_crouching == 1 then get_state_render = definitions.player_states.AIR_CROUCH
    elseif not e_onground and e_crouching < 1 then get_state_render = definitions.player_states.AIR
    elseif cheatmenu.get_slowwalk:get() then get_state_render = definitions.player_states.WALK
    elseif e_onground and e_velocity > 4 then get_state_render = definitions.player_states.RUN
    end
	
    return get_state_render 
end


local function get_weapon_name(player)
    if not player:get_player_weapon() then return end
    I_weapon = player:get_player_weapon():get_weapon_info().weapon_name
    return I_weapon
end

for state, settings in pairs(menuitems._builder_aa) do
	if menuitems.select_aa_state:get() == state then
		settings.Pitch:visibility(true)
		settings.Yaw_base:visibility(true)
		settings.Yaw_direction:visibility(true)
		settings.Yaw:visibility(true)
		settings.Yaw_mod:visibility(true)
		settings.jitter_range:visibility(true)
		settings.Desync:visibility(true)
		settings.Inverter:visibility(true)
		settings.left_limit:visibility(true)
		settings.right_limit:visibility(true)
		settings.Options:visibility(true)
		settings.Freestand:visibility(true)
	else
		settings.Pitch:visibility(false)
		settings.Yaw_base:visibility(false)
		settings.Yaw_direction:visibility(false)
		settings.Yaw:visibility(false)
		settings.Yaw_mod:visibility(false)
		settings.jitter_range:visibility(false)
		settings.Desync:visibility(false)
		settings.Inverter:visibility(false)
		settings.left_limit:visibility(false)
		settings.right_limit:visibility(false)
		settings.Options:visibility(false)
		settings.Freestand:visibility(false)
	end
end

menuitems.select_aa_state:set_callback(function(e)
	for state, settings in pairs(menuitems._builder_aa) do
		if e:get() == state then
			settings.Pitch:visibility(true)
			settings.Yaw_base:visibility(true)
			settings.Yaw_direction:visibility(true)
			settings.Yaw:visibility(true)
			settings.Yaw_mod:visibility(true)
			settings.jitter_range:visibility(true)
			settings.Desync:visibility(true)
			settings.Inverter:visibility(true)
			settings.left_limit:visibility(true)
			settings.right_limit:visibility(true)
			settings.Options:visibility(true)
			settings.Freestand:visibility(true)
		else
			settings.Pitch:visibility(false)
			settings.Yaw_base:visibility(false)
			settings.Yaw_direction:visibility(false)
			settings.Yaw:visibility(false)
			settings.Yaw_mod:visibility(false)
			settings.jitter_range:visibility(false)
			settings.Desync:visibility(false)
			settings.Inverter:visibility(false)
			settings.left_limit:visibility(false)
			settings.right_limit:visibility(false)
			settings.Options:visibility(false)
			settings.Freestand:visibility(false)
		end
	end
end)


function overlay_custom_scope()
-- custom scope overlay
	if menuitems.custom_scope_overlay:get() and definitions.localplayer()["m_bIsScoped"] then
		cheatmenu.scope_overlay:override("Remove All")
		-- right
		render.line(
			vector(definitions.screen_size().x/2 + menuitems.custom_scope_overlay.gapx:get(), definitions.screen_size().y/2),
			vector(definitions.screen_size().x/2 + menuitems.custom_scope_overlay.gapx:get() + menuitems.custom_scope_overlay.offset:get(), definitions.screen_size().y/2),
			menuitems.custom_scope_overlay.scope_color:get()
		)
		
		-- top
		render.line(
			vector(definitions.screen_size().x/2, definitions.screen_size().y/2 - menuitems.custom_scope_overlay.gapy:get()),
			vector(definitions.screen_size().x/2, definitions.screen_size().y/2 - menuitems.custom_scope_overlay.gapy:get() - menuitems.custom_scope_overlay.offset:get()),
			menuitems.custom_scope_overlay.scope_color:get()
		)

		-- left
		render.line(
			vector(definitions.screen_size().x/2 - menuitems.custom_scope_overlay.gapx:get(), definitions.screen_size().y/2),
			vector(definitions.screen_size().x/2 - menuitems.custom_scope_overlay.gapx:get() - menuitems.custom_scope_overlay.offset:get(), definitions.screen_size().y/2),
			menuitems.custom_scope_overlay.scope_color:get()
		)
		
		-- bottom
		render.line(
			vector(definitions.screen_size().x/2, definitions.screen_size().y/2 + menuitems.custom_scope_overlay.gapy:get()),
			vector(definitions.screen_size().x/2, definitions.screen_size().y/2 + menuitems.custom_scope_overlay.gapy:get() + menuitems.custom_scope_overlay.offset:get()),
			menuitems.custom_scope_overlay.scope_color:get()
		)
	end
end

--[[local elapsed_time = 0
local duration = 1

function linear_interp(start_val, end_val)
	if elapsed_time < duration then
		elapsed_time = elapsed_time + (globals.absoluteframetime * 10)
		local t = math.min(elapsed_time / duration, 1)
		local interp_val = start_val + (end_val - start_val) * t	
		return interp_val
	end
end

function linear_interp_reverse(start_val, end_val)
	if elapsed_time < duration then
		elapsed_time = elapsed_time + (globals.absoluteframetime * 10)
		local t = math.min(elapsed_time / duration, 1)
		local interp_val = end_val + (start_val - end_val) * t
		return interp_val
	end
end]]


local indicators = {
	"KNOCKOUT",
	"DT",
	"HS",
	"DMG: ",
	"LC"
}

local shift = 1

function render_indicators()
	if menuitems.under_crosshair:get() then
		local default_indicator_pos = vector(definitions.screen_size().x/2, definitions.screen_size().y/2 + 15)
		local alpha = definitions.localplayer().m_bIsScoped and 80 or menuitems.under_crosshair.name_color:get().a
		local indicator_color = color(menuitems.under_crosshair.name_color:get().r, menuitems.under_crosshair.name_color:get().g, menuitems.under_crosshair.name_color:get().b, alpha)
		local right_arrow_color = rage.antiaim:inverter() and color(0, 0, 0, 50) or indicator_color
		local left_arrow_color = rage.antiaim:inverter() and indicator_color or color(0, 0, 0, 50)

		-- sum animation
		shift = definitions.localplayer().m_bIsScoped and shift + 0.5 or shift - 0.5
		if shift > 10 then shift = 10 end
		if shift < 1 then shift = 1 end

		default_indicator_pos.x = default_indicator_pos.x + shift

		-- texts
		for	i in pairs(indicators) do
			indicator_color = color(menuitems.under_crosshair.name_color:get().r, menuitems.under_crosshair.name_color:get().g, menuitems.under_crosshair.name_color:get().b, alpha)

			default_indicator_pos.y = default_indicator_pos.y + 10

			if i == 2 then
				indicator_color = cheatmenu.Double_tap:get() and indicator_color or color(0, 0, 0, alpha)

			elseif i == 3 then
				indicator_color = cheatmenu.Hide_shot:get() and indicator_color or color(0, 0, 0, alpha)
			elseif i == 4 then
				indicators[i] = "DMG: " .. cheatmenu.min_dmg:get()
			elseif i == 5 and not definitions.render_lc_indicator then
				indicator_color = color(0, 0, 0, alpha)
			end
			
	
			render.text(
				2,
				default_indicator_pos,
				indicator_color,
				"s", 
				indicators[i]
			)
		end


		--left arrow
		render.poly(
			left_arrow_color,
			vector(definitions.screen_size().x/2 + 70, definitions.screen_size().y/2),
			vector(definitions.screen_size().x/2 + 70, definitions.screen_size().y/2),
			
			vector(definitions.screen_size().x/2 + 50, definitions.screen_size().y/2 + 10),
			vector(definitions.screen_size().x/2 + 50, definitions.screen_size().y/2 + 10),
			
			vector(definitions.screen_size().x/2 + 50, definitions.screen_size().y/2 - 10),
			vector(definitions.screen_size().x/2 + 50, definitions.screen_size().y/2 - 10)
		)
		-- right arrow
		render.poly(
			right_arrow_color,
			vector(definitions.screen_size().x/2 - 70, definitions.screen_size().y/2),
			vector(definitions.screen_size().x/2 - 70, definitions.screen_size().y/2),

			vector(definitions.screen_size().x/2 - 50, definitions.screen_size().y/2 - 10),
			vector(definitions.screen_size().x/2 - 50, definitions.screen_size().y/2 - 10),

			vector(definitions.screen_size().x/2 - 50, definitions.screen_size().y/2 + 10),
			vector(definitions.screen_size().x/2 - 50, definitions.screen_size().y/2 + 10)
		)
	end
end

function run_disable_rendering_models(ui_element)
	if menuitems.fps_fix:get() then
		-- why the fuck am I running 3 for loops here? THIS IS TERRIBLE PRACTICE. DON'T COPY. THIS FUNCTION IS WRITTEN BY A SPED.
	
		for _, mat in ipairs(definitions.localplayer_materials) do
			if ui_element:get(2) then
				cheatmenu.self_chams:override(true)
				mat:var_flag(2, true)
			else
				cheatmenu.self_chams:override()
				mat:var_flag(2, false)
			end	
		end
		
		for _, mat in ipairs(definitions.team8s_materials) do
			if ui_element:get(3) then
				cheatmenu.teammates_chams:override(true)
				mat:var_flag(2, true)
			else
				mat:var_flag(2, false)
				cheatmenu.teammates_chams:override()
			end	
		end
		
		for _, mat in ipairs(definitions.team8s_weapon_materials) do
			if ui_element:get(3) then
				cheatmenu.teammates_weapon_chams:override(true)			
				mat:var_flag(2, true)
			else
				mat:var_flag(2, false)
				cheatmenu.teammates_weapon_chams:override()
			end	
		end
	end
end

function run_ragebot_fps_fix()
	if menuitems.fps_fix:get() and menuitems.fps_fix.mitigations:get(1) then
		if entity.get_threat(true) or (getclosestenemy() and getclosestenemy():is_visible()) then
			cheatmenu.rage_main:override(true)
		else
			cheatmenu.rage_main:override(false)
		end
	else
		cheatmenu.rage_main:override()
	end
end

local function nade_held()
	if get_weapon_name(entity.get_local_player()) == "weapon_smokegrenade" or get_weapon_name(entity.get_local_player()) == "weapon_hegrenade" or get_weapon_name(entity.get_local_player()) == "weapon_flashgrenade" or get_weapon_name(entity.get_local_player()) == "weapon_incgrenade" or get_weapon_name(entity.get_local_player()) == "weapon_molotov" then
		return true
	end
	return false
end

function run_break_lc(in_air, cmd)   
    if menuitems.ourexploit:get() and cheatmenu.Double_tap:get() and in_air and not nade_held() then
		if not entity.get_threat(true) then return end
		if menuitems.ourexploit.only_safe_head:get() and not cmd.in_duck then return end
		if globals.tickcount % 1.2 == 0.000 then
			definitions.render_lc_indicator = true
			cheatmenu.Double_tap:override(false)
        else
			definitions.render_lc_indicator = false
            cheatmenu.Double_tap:override()
        end
    else
		definitions.render_lc_indicator = false
        cheatmenu.Double_tap:override()   
    end
end

function run_nade_fix()
 -- nade fix
    if menuitems.nade_fix:get() then
        if get_weapon_name(definitions.localplayer()) == "weapon_smokegrenade" or get_weapon_name(definitions.localplayer()) == "weapon_hegrenade" or get_weapon_name(definitions.localplayer()) == "weapon_flashgrenade" or get_weapon_name(definitions.localplayer()) == "weapon_incgrenade" or get_weapon_name(definitions.localplayer()) == "weapon_molotov" then
            cheatmenu.Double_tap:override(false)
            cheatmenu.Double_tap:override(false)
        else
            cheatmenu.Hide_shot:override()
            cheatmenu.Double_tap:override()
        end
    end
end

function run_leg_breaker()
	-- leg breaker
    if menuitems.leg_fucker:get() then
        cheatmenu.get_legmovement:override(globals.tickcount % 40 < 30 and "Walking" or "Sliding")
    else
        cheatmenu.get_legmovement:override()
    end
end


function run_update_conditional_aa()
	-- conditional aa
	if menuitems.enable_conditional_aa:get() then
		for state, settings in pairs(menuitems._builder_aa) do
			if get_player_state(definitions.localplayer()) == state then
				cheatmenu.get_pitch:override(settings.Pitch:get())
				cheatmenu.get_yawbase:override(settings.Yaw_direction:get())
				cheatmenu.get_yawbase_angle:override(settings.Yaw_base:get())
				cheatmenu.get_yawbase_offset:override(settings.Yaw:get())
				cheatmenu.get_yaw_mod:override(settings.Yaw_mod:get())
				cheatmenu.get_yaw_mod_degree:override(settings.jitter_range:get())
				cheatmenu.get_fakeangles_enabled:override(settings.Desync:get())
				cheatmenu.inverter:override(settings.Inverter:get())
				cheatmenu.leftlimit:override(settings.left_limit:get())
				cheatmenu.rightlimit:override(settings.right_limit:get())
				cheatmenu.get_fakeangles_options:override(settings.Options:get())
				cheatmenu.get_freestanding_options:override(settings.Freestand:get())
			end
		end
	end
end

function run_defensive_aa(cmd, in_air)
    -- defensive aa
    if menuitems.defensive_aa:get() then -- our main switch
		--cmd.force_defensive = true
		
		-- if no triggers do nothing
		if #menuitems.defensive_aa_triggers:get() ~= 0 then
	
			-- remove all overrides before changing so we make sure only our specified conditions can trigger defensive
			cheatmenu.get_yawbase_offset:override()
			cheatmenu.get_pitch:override()
		
			-- if fake ducking do nothing
			if not cheatmenu.get_fakeduck:get() then
				local triggers = menuitems.defensive_aa_triggers
				-- in air check
				if triggers:get(1) and not in_air then return end
				-- threat check
				if triggers:get(2) and entity.get_threat(true) == nil then return end

				-- force defensive before checking for disablers
				if menuitems.defensive_aa.force_defensive:get() then
					cmd.force_defensive = true
				end

				-- disablers check (on knfie out)
				if menuitems.defensive_aa.disablers:get(1) and get_weapon_name(definitions.localplayer()) == 'weapon_knife' then return end

				-- disablers check (on fake lag)
				if menuitems.defensive_aa.disablers:get(2) and (not cheatmenu.Double_tap:get() and not cheatmenu.Hide_shot:get()) and cheatmenu.get_fakelag:get() then return end
				
				-- disablers check (on taser pull out)
				if menuitems.defensive_aa.disablers:get(3) and get_weapon_name(definitions.localplayer()) == 'weapon_taser' then return end


				if math.floor(globals.realtime * 1000) % 3 == 2 then
					-- our flick var
					definitions.jitter_side = definitions.jitter_side * -1 -- this var always returns either 1 or -1. So you can think of it as ON and OFF.
					-- pitch
					if menuitems.defensive_aa_pitch_enable:get() then
						if menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_angle:get() == 'Custom' then
							-- if custom angle is set
							cheatmenu.get_pitch:override('Disabled')
							
							cmd.view_angles.x = menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_custom_angle:get()
						elseif menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_angle:get() == 'Random' then
							cheatmenu.get_pitch:override('Disabled')
							cmd.view_angles.x = math.random(-89, 89)
						else
							-- preset angle (45, 90, 180, etc)
							cheatmenu.get_pitch:override(menuitems.defensive_aa_pitch_enable.defensive_aa_pitch_angle:get())
						end
					end
					
					-- yaw
					if menuitems.defensive_aa_yaw_enable:get() then
						if menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_angle:get() == 'Custom' then
							-- custom angle
							cheatmenu.get_yawbase_offset:override(definitions.jitter_side > 0 and menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_custom_angle:get() or menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_custom_angle:get() * -1)
						elseif menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_angle:get() == 'Spin' then
							-- spinning
							definitions.spin_angle = definitions.spin_angle + 20
							if definitions.spin_angle >= 180 then definitions.spin_angle = -180 end
							cheatmenu.get_yawbase_offset:override(definitions.spin_angle)
						elseif menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_angle:get() == 'Random' then
							cheatmenu.get_yawbase_offset:override(math.random(-180, 180))
						else
							-- preset angle
							cheatmenu.get_yawbase_offset:override(definitions.jitter_side > 0 and tonumber(menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_angle:get()) or tonumber(menuitems.defensive_aa_yaw_enable.defensive_aa_yaw_angle:get()) *-1 ) 
						end
					end
				end
			end
		end
    end
end

-- function to check our inventory
function do_I_have_taser()
	local inventory = definitions.localplayer():get_player_weapon(true)
	for i in pairs(inventory) do
		local name = inventory[i]:get_weapon_info().weapon_name
		if name == "weapon_taser" then
			return true
		end
	end
	return inventory[2]:get_weapon_info().weapon_name
end

function run_safety_swap()

	  -- SAFETY SWAP GUN
    if menuitems.switch_safe_taser:get() then

	
		local closest_enemy = getclosestenemy()
		
		if closest_enemy ~= nil then
		
			local my_origin = definitions.localplayer():get_origin()
			local enemy_origin = closest_enemy:get_origin()
			local my_dist_to_enemy = enemy_origin:dist(my_origin)
			
			-- if the enemy is in range
			if my_dist_to_enemy < menuitems.switch_safe_taser.range:get() then

				local enemy_weapon_name = get_weapon_name(closest_enemy)
		
				
				if enemy_weapon_name == "weapon_taser" then

					definitions.alreadypulledtaser = definitions.alreadypulledtaser + 1
					
					if definitions.alreadypulledtaser < 1 then

						
						if menuitems.switch_safe_taser.equip_items:get() == "Taser (falls back to secondary if not available)" then
							local have_taser = do_I_have_taser()
							
							if have_taser == true then
								utils.console_exec("use weapon_taser")
							else
								utils.console_exec("use " .. have_taser)
							end

						elseif menuitems.switch_safe_taser.equip_items:get() == "Next Available (any weapon)" then
							utils.console_exec("INVNEXTGUN")
						end
					end
				end
			else
				definitions.alreadypulledtaser = 0
			end
		end
    end
end

function run_auto_tp(in_air)
	if menuitems.auto_tp:get() then
		if menuitems.auto_tp.type_of_tp:get() == 1 then
			if in_air and entity.get_threat(true) then
				if definitions.tp_once then
					cheatmenu.Double_tap:override(false)
					definitions.tp_once = false
				end
			else
				definitions.tp_once = true
				cheatmenu.Double_tap:override()
			end
		elseif menuitems.auto_tp.type_of_tp:get() == 2 then
			local our_trace_start = definitions.localplayer():get_origin()
			local our_trace_end = vector(definitions.localplayer():get_origin().x, definitions.localplayer():get_origin().y, definitions.localplayer():get_origin().z - definitions.our_trace_z_offset)
			
			-- if on ground
			if definitions.localplayer():get_anim_state().duration_in_air >= definitions.check_for_tp_after_air_duration then
			
				if entity.get_threat(true) == nil then return end
				
				local our_trace = utils.trace_line(our_trace_start, our_trace_end)
			
				-- start stretching trace Z pos until it hits something then checking the distance between us and the ground (or whatever below us)
				-- if this distance is less than x -> teleport
			
				if our_trace:did_hit() then
					local distance_from_ground = math.abs(our_trace_start.z - our_trace.end_pos.z)
					if distance_from_ground <= 27 then
						if definitions.tp_once then
							rage.exploit:force_teleport()
							definitions.tp_once = false
						end
					end	
				else
					definitions.our_trace_z_offset = definitions.our_trace_z_offset + 200
					definitions.tp_once = true
				end
			else
				definitions.our_trace_z_offset = 0
			end
		end
	end
end

-- under contruction
function run_anti_bruteforce()
	-- checking if we are alive and enemy isn't nil
	-- initial desync switch on threat
	if entity.get_threat(true) then
		if definitions.set_who_we_met_first then
			definitions.who_we_met_first = entity.get_threat(true)
			cheatmenu.inverter:set(cheatmenu.inverter:get() and false or true)
			definitions.set_who_we_met_first = false
		end
	end

	-- if we are dead or if the guy who shot is not who we just saw 
	if definitions.entity_that_shot ~= definitions.who_we_met_first then
		definitions.bullet_start_pos = nil
		definitions.bullet_end_pos = nil
		cheatmenu.inverter:override()
		cheatmenu.rightlimit:override()
		cheatmenu.leftlimit:override()
		definitions.bruteforce_counter = 0
		return
	end
	
	-- if the person who shot was the one we first initially met or peeked (or they peeked)
	
	-- checking if enemy has shot
	if definitions.bullet_start_pos ~= nil and definitions.bullet_end_pos ~= nil then
		-- enemy and bullet vector calc
		local vec_from_enemy_to_bullet_impact = definitions.bullet_end_pos - definitions.bullet_start_pos
		local magnitude_of_enemy_to_bullet_impact = definitions.bullet_end_pos:dist(definitions.bullet_start_pos)
		
		-- shot angle calc
		local dot_product = (definitions.vec_from_enemy_to_me.x * vec_from_enemy_to_bullet_impact.x) + (definitions.vec_from_enemy_to_me.y * vec_from_enemy_to_bullet_impact.y) + (definitions.vec_from_enemy_to_me.z * vec_from_enemy_to_bullet_impact.z)
		local cosine_of_angle = dot_product / (definitions.magnitude_from_enemy_to_me * magnitude_of_enemy_to_bullet_impact)
		
		-- shot side calc
		local cross_product = vector(
			definitions.vec_from_enemy_to_me.y * vec_from_enemy_to_bullet_impact.z - definitions.vec_from_enemy_to_me.z * vec_from_enemy_to_bullet_impact.y,
			definitions.vec_from_enemy_to_me.z * vec_from_enemy_to_bullet_impact.x - definitions.vec_from_enemy_to_me.x * vec_from_enemy_to_bullet_impact.z, 
			definitions.vec_from_enemy_to_me.x * vec_from_enemy_to_bullet_impact.y - definitions.vec_from_enemy_to_me.y * vec_from_enemy_to_bullet_impact.x
		)
		
		local calc_angle = 180 - math.floor(math.deg(math.acos(cosine_of_angle)))
		local calc_side = cross_product:normalized().z * -1 -- -1 cuz 0 yaw is facing backwards
		
		if calc_angle > 60 then return end
		-- setting the angle's sign to check for side
		if calc_side < 0 then
			-- represent angle based on which side the bullet was shot
			calc_angle  = calc_angle * -1
		end
		
		calc_side = calc_side > 0 and "right" or "left"
		
		-- run Bruteforce logic (user custom)
		--definitions.bruteforce_counter = definitions.bruteforce_counter + 1
		
		-- run bruteforce logic (automated)
		--[[local angle_factor = 35
		if calc_side == "right" then
			cheatmenu.inverter:set(false)
			local adjusted_angle = calc_angle
			if calc_angle >= 50 then
				adjusted_angle = adjusted_angle - angle_factor
			elseif calc_angle <= 10 then
				adjusted_angle = adjusted_angle + angle_factor
			end
			cheatmenu.rightlimit:override(adjusted_angle)
		elseif calc_side == "left" then
			cheatmenu.inverter:set(true)
			local adjusted_angle = calc_angle
			if calc_angle <= -50 then
				adjusted_angle = adjusted_angle + angle_factor
			elseif calc_angle >= -10 then
				adjusted_angle = adjusted_angle - angle_factor
			end
			cheatmenu.leftlimit:override(adjusted_angle)
		end]]

	
		--[[if definitions.log_angle_once then
			--print(calc_angle)
			utils.console_exec("say " .. "KNOCKOUT: " .. definitions.entity_that_shot:get_name() .. " Shot " .. tostring(calc_angle) .. " degrees to the " .. calc_side)
			definitions.log_angle_once = false
		end]]
	end
end


local function run_non_desync_aa(in_air, cmd)

	if menuitems.aa_experiment:get() then

		if cmd.in_attack == 1 or nade_held() or definitions.localplayer():get_anim_state().ladder_speed <= 0 or menuitems.defensive_aa:get() then 
			cheatmenu.get_antiaim:override()
			return 
		end

		cheatmenu.get_antiaim:override(false)
		
		local cur_target = entity.get_threat()

		if cur_target ~= nil then
		
			-- getting at target yaw
			local enemy_pos = cur_target:get_origin()
			local direction = enemy_pos - definitions.localplayer():get_origin()
			local target_yaw = math.deg(math.atan2(direction.y, direction.x))
			target_yaw = target_yaw + 180

			-- setting pitch
			cmd.view_angles.x = 89
			
			if menuitems.aa_experiment.Type:get() == 1 then
				-- distortion
				if definitions.distortion_cur_angle > definitions.distortion_minmax[2] then
					definitions.swing_right = false
				elseif definitions.distortion_cur_angle < definitions.distortion_minmax[1] then
					definitions.swing_right = true		
				end
				if definitions.swing_right then
					definitions.distortion_cur_angle = definitions.distortion_cur_angle + (math.abs(definitions.distortion_minmax[2] / 2) + math.random(-10, 10))
				else
					definitions.distortion_cur_angle = definitions.distortion_cur_angle - (math.abs(definitions.distortion_minmax[2] / 2) + math.random(-10, 10))
				end
				--cheatmenu.get_yawbase_offset:override(definitions.distortion_cur_angle)
				cmd.view_angles.y = target_yaw + definitions.distortion_cur_angle
			elseif menuitems.aa_experiment.Type:get() == 2 then
				-- jitter
				local jitter_angles = {-math.random(-60, 40), math.random(-40, 60)}
				
				if #definitions.old_angles == 0 then
					definitions.old_angles[1] = jitter_angles[1]
					definitions.old_angles[2] = jitter_angles[2]
				else
					--print_dev(jitter_angles[1], " ", definitions.old_angles[1], " ", jitter_angles[2], " ", definitions.old_angles[2])
					if definitions.old_angles[1] == jitter_angles[1] or definitions.old_angles[2] == jitter_angles[2] then return end
				end
					
				definitions.jitter_idx = definitions.jitter_idx + 1
				
				if definitions.jitter_idx > # jitter_angles then definitions.jitter_idx = 1 end
				
				local cur_angle = jitter_angles[definitions.jitter_idx]
				
				cmd.view_angles.y = target_yaw + cur_angle
				
			elseif menuitems.aa_experiment.Type:get() == 3 then
				-- spin
				if entity.get_threat(true) then
					cheatmenu.get_antiaim:override()
				else
					definitions.spin_factor = definitions.spin_factor + 25
					cmd.view_angles.y = cmd.view_angles.y + definitions.spin_factor
				end
			elseif menuitems.aa_experiment.Type:get() == 4 then
				cheatmenu.get_antiaim:override()
				
				--sway desync
				if definitions.sway_add_desync > 60 or definitions.sway_add_desync < 0 then
					definitions.sway_add_factor = definitions.sway_add_factor * -1
				end
				definitions.sway_add_desync = definitions.sway_add_desync + definitions.sway_add_factor
				cheatmenu.leftlimit:override(definitions.sway_add_desync)
				cheatmenu.rightlimit:override(definitions.sway_add_desync)
			elseif menuitems.aa_experiment.Type:get() == 5 then
				cheatmenu.get_antiaim:override()
			
				-- random desync
				cheatmenu.rightlimit:override(math.random(10, 50))
				cheatmenu.leftlimit:override(math.random(10, 50))
			end

			-- run some smart anti aim logic
			-- check for priority target
			local priority = cur_target == entity.get_threat()


			
		else
			cmd.view_angles.y = cmd.view_angles.y + 180
		end
	else
		cheatmenu.get_antiaim:override()
	end
end

local function get_player_angles(player)
	local player_angles = nil
	local e_eye_pitch = math.ceil(player:get_anim_state().eye_pitch)
	local e_eye_yaw = math.floor(player:get_anim_state().eye_yaw)
	e_eye_yaw = ( ( e_eye_yaw - 360 ) * ( ( e_eye_yaw + 180) / 360 ) ) + 180
	
	-- check for freestanding ig?
	
	--[[if (e_eye_yaw >= 90 or e_eye_yaw <= -90) and player ~= entity.get_threat(true) then
		e_eye_yaw = e_eye_yaw >= 90 and 45 or -45
	end]]
	
	player_angles = {pitch = e_eye_pitch, yaw = e_eye_yaw}

	return player_angles
end


local function run_aa_stealer(cmd, in_air)
	if menuitems.aa_steal:get() then
		cheatmenu.get_pitch:override('Default')
		menuitems.enable_conditional_aa:override(false)
		local cur_threat = entity.get_threat()
		if cur_threat ~= nil then
			cheatmenu.get_yawbase_offset:override(get_player_angles(cur_threat).yaw)
			if not cmd.in_use and not cmd.in_attack and not nade_held() and definitions.localplayer():get_anim_state().ladder_speed <= 0 then
				cmd.view_angles.x = get_player_angles(cur_threat).pitch
			end
		else
			cheatmenu.get_yawbase_offset:override()
		end
	end

end


function run_killsay(e)
    -- killsay
    if menuitems.killsay_enable:get() then
        if e.target["m_iHealth"] == (0 or nil) then
            utils.console_exec("say " .. definitions.killsays[math.random(#definitions.killsays)])
        end
    end
end

function run_hideshots_ideal_tick()
    -- hideshots ideal tick XP -- ideal ticking with hideshots (kinda) (it's very interesting.)
    if menuitems.yallah_yallah:get() and cheatmenu.Hide_shot:get() and cheatmenu.get_autopeek:get() then
        --rage.exploit:force_teleport()
        cheatmenu.Hide_shot:override(false)
    else
        cheatmenu.Hide_shot:override()
    end
end


function run_shot_logs(e)
    if menuitems.logs_enable.aimbot:get() then
		local log_color = logging_shot_color:get():to_hex()
        local shot_entity = e.target
        local shot_entity_health_remaining = e.target["m_iHealth"]
        local shot_dmg = e.damage
        local shot_hitchance = e.hitchance
        local shot_BT = e.backtrack
        local shot_position = e.aim
        local shot_wanted_damage = e.wanted_damage
        local miss_reason = e.state

		-- checking for enemy's name to not be too long.
        if string.len(shot_entity:get_name()) >= 15 then
            toolong_logname = string.sub(shot_entity:get_name(), 1, 15) .. "..."
        else
            toolong_logname = shot_entity:get_name()
        end

        shot_hitbox = definitions.hitboxes[e.hitgroup]

        if shot_hitbox == nil then
            shot_hitbox = "generic"
        end

          -- set hit/miss var
		local hit_miss = miss_reason == nil and "HIT " or "MISSED "

		local log_prefix = definitions.white .. "KNOCKOUT: " .. "\a" .. log_color .. hit_miss .. definitions.white

		local log_string = ""

        if hit_miss == "HIT " then ----------------------------- IF WE HIT SHOT
			-- combining the rest of the log string
			-- checking how detailed the log should be
			if menuitems.logs_enable.complexity:get() == "Default" then
				log_string = log_prefix .. toolong_logname .. "'s ".. "\a" .. log_color .. shot_hitbox .. definitions.white .. " For " .. "\a" .. log_color .. shot_dmg .. definitions.white
			elseif menuitems.logs_enable.complexity:get() == "Detailed" then
				log_string = log_prefix .. toolong_logname .. "'s ".. "\a" .. log_color .. shot_hitbox .. definitions.white .. " For " .. "\a" .. log_color .. shot_dmg .. definitions.white .. " | Wanted Damage: " .. "\a" .. log_color .. shot_wanted_damage .. definitions.white .. " | Hitchance: " .. "\a" .. log_color .. shot_hitchance .. "%" .. definitions.white .. " | Backtracked: " .. "\a" .. log_color .. shot_BT .. " Ticks" .. definitions.white .. " | " .. "\a" .. log_color .. shot_entity_health_remaining .. definitions.white .. " Health Remaining."
			end
        else --------------------------------- IF WE MISSED SHOT
            -- combining the rest of the log string
			-- checking how detailed the log should be
			if menuitems.logs_enable.complexity:get() == "Default"  then
				log_string = log_prefix .. toolong_logname .. "'s ".. "\a" .. log_color .. shot_hitbox .. definitions.white .. " due to " .. "\a" .. logging_death_color:get():to_hex() .. string.upper(miss_reason) .. definitions.white .. "."
			elseif menuitems.logs_enable.complexity:get() == "Detailed"  then
				log_string = log_prefix .. toolong_logname .. "'s ".. "\a" .. log_color .. shot_hitbox .. definitions.white .. " due to " .. "\a" .. logging_death_color:get():to_hex() .. string.upper(miss_reason) .. definitions.white ..  " | " .. "\a" .. log_color .. " Hitchance: " .. shot_hitchance .. "%"  .. definitions.white .. " | Backtracked: " .. "\a" .. log_color .. shot_BT .. " Ticks" .. definitions.white .. " | " .. "\a" .. log_color .. shot_entity_health_remaining .. definitions.white .. " Health Remaining."
			end
        end

		if menuitems.logs_enable.location:get(1) then
			common.add_event(log_string)
		end

		if menuitems.logs_enable.location:get(2) then
			print_raw(log_string)
			-- spacing
			print("")
		end 
    end
end

local function run_death_logs(e)

    if menuitems.logs_enable.death:get() then

		local log_color = logging_death_color:get():to_hex()
	
        local event_info = {
            MYuserid = definitions.localplayer():get_player_info()['userid'],
            died_userid = e['userid'],
            -------------------------
            attacker = e['attacker'],
            weapon_used_to_kill = e['weapon'],
            was_headshot = e['headshot'],
            penetration = e['penetrated'],
            distance_to_me = e['distance'] -- distance to victim. -- this case it's localplayer()
        }

        -- enemy info
        local enemy = entity.get(event_info.attacker, true)
        local enemy_info = {
            enemy_name = enemy:get_name(),
            enemy_anim_state = enemy:get_anim_state(),
            enemy_origin = enemy:get_origin()
        }
  
        -- checking for enemy's name to not be too long.
        if string.len(enemy_info.enemy_name) >= 16 then
            toolong_logname_death = string.sub(enemy_info.enemy_name, 1, 16) .. "..."
        else
            toolong_logname_death = enemy_info.enemy_name
        end

		local str_hs_baim = event_info.was_headshot and "Headshoting" or "Baiming"
        --- the actual LOGGING ---
		-- no complexity for death logs
		local death_log = definitions.white .. "KNOCKOUT: " .. "\a" .. log_color .. "DEATH " .. definitions.white .. "from " .. toolong_logname_death .. "\a" .. log_color .. " " .. str_hs_baim  .. definitions.white .." you with " .. string.upper(event_info.weapon_used_to_kill) .. " from " .. math.floor(event_info.distance_to_me) .." meters away."

		if menuitems.logs_enable.location:get(1) then
			common.add_event(death_log)
		end
		if menuitems.logs_enable.location:get(2) then
			print_raw(death_log)
			-- spacing
			print("")
		end
    end
end

local function generate_random_directions()
	-- generate lines
	for i = 1, definitions.num_of_lines do 
		local theta = math.random() * 2 * math.pi
		local phi = math.acos(2 * math.random() - 1)
		local direction = {
			x = math.sin(phi) * math.cos(theta),
			y = math.sin(phi) * math.sin(theta),
			z = math.cos(phi)
		}
		-- add random direction to our table
		table.insert(definitions.new_random_directions, direction)
	end
end

-- start and end coordinates for our new lines
local function generate_new_line_postions(impact_point)
	for i, direction in ipairs(definitions.new_random_directions) do
		table.insert(definitions.new_lines_from_random_directions, 
		{
			start = vector(
				impact_point.x + (definitions.start_line_length + definitions.start_line_offset) * definitions.new_random_directions[i].x,
				impact_point.y + (definitions.start_line_length + definitions.start_line_offset) * definitions.new_random_directions[i].y,
				impact_point.z + (definitions.start_line_length + definitions.start_line_offset) * definitions.new_random_directions[i].z
			)
		})
	end
end

local function render_world_hitmarker(ctx)

	if not (#definitions.new_random_directions >= definitions.num_of_lines) then
		generate_random_directions()
		generate_new_line_postions(definitions.aim_points)
	end

	local max_line_length = menuitems.world_hitmarker.world_hitmarker_length:get()
	local hitmarker_speed = menuitems.world_hitmarker.world_hitmarker_speed:get()  / 10
	
	for i, line in ipairs(definitions.new_lines_from_random_directions) do
		if definitions.extending then
			-- extend until length hits max length
			definitions.end_line_length = definitions.end_line_length + hitmarker_speed
	
			if definitions.end_line_length >= max_line_length then
				definitions.end_line_length = max_line_length
				definitions.extending = false
			end
			
		else
			-- then bring the start pos to end pos (closing effect)
			definitions.start_line_length = definitions.start_line_length + hitmarker_speed
			
			if definitions.start_line_length >= definitions.end_line_length then
				definitions.start_line_length = definitions.start_line_offset
				definitions.end_line_length = 0
				return
			end
		end
		
		
		local start = vector(
			line.start.x + definitions.start_line_length * definitions.new_random_directions[i].x,
			line.start.y + definitions.start_line_length * definitions.new_random_directions[i].y,
			line.start.z + definitions.start_line_length * definitions.new_random_directions[i].z
		)
	
		local l_end = vector(
			line.start.x + definitions.end_line_length * definitions.new_random_directions[i].x,
			line.start.y + definitions.end_line_length * definitions.new_random_directions[i].y,
			line.start.z + definitions.end_line_length * definitions.new_random_directions[i].z
		)
		
		local flags = menuitems.world_hitmarker.world_hitmarker_glow:get() and "lwg" or "lw"

		-- render
		ctx:render(
			start,
			l_end,
			menuitems.world_hitmarker.world_hitmarker_width:get() / 10, 
			flags, 
			menuitems.world_hitmarker.world_hitmarker_color:get()
		)
	end
end

local function is_in_air()
	local prop = definitions.localplayer()["m_fFlags"]
    local air = (prop == 256 or prop == 262)
	if air then
		return true
	end
	return false
end


events.createmove:set(function(cmd)
	if definitions.localplayer() == nil then return end
	if not definitions.localplayer():is_alive() then return end

	local in_air = is_in_air()
	-- run_safety_swap()
	run_ragebot_fps_fix()
	run_disable_rendering_models(menuitems.fps_fix.mitigations)
	-- run_non_desync_aa(in_air, cmd)
	run_nade_fix()
	run_break_lc(in_air, cmd)
	run_leg_breaker()
	run_update_conditional_aa()
	run_defensive_aa(cmd, in_air)
	run_auto_tp(in_air)
	--run_aa_stealer(cmd, in_air)
end)

events.player_death:set(function(e)
	local who_died = entity.get(e.userid, true)
	if who_died == definitions.localplayer() then
		run_death_logs(e)
		definitions.bruteforce_counter = 0
		definitions.bullet_start_pos = nil
		definitions.bullet_end_pos = nil
		cheatmenu.inverter:override()
		cheatmenu.rightlimit:override()
		cheatmenu.leftlimit:override()
	end
end)

events.round_start:set(function()
	if menuitems.clan_taga:get() then
		cheatmenu.clantag_nl:override(false)
		common.set_clan_tag(menuitems.clan_taga.custom_clan_taga:get())
	end

	if definitions.localplayer() == nil then return end
	shot = 1
	flashCSGOWindow()
	definitions.localplayer():set_icon("https://img.icons8.com/?size=100&id=RqQeO1sLIHFS&format=png&color=000000")
end)

events.aim_ack:set(function(e)
	if definitions.localplayer() == nil then return end
	if not definitions.localplayer():is_alive() then return end
	run_killsay(e)
	run_hideshots_ideal_tick()
	run_shot_logs(e)
end)

events.render_glow:set(function(ctx)
	if definitions.localplayer() == nil then return end
	if menuitems.world_hitmarker:get() and definitions.aim_points ~= nil then
		-- if we are not alive or no shot positon is available return.
		-- render lines logic based of these points.
		render_world_hitmarker(ctx)
	end
end)


events.render:set(function()
	if definitions.localplayer() == nil then return end
	if not definitions.localplayer():is_alive() then return end
	overlay_custom_scope()
	render_indicators()
end)

events.bullet_impact:set(function(e)
	definitions.entity_that_shot = entity.get(e.userid, true)
	if definitions.entity_that_shot == entity.get_threat(true) then
		definitions.log_angle_once = true
		definitions.bullet_start_pos = definitions.entity_that_shot:get_origin()
		definitions.bullet_end_pos = vector(e.x, e.y, e.z)
		definitions.vec_from_enemy_to_me = definitions.entity_that_shot:get_origin() - definitions.localplayer():get_origin()
		definitions.magnitude_from_enemy_to_me = definitions.entity_that_shot:get_origin():dist(definitions.localplayer():get_origin())
		definitions.bruteforce_counter = definitions.bruteforce_counter + 1
	else
		definitions.bruteforce_counter = 0
	end
end)

events.aim_fire:set(function(e)
	-- on this event, clear any old line coordinates so that we only render hitmarker for one enemy at a time. Saves shit TON of FPS.
	clear_table(definitions.new_random_directions)
	clear_table(definitions.new_lines_from_random_directions)
	definitions.aim_points = nil

	-- one shot at a time. More = shit performance because more points and more rendering. WAY MORE rendering.
	definitions.aim_points = e.aim
	definitions.extending = true
	definitions.start_line_length = 0
	definitions.end_line_length = 0
end)

events.shutdown:set(function()
	for _, mat in ipairs(definitions.localplayer_materials) do
		mat:var_flag(2, false)
	end
	for _, mat in ipairs(definitions.team8s_materials) do
		mat:var_flag(2, false)
	end
	for _, mat in ipairs(definitions.team8s_weapon_materials) do
		mat:var_flag(2, false)
	end
	cheatmenu.self_chams:override()
	cheatmenu.teammates_chams:override()
	cheatmenu.teammates_weapon_chams:override()
    common.set_clan_tag("")
    cheatmenu.clantag_nl:override()
end)
