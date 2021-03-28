# Astropanel

Terminal program for amateur astronomers with weather forecast.

## Functionality
This program gives you essential data to plan your observations:

* Weather forecast for the next 9 days with coloring (red/yellow/green) based
  on your limits for cloud cover, humidity, temperature and wind
* Graphic representation of when the Sun, Moon and planets are visible
  with the Moon's phase showing in how light the representing bar is
* Extra information for each day: Fog, wind gust speed, dew point temperature,
  air pressure, UV Index, Sun and Moon precise rise and set and Moon phase.
  The Moon phase is expressed as a number between 0 and 100 where 50 is the
  full moon.
* Astronomical events for each of the 9 days, with option to list them in one
  view
* Star chart showing in the terminal for the selected day and time of day
  PS: The star chart is only generated for latitudes above +23
* A table showing RA, Dec, distance, rise, set and transit for the planets
* Show today's Astronomy Picture Of the Day

## Requirements
You need to have [Ruby](https://www.ruby-lang.org/en/) installed to use Astropanel.
You also need to install the latest Ruby Curses library via `gem install curses`.

Then there are two basic prerequisites needed: `x11-utils` and `xdotool`.

To have the star chart displayed, you need to have `imagemagick` and `w3m-img` installed.

To get all prerequisites installed on Ubuntu:
`apt-get install ruby-full git libncurses-dev x11-utils xdotool imagemagick w3m-img`

And on Arch:
`pacman -S ruby git xorg-xwininfo xdotool imagemagick w3m-img`

Also, images like the star chart and APOD is only reliably tested on the URXVT
terminal emulator.

## Launching Astropanel
The first time you launch Astropanel (make astropanel.rb executable; `chmod +x
astropanel.rb` and run it), it will ask for your location, Latitude and
Longitude.

When you start the program, it will show you the list of forecast points for
today and the next 9 days (from https://met.no). The first couple of days are
detailed down to each hour, while the rest of the days have 4 forecast points
(hours 00, 06, 12 and 18). Time is for your local time zone.

When inside the program, you can set the various limits as you see fit. 

## Keys

Just press "?" to get the help for each possible key binding:

```
KEYS
 ? = Show this help text       ENTER = Refresh starchart/image
 l = Edit Location                 r = Refresh all data
 a = Edit Latitude                 s = Get starchart for selected time
 o = Edit Longitude                S = Open starchart in image program
 c = Edit Cloud limit              A = Show Astronomy Picture Of the Day
 h = Edit Humidity limit           e = Show upcoming events
 t = Edit Temperature limit        W = Write to config file       
 w = Edit Wind limit               q = Quit (write to config file)
 b = Edit Bortle value             Q = Quit (no config write)     
```
These should be self explanatory. Until I can figure out how to automatically
fetch a location's Bortle value (light pollution), this is entered manually.

## Quitting the program and saving configuration
Location values you change in the program are written to the config file when
you quit via "q". Use "Q" to quit without writing the values (if you want to
see the forecast for different locations and not overwrite your preferred
location data). Use 'W' to write new limit values to the config file.

In Termux for Android or environments where images can't be shown in a
terminal, set this in the config file (.ap.conf): `@noimage = true`

## Screencast
Click on this screenshot to see a screencast that will give you a sense of how
this application works:

[![Astropanel screencast](/screenshot.png)](https://youtu.be/36jsu3YBLyw)

