-- file : app.lua

module=nil
local module = {}

--[[app require:
rfswitch
pwm
mqtt
i2c
--]]

--  Variables
rf315_pin=0-- GPIO16 -- don't use GPIo0 - it will pull-down - and node can't boot!
bh1750sda=6 -- GPIO14
bh1750scl=5 -- GPIO12
require 'commons' -- need for bh1750
rgb = ldfile('rgb.lua') or ldfile('rgb.lc')

-- Sends a simple ping to the broker
local function send_ping()
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

-- Sends my id to the broker for registration
local function register_myself()
    local endpoint = config.ENDPOINT .. config.ID .. "/#"
    m:subscribe(endpoint,0,function(conn)
        print("I:Subscribed to endpoint:",endpoint)
    end)
end

local function rf315(action)
    -- for luster = 10 is perfect, but for solo-6c - 5 better... ¯\_(ツ)_/¯
    local repeat_c = 10
    local pulse_len = 300
    if action == "a" then
        rfswitch.send(6, pulse_len, repeat_c, rf315_pin, 5250051, 24)
    elseif action == "b" then
        rfswitch.send(6, pulse_len, repeat_c, rf315_pin, 5250060, 24)
    elseif action == "c" then
        rfswitch.send(6, pulse_len, repeat_c, rf315_pin, 5250096, 24)
    elseif action == "d" then
        rfswitch.send(6, pulse_len, repeat_c, rf315_pin, 5250240, 24)
    else
        rfswitch.send(6, 300, 5, rf315_pin, action, 24)
        rfswitch.send(1, 300, 5, rf315_pin, action, 24)
    end
    print("D:rf315=" .. action )
    m:publish(config.ENDPOINT .. config.ID, "D:rf315=" .. action ,0,0)
    -- clean-up hack (looks like somewhere rf stucks)
    --rfswitch.send(0, 300, 5, rf315_pin, 0, 12)
    --tmr.delay(300)
end

local function lux_data_send()
    bh1750 = ldfile('bh1750.lua') or ldfile('bh1750.lc')
    res = bh1750.init(bh1750sda, bh1750scl)
    if not res then
            bh1750 = nil
            lux = 0
    else lux = bh1750.lux() end
    res = nil
    --print("I:Lux=" .. lux)
    m:publish(config.ENDPOINT .. config.ID, "lux=" .. lux,0,0)
end

local function mqtt_start()
    m = mqtt.Client(config.ID, 120)
    rf315("d")
    m:on("connect", function(client)
        m:publish(config.ENDPOINT .. config.ID .. "/status/", "D:online" ,0,0)
        -- initiate
        lux_data_send()
    end)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data)
      if data ~= nil then
        print(topic .. ":" .. data)
        if topic.match(string.lower(topic), "/(%w+)/rgb") then
            if data.match(string.lower(data), "rgb") then
              -- topic=XXX/XXX/rgb,data=rgb(0,0,255)
              --[[ blink- usefully to debug
              but we don't want to blink on any message..
              so let it be only for one--]]
              rgb.onboard_led_blink()
              --print ("I:The word 'rgb' was captured")
              local r, g, b = string.match(data, "(%d+),(%d+),(%d+)")
              rgb.rgb_led(r,g,b)
            end
        elseif topic.match(string.lower(topic), "/(%w+)/fade") then
          if data.match(string.lower(data), "fade") then
            -- topic=XXX/XXX/fade,data=fade(none,none,none,10,50,in)
            local r, g, b, fadeAmount, tmr_speed, mode = string.match(data, "(%w+),(%w+),(%w+),(%d+),(%d+),(%a+)")
            rgb.rgb_fade(r, g, b, fadeAmount, tmr_speed, mode)
          end
        elseif topic.match(string.lower(topic), "/(%w+)/rf") then
          if data.match(string.lower(data), "luster") then
            --print ("I:The word 'luster' was captured")
            local value = string.match(data, ".*=(%w+)")
            rf315(value)
          elseif data.match(string.lower(data), "irda") then
            --print ("I:The word 'irda' was captured")
            local value = string.match(data, ".*=(%d+)")
            rf315(value)
          end
        elseif topic.match(string.lower(topic), "/(%w+)/lux") then
          if data.match(string.lower(data), "get_lux") then
            --print ("I:The word 'get_lux' was captured")
            lux_data_send()
          end
        end
      end
    end)
    m:on("offline", function(con)
        print("E:Mqtt down!Restarting whole node in 10s")
        wdog_timer = tmr.create()
        wdog_timer:register(10*1000, tmr.ALARM_SINGLE, function (t)
          print("E:Mqtt down!Restarting whole node!")
          node.restart()
        end)
        wdog_timer:start()
    end)
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, function(client)
          register_myself()
          -- And then pings each 60s
          ping_timer = tmr.create()
          ping_timer:register(5*1000, tmr.ALARM_AUTO,
          function()
            send_ping()
            collectgarbage();
          end)
        end,
        function(client, reason)
          print("D: Mqtt failed reason: ", reason)
    end)
end

function module.start()
  print("app started")
  mqtt_start()
end

return module
