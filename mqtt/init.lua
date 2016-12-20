-- file : init.lua
require("commons")
app = ldfile('app.lua') or ldfile('app.lc')
config = ldfile('config.lua') or ldfile('config.lc')
setup = ldfile('setup.lua') or ldfile('setup.lc')
setup.start()
