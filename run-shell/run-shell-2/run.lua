local wibox = require("wibox")

local icon = {
    {
        markup = '<span font="awesomewm-font 14" color="#ffffff">a</span>',
        widget = wibox.widget.textbox,
    },
    id = 'icon',
    top = 2,
    left = 10,
    layout = wibox.container.margin
}

local text = '<b>Run</b>: '

return {
    icon = icon,
    text = text,
    cursor_color = '#74aeab',
    history = '/history'
}