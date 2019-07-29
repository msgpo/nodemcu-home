-- Expecting in secrets.lua:
-- MQTT_BROKER_URL = "xxxxxxxx.xxx"

dofile("secrets.lua")

-------------------------------------------------------------------------------

MQTT_KEEP_ALIVE_SEC = 60 * 5
MQTT_CLIENT_ID = "node-" .. tostring(node.chipid())

-- Ping self every second
MQTT_PING_MS = 1000

-- Reconnect after 10 seconds
MQTT_RECONNECT_MS = 10000

-- Topic for self commands
MQTT_COMMAND_TOPIC = "/" .. MQTT_CLIENT_ID .. "/command"

-------------------------------------------------------------------------------

-- MQTT connection state
mqtt_conn = {
  connected = false,
  client = mqtt:Client(MQTT_CLIENT_ID,
                       MQTT_KEEP_ALIVE_SEC),

  -- Function to call when connected
  -- Parameters: client
  on_connect = nil,

  -- Function to call for each message
  -- Parameters: client, topic, data
  on_message = nil,

  -- Timers
  ping_timer = nil,
  reconnect_timer = nil
}

-------------------------------------------------------------------------------

function mqtt_reconnect()
  mqtt_conn.reconnect_timer = tmr:create()
  mqtt_conn.reconnect_timer:register(MQTT_RECONNECT_MS,
                                     tmr.ALARM_SINGLE,
                                     mqtt_start)
  mqtt_conn.reconnect_timer:start()
end

function mqtt_connect(client)
  mqtt_conn.connected = true
  mqtt_conn.client:subscribe(MQTT_COMMAND_TOPIC, 0)

  if not mqtt_conn.ping_timer:state() then
    -- Start "self" ping timer
    mqtt_conn.ping_timer:start()
  end

  if mqtt_conn.on_connect then
    -- Call user function
    mqtt_conn.on_connect(mqtt_conn.client)
  end
  print("MQTT connected")
end

function mqtt_ping()
  if not mqtt_conn.reconnect_timer then
    -- Automatically reconnect
    mqtt_reconnect()
  end

  if mqtt_conn.connected then
    -- Send "self" ping
    mqtt_conn.client:publish(MQTT_COMMAND_TOPIC, "ping", 0, 1)
  end
end

function mqtt_message(client, topic, data)
  if topic == MQTT_COMMAND_TOPIC then
    command = data

    if command == "ping" then
      -- Ping received: cancel reconnect timer
      if mqtt_conn.reconnect_timer then
        mqtt_conn.reconnect_timer:unregister()
        mqtt_conn.reconnect_timer = nil
      end
    elseif command == "restart" then
      node.restart()
    end
  end

  if mqtt_conn.on_message then
    -- Forward message to user handler
    mqtt_conn.on_message(mqtt_conn.client, topic, data)
  end
end

-------------------------------------------------------------------------------

function mqtt_start()
  print("Connecting to MQTT broker at " .. MQTT_BROKER_URL)
  mqtt_conn.connected = false

  if not mqtt_conn.ping_timer then
    -- Create "self" ping timer (will be started in mqtt_connect)
    mqtt_conn.ping_timer = tmr:create()
    mqtt_conn.ping_timer:register(MQTT_PING_MS,
                                  tmr.ALARM_AUTO,
                                  mqtt_ping)
  end

  mqtt_conn.client:connect(MQTT_BROKER_URL,
                           1883, 0, -- secure
                           mqtt_connect,
                           function(client, reason)
                             print("Failed to connect")
                             mqtt_reconnect()
                           end)

  mqtt_conn.client:on("message", mqtt_message)
end
