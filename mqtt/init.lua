-- file : init.lua
require("commons")
app = ldfile('app.lua') or ldfile('app.lc')
config = ldfile('config.lua') or ldfile('config.lc')
setup = ldfile('setup.lua') or ldfile('setup.lc')
-- since at boot G_pin pin always 1, we need to disable it asap
rgb = ldfile('rgb.lua') or ldfile('rgb.lc')
rgb.init_rgb_led()
setup.start()
