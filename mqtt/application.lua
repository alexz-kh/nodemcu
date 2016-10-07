-- file : application.lua
local module = {}
m = nil

----
config = require("config")
setup = require("setup")

setup.start()
----

-- Sends a simple ping to the broker
--local function send_ping()
function send_ping()
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

-- Sends my id to the broker for registration
--local function register_myself()
function register_myself()
    m:subscribe(config.ENDPOINT .. config.ID,0,function(conn)
        print("Successfully subscribed to data endpoint")
    end)
end

function on_click()
    gpio.trig(pin)
    print "Pressed";send_ping()
    tmr.stop(5)
    tmr.alarm(5, 500, tmr.ALARM_SINGLE, register_on_click)
end

function register_on_click()
    pin=3
    mode=gpio.INT
    gpio.mode(pin, mode, gpio.PULLUP)
    gpio.trig(pin, "down", on_click)
end

function led_on()
    pin=4
    mode=gpio.OUTPUT
    gpio.mode(pin, mode)
    gpio.write(pin, gpio.LOW)
    tmr.stop(4)
    tmr.alarm(4, 2500, tmr.ALARM_SINGLE, function() gpio.write(pin, gpio.HIGH) end)
end

--local function mqtt_start()
function mqtt_start()
    m = mqtt.Client(config.ID, 120)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data)
      if data ~= nil then
        print(topic .. ": " .. data)
        led_on()
        --register_on_click()
        -- do something, we have received a message
      end
    end)
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 1, function(con)
        register_myself()
        print "zzz"
        -- And then pings each 1000 milliseconds
        --tmr.stop(6)
        --tmr.alarm(6, 1000, 1, send_ping)
        --send_ping()
    end)
end

--function module.start()
  mqtt_start()
--end

--return module



