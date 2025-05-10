Gem::Specification.new do |s|
  s.name        = 'astropanel'
  s.version     = '2.2'
  s.licenses    = ['Unlicense']
  s.summary     = "Terminal program for amateur astronomers with weather forecast."
  s.description = "This program shows essential data in order to plan your observations: 9 days weather forecast, full ephemeris for the Sun, the Moon and all major planets, complete with graphic representation of rise/set times, detailed info for each day with important astronomical events, star chart displayed in the terminal and more. New in 2.0: Full rewrite using rcurses (https://github.com/isene/rcurses). 2.2: Fixed help (key '?')"
  s.authors     = ["Geir Isene"]
  s.email       = 'g@isene.com'
  s.files       = ["bin/astropanel", "README.md"]
  s.add_runtime_dependency 'rcurses', '~> 3.5'
  s.executables << 'astropanel'
  s.homepage    = 'https://isene.com/'
  s.metadata    = { "source_code_uri" => "https://github.com/isene/astropanel" }
end
