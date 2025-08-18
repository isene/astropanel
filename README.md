# Astropanel

[![Gem Version](https://badge.fury.io/rb/astropanel.svg)](https://badge.fury.io/rb/astropanel)
[![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=flat&logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-Public%20Domain-brightgreen.svg)](https://unlicense.org/)
[![GitHub stars](https://img.shields.io/github/stars/isene/astropanel.svg)](https://github.com/isene/astropanel/stargazers)
[![Stay Amazing](https://img.shields.io/badge/Stay-Amazing-blue.svg)](https://isene.org)

<img src="logo.jpg" align="left" width="150" height="150">Terminal program for
amateur astronomers with weather forecast, ephemeris, astronomical events and
more. It's what you need to decide wether to take your telescope out for a
spin.

**NEW in 3.0.0: Major accuracy improvement with IAU 2006 obliquity standard and higher-precision ephemeris calculations from the [ephemeris](https://github.com/isene/ephemeris) project**

**NOTE: 2.0: Full rewrite using [rcurses](https://github.com/isene/rcurses)**

Install by cloning this repo and putting `astropanel` into your "bin"
directory. Or you can simply run `gem install astropanel`.

## Accuracy Improvements in 3.0.0
This version includes significant accuracy improvements to the ephemeris calculations:

* **IAU 2006 Obliquity Standard**: Updated from the simplified obliquity calculation to the modern International Astronomical Union 2006 standard with proper secular variations
* **Higher-Precision Orbital Elements**: More accurate mean motion values for all planets based on modern ephemeris data
* **Enhanced Perturbation Calculations**: Detailed lunar, Jupiter, Saturn, and Uranus perturbation calculations for improved positional accuracy
* **Better Topocentric Corrections**: Improved geocentric-to-topocentric coordinate transformations

These improvements provide significantly more accurate planetary positions, with improvements of 10+ arcminutes for major planets and up to 1 degree for the Moon compared to previous versions.

The enhanced ephemeris calculations are based on the [ephemeris](https://github.com/isene/ephemeris) project, which implements modern astronomical standards for higher accuracy.

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
* A table showing RA, Dec, distance, rise, set and transit for the planets with significantly improved accuracy using modern astronomical standards
* Show today's Astronomy Picture Of the Day

## Condition rules
The rules to calculate whether the condition is green, yellow or red are:

* The limits you set will determine the "negative points" given
* With 4 or more negative points, the condition becomes red
* With 2 or 3 negative points, the condition is yellow
* Less than two negative points makes the condition green
* Two negative points are given if the cloud coverage exceeds your cloud limit
* Another negative point is given if the cloud coverage is more than (100 - cloud limit)/2
* Another negative point is given if the cloud coverage is above 90%
* A negative point is given if the humidity exceeds your humidity limit
* A negative point is given if the air temperature is below your temperature limit
* Another negative point is given if the temperature is below your temperature limit - 7°C
* A negative point is given if the wind exceeds your wind limit
* Another negative point is given if the wind exceeds twice your wind limit

## Requirements
You need to have [Ruby](https://www.ruby-lang.org/en/) installed to use Astropanel.

Then there are two basic prerequisites needed: `x11-utils` and `xdotool`.

To have the star chart displayed, you need to have `imagemagick` and `w3m-img` installed.

To get all prerequisites installed on Ubuntu:
`apt-get install ruby-full git libncurses-dev x11-utils xdotool imagemagick w3m-img`

And on Arch:
`pacman -S ruby git xorg-xwininfo xdotool imagemagick w3m-img`

Also, images like the star chart and APOD is only reliably tested on the URXVT
terminal emulator.

## Launching Astropanel
The first time you launch Astropanel (make astropanel executable; `chmod +x
astropanel` and run it), it will ask for your location, Latitude and
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
 l = Edit Location                 r = Redraw all panes and image
 a = Edit Latitude                 R = Refresh all data (and re-fetch image)
 o = Edit Longitude                s = Get starchart for selected time          
 c = Edit Cloud limit              S = Open starchart in image program          
 h = Edit Humidity limit           A = Show Astronomy Picture Of the Day        
 t = Edit Temperature limit        e = Show upcoming events                     
 w = Edit Wind limit               W = Write to config file                     
 b = Edit Bortle value             q = Quit (write to config file, Q = no write)
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

