-------------------------------------------------
-- Volume Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")

local secrets = require("awesome-wm-widgets.secrets")

local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"

local device_arg
if secrets.volume_audio_controller == 'pulse' then
	device_arg = '-D pulse'
else
	device_arg = ''
end

local GET_VOLUME_CMD = 'amixer ' .. device_arg .. ' sget Master'
local INC_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master 5%+'
local DEC_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master 5%-'
local TOG_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master toggle'


local volume_widget = wibox.widget {
    {
        id = "icon",
        image = path_to_icons .. "audio-volume-muted-symbolic.svg",
        resize = false,
        widget = wibox.widget.imagebox,
    },
    layout = wibox.container.margin(_, _, _, 3),
    set_image = function(self, path)
        self.icon.image = path
    end
}

local update_graphic = function(widget, stdout, _, _, _)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))
    local volume_icon_name
    if mute == "off" then volume_icon_name="audio-volume-muted-symbolic_red"
    elseif (volume >= 0 and volume < 25) then volume_icon_name="audio-volume-muted-symbolic"
    elseif (volume < 50) then volume_icon_name="audio-volume-low-symbolic"
    elseif (volume < 75) then volume_icon_name="audio-volume-medium-symbolic"
    elseif (volume <= 100) then volume_icon_name="audio-volume-high-symbolic"
    end
    widget.image = path_to_icons .. volume_icon_name .. ".svg"
end

--[[ allows control volume level by:
- clicking on the widget to mute/unmute
- scrolling when cursor is over the widget
]]
volume_widget:connect_signal("button::press", function(_,_,_,button)
    if (button == 4)     then spawn(INC_VOLUME_CMD, false)
    elseif (button == 5) then spawn(DEC_VOLUME_CMD, false)
    elseif (button == 1) then spawn(TOG_VOLUME_CMD, false)
    end

    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volume_widget, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(GET_VOLUME_CMD, 1, update_graphic, volume_widget)

return volume_widget
