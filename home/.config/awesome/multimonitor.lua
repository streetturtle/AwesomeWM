local gears = require("gears")
local awful = require("awful")
local async = require("async")
require("awful.autofocus")
local naughty = require("naughty")
local wibox = require("wibox")

local debug_util = require("debug_util")
local serialize = require("serialize")
local variables = require("variables")
local xrandr = require("xrandr")

local function show_screens()
    for s in screen do
        local title = "Screen " .. s.index
        local text = ""
        for k, _ in pairs(s.outputs) do
            text = text .. k .. " "
        end
        text = text .. " " .. s.geometry.width .. "x" .. s.geometry.height
                .. "+" .. s.geometry.x .. "+" .. s.geometry.y
        naughty.notify({text=text, title=title, screen=s})
    end
end

local configured_outputs = {}
local configured_screen_layout = nil
local saved_screen_layout = ""
local configured_outputs_file = variables.config_dir .. "/outputs.json"
local layout_changing = false

local function get_screen_name(s)
    return gears.table.keys(s.outputs)[1]
end

local function move_to_screen(c, s)
    debug_util.log("Moving client "
            .. debug_util.get_client_debug_info(c)
            .. " to screen " .. get_screen_name(s))
    local maximized = c.maximized
    c.maximized = false
    c:move_to_screen(s)
    c.maximized = maximized
end

local function get_configuration(key)
    if not configured_outputs[key] then
        configured_outputs[key] = {}
    end

    return configured_outputs[key]
end

local function get_current_configuration(field)
    if not configured_screen_layout then
        return nil
    end

    local current_configuration = get_configuration(
            configured_screen_layout.key)

    if field then
        if not current_configuration[field] then
            current_configuration[field] = {}
        end
        return current_configuration[field]
    else
        return current_configuration
    end
end

local function save_configured_outputs()
    -- debug_util.log("Saving screen configuration to file.")
    serialize.save_to_file(configured_outputs_file, configured_outputs)
end

local function load_configured_outputs()
    configured_outputs = serialize.load_from_file(configured_outputs_file)
    debug_util.log("Loading screen configuration from file.")
    debug_util.log(debug_util.to_string_recursive(configured_outputs))
end

local function set_client_configuration(client_configuration, c)
    client_configuration[tostring(c.window)] = {
            screen=get_screen_name(c.screen),
            x=c.x, y=c.y,
            maximized=c.maximized}
end

local function initialize_client_configuration()
    local client_configuration = get_current_configuration("clients")
    if not client_configuration then
        return
    end
    for k, _ in pairs(client_configuration) do
        client_configuration[k] = nil
    end
    for _, c in pairs(client.get()) do
        set_client_configuration(client_configuration, c)
    end
end

local function get_active_screen_layout()
    local result = {}
    for s in screen do
        local name = get_screen_name(s)
        local g = s.geometry
        result[name] = {
            width=g.width,
            height=g.height,
            dx=g.x,
            dy=g.y,
            connected=true,
            active=true,
        }
    end
    return result
end

local function is_screen_equal(settings1, settings2)
    if not (settings1.width == settings2.width
            and settings1.height == settings2.height
            and settings1.dx == settings2.dx
            and settings1.dy == settings2.dy) then
        return false
    end

    if settings1.orientation and settings2.orientation then
        return settings1.orientation == settings2.orientation and
                settings1.primary == settings2.primary
    else
        return true
    end
end

local function is_layout_equal_(layout1, layout2)
    for name, settings1 in pairs(layout1) do
        if not settings1.active then
            goto continue
        end
        local settings2 = layout2[name]
        if not settings2 or not settings2.active
                or not is_screen_equal(settings1, settings2) then
            return false
        end
        ::continue::
    end

    return true
end

local function is_layout_equal(layout1, layout2)
    return is_layout_equal_(layout1, layout2)
            and is_layout_equal_(layout2, layout1)
end

local function is_layout_up_to_date()
    if not configured_screen_layout then
        return false
    end

    local active_layout = get_active_screen_layout()

    return is_layout_equal(configured_screen_layout.outputs, active_layout)
end

