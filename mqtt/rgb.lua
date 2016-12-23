-- pwm rgb lib, and onboard led blinker
local m = {}

-- FIXME move to config!
local b_pin=1 -- GPIO5
local g_pin=7 -- GPIO13
local r_pin=2 -- GPIO4
pwm_clock=60

rgb_timer = tmr.create()

local rgb_convert = function(value,to)
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

local _rgb_led = function(r,g,b)
    -- RGB LED
    -- convert rgb255 => pwm1024
    -- Mobile app can send only in rgb255 mode :(
    --
    r = rgb_convert(r,"pwm")
    g = rgb_convert(g,"pwm")
    b = rgb_convert(b,"pwm")
    print("D:rgb_led:", r, g ,b )
    pwm.setduty(r_pin,r) -- Set working on 1 LED Red
    pwm.setduty(g_pin,g) -- Set to work on 2 LED Green
    pwm.setduty(b_pin,b) -- Set to work on 3 LED Blue
end

return {
  rgb_timer = rgb_timer,
  rgb_led = _rgb_led,

  rgb_led = function(r,g,b)
    -- Stop timer, if it was ran from 'fade'
    if rgb_timer then
      rgb.rgb_timer:stop()
      rgb.rgb_timer:unregister()
    end
    _rgb_led(r,g,b)
  end,

  onboard_led_blink = function(self)
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
  end,

  init_rgb_led = function()
      pwm.setup(r_pin,pwm_clock,0)
      pwm.setup(g_pin,pwm_clock,0)
      pwm.setup(b_pin,pwm_clock,0)
      pwm.start(r_pin)
      pwm.start(g_pin)
      pwm.start(b_pin)
  end,

  rgb_fade = function(r,g,b,fadeAmount,tmr_speed,mode)
      -- have no idea why, but node restart's if speed less then 50 o_O
      --- and only in those func...
      if (tonumber(tmr_speed) < 50) then
        tmr_speed = 50;
      end
      if rgb_timer then
        local t_status, t_num = rgb_timer:state()
        if t_status then
          print("D: Prev. rgb_timer found!Kill them!")
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
          _rgb_led(r,g,b)
          if ((r == 0 or r == 255 ) and (g == 0 or g == 255) and (b == 0 or b == 255)) then
            rgb_timer:stop()
            rgb_timer:unregister()
            print("D: rgb_fade done")
          end
      end)
      rgb_timer:start()
  end
}
