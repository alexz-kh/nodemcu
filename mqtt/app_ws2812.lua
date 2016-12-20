-- file : application.lua
module=nil
local module = {}
NUMLEDS = 185;
---

-- Sends a simple ping to the broker
local function send_ping()
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

-- Sends my id to the broker for registration
local function register_myself()
    m:subscribe(config.ENDPOINT .. config.ID,0,function(conn)
        print("I:Subscribed to endpoint:" .. config.ENDPOINT .. config.ID)
    end)
end

local function strip_set_rgb(r,g,b)
    ws2812.init()
    ws2812.write(string.char(0,0,0):rep(NUMLEDS))
    ws2812.write(string.char(g,r,b):rep(NUMLEDS))
    --ws2812.write(string.char(0,50,0):rep(185))
end

local function strip_ping(r,g,b,count)
    local i, buffer = 0, ws2812.newBuffer(NUMLEDS, 3);
    buffer:fill(0,0,0);
    tmr.alarm(5, 50, 1, function()
            i=i+1
            buffer:fade(2)
            buffer:set(i%buffer:size()+1, g, r, b)
            ws2812.write(buffer)
            end)
    local t = 0
    tmr.alarm(4,1000,1, function()
        t=t+1
        print(t.."/"..count)
        if t > count then
            tmr.stop(0);tmr.stop(1);
            buffer:fill(0,0,0);
            ws2812.write(buffer)
        end
    end)
end

local function mqtt_start()
    m = mqtt.Client(config.ID, 120)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data)
      if data ~= nil then
        print(topic .. ": " .. data)
        if data.match(string.lower(data), "rgb") then
          print ("The word 'rgb' was found:")
          local r, g, b = string.match(data, "(%d+),(%d+),(%d+)")
          strip_set_rgb(r,g,b)
        elseif data.match(string.lower(data), "buffer") then
          local r, g, b, count = string.match(data, "(%d+),(%d+),(%d+),(%d+)")
          strip_ping(r,g,b,count)
        end
      end
    end)
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 1, function(con)
        register_myself()
        -- And then pings each 60s
        tmr.stop(6)
        tmr.alarm(6, 60*1000, 1, send_ping)
    end)
end

function module.start()
  ws2812.init()
  strip_set_rgb(0,0,0)
  print("fuck")
  mqtt_start()
end

return module
