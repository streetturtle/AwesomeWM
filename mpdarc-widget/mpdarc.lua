-------------------------------------------------
-- mpd Arc Widget for Awesome Window Manager
-- Modelled after Pavel Makhov's work

-- @author Raphaël Fournier-S'niehotta
-- @copyright 2018 Raphaël Fournier-S'niehotta
-------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local naughty = require("naughty")
local gfs = require("gears.filesystem")

local mpdarc_widget = {}
local function worker(args)
  local GET_MPD_CMD = "mpc status"
  local TOGGLE_MPD_CMD = "mpc toggle"
  local PAUSE_MPD_CMD = "mpc pause"
  local STOP_MPD_CMD = "mpc stop"
  local NEXT_MPD_CMD = "mpc next"
  local PREV_MPD_CMD = "mpc prev"

  local path_to_icons = args.path_to_icons or "/usr/share/icons/Arc"

  if not gfs.dir_readable(path_to_icons) then
    naughty.notify{
        title = "MPD Arc Widget",
        text = "Folder with icons doesn't exist: " .. path_to_icons,
        preset = naughty.config.presets.critical
    }
  end

  local PAUSE_ICON_NAME = path_to_icons .. "/actions/24/player_pause.png"
  local PLAY_ICON_NAME = path_to_icons .. "/actions/24/player_play.png"
  local STOP_ICON_NAME = path_to_icons .. "/actions/24/player_stop.png"

  local icon = wibox.widget { 
          id = "icon",
          widget = wibox.widget.imagebox,
          image = PLAY_ICON_NAME
      }
  local mirrored_icon = wibox.container.mirror(icon, { horizontal = true })

  local mpdarc = wibox.widget {
      mirrored_icon,
      max_value = 1,
      value = 0.75,
      thickness = 2,
      start_angle = 4.71238898, -- 2pi*3/4
      forced_height = 32,
      forced_width = 32,
      rounded_edge = true,
      bg = "#ffffff11",
      paddings = 0,
      widget = wibox.container.arcchart
  }

  local mpdarc_icon_widget = wibox.container.mirror(mpdarc, { horizontal = true })
  local mpdarc_current_song_widget = wibox.widget {
      id = 'current_song',
      widget = wibox.widget.textbox,
      font = 'Play 9'
  }

  local update_graphic = function(widget, stdout, _, _, _)
      local current_song = string.gmatch(stdout, "[^\r\n]+")()
      stdout = string.gsub(stdout, "\n", "")
      local mpdpercent = string.match(stdout, "(%d%d)%%")
      local mpdstatus = string.match(stdout, "%[(%a+)%]")
      if mpdstatus == "playing" then 
        icon.image = PLAY_ICON_NAME
        widget.colors = { beautiful.widget_main_color }
        widget.value = tonumber((100-mpdpercent)/100)
        mpdarc_current_song_widget.markup = current_song
      elseif mpdstatus == "paused" then
        icon.image = PAUSE_ICON_NAME
        widget.colors = { beautiful.widget_main_color }
        widget.value = tonumber(mpdpercent/100)
        mpdarc_current_song_widget.markup = current_song
      else
        icon.image = STOP_ICON_NAME
        if string.len(stdout) == 0 then -- MPD is not running
          mpdarc_current_song_widget.markup = "MPD is not running"
        else
          widget.colors = { beautiful.widget_red }
          mpdarc_current_song_widget.markup = ""
        end
      end
  end

  mpdarc:connect_signal("button::press", function(_, _, _, button)
      if (button == 1) then awful.spawn(TOGGLE_MPD_CMD, false)      -- left click
      elseif (button == 2) then awful.spawn(STOP_MPD_CMD, false)
      elseif (button == 3) then awful.spawn(PAUSE_MPD_CMD, false)
      elseif (button == 4) then awful.spawn(NEXT_MPD_CMD, false)  -- scroll up
      elseif (button == 5) then awful.spawn(PREV_MPD_CMD, false)  -- scroll down
      end

      spawn.easy_async(GET_MPD_CMD, function(stdout, stderr, exitreason, exitcode)
          update_graphic(mpdarc, stdout, stderr, exitreason, exitcode)
      end)
  end)

  local notification
  function show_MPD_status()
      spawn.easy_async(GET_MPD_CMD,
          function(stdout, _, _, _)
              notification = naughty.notify {
                  text = stdout,
                  title = "MPD",
                  timeout = 5,
                  hover_timeout = 0.5,
                  width = 600,
              }
          end)
  end

  mpdarc:connect_signal("mouse::enter", function() show_MPD_status() end)
  mpdarc:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

  watch(GET_MPD_CMD, 1, update_graphic, mpdarc)

  local mpdarc_widget = wibox.widget {
      mpdarc_icon_widget,
      mpdarc_current_song_widget,
      layout = wibox.layout.align.horizontal,
    }

    return mpdarc_widget
end

return setmetatable(mpdarc_widget, { __call = function(_, ...) return worker(...) end })