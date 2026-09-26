local obs = obslua
local ffi = require("ffi")

ffi.cdef[[
    int IsGameForeground(const char* exe_name);
    int GetForegroundProcessName(char* out_buf, int max_len);
]]

local function get_helper_path()
    local dir = ""
    if script_path then
        local sp = script_path()
        if sp then
            dir = sp:match("^(.*[/\\])") or ""
        end
    end
    if dir ~= "" then
        return dir .. "fg_helper.dll"
    end
    return "fg_helper.dll"
end

local helper_dll_path = get_helper_path()
local helper = ffi.load(helper_dll_path)

local game_source_name = "Game Capture"
local display_source_name = "Display Capture"
local check_interval = 250
local enabled = true

local last_state = -1 -- -1: init, 0: desktop, 1: in_game, 2: alt_tabbed

local function get_active_scene()
    local scene_source = obs.obs_frontend_get_current_scene()
    if scene_source ~= nil then
        return scene_source
    end

    scene_source = obs.obs_get_source_by_name("Scene")
    if scene_source ~= nil then
        return scene_source
    end

    local scenes = obs.obs_frontend_get_scenes()
    if scenes ~= nil and #scenes > 0 then
        scene_source = scenes[1]
        for i = 2, #scenes do
            obs.obs_source_release(scenes[i])
        end
        return scene_source
    end

    return nil
end

local function set_source_visibility(source_name, is_visible)
    local scene_source = get_active_scene()
    if scene_source == nil then
        return
    end

    local scene = obs.obs_scene_from_source(scene_source)
    if scene ~= nil then
        local item = obs.obs_scene_find_source(scene, source_name)
        if item ~= nil then
            local current_vis = obs.obs_sceneitem_visible(item)
            if current_vis ~= is_visible then
                obs.obs_sceneitem_set_visible(item, is_visible)
            end
        end
    end

    obs.obs_source_release(scene_source)
end

local function is_game_hooked()
    local source = obs.obs_get_source_by_name(game_source_name)
    if source == nil then
        return false, ""
    end

    local hooked = false
    local exe = ""

    local ph = obs.obs_source_get_proc_handler(source)
    if ph ~= nil then
        local cd = obs.calldata_create()
        obs.proc_handler_call(ph, "get_hooked", cd)
        hooked = obs.calldata_bool(cd, "hooked")
        exe = obs.calldata_string(cd, "executable") or ""
        obs.calldata_destroy(cd)
    end

    if not hooked then
        local width = obs.obs_source_get_width(source)
        if width > 0 then
            hooked = true
        end
    end

    obs.obs_source_release(source)
    return hooked, exe
end

local function check_timer()
    if not enabled then
        return
    end

    local hooked, exe = is_game_hooked()

    if hooked and exe ~= "" then
        local is_foreground = (helper.IsGameForeground(exe) == 1)

        if is_foreground then
            -- In game
            if last_state ~= 1 then
                last_state = 1
                set_source_visibility(display_source_name, false)
                set_source_visibility(game_source_name, true)
                obs.script_log(obs.LOG_INFO, string.format("[AutoToggle] In game (%s): Game ON, Display OFF (1:1 FPS)", exe))
            end
        else
            -- Alt-tabbed
            if last_state ~= 2 then
                last_state = 2
                set_source_visibility(display_source_name, true)
                set_source_visibility(game_source_name, false)
                obs.script_log(obs.LOG_INFO, string.format("[AutoToggle] Alt-Tabbed: Display ON, Game OFF (%s in background)", exe))
            end
        end
    else
        -- Desktop (no game)
        if last_state ~= 0 then
            last_state = 0
            set_source_visibility(display_source_name, true)
            set_source_visibility(game_source_name, true)
            obs.script_log(obs.LOG_INFO, "[AutoToggle] Desktop mode: Display ON, Game ready")
        end
    end
end

function script_description()
    return "Auto Game / Display Capture Switcher for OBS Studio:\n\n" ..
           "- In Game: Automatically hides Display Capture to eliminate DWM 280Hz polling overhead and give 1:1 native FPS.\n" ..
           "- Alt-Tabbed / Desktop: Automatically reveals Display Capture and hides Game Capture to capture your desktop seamlessly.\n" ..
           "- No Game: Display Capture is active, Game Capture is waiting for any game to launch."
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_bool(props, "enabled", "Enable Auto Switcher")

    local p_game = obs.obs_properties_add_list(props, "game_source", "Game Capture Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local p_disp = obs.obs_properties_add_list(props, "display_source", "Display Capture Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)

    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, s in ipairs(sources) do
            local s_id = obs.obs_source_get_id(s)
            local s_name = obs.obs_source_get_name(s)
            if s_id == "game_capture" then
                obs.obs_property_list_add_string(p_game, s_name, s_name)
            elseif s_id == "monitor_capture" then
                obs.obs_property_list_add_string(p_disp, s_name, s_name)
            end
        end
        obs.source_list_release(sources)
    end

    obs.obs_properties_add_int(props, "check_interval", "Check Interval (ms)", 100, 1000, 50)
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_bool(settings, "enabled", true)
    obs.obs_data_set_default_string(settings, "game_source", "Game Capture")
    obs.obs_data_set_default_string(settings, "display_source", "Display Capture")
    obs.obs_data_set_default_int(settings, "check_interval", 250)
end

function script_update(settings)
    enabled = obs.obs_data_get_bool(settings, "enabled")
    game_source_name = obs.obs_data_get_string(settings, "game_source")
    display_source_name = obs.obs_data_get_string(settings, "display_source")
    local new_interval = obs.obs_data_get_int(settings, "check_interval")
    if new_interval < 100 then new_interval = 100 end

    if new_interval ~= check_interval then
        check_interval = new_interval
        obs.timer_remove(check_timer)
        obs.timer_add(check_timer, check_interval)
    end

    last_state = -1
end

function script_load(settings)
    obs.timer_add(check_timer, check_interval)
    obs.script_log(obs.LOG_INFO, "[AutoToggle] Auto Game/Display Switcher active")
end

function script_unload()
    obs.timer_remove(check_timer)
    obs.script_log(obs.LOG_INFO, "[AutoToggle] Auto Game/Display Switcher unloaded")
end
