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
-- FIXME move to config!
b_pin=1 -- GPIO5
g_pin=7 -- GPIO13
r_pin=2 -- GPIO4
rf315_pin=0-- GPIO16 -- don't use GPIo0 - it will pull-down - and node can't boot!
bh1750sda=6 -- GPIO14
bh1750scl=5 -- GPIO12
pwm_clock=60
require 'commons' -- need for bh1750

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

local function init_rgb_led()
    pwm.setup(r_pin,pwm_clock,0)
    pwm.setup(g_pin,pwm_clock,0)
    pwm.setup(b_pin,pwm_clock,0)
    pwm.start(r_pin)
    pwm.start(g_pin)
    pwm.start(b_pin)
end

local function rgb_convert(value,to)
    if to == "pwm" then
        local res = 1023*tonumber(value) / 255
        if (res > 1023 or res < 0) then
          print("E:R color wrong value!")
          r=512
        end
        return res
    elseif to == "rgb" then
        local res = 255*tonumber(value) / 1023
        return res
    end
end

local function rgb_led(r,g,b)
    -- RGB LED
    --[[ convert rgb255 => pwm1024
    Mobile app can send only in rgb255 mode :(
    --]]
    r = rgb_convert(r,"pwm")
    g = rgb_convert(g,"pwm")
    b = rgb_convert(b,"pwm")
    pwm.setduty(r_pin,r) -- Set working on 1 LED Red
    pwm.setduty(g_pin,g) -- Set to work on 2 LED Green
    pwm.setduty(b_pin,b) -- Set to work on 3 LED Blue
end

local function rgb_fade(r,g,b,fadeAmount,tmr_speed,mode)
    if rgb_timer then
      local t_status, t_num = rgb_timer:state()
      if t_status then
        --print("D: Prev. rgb_timer found!Kill them!")
        rgb_timer:stop()
        rgb_timer:unregister()
      end
    end
    rgb_timer = tmr.create()
    rgb_timer:register(tmr_speed, tmr.ALARM_AUTO,
    function(rgb_timer)
        if (r == "none") then
          r = rgb_convert(pwm.getduty(r_pin),"rgb")
        end
        if (g == "none") then
          g = rgb_convert(pwm.getduty(g_pin),"rgb")
        end
        if (b == "none") then
          b = rgb_convert(pwm.getduty(b_pin),"rgb")
        end

        if (mode == "out") then
          r = r - fadeAmount;
          g = g - fadeAmount;
          b = b - fadeAmount;
        else
          r = r + fadeAmount;
          g = g + fadeAmount;
          b = b + fadeAmount;
        end

        if r <= 0 then
          r = 0
        elseif r >= 255 then
          r = 255
        end
        if g <= 0 then
          g = 0
        elseif g >= 255 then
          g = 255
        end
        if b <= 0 then
          b = 0
        elseif b >= 255 then
          b = 255
        end
        print("D: rgb_fade mode:".. mode .. " " .. r,g,b)
        rgb_led(r,g,b)
        if ((r == 0 or r == 255 ) and (g == 0 or g == 255) and (b == 0 or b == 255)) then
          rgb_timer:stop()
          rgb_timer:unregister()
        end

    end)
    rgb_timer:start()
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
    end
    print("D:rf315=" .. action )
    m:publish(config.ENDPOINT .. config.ID, "D:rf315=" .. action ,0,0)
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

local function onboard_led_blink()
        local led_pin=4
        gpio.mode(led_pin, gpio.OUTPUT)
        -- inverted logic?
        gpio.write(led_pin, gpio.HIGH)
        local led_status=0
        led_tmr = tmr.create()
        led_tmr:register(100, tmr.ALARM_AUTO, function (t)
            gpio.write(led_pin, gpio.LOW)
            if led_status == 1 then
              gpio.write(led_pin, gpio.HIGH)
              t:stop()
              t:unregister()
            end
            led_status=1
        end)
        led_tmr:start()
end

local function mqtt_start()
    init_rgb_led()
    m = mqtt.Client(config.ID, 120)
    rf315("d")
    m:on("connect", function(client)
        m:publish(config.ENDPOINT .. config.ID, "D:online" ,0,0)
    end)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data)
      if data ~= nil then
        print(topic .. ": " .. data)
        if data.match(string.lower(data), "rgb") then
          --[[ blink- usefully to debug
          but we don't want to blink on any message..
          so let it be only for one--]]
          onboard_led_blink()
          --print ("I:The word 'rgb' was captured")
          local r, g, b = string.match(data, "(%d+),(%d+),(%d+)")
          rgb_led(r,g,b)

        elseif data.match(string.lower(data), "fade") then
          --print ("I:The word 'fade' was captured")
          local r, g, b, fadeAmount, tmr_speed, mode = string.match(data, "(%w+),(%w+),(%w+),(%d+),(%d+),(%a+)")
          rgb_fade(r, g, b, fadeAmount, tmr_speed, mode)

        elseif data.match(string.lower(data), "luster") then
          --print ("I:The word 'luster' was captured")
          local value = string.match(data, ".*=(%w+)")
          rf315(value)

        elseif data.match(string.lower(data), "irda") then
          --print ("I:The word 'irda' was captured")
          local value = string.match(data, ".*=(%d+)")
          rf315(value)

        --[[ FIXME
        elseif data.match(string.lower(data), "buffer") then
          local r, g, b, count = string.match(data, "(%d+),(%d+),(%d+),(%d+)")
          strip_ping(r,g,b,count)
        --]]
        elseif data.match(string.lower(data), "get_lux") then
          --print ("I:The word 'get_lux' was captured")
          lux_data_send()
        end
      end
    end)
    m:on("offline", function(con)
        wdog_timer = tmr.create()
        wdog_timer:register(10000, tmr.ALARM_SINGLE, function (t)
          print("E:Mqtt down!Restarting whole node in 10s!")
        end)
        wdog_timer:start()
        node.restart()
    end)
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 1, function(con)
        register_myself()
        -- And then pings each 60s
        ping_timer = tmr.create()
        ping_timer:register(60*1000, tmr.ALARM_AUTO,
        function(ping_timer)
            send_ping()
            collectgarbage();
        end)
    end)
end

function module.start()
  print("app started")
  mqtt_start()
end

return module
