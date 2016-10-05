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
    --app.start()
  end
end

local function wifi_start_ST(list_aps)
    if list_aps then
        for key,value in pairs(list_aps) do
            if config.SSID and config.SSID[key] then
                wifi.setmode(wifi.STATION);
                for k,v in pairs(config) do
                    if k == "MAC" then
                        print(k.."="..v)
                        wifi.sta.setmac(v)
                    end
                end
                wifi.sta.config(key,config.SSID[key])
                wifi.sta.connect()
                print("Connecting to " .. key .. " ...")
                --config.SSID = nil  -- can save memory
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

    print("Soft AP started")
    print("Heep:(bytes)"..node.heap());
    print("MAC:"..wifi.ap.getmac().."\r\nIP:"..wifi.ap.getip());
end


function module.start()
    print("Configuring Wifi ...")
    if config.WFMODE == "AP" then
            wifi_start_AP()
        elseif op == "STATION" then
            wifi_start_ST()
            wifi.setmode(wifi.STATION);
            wifi.sta.getap(wifi_start_ST)
        else
            print("Error to init wifi config!")
        end
    config.AP = nil;
    config.ap_config = nil;
    collectgarbage();
end

return module
