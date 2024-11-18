Gem::Specification.new do |s|
  s.name        = 'astropanel'
  s.version     = '1.1.6'
  s.licenses    = ['Unlicense']
  s.summary     = "Terminal program for amateur astronomers with weather forecast."
  s.description = "This program shows essential data in order to plan your observations: 9 days weather forecast, full ephemeris for the Sun, the Moon and all major planets, complete with graphic representation of rise/set times, detailed info for each day with important astronomical events, star chart displayed in the terminal and more. New in 1.1.6: Dropped the '.rb' suffix"
  s.authors     = ["Geir Isene"]
  s.email       = 'g@isene.com'
  s.files       = ["bin/astropanel"]
  s.add_runtime_dependency 'curses', '~> 1.3', '>= 1.3.2'
  s.executables << 'astropanel'
  s.homepage    = 'https://isene.com/'
  s.metadata    = { "source_code_uri" => "https://github.com/isene/astropanel" }
end
