# LightwaveRF Lightweight Sinatra Web Server

A really simple Ruby Sinatra server that uses the lightwave_rf gem to control the Lightwave RF Wifi Link and devices.

This sends broadcast messages over the network that the server runs on. Therefore it must be on the same network as the Wifi Link.

## Installation

Install the required gems:

    $ bundle --path ./vendor/bundle

## Usage

Start the Sinatra Server (Default port with foreman is 5000)

    $ bundle exec foreman start

### Controlling Devices

The format for the commands is:

    http://localhost:9292/room/device/action(/level)

Examples:

    # to turn on device 1 in room 1:
    http://localhost:9292/1/1/on

    # to turn off device 2 in room 3:
    http://localhost:9292/3/2/off

    # to dim device 1 in room 1 to 50%:
    http://localhost:9292/1/1/dim/50

Note: This should probably be using `POST` requests instead of `GET` requests but it's easier to create `GET` requests by just navigating with a browser for the purposes of demonstration. If you're going to use this for anything but messing about I'd recommend replacing the method.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
