# Astropanel

Terminal program for amateur astronomers with weather forecast.

This program gives you essential data to plan your observations:

* Weather forecast for the next 9 days with coloring (red/yellow/green) based
  on your limits for cloud cover, humidity, temperature and wind
* Easy graphic representation of when the Sun, Moon and planets are visible
  with the Moon's phase showing in how light the representing bar is
* Extra information for each day: Fog, wind gust speed, dew point temperature,
  air pressure, UV Index, Sun and Moon precise rise and set and Moon phase.
  The Moon phase is expressed as a number between 0 and 100 where 50 is the
  full moon.
* Astronomical events for each of the 9 days, with option to list them in one
  view
* Starchart showing in the terminal for the selected day and time of day
* A table showing RA, Dec, distance, rise, set and transit for the planets
* Show today's Astronomy Picture Of the Day

You need to have [Ruby](https://www.ruby-lang.org/en/) installed to use Astropanel.

To have the star chart displayed, you need to have `w3m`installed (on Ubuntu:
`apt-get install w3m`).

The first time you launch Astropanel (make astropanel.rb executable; `chmod +x
astropanel.rb` and run it), it will ask for your location, Latitude and
Longitude.

When you start the program, it will show you the list of forecast points for
today and the next 9 days (from https://met.no). The first couple of days are
detailed down to each hour, while the rest of the days have 4 forecast points
(hours 00, 06, 12 and 18). Time is for your local time zone.

You can set the various limits as you see fit. Just press "?" to get the help
for each possible key binding:

```
KEYS
 ? = Show this help text       ENTER = Refresh starchart/image
 l = Edit Location                 r = Refresh all data
 a = Edit Latitude                 s = Get starchart for selected time
 o = Edit Longitude                S = Open starchart in image program
 c = Edit Cloud limit              A = Show Astronomy Picture Of the Day
 h = Edit Humidity limit           e = Show upcoming events
 t = Edit Temperature limit        p = Show info on planets
 w = Edit Wind limit
 b = Edit Bortle value
 W = Write to config file
 q = Quit (write to config file)
 Q = Quit (no config write)
```
These should be self explanatory. Until I can figure out how to automatically
fetch a location's Bortle value (light pollution), this is entered manually.

Values you change in the program are written to the config file when you quit
via "q". Use "Q" to quit without writing the values (if you want to see the
forecast for different locations and not overwrite your preferred location
data).

Click on this screenshot to see a screencast that will give you a sense of how
this application works:

[![Astropanel screencast](/screenshot.png)](https://youtu.be/36jsu3YBLyw)




