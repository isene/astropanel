#!/usr/bin/env ruby
# encoding: utf-8

# PROGRAM INFO 
# Name:       AstroPanel
# Language:   Pure Ruby, best viewed in VIM
# Author:     Geir Isene <g@isene.com>
# Web_site:   http://isene.com/
# Github:     https://github.com/isene/AstroPanel
# License:    I release all copyright claims. This code is in the public domain.
#             Permission is granted to use, copy modify, distribute, and sell
#             this software for any purpose. I make no guarantee about the
#             suitability of this software for any purpose and I am not liable
#             for any damages resulting from its use. Further, I am under no
#             obligation to maintain or extend this software. It is provided 
#             on an 'as is' basis without any expressed or implied warranty.

# PRELIMINARIES
@help = <<HELPTEXT
AstroPanel (https://github.com/isene/AstroPanel)

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

COPYRIGHT: Geir Isene, 2020. No rights reserved. See http://isene.com for more.
HELPTEXT
begin # BASIC SETUP
  require 'net/http'
  require 'open-uri'
  require 'json'
  require 'date'
  require 'time'
  require 'readline'
  require 'io/console'
  require 'curses'
  include  Curses

  begin # Check if network is available
    URI.open("https://www.met.no/", :open_timeout=>5)
  rescue
    puts "\nUnable to get data from met.no\n\n"
    exit
  end

  @w3mimgdisplay = "/usr/lib/w3m/w3mimgdisplay"

  # INITIALIZE VARIABLES 
  @loc, @lat, @lon, @cloudlimit, @humiditylimit, @templimit, @windlimit = ""
  if File.exist?(Dir.home+'/.ap.conf')
    load(Dir.home+'/.ap.conf')
  else
    until @loc.match(/\w+\/\w+/)
      puts "\nEnter Location (format like Europe/Oslo): "
      @loc = Readline.readline('> ', true).chomp.to_s
    end
    until (-90.0..90.0).include?(@lat)
      puts "\nEnter Latitude (format like 59.4351 or -14.54):"
      @lat = Readline.readline('> ', true).chomp.to_f
    end
    until (-180.0..180.0).include?(@lon)
      puts "\nEnter Longitude (between -180 and 180):"
      @lon = Readline.readline('> ', true).chomp.to_f
    end
    until (0..100.0).include?(@cloudlimit)
      puts "\nLimit for Cloud Coverage (format like 35 for 35%):"
      @cloudlimit = Readline.readline('> ', true).chomp.to_i
    end
    until (0..100.0).include?(@humiditylimit)
      puts "\nLimit for Humidity (format 70 for 70%):"
      @humiditylimit = Readline.readline('> ', true).chomp.to_i
    end
    until (-100.0..100.0).include?(@templimit)
      puts "\nMinimum observation temperature in °C (format like -15):"
      @templimit =Readline.readline('> ', true).chomp.to_i
    end
    until (0..50.0).include?(@windlimit)
      puts "\nLimit for Wind in m/s (format like 6):"
      @windlimit = Readline.readline('> ', true).chomp.to_i
    end
    conf =  "@loc = \"#{@loc}\"\n"
    conf += "@lat = #{@lat}\n"
    conf += "@lon = #{@lon}\n"
    conf += "@cloudlimit = #{@cloudlimit}\n"
    conf += "@humiditylimit = #{@humiditylimit}\n"
    conf += "@templimit = #{@templimit}\n"
    conf += "@windlimit = #{@windlimit}\n"
    File.write(Dir.home+'/.ap.conf', conf)
  end
  ## Don't change these
  @image         = "/tmp/starchart.jpg"
  @w_l_width     = 70
  @weather_point = []
  @weather       = []
  @history       = []
  @index         = 0
  
  ## Curses setup 
  Curses.init_screen
  Curses.start_color
  Curses.curs_set(0)
  Curses.noecho
  Curses.cbreak
  Curses.stdscr.keypad = true

  ## Initialize colors
  init_pair(1, 118, 0)  # green bg
  init_pair(2, 214, 0)  # orange bg
  init_pair(3, 160, 0)  # red bg
end
# CLASSES
class Numeric # NUMERIC CLASS EXTENSION
	def deg
	  self * Math::PI / 180 
  end
  def hms
    hrs = self.to_i
    m   = ((self - hrs)*60).abs
    min = m.to_i
    sec = ((m - min)*60).to_i.abs
    return hrs, min, sec
  end
  def to_hms
    hrs, min, sec = self.hms
    return "#{hrs.to_s.rjust(2, "0")}:#{min.to_s.rjust(2, "0")}:#{sec.to_s.rjust(2, "0")}"
  end
end
class Ephemeris # THE CORE EPHEMERIS CLASS
  # The repo for this class: https://github.com/isene/ephemeris
  attr_reader :sun, :moon, :mercury, :venus, :mars, :jupiter, :saturn, :uranus, :neptune
  
  def body_data
  @body = {
  "sun" => {
    "N" => 0.0,
    "i" => 0.0,
    "w" => 282.9404 + 4.70935e-5 * @d,
    "a" => 1.000000,
    "e" => 0.016709 - 1.151e-9 * @d,
    "M" => 356.0470 + 0.98555 * @d},
    #"M" => 356.0470 + 0.9856002585 * @d},
  "moon" => {
    "N" => 125.1228 - 0.0529538083 * @d,
    "i" => 5.1454,
    "w" => 318.0634 + 0.1643573223 * @d,
    "a" => 60.2666, 
    "e" => 0.054900,
    "M" => 115.3654 + 13.06478 * @d},
    #"M" => 115.3654 + 13.0649929509 * @d},
  "mercury" => {
    "N" => 48.3313 + 3.24587e-5 * @d,
    "i" => 7.0047 + 5.00e-8 * @d,
    "w" => 29.1241 + 1.01444e-5 * @d,
    "a" => 0.387098,  
    "e" => 0.205635 + 5.59e-10 * @d,
    #"M" => 168.6562 + 4.09257 * @d},
    "M" => 168.6562 + 4.0923344368 * @d},
  "venus" => {
    "N" => 76.6799 + 2.46590e-5 * @d,
    "i" => 3.3946 + 2.75e-8 * @d,
    "w" => 54.8910 + 1.38374e-5 * @d,
    "a" => 0.723330,
    "e" => 0.006773 - 1.302e-9 * @d,
    #"M" => 48.0052 + 1.602206 * @d},
    "M" => 48.0052 + 1.6021302244 * @d},
  "mars" => {
    "N" => 49.5574 + 2.11081e-5 * @d,
    "i" => 1.8497 - 1.78e-8 * @d,
    "w" => 286.5016 + 2.92961e-5 * @d,
    "a" => 1.523688,
    "e" => 0.093405 + 2.516e-9 * @d,
    "M" => 18.6021 + 0.52398 * @d},
    #"M" => 18.6021 + 0.5240207766 * @d},
  "jupiter" => {
    "N" => 100.4542 + 2.76854e-5 * @d,
    "i" => 1.3030 - 1.557e-7 * @d,
    "w" => 273.8777 + 1.64505e-5 * @d,
    "a" => 5.20256,
    "e" => 0.048498 + 4.469e-9 * @d,
    "M" => 19.8950 + 0.083052 * @d},
    #"M" => 19.8950 + 0.0830853001 * @d},
  "saturn" => {
    "N" => 113.6634 + 2.38980e-5 * @d,
    "i" => 2.4886 - 1.081e-7 * @d,
    "w" => 339.3939 + 2.97661e-5 * @d,
    "a" => 9.55475,
    "e" => 0.055546 - 9.499e-9 * @d,
    "M" => 316.9670 + 0.03339 * @d},
    #"M" => 316.9670 + 0.0334442282 * @d},
  "uranus" => {
    "N" => 74.0005 + 1.3978e-5 * @d,
    "i" => 0.7733 + 1.9e-8 * @d,
    "w" => 96.6612 + 3.0565e-5 * @d,
    "a" => 19.18171 - 1.55e-8 * @d,
    "e" => 0.047318 + 7.45e-9 * @d,
    "M" => 142.5905 + 0.01168 * @d},
    #"M" => 142.5905 + 0.011725806 * @d},
  "neptune" => {
    "N" => 131.7806 + 3.0173e-5 * @d,
    "i" => 1.7700 - 2.55e-7 * @d,
    "w" => 272.8461 - 6.027e-6 * @d,
    "a" => 30.05826 + 3.313e-8 * @d,
    "e" => 0.008606 + 2.15e-9 * @d,
    "M" => 260.2471 + 0.005953 * @d}}
    #"M" => 260.2471 + 0.005995147 * @d}}
  end

  def hms_dms(ra, dec) # Show HMS & DMS
    h, m, s = (ra/15).hms
    ra_hms  = "#{h.to_s.rjust(2)}h #{m.to_s.rjust(2)}m #{s.to_s.rjust(2)}s"
    d, m, s = dec.hms
    dec_dms = "#{d.to_s.rjust(3)}° #{m.to_s.rjust(2)}´ #{s.to_s.rjust(2)}˝"
    return ra_hms, dec_dms
  end

  def alt_az(ra, dec, time)
    pi      = Math::PI
    ra_h = ra/15
    #ha   = (@sidtime - ra_h)*15
    ha   = (time - ra_h)*15
    x    = Math.cos(ha.deg) * Math.cos(dec.deg)
    y    = Math.sin(ha.deg) * Math.cos(dec.deg)
    z    = Math.sin(dec.deg)
    xhor = x * Math.sin(@lat.deg) - z * Math.cos(@lat.deg)
    yhor = y
    zhor = x * Math.cos(@lat.deg) + z * Math.sin(@lat.deg)
    az   = Math.atan2(yhor, xhor)*180/pi + 180
    alt  = Math.asin(zhor)*180/pi
    return alt, az
  end

  def body_alt_az(body, time)
    self.alt_az(self.body_calc(body)[0], self.body_calc(body)[1], time)
  end

  def rts(ra, dec)
    pi      = Math::PI
    transit = (ra - @ls - @lon)/15 + 12 + @tz
    transit = (transit + 24) % 24
    cos_lha = (-Math.sin(@lat.deg) * Math.sin(dec.deg)) / (Math.cos(@lat.deg) * Math.cos(dec.deg))
    if cos_lha < -1
      rise  = "always"
      set   = "never"
    elsif cos_lha > 1
      rise  = "never"
      set   = "always"
    else
      lha   = Math.acos(cos_lha) * 180/pi
      lha_h = lha/15
      rise  = ((transit - lha_h + 24) % 24).to_hms
      set   = ((transit + lha_h + 24) % 24).to_hms
    end
    trans = transit.to_hms
    return rise, trans, set
  end

  def print

    def distf(d)
      int = d.to_i.to_s.rjust(2)
      f   = d % 1
      frc = "%.4f" % f
      return int + frc[1..5]
    end

    out   = "Planet  │ RA          │ Dec          │ Dist. │ Rise  │ Trans │ Set   \n"
    out  += "────────┼─────────────┼──────────────┼───────┼───────┼───────┼────── \n"

    #["sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune"].each do |p|
    ["mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune"].each do |p|
      o     = self.body_calc(p)
      n_o   = (p[0].upcase + p[1..-1]).ljust(7)
      ra_o  = o[3].ljust(11)
      dec_o = o[4].ljust(12)
      d_o   = distf(o[2])[0..-3]
      ris_o = o[5][0..-4].rjust(5)
      tra_o = o[6][0..-4].rjust(5)
      set_o = o[7][0..-4].rjust(5)

      out  += "#{n_o } │ #{ra_o    } │ #{dec_o    } │ #{d_o } │ #{ris_o} │ #{tra_o} │ #{set_o} \n"
    end
    return out
  end

  def initialize (date, lat, lon, tz)
    pi      = Math::PI

    def get_vars(body) # GET VARIABLES FOR THE BODY
      b = @body[body]
      return b["N"], b["i"], b["w"], b["a"], b["e"], b["M"]
    end

    def body_calc(body) # CALCULATE FOR THE BODY
      pi      = Math::PI
      n_b, i_b, w_b, a_b, e_b, m_b = self.get_vars(body)
      w_b     = (w_b + 360) % 360
      m_b     = m_b % 360
      e1      = m_b + (180/pi) * e_b * Math.sin(m_b.deg) * (1 + e_b*Math.cos(m_b.deg))
      e0      = 0
      while (e1 - e0).abs > 0.0005
        e0    = e1
        e1    = e0 - (e0 - (180/pi) * e_b * Math.sin(e0.deg) - m_b) / (1 - e_b * Math.cos(e0.deg))
      end
      e       = e1
      x       = a_b * (Math.cos(e.deg) - e_b)
      y       = a_b * Math.sqrt(1 - e_b*e_b) * Math.sin(e.deg)
      r       = Math.sqrt(x*x + y*y)
      v       = (Math.atan2(y, x)*180/pi + 360) % 360
      xeclip  = r * (Math.cos(n_b.deg) * Math.cos((v+w_b).deg) - Math.sin(n_b.deg) * Math.sin((v+w_b).deg) * Math.cos(i_b.deg))
      yeclip  = r * (Math.sin(n_b.deg) * Math.cos((v+w_b).deg) + Math.cos(n_b.deg) * Math.sin((v+w_b).deg) * Math.cos(i_b.deg))
      zeclip  = r * Math.sin((v+w_b).deg) * Math.sin(i_b.deg)
      lon     =  (Math.atan2(yeclip, xeclip)*180/pi + 360) % 360
      lat     =  Math.atan2(zeclip, Math.sqrt(xeclip*xeclip + yeclip*yeclip))*180/pi
      r_b     =  Math.sqrt(xeclip*xeclip + yeclip*yeclip + zeclip*zeclip)
      m_J     = @body["jupiter"]["M"] 
      m_S     = @body["saturn"]["M"] 
      m_U     = @body["uranus"]["M"] 
      plon    = 0
      plat    = 0
      pdist   = 0
      case body
      when "moon"
        lb     = (n_b + w_b + m_b) % 360
        db     = (lb - @ls + 360) % 360
        fb     = (lb - n_b + 360) % 360
        plon  += -1.274 * Math.sin((m_b - 2*db).deg)
        plon  +=  0.658 * Math.sin((2*db).deg)
        plon  += -0.186 * Math.sin(@ms.deg)
        plon  += -0.059 * Math.sin((2*m_b - 2*db).deg)
        plon  += -0.057 * Math.sin((m_b - 2*db + @ms).deg)
        plon  +=  0.053 * Math.sin((m_b + 2*db).deg)
        plon  +=  0.046 * Math.sin((2*db - @ms).deg)
        plon  +=  0.041 * Math.sin((m_b - @ms).deg)
        plon  += -0.035 * Math.sin(db.deg)
        plon  += -0.031 * Math.sin((m_b + @ms).deg)
        plon  += -0.015 * Math.sin((2*fb - 2*db).deg)
        plon  +=  0.011 * Math.sin((m_b - 4*db).deg)
        plat  += -0.173 * Math.sin((fb - 2*db).deg)
        plat  += -0.055 * Math.sin((m_b - fb - 2*db).deg)
        plat  += -0.046 * Math.sin((m_b + fb - 2*db).deg)
        plat  +=  0.033 * Math.sin((fb + 2*db).deg)
        plat  +=  0.017 * Math.sin((2*m_b + fb).deg)
        pdist += -0.58  * Math.cos((m_b - 2*db).deg)
        pdist += -0.46  * Math.cos(2*db.deg)
      when "jupiter"
        plon  += -0.332 * Math.sin((2*m_J - 5*m_S - 67.6).deg)
        plon  += -0.056 * Math.sin((2*m_J - 2*m_S + 21).deg)
        plon  +=  0.042 * Math.sin((3*m_J - 5*m_S + 21).deg)
        plon  += -0.036 * Math.sin((m_J - 2*m_S).deg)
        plon  +=  0.022 * Math.cos((m_J - m_S).deg)
        plon  +=  0.023 * Math.sin((2*m_J - 3*m_S + 52).deg)
        plon  += -0.016 * Math.sin((m_J - 5*m_S - 69).deg)
      when "saturn"
        plon  +=  0.812 * Math.sin((2*m_J - 5*m_S - 67.6).deg)
        plon  += -0.229 * Math.cos((2*m_J - 4*m_S - 2).deg)
        plon  +=  0.119 * Math.sin((m_J - 2*m_S - 3).deg)
        plon  +=  0.046 * Math.sin((2*m_J - 6*m_S - 69).deg)
        plon  +=  0.014 * Math.sin((m_J - 3*m_S + 32).deg)
        plat  += -0.020 * Math.cos((2*m_J - 4*m_S - 2).deg)
        plat  +=  0.018 * Math.sin((2*m_J - 6*m_S - 49).deg)
      when "uranus"
        plon  +=  0.040 * Math.sin((m_S - 2*m_U + 6).deg)
        plon  +=  0.035 * Math.sin((m_S - 3*m_U + 33).deg)
        plon  += -0.015 * Math.sin((m_J - m_U + 20).deg)
      end
      lon   += plon
      lat   += plat
      r_b   += pdist
      if body == "moon"
        xeclip  = Math.cos(lon.deg) * Math.cos(lat.deg)
        yeclip  = Math.sin(lon.deg) * Math.cos(lat.deg)
        zeclip  = Math.sin(lat.deg)
      else
        xeclip += @xs
        yeclip += @ys
      end
      xequat  = xeclip
      yequat  = yeclip * Math.cos(@ecl.deg) - zeclip * Math.sin(@ecl.deg)
      zequat  = yeclip * Math.sin(@ecl.deg) + zeclip * Math.cos(@ecl.deg)
      ra      = (Math.atan2(yequat, xequat)*180/pi + 360) % 360
      dec     = Math.atan2(zequat, Math.sqrt(xequat*xequat + yequat*yequat))*180/pi
      body   == "moon" ? par = Math.asin(1/r_b)*180/pi : par = (8.794/3600)/r_b
      gclat   = @lat - 0.1924 * Math.sin(2*@lat.deg)
      rho     = 0.99833 + 0.00167 * Math.cos(2*@lat.deg)
      lst     = @sidtime * 15
      ha      = (lst - ra + 360) % 360
      g       = Math.atan(Math.tan(gclat.deg) / Math.cos(ha.deg))*180/pi
      topRA   = ra  - par * rho * Math.cos(gclat.deg) * Math.sin(ha.deg) / Math.cos(dec.deg)
      topDecl = dec - par * rho * Math.sin(gclat.deg) * Math.sin((g - dec).deg) / Math.sin(g.deg)
      ra      = topRA.round(4)
      dec     = topDecl.round(4)
      r       = Math.sqrt(xequat*xequat + yequat*yequat + zequat*zequat).round(4)
      ri, tr, se = self.rts(ra, dec)
      object  = [ra, dec, r, self.hms_dms(ra, dec), ri, tr, se].flatten
      return object
    end
      
    # START OF INITIALIZE
    @lat   = lat
    @lon   = lon
    @tz    = tz
    y      = date[0..3].to_i
    m      = date[5..6].to_i
    d      = date[8..9].to_i
    @d     = 367*y - 7*(y + (m+9)/12) / 4 + 275*m/9 + d - 730530
    @ecl   = 23.4393 - 3.563E-7*@d

    self.body_data

    # SUN
    n_s, i_s, w_s, a_s, e_s, m_s = self.get_vars("sun")
    w_s      = (w_s + 360) % 360
    @ms      = m_s % 360
    es       = @ms + (180/pi) * e_s * Math.sin(@ms.deg) * (1 + e_s*Math.cos(@ms.deg))
    x        = Math.cos(es.deg) - e_s
    y        = Math.sin(es.deg) * Math.sqrt(1 - e_s*e_s)
    v        = Math.atan2(y,x)*180/pi
    r        = Math.sqrt(x*x + y*y)
    tlon     = (v + w_s)%360
    @xs      = r * Math.cos(tlon.deg)
    @ys      = r * Math.sin(tlon.deg)
    xe       = @xs
    ye       = @ys * Math.cos(@ecl.deg)
    ze       = @ys * Math.sin(@ecl.deg)
    r        = Math.sqrt(xe*xe + ye*ye + ze*ze)
    ra       = Math.atan2(ye,xe)*180/pi
    ra_s     = ((ra + 360)%360).round(4)
    dec_s    = (Math.atan2(ze,Math.sqrt(xe*xe + ye*ye))*180/pi).round(4)

    @ls      = (w_s + @ms)%360
    gmst0   = (@ls + 180)/15%24
    @sidtime = gmst0 + @lon/15 
    
    @alt_s, @az_s = self.alt_az(ra_s, dec_s, @sidtime)

    @sun     = [ra_s, dec_s, 1.0, self.hms_dms(ra_s, dec_s)].flatten 
    @moon    = self.body_calc("moon").flatten
    @mercury = self.body_calc("mercury").flatten
    @venus   = self.body_calc("venus").flatten
    @mars    = self.body_calc("mars").flatten
    @jupiter = self.body_calc("jupiter").flatten
    @saturn  = self.body_calc("saturn").flatten
    @uranus  = self.body_calc("uranus").flatten
    @neptune = self.body_calc("neptune").flatten

  end
end
class String # CLASS EXTENSION
  def decoder
    self.gsub(/&#(\d+);/) { |m| $1.to_i(10).chr(Encoding::UTF_8) }
  end
end
class Curses::Window # CLASS EXTENSION 
  attr_accessor :fg, :bg, :attr, :text, :update, :pager, :pager_more, :pager_cmd, :locate, :nohistory 
  # General extensions (see https://github.com/isene/Ruby-Curses-Class-Extension)
  def clr
    self.setpos(0, 0)
    self.maxy.times {self.deleteln()}
    self.refresh
    self.setpos(0, 0)
  end
  def fill # Fill window with color as set by :bg
    self.setpos(0, 0)
    self.bg = 0 if self.bg   == nil
    self.fg = 255 if self.fg == nil
    init_pair(self.fg, self.fg, self.bg)
    blank = " " * self.maxx
    self.maxy.times {self.attron(color_pair(self.fg)) {self << blank}}
    self.refresh
    self.setpos(0, 0)
  end
  def write # Write context of :text to window with attributes :attr
    self.bg   = 0 if self.bg   == nil
    self.fg   = 255 if self.fg == nil
    init_pair(self.fg, self.fg, self.bg)
    self.attr = 0 if self.attr == nil
    self.attron(color_pair(self.fg) | self.attr) { self << self.text }
    self.refresh
    self.text = ""
  end
  def p(fg, bg, attr, text)
    init_pair(fg, fg, bg)
    self.attron(color_pair(fg) | attr) { self << text }
    self.refresh
  end
end
# GENERIC FUNCTIONS 
def getchr # PROCESS KEY PRESSES
  # Note: Curses.getch blanks out @w_t
  # @w_l.getch makes Curses::KEY_DOWN etc not work
  # Therefore resorting to the generic method
  c = STDIN.getch(min: 0, time: 5)
  case c
  when "\e"    # ANSI escape sequences
    case $stdin.getc
    when '['   # CSI
      case $stdin.getc
      when 'A' then chr = "UP"
      when 'B' then chr = "DOWN"
      when 'C' then chr = "RIGHT"
      when 'D' then chr = "LEFT"
      when 'Z' then chr = "S-TAB"
      when '2' then chr = "INS"    ; STDIN.getc
      when '3' then chr = "DEL"    ; STDIN.getc
      when '5' then chr = "PgUP"   ; STDIN.getc
      when '6' then chr = "PgDOWN" ; STDIN.getc
      when '7' then chr = "HOME"   ; STDIN.getc
      when '8' then chr = "END"    ; STDIN.getc
      end
    end
  when "", "" then chr = "BACK"
  when "" then chr = "WBACK"
  when "" then chr = "LDEL"
  when "" then chr = "C-T"
  when "\r" then chr = "ENTER"
  when "\t" then chr = "TAB"
  when /./  then chr = c
  end
  return chr
end
def main_getkey # GET KEY FROM USER
  chr = getchr
  case chr
  when '?' # Show helptext in right window 
    w_u_msg(@help)
  when 'UP'
    @index = @index <= @min_index ? @max_index : @index - 1
  when 'DOWN'
    @index = @index >= @max_index ? @min_index : @index + 1
  when 'PgUP'
    @index -= @w_l.maxy - 2
    @index = @min_index if @index < @min_index
  when 'PgDOWN'
    @index += @w_l.maxy - 2
    @index = @max_index if @index > @max_index
  when 'HOME'
    @index = @min_index
  when 'END'
    @index = @max_index
  when 'l'
    @loc = w_b_getstr("Loc: ", @loc)
  when 'a'
    @lat = w_b_getstr("Lat: ", @lat.to_s).to_f
  when 'o'
    @lon = w_b_getstr("Lon: ", @lon.to_s).to_f
  when 'c'
    @cloudlimit = w_b_getstr("Cloudlimit: ", @cloudlimit.to_s).to_i
  when 'h'
    @humiditylimit = w_b_getstr("Humiditylimit: ", @humiditylimit.to_s).to_i
  when 't'
    @templimit = w_b_getstr("Templimit: ", @templimit.to_s).to_i
  when 'w'
    @windlimit = w_b_getstr("Windlimit: ", @windlimit.to_s).to_i
  when 'b'
    @bortle = w_b_getstr("Bortle: ", @bortle.to_s).to_i
  when 'e'
    ev = "\nUPCOMING EVENTS:\n\n"
    @events.each do |key, val|  
      ev += key + " " + val["time"] + " " + val["event"] + "\n"
    end
    w_u_msg(ev)
  when 'p'
    info  = @weather[@index][3].split("\n")[0][0..-7] + "\n\n"
    info += @planets[@weather[@index][0]]["table"]
    w_u_msg(info)
  when 's'
    starchart
    @image = "/tmp/starchart.jpg"
    image_show("clear")
    image_show(@image)
  when 'S'
    begin
      Thread.new { system("xdg-open '/tmp/starchart.jpg'") }
    rescue
    end
    @break = true
  when 'A'
    apod
    @image = "/tmp/apod.jpg"
    image_show("clear")
    image_show(@image)
  when 'ENTER' # Refresh image
    image_show(@image)
  when 'r' # Refresh all windows 
    @break = true
  when '@' # Enter "Ruby debug"
    @w_b.nohistory = false
    cmd = w_b_getstr("◆ ", "")
    begin
      @w_b.text = eval(cmd)
      @w_b.fill
      @w_b.write
    rescue StandardError => e
      w_b_info("Error: #{e.inspect}")
    end
    @w_b.update = false
  when ';' # Show command history 
    w_u_info("Command history (latest on top):\n\n" + @history.join("\n"))
  when 'R' # Reload .ap.conf
    if File.exist?(Dir.home+'/.ap.conf')
      load(Dir.home+'/.ap.conf')
    end
    w_b_info(" Config reloaded")
    @w_b.update = false
  when 'W' # Write all parameters to .ap.conf
    @write_conf_all = true
    conf_write
  when 'q' # Exit 
    @write_conf = true
    exit 0
  when 'Q' # Exit without writing to .ap.conf
    @write_conf = false
    exit 0
  end
end
def get_weather # WEATHER FORECAST FROM MET.NO
  weatherURI     = "https://api.met.no/weatherapi/locationforecast/2.0/complete?"
  weather_json   = weatherURI + "lat=#{@lat}&lon=#{@lon}"
  weather_data   = JSON.parse(Net::HTTP.get(URI(weather_json)))
  @weather_point = weather_data["properties"]["timeseries"]
  weather_size   = @weather_point.size
  @weather       = []
  weather_size.times do |t|
    details = @weather_point[t]["data"]["instant"]["details"]
    time    = @weather_point[t]["time"]
    date    = time[0..9]
    hour    = time[11..12]
    wthr    = details["cloud_area_fraction"].to_i.to_s.rjust(5) + "%"
    wthr   += details["relative_humidity"].to_s.rjust(7)
    wthr   += details["air_temperature"].to_s.rjust(6)
    wind    = details["wind_speed"].to_s + " ("
    case details["wind_from_direction"].to_i
    when 0..22
      wdir = "N"
    when 23..67
      wdir = "NE"
    when 68..112
      wdir = "E"
    when 113..158
      wdir = "SE"
    when 159..203
      wdir = "S"
    when 204..249
      wdir = "SW"
    when 250..294
      wdir = "W"
    when 295..340
      wdir = "NW"
    else
      wdir = "N"
    end
    wind += wdir.rjust(2)
    wthr += wind.rjust(10) + ")"
    info  = date + " (" + Date.parse(date).strftime("%A") + ") #{hour}:00\n\n" 
    info += "Cloud cover (-/+)  " + details["cloud_area_fraction"].to_i.to_s + "% (" 
    info += details["cloud_area_fraction_low"].to_i.to_s + "% " + details["cloud_area_fraction_high"].to_i.to_s + "%)\n"
    details["fog_area_fraction"] == 0 ? fog = "-" : fog = (details["fog_area_fraction"].to_f.round(1)).to_s + "%" 
    info += "Humidity/Fog       " + details["relative_humidity"].to_s + "% / " + fog + "\n"
    info += "Temp (dew point)   " + details["air_temperature"].to_s + "°C ("
    info += details["dew_point_temperature"].to_s + "°C)\n"
    info += "Wind [gust speed]  " + details["wind_speed"].to_s + " m/s (" + wdir + ") [" + details["wind_speed_of_gust"].to_s + " m/s]\n"
    info += "Air pressure       " + details["air_pressure_at_sea_level"].to_i.to_s + " hPa\n"
    info += "UV index           " + details["ultraviolet_index_clear_sky"].to_s + "\n"
    @weather.push([date, hour, wthr, info])
  end
end
def get_astro # ASTRONOMICAL DATA FROM MET.NO (official and precise)
  astro = {}
  astroURI      = "https://api.met.no/weatherapi/sunrise/2.0/?lat=#{@lat}&lon=#{@lon}&date="
  10.times do |x|
    date        = (Time.now + 86400 * x).strftime("%F")
    d_add       = "#{date}&offset=#{@tz}:00"
    astro_xml   = astroURI + d_add
    astro_data  = Net::HTTP.get(URI(astro_xml))
    sunrise     = astro_data[/<sunrise time="\d\d\d\d-\d\d-\d\dT(\d\d:\d\d:\d\d)/,1]
    sunrise     = "(no data)" if sunrise == nil
    sunset      = astro_data[/<sunset time="\d\d\d\d-\d\d-\d\dT(\d\d:\d\d:\d\d)/,1]
    sunset      = "(no data)" if sunset == nil
    moonrise    = astro_data[/<moonrise time="\d\d\d\d-\d\d-\d\dT(\d\d:\d\d:\d\d)/,1]
    moonrise    = "(no data)" if moonrise == nil
    moonset     = astro_data[/<moonset time="\d\d\d\d-\d\d-\d\dT(\d\d:\d\d:\d\d)/,1]
    moonset     = "(no data)" if moonset == nil
    moonphase   = astro_data[/MOON PHASE=(.*)/,1].to_f
    astro[date] = {"sunrise" => sunrise, "sunset" => sunset, "moonrise" => moonrise, "moonset" => moonset, "moonphase" => moonphase} 
  end
  return astro
end
def get_planets # PLANET EPHEMERIS DATA
  planets = {}
  10.times do |x|
    date          = (Time.now + 86400 * x).strftime("%F")
    p             = Ephemeris.new(date, @lat, @lon, @tz.to_i)
    planets[date] = {"table" => p.print, 
                     "Mrise" => p.mercury[5], "Mset" => p.mercury[7],
                     "Vrise" => p.venus[5],   "Vset" => p.venus[7],
                     "Arise" => p.mars[5],    "Aset" => p.mars[7],
                     "Jrise" => p.jupiter[5], "Jset" => p.jupiter[7],
                     "Srise" => p.saturn[5],  "Sset" => p.saturn[7],
                     "Urise" => p.uranus[5],  "Uset" => p.uranus[7],
                     "Nrise" => p.neptune[5], "Nset" => p.neptune[7]}
  end
  return planets
end
def get_events # ASTRONOMICAL EVENTS
  events = {}
  eventsURI   = "https://in-the-sky.org//rss.php?feed=dfan&latitude=#{@lat}&longitude=#{@lon}&timezone=#{@loc}"
  events_rss  = Net::HTTP.get(URI(eventsURI))
  events_data = events_rss.scan(/<item>.*?<\/item>/m)
  events_data.each do |e|
    date  = Time.parse(e[/<title>(.{11})/,1]).strftime("%F")
    time  = e[/\d\d:\d\d:\d\d/]
    event = e[/<description>&lt;p&gt;(.*?).&lt;\/p&gt;<\/description>/,1].decoder
    event.gsub!(/&amp;deg;/, "°")
    event.gsub!(/&amp;#39;/, "'")
    link  = e[/<link>(.*?)<\/link>/,1]
    events[date] = {"time" => time, "event" => event, "link" => link} if date >= @today
  end
  return events
end
def get_cond(t) # GREEN/YELLOW/RED FROM CONDITIONS
  details = @weather_point[t]["data"]["instant"]["details"]
  cond = 0
  cond += 1 if details["cloud_area_fraction"].to_i > @cloudlimit
  cond += 1 if details["cloud_area_fraction"].to_i > @cloudlimit + (100 - @cloudlimit)/2 
  cond += 2 if details["cloud_area_fraction"].to_i > 90
  cond += 1 if details["relative_humidity"].to_i > @humiditylimit
  cond += 1 if details["air_temperature"].to_i < @templimit
  cond += 1 if details["wind_speed"].to_i > @windlimit
  case cond
  when 0..1
    return 1
  when 2..3
    return 2
  else
    return 3
  end
end
def conf_write # WRITE TO .AP.CONF
  if File.exist?(Dir.home+'/.ap.conf')
    conf = File.read(Dir.home+'/.ap.conf')
  else
    conf = ""
  end
  if @write_conf_all
    conf.sub!(/^@loc.*/, "@loc = \"#{@loc}\"")
    conf.sub!(/^@lat.*/, "@lat = #{@lat}")
    conf.sub!(/^@lon.*/, "@lon = #{@lon}")
    conf.sub!(/^@cloudlimit.*/, "@cloudlimit = #{@cloudlimit}")
    conf.sub!(/^@humiditylimit.*/, "@humiditylimit = #{@humiditylimit}")
    conf.sub!(/^@templimit.*/, "@templimit = #{@templimit}")
    conf.sub!(/^@windlimit.*/, "@windlimit = #{@windlimit}")
    w_u_msg("Press W again to write this to .ap.conf:\n\n" + conf)
    if getchr == 'W'
      w_b_info(" Parameters written to .ap.conf")
      @w_b.update = false
    else
      w_b_info(" Config NOT updated")
      @w_b.update = false
      return
    end
  end
  File.write(Dir.home+'/.ap.conf', conf)
end
# TOP WINDOW FUNCTIONS 
def w_t_info # SHOW INFO IN @w_t
  @w_t.clr
  text  = " #{@loc} (tz=#{'%02d' % @tz}) Lat: #{@lat}, Lon: #{@lon} " 
  text += "(Bortle #{@bortle})  "
  text += "Updated: #{@time} (JD: 24#{DateTime.now.amjd().to_f.round(2)})"
  text += " " * (@w_t.maxx - text.length) if text.length < @w_t.maxx
  @w_t.text = text
  @w_t.write
end
# LEFT WINDOW FUNCTIONS
def print_sm(ix, date, rise, set, c0, c1, c2)
  if @astro[date][set][0..1] < @astro[date][rise][0..1] and @weather[ix][1] <= @astro[date][set][0..1]
    @w_l.p(c0,c0,0," ")
  elsif @astro[date][set][0..1] < @astro[date][rise][0..1] and @weather[ix][1] >= @astro[date][rise][0..1]
    @w_l.p(c0,c0,0," ")
  elsif @weather[ix][1] > @astro[date][rise][0..1] and @weather[ix][1] < @astro[date][set][0..1]
    @w_l.p(c0,c0,0," ")
  elsif @weather[ix][1] == @astro[date][rise][0..1]
    @w_l.p(c1,c1,0," ")
  elsif @weather[ix][1] == @astro[date][set][0..1]
    @w_l.p(c2,c2,0," ")
  else
    @w_l << " "
  end
end
def print_p(ix, date, rise, set, c)
  @w_l << " "
  if @planets[date][set] == "never"
    @w_l.p(c,0,0,"┃")
  elsif @planets[date][set][0..1] < @planets[date][rise][0..1] and @weather[ix][1] <= @planets[date][set][0..1]
    @w_l.p(c,0,0,"┃")
  elsif @planets[date][set][0..1] < @planets[date][rise][0..1] and @weather[ix][1] >= @planets[date][rise][0..1]
    @w_l.p(c,0,0,"┃")
  elsif @weather[ix][1] >= @planets[date][rise][0..1] and @weather[ix][1] <= @planets[date][set][0..1]
    @w_l.p(c,0,0,"┃")
  else
    @w_l << " "
  end
end
def w_l_info # SHOW WEATHER CONDITION AND RISE/SET IN @w_l
  @w_l.clr
  @w_l.attron(Curses::A_BLINK) { @w_l << "YYYY-MM-DD  HH  Cld%   Hum%    °C   Wind m/s  * ● ○ m V M J S U N\n" }
  ix = 0; t = 1; prev_date = ""
  ix = @index - @w_l.maxy/2 if @index > @w_l.maxy/2 and @weather.size > @w_l.maxy
  while ix < @weather.size and t < @w_l.maxy do
    marker = 0
    color  = color_pair(get_cond(ix))
    date = @weather[ix][0]
    date == prev_date ? line = "            " : line = date + "  "
    @w_l.attron(color) { @w_l << line } 
    marker = Curses::A_UNDERLINE if ix == @index
    line   = @weather[ix][1] + @weather[ix][2]
    @w_l.attron(color | marker) { @w_l << line }
    if @events.has_key?(date)
      @events[date]["time"][0..1] == @weather[ix][1] ? line = "  ! " : line = "    "
    else
      line = "    "
    end
    begin
      @w_l.attron(color) { @w_l << line }
      print_sm(ix, date, "sunrise", "sunset", 226, 193, 214)
      @w_l << " "
      c0 = ((50 - (@astro[date]["moonphase"] - 50).abs)/2.7 + 237).to_i
      print_sm(ix, date, "moonrise", "moonset", c0, 110, 109)
      print_p(ix, date, "Mrise", "Mset", 130)
      print_p(ix, date, "Vrise", "Vset", 153)
      print_p(ix, date, "Arise", "Aset", 124)
      print_p(ix, date, "Jrise", "Jset", 108)
      print_p(ix, date, "Srise", "Sset", 142)
      print_p(ix, date, "Urise", "Uset", 24)
      print_p(ix, date, "Nrise", "Nset", 27)
    rescue
    end
    clrtoeol
    @w_l << "\n"
    prev_date = date unless date == prev_date
    ix += 1
    t  += 1
  end
  @w_l.refresh
end
# RIGHT UPPER WINDOW FUNCTIONS
def w_u_msg(msg) # MESSAGES IN @w_u
  @w_u.clr
  @w_u.text = msg
  @w_u.write
  @w_u.update = false
end
def w_u_info # ASTRO INFO IN @w_u
  @w_u.clr
  color  = color_pair(get_cond(@index)) 
  info   = @weather[@index][3].split("\n")
  @w_u.attron(color) { @w_u << info[0] }
  @w_u.write
  info.shift
  @w_u.maxx < Curses.cols ? maxx = @w_u.maxx : maxx = Curses.cols
  info.each_with_index do |line, index| 
    line += " "*(maxx - line.length - 1)
    info[index] = line
  end
  @w_u.text  = info.join("\n")
  @w_u.text += "\n\n"
  date = @weather[@index][0]
  begin
    @w_u.text += "Sunrise/set        " + @astro[date]["sunrise"] + " / " + @astro[date]["sunset"] + "\n"
    @w_u.text += "Moonrise/set       " + @astro[date]["moonrise"] + " / " + @astro[date]["moonset"] + "\n" 
    phase = @astro[date]["moonphase"]
    if phase < 2.5
      phrase = "New moon"
    elsif phase < 27.5
      phrase = "Waxing crescent"
    elsif phase < 32.5
      phrase = "First quarter"
    elsif phase < 47.5
      phrase = "Waxing gibbous"
    elsif phase < 52.5
      phrase = "Full moon"
    elsif phase < 72.5
      phrase = "Waning gibbous"
    elsif phase < 77.5
      phrase = "Last quarter"
    elsif phase < 97.5
      phrase = "Waning crescent"
    else
      phrase = "New moon"
    end
    @w_u.text += "Moon phase         " + @astro[date]["moonphase"].to_s + " (#{phrase})"
    @w_u.write
  rescue
  end
  @w_u << "\n\n"
  if @events.has_key?(date)
    text  = "@ " + @events[date]["time"] + ": "
    text += @events[date]["event"] + "\n"
    text += @events[date]["link"] + "\n"
    if @events[date]["time"][0..1] == @weather[@index][1]
      @w_u.p(111,0,Curses::A_BOLD,text)
    else
      @w_u.text = text
      @w_u.write
    end
  end
end
# RIGHT LOWER WINDOW FUNCTIONS
def image_show(image)# SHOW THE SELECTED IMAGE IN TOP RIGHT WINDOW
  # Pass "clear" to clear the window for previous image
  begin
    terminfo    = `xwininfo -id $(xdotool getactivewindow)`
    term_w      = terminfo.match(/Width: (\d+)/)[1].to_i
    term_h      = terminfo.match(/Height: (\d+)/)[1].to_i
    char_w      = term_w / Curses.cols
    char_h      = term_h / Curses.lines
    img_x       = char_w * (@w_l_width + 1)
    img_y       = char_h * (Curses.lines/2)
    img_max_w   = char_w * (Curses.cols - @w_l_width - 2)
    img_max_h   = char_h * (Curses.lines/2 - 2)
    if image == "clear"
      img_max_w += 2
      img_max_h += 2
      `echo "6;#{img_x};#{img_y};#{img_max_w};#{img_max_h};\n4;\n3;" | #{@w3mimgdisplay}`
    else
      img_w,img_h = `identify -format "%[fx:w]x%[fx:h]" #{image} 2>/dev/null`.split('x')
      img_w       = img_w.to_i
      img_h       = img_h.to_i
      if img_w > img_max_w
        img_h = img_h * img_max_w / img_w 
        img_w = img_max_w
      end
      if img_h > img_max_h
        img_w = img_w * img_max_h / img_h
        img_h = img_max_h
      end
      `echo "0;1;#{img_x};#{img_y};#{img_w};#{img_h};;;;;\"#{image}\"\n4;\n3;" | #{@w3mimgdisplay}`
    end
  rescue
    @w_u << "Error showing image"
  end
end
def starchart # GET AND SHOW STARCHART FOR SELECTED TIME
  d = Time.parse(@weather[@index][0]).strftime("%d").to_i
  m = Time.parse(@weather[@index][0]).strftime("%m").to_i
  y = Time.parse(@weather[@index][0]).strftime("%Y").to_i
  starchartURI = "https://www.stelvision.com/carte-ciel/visu_carte.php?stelmarq=C&mode_affichage=normal&req=stel&date_j_carte=#{d}&date_m_carte=#{m}&date_a_carte=#{y}&heure_h=#{@weather[@index][1].to_i}&heure_m=00&longi=#{@lon}&lat=#{@lat}&tzone=#{@tz.to_i}.0&dst_offset=1&taille_carte=1200&fond_r=255&fond_v=255&fond_b=255&lang=en"
  `curl -s "#{starchartURI}" > /tmp/stars.png`
  `convert /tmp/stars.png /tmp/starchart.jpg`
  #`convert /tmp/stars.png -fuzz 25% -fill none -draw "matte 0,0 floodfill" -background black -flatten /tmp/starchart.jpg`
end
def apod # GET ASTRONOMY PICTRUE OF THE DAY
  apod = Net::HTTP.get(URI("https://apod.nasa.gov/apod/astropix.html"))
  apod.sub!(/^.*IMG SRC=./m, "")
  apod.sub!(/\".*/m, "")
  apod = "https://apod.nasa.gov/apod/" + apod
  `curl -s "#{apod}" > /tmp/apod.jpg`
end
# BOTTOM WINDOW FUNCTIONS 
def w_b_info(info) # SHOW INFO IN @W_B
  @w_b.clr
  info      = "?=Show Help | Edit: l=Loc a=Lat o=Lon | s=Starchart for selected time | ENTER=Refresh r=Redraw q=Quit Q=Quit (no config save)" if info == nil
  info      = info[1..(@w_b.maxx - 3)] + "…" if info.length + 3 > @w_b.maxx 
  info     += " " * (@w_b.maxx - info.length) if info.length < @w_b.maxx
  @w_b.text = info
  @w_b.write
  @w_b.update = false
end
def w_b_getstr(pretext, text) # A SIMPLE READLINE-LIKE ROUTINE
  Curses.curs_set(1)
  Curses.echo
  stk = 0
  @history.insert(stk, text)
  pos = @history[stk].length
  chr = ""
  while chr != "ENTER"
    @w_b.setpos(0,0)
    @w_b.text = pretext + @history[stk]
    @w_b.text += " " * (@w_b.maxx - text.length) if text.length < @w_b.maxx
    @w_b.write
    @w_b.setpos(0,pretext.length + pos)
    @w_b.refresh
    chr = getchr
    case chr
    when 'UP'
      unless @w_b.nohistory
        unless stk == @history.length - 1
          stk += 1 
          pos = @history[stk].length
        end
      end
    when 'DOWN'
      unless @w_b.nohistory
        unless stk == 0
          stk -= 1 
          pos = @history[stk].length
        end
      end
    when 'RIGHT'
      pos += 1 unless pos > @history[stk].length
    when 'LEFT'
      pos -= 1 unless pos == 0
    when 'HOME'
      pos = 0
    when 'END'
      pos = @history[stk].length
    when 'DEL'
      @history[stk][pos] = ""
    when 'BACK'
      unless pos == 0
        pos -= 1
        @history[stk][pos] = ""
      end
    when 'WBACK'
      unless pos == 0
        until @history[stk][pos - 1] == " " or pos == 0
          pos -= 1
          @history[stk][pos] = ""
        end
        if @history[stk][pos - 1] == " "
          pos -= 1
          @history[stk][pos] = ""
        end
      end
    when 'LDEL'
      @history[stk] = ""
      pos = 0
    when /^.$/
      @history[stk].insert(pos,chr)
      pos += 1
    end
  end
  curstr = @history[stk]
  @history.shift if @w_b.nohistory
  unless @w_b.nohistory
    @history.uniq!
    @history.compact!
    @history.delete("")
  end
  Curses.curs_set(0)
  Curses.noecho
  return curstr
end

# MAIN PROGRAM 
loop do # OUTER LOOP - (catching refreshes via 'r')
  @break = false # Initialize @break variable (set if user hits 'r')
  @today = Time.now.strftime("%F")
  @tz    = Time.now.strftime("%z")[0..2]
  @time  = Time.now.strftime("%H:%M")
  get_weather
  @planets = get_planets
  @astro  = get_astro
  @events = get_events
  Thread.new {starchart}
  Thread.new {apod}
  begin # Create the four windows/panels 
    Curses.stdscr.bg = 236 # Use for borders
    Curses.stdscr.fill
    maxx = Curses.cols
    exit if maxx < @w_l_width
    maxy = Curses.lines
    # Curses::Window.new(h,w,y,x)
    @w_t = Curses::Window.new(1, maxx, 0, 0)
    @w_b = Curses::Window.new(1, maxx, maxy - 1, 0)
    @w_l = Curses::Window.new(maxy - 2, @w_l_width - 1, 1, 0)
    @w_u = Curses::Window.new(maxy/2 - 1, maxx - @w_l_width, 1, @w_l_width)
    @w_d = Curses::Window.new(maxy/2, maxx - @w_l_width, maxy/2, @w_l_width)
    @w_t.fg, @w_t.bg = 7, 19
    @w_t.attr        = Curses::A_BOLD
    @w_b.fg, @w_b.bg = 7, 17
    @w_d.fill
    @w_t.update = true
    @w_b.update = true
    @w_l.update = true
    @w_u.update = true
    @w_d.update = true
    loop do # INNER, CORE LOOP 
      @min_index = 0
      @max_index = @weather.size - 1
      # Top window (info line) 
      w_t_info
      # Bottom window (command line) Before @w_u to avoid image dropping out on startup
      w_b_info(nil) if @w_b.update
      @w_b.update = true
      # Left and right windows (browser & content viewer)
      w_l_info
      w_u_info if @w_u.update
      @w_u.update = true
      Curses.curs_set(1) # Clear residual cursor
      Curses.curs_set(0) # ...from editing files 
      main_getkey        # Get key from user 
      @w_u.text = ""
      if @w_d.update
        image_show("clear")
        image_show(@image)
      end
      @w_d.update = false
      break if @break    # Break to outer loop, redrawing windows, if user hit 'r'
      break if Curses.cols != maxx or Curses.lines != maxy # break on terminal resize 
    end
  ensure # On exit: close curses, clear terminal 
    @write_conf_all = false
    conf_write if @write_conf # Write marks to config file
    image_show("clear")
    close_screen
  end
end

# vim: set sw=2 sts=2 et fdm=syntax fdn=2 fcs=fold\:\ :
