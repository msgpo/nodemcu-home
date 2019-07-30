-- Shared initialization for all NodeMCU chips.
-- Does the following:
-- 1. Reads WiFi SSID/Password from secrets.lua
-- 2. Connects to WiFi and waits 3 seconds
-- 3. (Optionally) Downloads application.lua code from CODE_HOST (defined in secrets.lua)
-- 4. Runs application.lua
-- 5. (Optionally) Restarts every hour

AUTO_RESTART = true

-------------------------------------------------------------------------------

-- Expecting in secrets.lua:
-- SSID = "xxxxxxxxxx"
-- PASSWORD = "xxxxxxxxxx"
-- CODE_HOST = "xxxxxxxx.xxx"

-- Disable code download
CODE_HOST = nil

dofile("secrets.lua")

-------------------------------------------------------------------------------

-- Automatically reset every hour
function reset()
  print("Resetting")
  node.restart()
end

if AUTO_RESTART then
  tmr.create():alarm(1000*60*60, tmr.ALARM_SINGLE, reset)
end

-------------------------------------------------------------------------------

-- Downloads a file from an HTTP host and then calls a function
function download_file(host, path, f_name, after)
  print("Downloading " .. host .. path)
  socket = net.createConnection(net.TCP)
  socket:on(
    "connection",
    function(s)
      socket:send("GET " .. path .. " HTTP/1.1\r\nHost: " .. host .. "\r\nConnection: close\r\nAccept: */*\r\n\r\n")
  end)

  fd = nil

  socket:on(
    "disconnection",
    function(s)
      if fd then
        fd.close()
        print("Downloaded " .. f_name .. " from " .. host .. path)

        if after then
          after()
        end
      end
  end)

  in_body = false
  cr = false
  newlines = 0
  got_response = false
  is_ok = true

  socket:on(
    "receive",
    function(s, data)
      if not got_response then
        -- Check for 200
        if not data:match("HTTP/1.1 200 OK") then
          is_ok = false
        end

        got_response = true
      end

      if not is_ok then
        return  -- 404
      end

      -- Look for blank line (two \r\n in a row)
      if not in_body then
        for i = 1, string.len(data) do
          c = string.sub(data, i, i)
          if not cr and (c == "\r") then
            cr = true
          elseif cr and (c == "\n") then
            newlines = newlines + 1
            cr = false
          else
            cr = false
            newlines = 0
          end

          if newlines == 2 then
            data = string.sub(data, i+1)
            in_body = true
          end
        end
      end

      if in_body and (string.len(data) > 0) then
        if not fd then
          -- First buffer
          fd = file.open(f_name, "w")
        end

        if fd then
          -- Write data to file
          fd.write(data)
        end
      end
  end)

  socket:connect(80, host)
end

-- Downloads an application.lua file for this chip from:
-- http://CODE_HOST/nodemcu/<chipid>/application.lua
function startup()
  if CODE_HOST then
    download_file(
      CODE_HOST,
      "/nodemcu/" .. tostring(node.chipid()) .. "/application.lua",
      "application.tmp",
      function()
        if file.exists("application.tmp") then
          -- Move temporary file
          file.remove("application.lua")
          file.rename("application.tmp", "application.lua")
          print("Running application.lua")
          dofile("application.lua")
        else
          print("application.lua missing")
        end
    end)
  end
end

-------------------------------------------------------------------------------

-- Call startup function 3 seconds after connecting
wifi_connected = function(T)
  print("Connected. Waiting 3 seconds to start...")
  tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)
end

wifi_got_ip = function(T)
  print("IP is "..T.IP)
end

wifi_disconnected = function(T)
  print("Disconnected")
end

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connected)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnected)

-------------------------------------------------------------------------------

-- Connect to WiFi automatically
print("Connecting to "..SSID)
wifi.setmode(wifi.STATION)
wifi.sta.config({ssid=SSID, pwd=PASSWORD, save=true})
