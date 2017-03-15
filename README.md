[![Build Status](https://travis-ci.org/FarmBot/farmbot_os.svg?branch=master)](https://travis-ci.org/FarmBot/farmbot_os.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/FarmBot/farmbot_os/badge.svg)](https://coveralls.io/github/FarmBot/farmbot_os)

# Farmbot OS
The "brains" of the Farmbot Project

## Installation
Instalation should be fairly straight forward, you will need a computer for this step.
(everything after this can be set up on a mobile device.)

### Windows users

 1. download and install [Etcher](https://etcher.io/).
 2. download the [latest release](https://github.com/FarmBot/farmbot_os/releases).
 3. insert an SD Card into your PC.
 4. open Etcher, and select the `.img` file you just downloaded.
 5. select your SD Card.
 6. Burn.

### Linux/OSX

 1. download the [latest release](https://github.com/FarmBot/farmbot_os/releases).
 2. ```dd if=</path/to/file> of=/dev/<sddevice> bs=4``` or use [Etcher](https://etcher.io/).

 ## Running
 0. Plug your SD Card into your RPi3
 0. Plug your Arduino into your RPi3
 0. Plug your power into your RPi3
 0. From a WiFi enabled device*, search for the SSID `farmbot-XXXX`
 0. Connect to that and open a web browser to [http://192.168.24.1/](http://192.168.24.1)
 0. Follow the on screen instructions to configure your FarmBot. Once you save your configuration FarmBot will connect to your home WiFi network and to the FarmBot web application.

\* If you are using a smartphone you may need to disable cellular data to allow your phone's browser to connect to the configurator.

## Updating the firmware
To update the firmware on the Raspberry Pi simply use the "update" button on the web application. There is no need to reinstall the entire OS.


# Problems?

See the [FAQ](faq.html)
If your problem isn't solved there please file an issue on [Github](https://github.com/FarmBot/farmbot_os/issues/new)

# Want to Help?

[Low Hanging Fruit](https://github.com/FarmBot/farmbot_os/search?utf8=%E2%9C%93&q=TODO)
[Development](CONTRIBUTING.md)
