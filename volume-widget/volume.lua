-------------------------------------------------
-- Volume Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov, Aurélien Lajoie
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gfs = require("gears.filesystem")
local dpi = require('beautiful').xresources.apply_dpi

local volume_icon_name="audio-volume-high-symbolic"
local GET_VOLUME_CMD = 'amixer sget Master'

local volume = {device = '', display_notification = false, notification = nil}

function volume:toggle()
    volume:_cmd('amixer ' .. volume.device .. ' sset Master toggle')
end

function volume:raise()
    volume:_cmd('amixer ' .. volume.device .. ' sset Master 5%+')
end
function volume:lower()
    volume:_cmd('amixer ' .. volume.device .. ' sset Master 5%-')
end

--{{{ Icon and notification update

--------------------------------------------------
--  Set the icon and return the message to display
--  base on sound level and mute
--------------------------------------------------
local function parse_output(stdout)
    local level = string.match(stdout, "(%d?%d?%d)%%")
    if stdout:find("%[off%]") then
        volume_icon_name="audio-volume-muted-symbolic_red"
        return level.."% <span color=\"red\"><b>Mute</b></span>"
    end
    level = tonumber(string.format("% 3d", level))

    if (level >= 0 and level < 25) then
        volume_icon_name="audio-volume-muted-symbolic"
    elseif (level < 50) then
        volume_icon_name="audio-volume-low-symbolic"
    elseif (level < 75) then
        volume_icon_name="audio-volume-medium-symbolic"
    else
        volume_icon_name="audio-volume-high-symbolic"
    end
    return level.."%"
end

--------------------------------------------------------
--Update the icon and the notification if needed
--------------------------------------------------------
local function update_graphic(widget, stdout, _, _, _)
    local txt = parse_output(stdout)
    widget.image = path_to_icons .. volume_icon_name .. ".svg"
    if volume.display_notification then
        volume.notification.iconbox.image = path_to_icons .. volume_icon_name .. ".svg"
        naughty.replace_text(volume.notification, "Volume", txt)
    end
end

local function notif(msg, keep)
    if volume.display_notification then
        naughty.destroy(volume.notification)
        volume.notification= naughty.notify{
            text =  msg,
            icon=path_to_icons .. volume_icon_name .. ".svg",
            icon_size = dpi(16),
            title = "Volume",
            position = volume.position,
            timeout = keep and 0 or 2, hover_timeout = 0.5,
            width = 200,
            screen = mouse.screen
        }
    end
end

--}}}

local function worker(args)
--{{{ Args
    local args = args or {}

    path_to_icons = args.path_to_icons or "/usr/share/icons/Arc/status/symbolic/"
    local volume_audio_controller = args.volume_audio_controller or 'pulse'
    volume.display_notification = args.display_notification or false
    local margins = args.margins or {0,0,0,0}
    volume.position = args.notification_position or "top_right"
    if volume_audio_controller == 'pulse' then
        volume.device = '-D pulse'
    end
    GET_VOLUME_CMD = 'amixer ' .. volume.device.. ' sget Master'
--}}}
--{{{ Check for icon path
    if not gfs.dir_readable(path_to_icons) then
        naughty.notify{
            title = "Volume Widget",
            text = "Folder with icons doesn't exist: " .. path_to_icons,
            preset = naughty.config.presets.critical
        }
        return
    end
--}}}
--{{{ Widget creation
    volume.widget = wibox.widget {
        {
            id = "icon",
            image = path_to_icons .. "audio-volume-medium-symbolic.svg",
            resize = false,
            widget = wibox.widget.imagebox,
        },
        layout = wibox.container.margin(_, margins[1], margins[2], margins[3],margins[4]),
        set_image = function(self, path)
            self.icon.image = path
        end
    }
--}}}
--{{{ Spawn functions
    function volume:_cmd(cmd)
        notif("")
        spawn.easy_async(cmd, function(stdout, stderr, exitreason, exitcode)
            update_graphic(volume.widget, stdout, stderr, exitreason, exitcode)
        end)
    end

    local function show()
        spawn.easy_async(GET_VOLUME_CMD,
        function(stdout, _, _, _)
        txt = parse_output(stdout)
        notif(txt, true)
        end
        )
    end
--}}}
--{{{ Mouse event
    --[[ allows control volume level by:
    - clicking on the widget to mute/unmute
    - scrolling when cursor is over the widget
    ]]
    volume.widget:connect_signal("button::press", function(_,_,_,button)
        if (button == 4)     then volume.raise()
        elseif (button == 5) then volume.lower()
        elseif (button == 1) then volume.toggle()
        end
    end)
    if volume.display_notification then
        volume.widget:connect_signal("mouse::enter", function() show() end)
        volume.widget:connect_signal("mouse::leave", function() naughty.destroy(volume.notification) end)
    end
--}}}

--{{{ Set initial icon
    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        parse_output(stdout)
        volume.widget.image = PATH_TO_ICONS .. volume_icon_name .. ".svg"
    end)
--}}}

    return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker(...) end })
