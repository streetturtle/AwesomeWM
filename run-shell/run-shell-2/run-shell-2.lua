-------------------------------------------------
-- Spotify Shell for Awesome Window Manager
-- Simplifies interaction with Spotify for Linux
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/spotify-shell

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local gfs = require("gears.filesystem")
local wibox = require("wibox")
local gears = require("gears")
local completion = require("awful.completion")

local run = require("awesome-wm-widgets.run-shell-2.run")

local run_shell = awful.widget.prompt()

local w = wibox {
    bg = '#2e3440',
    border_width = 1,
    border_color = '#3b4252',
    max_widget_size = 500,
    ontop = true,
    height = 50,
    width = 250,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
        --     `   gears.shape.infobubble(cr, width, height)
    end
}

local g = {
    {
        layout = wibox.container.margin,
        left = 10,
        run_shell,
    },
    id = 'left',
    layout = wibox.layout.fixed.horizontal
}


local function launch(type)

    if type == 'run' then
        table.insert(g, 1, run.icon)
        w:setup(g)
        awful.placement.top(w, { margins = { top = 40 }, parent = awful.screen.focused() })
        w.visible = true
        awful.prompt.run {
            prompt = run.text,
            bg_cursor = run.cursor_color,
            textbox = run_shell.widget,
            completion_callback = completion.shell,
            exe_callback = function(...)
                run_shell:spawn_and_handle_error(...)
            end,
            history_path = gfs.get_cache_dir() .. run.history,
            done_callback = function()
                w.visible = false
                table.remove(g, 1)
            end
        }
    elseif type == 'spotify' then
        table.insert(g, 1, {
            {
                image = '/usr/share/icons/Papirus-Light/32x32/apps/spotify-linux-48x48.svg',
                widget = wibox.widget.imagebox,
                resize = false
            },
            id = 'icon',
            top = 9,
            left = 10,
            layout = wibox.container.margin
        })
        w:setup(g)
        awful.placement.top(w, { margins = { top = 40 }, parent = awful.screen.focused() })
        w.visible = true

        awful.prompt.run {
            prompt = "<b>Spotify Shell</b>: ",
            bg_cursor = '#84bd00',
            textbox = run_shell.widget,
            history_path = gfs.get_dir('cache') .. '/spotify_history',
            exe_callback = function(input_text)
                if not input_text or #input_text == 0 then return end
                awful.spawn("sp " .. input_text)
            end,
            done_callback = function()
                w.visible = false
                table.remove(g, 1)
            end
        }
    end
end

return {
    launch = launch
}
