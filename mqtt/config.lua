-- file : config.lua
local module = {}

-- STATION related config
module.WFMODE = "STATION"
module.SSID = {}
module.SSID["Zzz"] = "reallynosense"
module.MAC = "5c:cf:7f:c3:3f:d5"
-- 5c:cf:7f:c3:3f:d5 nodemcu3
-- c8:3a:35:d0:00:91 nodemcu1
-- 18:fe:34:d6:2f:47 nodemcu-dev

-- Broker host
module.HOST = "192.168.1.122"
module.PORT = 8883
module.ID = "node3"
--module.ID = node.chipid()
module.ENDPOINT = "nodemcu/"

--  ws2818 related config
module.numleds = 10

-- AP related config
--module.WFMODE = "AP"
module.ap_config = {};
module.ap_config['ssid'] = "ESP8266"
module.ap_config['pwd'] = "12345678"
--for k,v in pairs(config.AP_SSID) do print(k,v) end
module.AP = {};
module.AP.ip = "192.168.4.1";
module.AP.netmask = "255.255.255.0";
module.AP.gateway = "192.168.4.1";

return module