local function save_screen_layout()
    local layout = configured_screen_layout

    if not layout then
        debug_util.log("No configuration yet. Not saving.")
        return
    end

    debug_util.log("Saving screen layout for configuration: "
            .. debug_util.to_string_recursive(layout))

    if not is_layout_up_to_date() then
        debug_util.log("Screen layout is not up to date. Not saving.")
        return
    end

    get_current_configuration().layout = layout

    initialize_client_configuration()
    saved_screen_layout = configured_screen_layout
    save_configured_outputs()
end

local function get_screens_by_name()
    local screens = {}
    for s in screen do
        screens[get_screen_name(s)] = s
    end
    return screens
end

local function restore_clients(clients)
    debug_util.log("Restoring client positions.")
    if not is_layout_up_to_date() then
        debug_util.log(
                "Screen layout is not up to date. Not restoring clients.")
        return
    end

    local screens = get_screens_by_name()
    local to_move = {}
    debug_util.log(debug_util.to_string_recursive(clients))
    for _, c in ipairs(client.get()) do
        local client_info = clients[tostring(c.window)]
        debug_util.log("Client " .. debug_util.get_client_debug_info(c)
                .. ": " .. debug_util.to_string_recursive(client_info))
        local screen_name = nil
        if client_info then
            screen_name = client_info.screen
        end
        if screen_name and screen_name ~= get_screen_name(c.screen) then
            to_move[c] = screens[screen_name]
        else
            to_move[c] = c.screen
        end
        if client_info then
            debug_util.log("Moving: " .. debug_util.get_client_debug_info(c)
                    .. " x=" .. c.x .. "->" .. tostring(client_info.x)
                    .. " y=" .. c.y .. "->" .. tostring(client_info.y))
            if client_info.x then
                c.x = client_info.x
            end
            if client_info.y then
                c.y = client_info.y
            end
            if client_info.maximized ~= nil then
                c.maximized = client_info.maximized
            end
        end
    end
    for c, s in pairs(to_move) do
        move_to_screen(c, s)
    end
end

local function finalize_configuration(configuration)
    if not is_layout_up_to_date() then
        debug_util.log("Screen layout is not up to date.")
        return false
    end

    if configuration.clients then
        restore_clients(configuration.clients)
    end
    if configuration.system_tray_screen then
        local screens = get_screens_by_name()
        local system_tray_screen = configuration.system_tray_screen
        debug_util.log("Moving system tray to " .. system_tray_screen)
        wibox.widget.systray().set_screen(screens[system_tray_screen])
    else
        wibox.widget.systray().set_screen("primary")
        debug_util.log("Moving system tray to primary screen")
    end
    save_screen_layout()
    layout_changing = false
    return true
end

local function handle_xrandr_finished(configuration)
    if not finalize_configuration(configuration) then
        gears.timer.start_new(0.5,
                function()
                    return not finalize_configuration(configuration)
                end)
    end
end

local function move_windows_to_screens(layout)
    local target_screens = {}

    for name, _ in pairs(layout) do
        table.insert(target_screens, name)
    end

    local screens = get_screens_by_name()
    local to_move = {}

    for _, c in ipairs(client.get()) do
        local screen_name = get_screen_name(c.screen)
        if not awful.util.table.hasitem(target_screens, screen_name) then
            to_move[c] = screens[target_screens[1]]
        end
    end

    for c, s in pairs(to_move) do
        move_to_screen(c, s)
    end
end

local function set_screen_layout(configuration)
    layout_changing = true
    debug_util.log("Setting new screen layout: "
            .. debug_util.to_string_recursive(configuration.layout))
    configured_screen_layout = configuration.layout
    move_windows_to_screens(configuration.layout)

    async.spawn_and_get_output(
            "xrandr " .. configuration.layout.arguments,
            function(_)
                handle_xrandr_finished(configuration)
            end)
end

local function reset_screen_layout(layout)
    local key = layout.key
    debug_util.log("Reset screen layout for " .. key)
    local configuration = get_configuration(key)
    configuration.layout = layout
    configuration.clients = nil
    set_screen_layout(configuration)
end

local layout_change_notification

local function dismiss_layout_change_notification()
    naughty.destroy(layout_change_notification,
            naughty.notificationClosedReason.dismissedByCommand)
end

