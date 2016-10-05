-- file : config.lua
local module = {}


--module.WFMODE = "STATION"
module.SSID = {}  
module.SSID["CoolNw"] = "12345678"

module.HOST = "192.168.1.2"
module.PORT = 1884  
module.ID = node.chipid()
module.MAC = "DE:AD:BE:EF:7A:C0"

module.ENDPOINT = "nodemcu/"  

module.WFMODE = "AP"

module.ap_config = {};
module.ap_config['ssid'] = "ESP8266"
module.ap_config['pwd'] = "12345678"

--for k,v in pairs(config.AP_SSID) do print(k,v) end

module.AP = {};
module.AP.ip = "192.168.4.1";
module.AP.netmask = "255.255.255.0";
module.AP.gateway = "192.168.4.1";

return module