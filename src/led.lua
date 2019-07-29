RED_LED_PIN = 0
BLUE_LED_PIN = 4 -- GPIO2

-- Reset state
gpio.mode(BLUE_LED_PIN, gpio.OUTPUT)

-- Turn red LED on (true) or off (false)
function red_led(on)
  if on then
    gpio.mode(RED_LED_PIN, gpio.OUTPUT)
  else
    gpio.mode(RED_LED_PIN, gpio.INPUT)
  end
end

-- Turn blue LED on (true) or off (false)
function blue_led(on)
  if on then
    gpio.write(BLUE_LED_PIN, gpio.LOW)
  else
    gpio.write(BLUE_LED_PIN, gpio.HIGH)
  end
end

