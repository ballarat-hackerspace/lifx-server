# lifx-server

First version: *quick and simple* can send a colour to all blubs on the local network.

## quick guide

### download and run the server

```
$ git clone https://github.com/ballarat-hackerspace/lifx-server.git
$ cd lifx-server
$ gem install lifx --no-rdoc --no-ri
$ gem install sinatra --no-rdoc --no-ri
$ ruby lifx-server <number of lifx bulbs>
```

### send a colour to all bulbs

```
$ curl http://localhost:5439/hsbk -d 'colour={ "h":120, "s":0.6, "b":0.75, "k":2200, "d":10 }'
```
