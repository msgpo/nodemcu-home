-- Watches a magnetic switch for the open/closed state of the back door

dofile("mqtt.lua")
dofile("led.lua")

REED_SWITCH_PIN = 1  -- GPIO5
DOOR_OPEN_LEVEL = gpio.HIGH
DOOR_TIMER_MS = 60000

mqtt_conn.on_connect = function(client)
  if not state_timer then
    -- Read the door state manually every minute
    state_timer = tmr.create()
    state_timer:register(DOOR_TIMER_MS,
                         tmr.ALARM_AUTO, read_door_state)
    state_timer:start()
  end
end

function publish_door_state(on)
  state = 'closed'
  if on then
    state = 'open'
  end

  if mqtt_conn.connected then
    print("Door state: " .. state)
    mqtt_conn.client:publish("home-assistant/back-door", state, 0, 1)
  end
end

function handle_interrupt(level, when)
  door_open = (level == DOOR_OPEN_LEVEL)
  red_led(door_open)
  publish_door_state(door_open)
end

function read_door_state()
  gpio.mode(REED_SWITCH_PIN, gpio.INPUT, gpio.PULLUP)
  door_open = (gpio.read(REED_SWITCH_PIN) == DOOR_OPEN_LEVEL)
  red_led(door_open)
  publish_door_state(door_open)

  -- Trigger on state change
  gpio.mode(REED_SWITCH_PIN, gpio.INT, gpio.PULLUP)
  gpio.trig(REED_SWITCH_PIN, "both", handle_interrupt)
end

mqtt_start()
read_door_state()
print("Application ready")
