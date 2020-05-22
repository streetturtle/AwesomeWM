# Battery widget

Simple and easy-to-install widget for Awesome Window Manager.

This widget consists of:

 - an icon which shows the battery level:
 ![Battery Widget](./bat-wid-1.png)
 - a pop-up window, which shows up when you hover over an icon:
 ![Battery Widget](./bat-wid-2.png)
 Alternatively you can use a tooltip (check the code):
 ![Battery Widget](./bat-wid-22.png)
 - a pop-up warning message which appears on bottom right corner when battery level is less that 15% (you can get the image [here](https://vk.com/images/stickers/1933/512.png)):
 ![Battery Widget](./bat-wid-3.png)

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `font` | Play 8 | Fond |
| `path_to_icons` | `/usr/share/icons/Arc/status/symbolic/` | Path to the folder with icons* |
| `show_current_level`| false | Show current charge level |
| `margin_right`|0| The right margin of the widget|
| `margin_left`|0| The left margin of the widget|
| `margins_icon` | `{0,0,0,0}` | The margins of the battery **icon** (not the whole widget). From left to right : left, right, top and bottom margins
| `display_notification` | `false` | Display a notification on mouseover |
| `notification_position` | `top_right` | The notification position |
| `warning_msg_title` | _Huston, we have a problem_ | Title of the warning popup |
| `warning_msg_text` | _Battery is dying_ | Text of the warning popup |
| `warning_msg_position` | `bottom_right` | Position of the warning popup |
| `warning_msg_icon` | ~/.config/awesome/awesome-wm-widgets/battery-widget/spaceman.jpg | Icon of the warning popup |
| `enable_battery_warning` | `true` | Display low battery warning |

*Note: the widget expects following icons be present in the folder:

 - battery-caution-charging-symbolic.svg
 - battery-empty-charging-symbolic.svg
 - battery-full-charged-symbolic.svg
 - battery-full-symbolic.svg
 - battery-good-symbolic.svg
 - battery-low-symbolic.svg
 - battery-caution-symbolic.svg
 - battery-empty-symbolic.svg
 - battery-full-charging-symbolic.svg
 - battery-good-charging-symbolic.svg
 - battery-low-charging-symbolic.svg
 - battery-missing-symbolic.svg

## Installation

This widget reads the output of acpi tool.
- install `acpi` and check the output:

```bash
$ sudo apt-get install acpi
$ acpi
Battery 0: Discharging, 66%, 02:34:06 remaining
```

```lua
local battery_widget = require("awesome-wm-widgets.battery-widget.battery")

...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		battery_widget(),
		...
```
