## Description

This Processing-Android sketch showcases an example application for the [ESP-WiFi-RC Receiver](https://github.com/normbxl/ESP-WiFi-RC-RCV).

Since the usual android controls are not multitouch capable a small set of sliders and a joystick like 2D controller pad were made.

The sketch depends on [hypermedia's UDP library](https://ubaa.net/shared/processing/udp/index.htm)

For the app to work both, the Smartphone and the ESP-WiFi-RCV device must be connected to the same wifi network, which normally is the network spawned by the ESP-WiFi-RCV device.

The app should discover the receiver by its MDNS (Bonjour) service name.

See the ESP_WiFi_RC_Android.pde for a starting point.