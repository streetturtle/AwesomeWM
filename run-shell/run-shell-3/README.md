# Run Shell

Blurs / pixelates background and shows widget with run prompt:

![screenshot](./blur.png)

![screenshot](./pixelate.png)

## Installation

1. To blur / pixelate the background this widget used [ffmpeg](https://www.ffmpeg.org/) and [frei0r](https://frei0r.dyne.org/) plugins (if you want to pixelate the background), which you need to install. Installation of those depends on your distribution, for ffmpeg just follow the installation section of the site, for frei0r I was able to install it by simply running

    ```
    sudo apt-get install frei0r-plugins
    ```

1. Clone this repo under **~/.config/awesome/**:

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/awesome-wm-widgets
    ```

1. Require widget at the beginning of **rc.lua**:

    ```lua
    local run_shell = require("awesome-wm-widgets.run-shell.run-shell-3.run-shell")
    ```

1. Use it (don't forget to comment out the default prompt):

    ```lua
    awful.key({modkey}, "r", function () run_shell.launch() end),
    ```
:warning: I am not 100% sure but it may (memory) leak. If awesome uses lots of RAM just reload config (Ctrl + Mod4 + r).