local function prompt_layout_change(configuration, new_layout)
    if layout_change_notification then
        dismiss_layout_change_notification()
    end
    layout_change_notification = naughty.notify({
        title="Screen layout changed",
        text="New configuration detected on " .. new_layout.key,
        timeout=30,
        actions={
            apply=function()
                debug_util.log("Applying new configuration")
                dismiss_layout_change_notification()
                reset_screen_layout(new_layout)
            end,
            revert=function()
                debug_util.log("Reverting to old configuration")
                dismiss_layout_change_notification()
                set_screen_layout(configuration)
            end,
        },
        destroy=function(reason)
            if reason == naughty.notificationClosedReason.expired then
                debug_util.log("Timeout - reverting to old configuration")
                set_screen_layout(configuration)
            end
        end})
end

local function reconfigure_screen_layout(layout)
    local key = layout.key
    local configuration = configured_outputs[key]

    if configured_screen_layout and configured_screen_layout.key == key then
        if is_layout_equal(layout.outputs, configuration.layout.outputs) then
            -- debug_util.log("Screen configuration is unchanged.")
        else
            debug_util.log("New screen layout detected.")
            prompt_layout_change(configuration, layout)
        end
    else
        debug_util.log("Detected new screen configuration: " .. key)
        if configuration then
            debug_util.log("Found saved configuration.")
            set_screen_layout(configuration)
        else
            debug_util.log("No saved configuration found.")
            reset_screen_layout(layout)
        end
    end

end

local function detect_screens()
    -- debug_util.log("Detect screens")
    xrandr.get_outputs(reconfigure_screen_layout)
end

local function check_screens()
    if not layout_changing then
        detect_screens()
    end
end

local function print_debug_info()
    naughty.notify({text=debug_util.to_string_recursive(configured_outputs),
            timeout=20})
end

local function save_client_position(client_configuration, c)
    debug_util.log("Save client position for "
            .. debug_util.get_client_debug_info(c))
    set_client_configuration(client_configuration, c)
    save_configured_outputs()
end

local function manage_client(c)
    local client_configuration = get_current_configuration("clients")
    if client_configuration
            and saved_screen_layout == configured_screen_layout
            and not client_configuration[tostring(c.window)] then
        debug_util.log("manage " .. debug_util.get_client_debug_info(c)
                .. " x=" .. c.x .. " y=" .. c.y)
        save_client_position(client_configuration, c)
    end
end

local function move_client(c)
    local client_configuration = get_current_configuration("clients")
    if client_configuration
            and saved_screen_layout == configured_screen_layout then
        save_client_position(client_configuration, c)
    end
end

local function unmanage_client(c)
    local client_configuration = get_current_configuration("clients")
    if client_configuration then
        client_configuration[tostring(c.window)] = nil
    end
end

local function set_system_tray_position()
    local target_screen = mouse.screen
    wibox.widget.systray().set_screen(target_screen)
    local configuration = get_current_configuration(nil)
    if configuration then
        naughty.notify({text="Found configuration"})
        configuration.system_tray_screen = get_screen_name(target_screen)
    else
        naughty.notify({text="Found no configuration"})
    end
    save_screen_layout()
end

local function cleanup_clients()
    local active_clients = {}
    for _, c in pairs(client.get()) do
        active_clients[tostring(c.window)] = true
    end
    local to_remove = {}
    for _, configuration in pairs(configured_outputs) do
        if configuration.clients then
            for window, _ in pairs(configuration.clients) do
                if not active_clients[window] then
                    table.insert(to_remove, window)
                end
            end
            for _, window in pairs(to_remove) do
                configuration.clients[window] = nil
            end
        end
    end
end

awesome.connect_signal("startup",
        function()
            client.connect_signal("manage", manage_client)
            client.connect_signal("property::position", move_client)
            client.connect_signal("unmanage", unmanage_client)
            cleanup_clients()
            detect_screens()
        end)

if gears.filesystem.file_readable(configured_outputs_file) then
    load_configured_outputs()
end

local screen_check_timer = gears.timer({
        timeout=2,
        autostart=true,
        callback=check_screens,
        single_shot=false})

return {
    detect_screens=detect_screens,
    move_to_screen=move_to_screen,
    print_debug_info=print_debug_info,
    set_system_tray_position=set_system_tray_position,
    show_screens=show_screens,
}
