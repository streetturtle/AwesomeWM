# Run Shell

Run prompt which is put inside a widget:

[Demo](https://imgur.com/ohjAuCQ.mp4)

## Installation

1. Clone this repo under **~/.config/awesome/**:

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/awesome-wm-widgets
    ```

1. Require widget at the beginning of **rc.lua**:

    ```lua
    local run_shell = require("awesome-wm-widgets.run-shell.run-shell.run-shell")
    ```

1. Use it (don't forget to comment out the default prompt):

    ```lua
    awful.key({modkey}, "r", function () run_shell.launch() end),
 
