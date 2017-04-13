local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local naughty = require("naughty")
local xrandr = require("xrandr")
local debug_util = require("debug_util")
local json = require("json/json")
local variables = require("variables")

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
local configured_outputs_file = variables.config_dir .. "/outputs.json"

local function save_configured_outputs()
    local content = json.encode(configured_outputs)
    local f = io.open(configured_outputs_file, "w")
    f:write(content)
    f:close()
end

local function load_configured_outputs()
    local f = io.open(configured_outputs_file, "r")
    local content = f:read("*a")
    configured_outputs = json.decode(content)
    f:close()
end

local function get_screen_name(s)
    return gears.table.keys(s.outputs)[1]
end

-- This function modifies its argument!!
local function get_layout_key(screens)
    table.sort(screens)
    local result = ""
    for _, s in ipairs(screens) do
        result = result .. s .. " "
    end
    return result
end

local function get_active_screens()
    local screens = {}
    for s in screen do
        table.insert(screens, get_screen_name(s))
    end
    return screens
end

local function save_screen_layout()
    local screen_names = {}
    local offsets = {}
    for s in screen do
        screen_names[s.geometry.x] = get_screen_name(s)
        table.insert(offsets, s.geometry.x)
    end
    local text = debug_util.to_string_recursive(offsets)
    table.sort(offsets)
    text = text .. "\n\n" .. debug_util.to_string_recursive(offsets)
    naughty.notify({text=text})
    local layout = {}
    for _, offset in ipairs(offsets) do
        table.insert(layout, screen_names[offset])
    end
    configured_outputs[get_layout_key(get_active_screens())] = layout
    save_configured_outputs()
end

local function switch_off_unknown_outputs()
    -- outputs = xrandr.outputs()
    -- awful.util.spawn(xrandr.command(
end

local function detect_screens()
    -- local outputs = xrandr.outputs()
    -- local text = ""
    -- for s in screen do
    --     local output = get_screen_name(s)
    --     text = text .. output .. ": "
    --     if gears.table.hasitem(outputs, output) then
    --         text = text .. " found"
    --     else
    --         text = text .. " not found"
    --     end
    --     text = text .. "\n"
    -- end
    -- naughty.notify({text=text, timeout=5, screen=1})
    local layout = configured_outputs[get_layout_key(get_active_screens())]
    if layout then
        awful.spawn.easy_async(xrandr.command(xrandr.outputs(), layout, true),
                function(_, stderr, _, exit_code)
                    if exit_code ~= 0 then
                        naughty.notify({
                                preset=naughty.config.presets.critical,
                                title="Error setting screen configuration",
                                text=stderr})
                    end
                    save_screen_layout()
                end)
    else
        save_screen_layout()
    end
end

local function clear_layout(layout)
    configured_outputs[get_layout_key(layout)] = nil
end

local function print_debug_info()
    naughty.notify({text=debug_util.to_string_recursive(configured_outputs),
            timeout=10})
end

if gears.filesystem.file_readable(configured_outputs_file) then
    load_configured_outputs()
end

return {
    show_screens=show_screens,
    detect_screens=detect_screens,
    clear_layout=clear_layout,
    print_debug_info=print_debug_info,
    switch_off_unknown_outputs=switch_off_unknown_outputs
}
