Gem::Specification.new do |s|
  s.name        = 'astropanel'
  s.version     = '4.1.0'
  s.licenses    = ['Unlicense']
  s.summary     = "Terminal program for amateur astronomers with weather forecast."
  s.description = "AstroPanel v4.1.0: Modern image display using termpix gem with Sixel and w3m protocol support. This program shows essential data in order to plan your observations: 9 days weather forecast, full ephemeris for the Sun, the Moon and all major planets, complete with graphic representation of rise/set times, detailed info for each day with important astronomical events, star chart displayed in the terminal and more."
  s.authors     = ["Geir Isene"]
  s.email       = 'g@isene.com'
  s.files       = ["bin/astropanel", "README.md"]
  s.add_runtime_dependency 'rcurses', '~> 6.0'
  s.add_runtime_dependency 'termpix', '~> 0.1'
  s.executables << 'astropanel'
  s.homepage    = 'https://isene.com/'
  s.metadata    = { "source_code_uri" => "https://github.com/isene/astropanel" }
end
