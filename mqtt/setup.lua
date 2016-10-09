-- file: setup.lua
local module = {}

local function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
    app.start()
  end
end

local function wifi_start_ST(list_aps)
    if list_aps then
        for key,value in pairs(list_aps) do
            if config.SSID and config.SSID[key] then
                for k,v in pairs(config) do
                    if k == "MAC" then
                        print(k.."="..v)
                        wifi.sta.setmac(v)
                        tmr.delay(1000)
                    end
                end
                wifi.sta.config(key,config.SSID[key])
                wifi.sta.connect()
                print("Connecting to " .. key .. " ...")
                tmr.alarm(1, 2500, 1, wifi_wait_ip)
            end
        end
    else
        print("Error getting AP list")
    end
end

local function wifi_start_AP()
    config = require("config")

    wifi.setmode(wifi.SOFTAP)
    wifi.ap.config(config.ap_config)
    wifi.ap.setip(config.AP)
    print("I:Soft AP started")
    print("I:Heep:(bytes)"..node.heap());
    print("I:MAC:"..wifi.ap.getmac().."\r\nIP:"..wifi.ap.getip());
    app.start()
end

function module.start()
    print("Configuring Wifi ...")
    if config.WFMODE == "AP" then
            wifi.sta.getap(wifi_start_AP)
        elseif config.WFMODE == "STATION" then
            wifi.setmode(wifi.STATION);
            tmr.delay(1000)
            wifi.sta.getap(wifi_start_ST)
        else
            print("Error to init wifi config!")
        end
    -- cleanup
    config.AP = nil;
    config.ap_config = nil;
    collectgarbage();
end

return module
