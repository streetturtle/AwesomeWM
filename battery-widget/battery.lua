-------------------------------------------------
-- Battery Widget for Awesome Window Manager
-- Shows the battery status using the ACPI tool
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/battery-widget

-- @author Pavel Makhov
-- @copyright 2017 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local naughty = require("naughty")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local gfs = require("gears.filesystem")
local dpi = require('beautiful').xresources.apply_dpi

-- acpi sample outputs
-- Battery 0: Discharging, 75%, 01:51:38 remaining
-- Battery 0: Charging, 53%, 00:57:43 until charged

local HOME = os.getenv("HOME")
local WIDGET_DIR = HOME .. '/.config/awesome/awesome-wm-widgets/battery-widget'

local battery_widget = {}
local function worker(user_args)
    local args = user_args or {}

    local font = args.font or 'Play 8'
    local path_to_icons = args.path_to_icons or "/usr/share/icons/Arc/status/symbolic/"
    local show_current_level = args.show_current_level or false
    local margin_left = args.margin_left or 0
    local margin_right = args.margin_right or 0
    local battery_backend = args.battery_backend or "acpi"

    local display_notification = args.display_notification or false
    local display_notification_onClick = args.display_notification_onClick or true
    local position = args.notification_position or "top_right"
    local timeout = args.timeout or 10

    local warning_msg_title = args.warning_msg_title or 'Huston, we have a problem'
    local warning_msg_text = args.warning_msg_text or 'Battery is dying'
    local warning_msg_position = args.warning_msg_position or 'bottom_right'
    local warning_msg_icon = args.warning_msg_icon or WIDGET_DIR .. '/spaceman.jpg'
    local enable_battery_warning = args.enable_battery_warning
    if enable_battery_warning == nil then
        enable_battery_warning = true
    end

    if not gfs.dir_readable(path_to_icons) then
        naughty.notify{
            title = "Battery Widget",
            text = "Folder with icons doesn't exist: " .. path_to_icons,
            preset = naughty.config.presets.critical
        }
    end

    local icon_widget = wibox.widget {
        {
            id = "icon",
            widget = wibox.widget.imagebox,
            resize = false
        },
        valigh = 'center',
        layout = wibox.container.place,
    }
    local level_widget = wibox.widget {
        font = font,
        widget = wibox.widget.textbox
    }

    battery_widget = wibox.widget {
        icon_widget,
        level_widget,
        layout = wibox.layout.fixed.horizontal,
    }
    -- Popup with battery info
    -- One way of creating a pop-up notification - naughty.notify
    local notification
    local function show_battery_status(batteryType)
        awful.spawn.easy_async([[bash -c 'acpi']],
        function(stdout, _, _, _)
            naughty.destroy(notification)
            notification = naughty.notify{
                text =  stdout,
                title = "Battery status",
                icon = path_to_icons .. batteryType .. ".svg",
                icon_size = dpi(16),
                position = position,
                timeout = 5, hover_timeout = 0.5,
                width = 200,
                screen = mouse.screen
            }
        end
        )
    end

    -- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one
    --battery_popup = awful.tooltip({objects = {battery_widget}})

    -- To use colors from beautiful theme put
    -- following lines in rc.lua before require("battery"):
    -- beautiful.tooltip_fg = beautiful.fg_normal
    -- beautiful.tooltip_bg = beautiful.bg_normal

    local function show_battery_warning()
        naughty.notify {
            icon = warning_msg_icon,
            icon_size = 100,
            text = warning_msg_text,
            title = warning_msg_title,
            timeout = 25, -- show the warning for a longer time
            hover_timeout = 0.5,
            position = warning_msg_position,
            bg = "#F06060",
            fg = "#EEE9EF",
            width = 300,
            screen = mouse.screen
        }
    end
    local last_battery_check = os.time()
    local batteryType = "battery-good-symbolic"

    if battery_backend == "acpi" then
        watch("acpi -i", timeout,
        function(widget, stdout)
            local battery_info = {}
            local capacities = {}
            for s in stdout:gmatch("[^\r\n]+") do
                local status, charge_str, _ = string.match(s, '.+: (%a+), (%d?%d?%d)%%,?(.*)')
                if status ~= nil then
                    table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
                else
                    local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
                    table.insert(capacities, tonumber(cap_str))
                end
            end

            local capacity = 0
            for _, cap in ipairs(capacities) do
                capacity = capacity + cap
            end

            local charge = 0
            local status
            for i, batt in ipairs(battery_info) do
                if capacities[i] ~= nil then
                    if batt.charge >= charge then
                        status = batt.status -- use most charged battery status
                        -- this is arbitrary, and maybe another metric should be used
                    end

                    charge = charge + batt.charge * capacities[i]
                end
            end
            charge = charge / capacity

            if show_current_level then
                level_widget.text = string.format('%d%%', charge)
            end

            if (charge >= 0 and charge < 15) then
                batteryType = "battery-empty%s-symbolic"
                if enable_battery_warning and status ~= 'Charging' and os.difftime(os.time(), last_battery_check) > 300 then
                    -- if 5 minutes have elapsed since the last warning
                    last_battery_check = os.time()

                    show_battery_warning()
                end
            elseif (charge >= 15 and charge < 40) then batteryType = "battery-caution%s-symbolic"
            elseif (charge >= 40 and charge < 60) then batteryType = "battery-low%s-symbolic"
            elseif (charge >= 60 and charge < 80) then batteryType = "battery-good%s-symbolic"
            elseif (charge >= 80 and charge <= 100) then batteryType = "battery-full%s-symbolic"
            end

            if status == 'Charging' then
                batteryType = string.format(batteryType, '-charging')
            else
                batteryType = string.format(batteryType, '')
            end

            widget.icon:set_image(path_to_icons .. batteryType .. ".svg")

            -- Update popup text
            -- battery_popup.text = string.gsub(stdout, "\n$", "")
        end,
        icon_widget)
    elseif battery_backend == "upower" then
        watch(
            { awful.util.shell, "-c", "upower -i $(upower -e | grep BAT) | sed -n '/present/,/icon-name/p'" },
            timeout,
            function(widget, stdout)
                local bat_now = {
                    state        = "N/A",
                    timefull     = "N/A",
                    percentage   = "N/A",
                }

                for k, v in string.gmatch(stdout, '([%a]+[%a|-]+):%s*([%a|%d]+[,|%a|%d]-)') do
                    if     k == "state"         then bat_now.state        = v
                    elseif k == 'full'          then bat_now.timefull     = v
                    elseif k == "percentage"    then bat_now.percentage   = tonumber(v)              -- %
                    end
                end

                -- customize here
                local charge = bat_now.percentage
                local status = bat_now.state
                if show_current_level then
                    level_widget.text = string.format('%d%%', charge)
                end

                if (charge >= 0 and charge < 15) then
                    batteryType = "battery-empty%s-symbolic"
                    if enable_battery_warning and status ~= 'charging' and os.difftime(os.time(), last_battery_check) > 300 then
                        -- if 5 minutes have elapsed since the last warning
                        last_battery_check = os.time()

                        show_battery_warning()
                    end
                elseif (charge >= 15 and charge < 40) then batteryType = "battery-caution%s-symbolic"
                elseif (charge >= 40 and charge < 60) then batteryType = "battery-low%s-symbolic"
                elseif (charge >= 60 and charge < 80) then batteryType = "battery-good%s-symbolic"
                elseif (charge >= 80 and charge <= 100) then batteryType = "battery-full%s-symbolic"
                end

                if (status == 'charging' and bat_now.timefull ~= "N/A") then
                    batteryType = string.format(batteryType, '-charging')
                else
                    batteryType = string.format(batteryType, '')
                end

                widget.icon:set_image(path_to_icons .. batteryType .. ".svg")
            end,
        icon_widget)
    end

    if display_notification then
        battery_widget:connect_signal("mouse::enter", function() show_battery_status(batteryType) end)
        battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)
    elseif display_notification_onClick then
        battery_widget:connect_signal("button::press", function(_,_,_,button)
            if (button == 3) then show_battery_status(batteryType) end
        end)
        battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)
    end

    return wibox.container.margin(battery_widget, margin_left, margin_right)
end

return setmetatable(battery_widget, { __call = function(_, ...) return worker(...) end })
