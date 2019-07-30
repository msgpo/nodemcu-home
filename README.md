# NodeMCU Lua Code for Home Automation

This repository contains code, firmware, and helper scripts for programming a [NodeMCU ESP8266 chip](https://github.com/nodemcu/nodemcu-firmware) (specifically [this one](https://www.amazon.com/gp/product/B010O1G1ES)).

## Firmware

The included firmware was built with the NodeMCU [cloud build service](https://nodemcu-build.com/) to include a few extra modules (MQTT, HTTP, and others I can't remember).

## Scripts

There are a few helper scripts in the `bin` directory for connecting to the ESP8266 and uploading firmware/code. You will need Python 2 installed for them to work. If necessary, a virtual environment will be created and the necessary software installed.

### Serial Connection

With your ESP8266 connected, run:

```bash
bin/connect-serial.sh
```

to start a serial terminal session. This assumes the ESP8266 is connected on `/dev/ttyUSB0`. Press `CTRL + ]` to exit.

### Upload Firmware

To upload the included firmware (in the `firmware` directory), just run:

```bash
bin/upload-firmware.sh
```

### Upload Code

Once you have the ESP8266 programmed, you can upload all of the `.lua` files in a directory with:

```bash
bin/upload-code.sh <DIR>
```

where `<DIR>` is the directory containing `init.lua`, etc.

## Lua Code

The included code under `src` is for two different use cases:

1. A magnetic door sensor ([reed switch](https://www.amazon.com/Gikfun-Sensor-Magnetic-Switch-Arduino/dp/B0154PTDFI))
2. A gyro washer/dryer sensor ([MPU6050](https://www.amazon.com/gp/product/B008BOPN40))

Both projects uses the same `init.lua` script that automatically gets executed at boot. This script reads a `secrets.lua` file (not included), which contains the WiFi SSID and password to connect to. After a brief delay, it automatically connects to WiFi and runs `application.lua`, which contains project-specific code.

The `init.lua` script also supports downloading the `application.lua` code from an HTTP server, allowing for "over the air" updates (with a reboot). If you define `CODE_HOST` in `secrets.lua`, the ESP8266 will download `http://CODE_HOST/nodemcu/<chipid>/application.lua` on boot (where `<chipid>` is from [node.chipid()](https://nodemcu.readthedocs.io/en/master/modules/node/#nodechipid)).

### Helper Functions

There are some shared helper functions defined in:

* `mqtt.lua`
    * Keeps an MQTT connection alive by pinging itself every second
* `led.lua`
    * Turn the built-in blue and red LEDs on and off

### Door Sensor

Reads the state of a magnetic (reed) switch on GPIO5 (open high) and reports it via MQTT. The switch state is both polled every second and caught via interrupt.

The result is used by a [Home Assistant binary sensor](https://www.home-assistant.io/components/binary_sensor/).

Excerpt from `configuration.yaml`:

```yaml
binary_sensor:
  - platform: mqtt
    name: "Back Door Sensor"
    state_topic: "home-assistant/back-door"
    value_template: >
      {% if value != "closed" %}
      ON
      {% else %}
      OFF
      {% endif %}
```

### Washer/Dryer Sensor

Reads the gyro state of the MPU6050 every second and publishes it out as JSON via MQTT.

The results are tracked by a [Home Assistant filter sensor](https://www.home-assistant.io/components/filter/) to create a moving average. This (thresholded) value is then used by a [Home Assistant binary sensor](https://www.home-assistant.io/components/binary_sensor/) to determine whether the washer/dryer is on or off (mine are next to each other).

Excerpt from `configuration.yaml`:

```yaml
sensor:
  - platform: mqtt
    name: laundry_motion_raw
    state_topic: "home-assistant/laundry"
    value_template: "{{ value_json.gyro }}"
  - platform: filter
    name: laundry_motion
    entity_id: sensor.laundry_motion_raw
    filters:
      - filter: time_simple_moving_average
        window_size: 00:05
        precision: 2
        
binary_sensor:
  - platform: threshold
    name: "Laundry Sensor"
    entity_id: sensor.laundry_motion
    upper: 5.0

```
