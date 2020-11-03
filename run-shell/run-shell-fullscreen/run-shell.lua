-------------------------------------------------
-- Run Shell for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/run-shell

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-- @copyright 2019 Pavel Makhov

-- @changed TornaxO7
-------------------------------------------------

local capi = {
    screen = screen,
    client = client,
}
local awful = require("awful")
local gfs = require("gears.filesystem")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local completion = require("awful.completion")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local helpers = require("helpers")
local beautiful = require("beautiful")

local run_shell = awful.widget.prompt(
    {
        bg = "#333333"
    }
)

-- generate the blur file
local _cmd_blur = [[bash -c 'ffmpeg -loglevel panic -f x11grab -video_size 1920x1080 -y -i :0.0 -filter_complex "boxblur=9" -vframes 1 /tmp/prompt_img.png ; echo done']]
awful.spawn.with_line_callback(string.format(_cmd_blur, tostring(awful.screen.focused().geometry.x)), {
     stderr = function(line)
                naughty.notification(
                    { 
                        title = "ERROR",
                        text = line .. "\nCouldn't generate the image /tmp/prompt_img.png...",
                        urgency = "critical",
                    }
                )
     end,
})

local widget = {}

function widget.new()
    local widget_instance = {
        _cached_wiboxes = {},
    }

    function widget_instance:_create_wibox()
        local w = wibox {
            visible = false,
            ontop = true,
            height = 1080,
            width = 1920
        }

        w:setup {
            {
                {
                    {
                        {
                            image = beautiful.awesome_icon,
                            resize = true,
                            visible = true,
                            opacity = 1,
                            widget = wibox.widget.imagebox
                        },
                        id = 'icon',
                        top = 3,
                        left = 10,
                        bottom = 3,
                        layout = wibox.container.margin
                    },
                    {
                        run_shell,
                        left = 10,
                        layout = wibox.container.margin,
                    },
                    id = 'left',
                    layout = wibox.layout.fixed.horizontal
                },
                widget = wibox.container.background,
                bg = '#333333',
                shape = helpers.rounded_rect(15),
                shape_border_color = beautiful.border_normal,
                shape_border_width = 1,
                forced_width = 500,
                forced_height = 50
            },
            layout = wibox.container.place
        }

        return w
    end

    function widget_instance:launch(s, c)
        c = c or capi.client.focus
        s = mouse.screen
        --        naughty.notify { text = 'screen ' .. s.index }
        if not self._cached_wiboxes[s] then
            self._cached_wiboxes[s] = {}
            --            naughty.notify { text = 'nope' }
        end
        if not self._cached_wiboxes[s][1] then
            self._cached_wiboxes[s][1] = self:_create_wibox()
            --            naughty.notify { text = 'nope' }
        end
        local w = self._cached_wiboxes[s][1]
        
        w.visible = true
        w.bgimage = '/tmp/prompt_img.png'
        awful.placement.top(w, { margins = { top = 0 }, parent = awful.screen.focused() })
        awful.prompt.run {
            prompt = 'Run: ',
            bg_cursor = '#74aeab',
            textbox = run_shell.widget,
            completion_callback = completion.shell,
            exe_callback = function(...)
                run_shell:spawn_and_handle_error(...)
            end,
            history_path = gfs.get_cache_dir() .. "/history",
            done_callback = function()
                w.visible = false
            end
        }
    end

    return widget_instance
end

local function get_default_widget()
    if not widget.default_widget then
        widget.default_widget = widget.new()
    end
    return widget.default_widget
end

function widget.launch(...)
    return get_default_widget():launch(...)
end

return widget

