require File.expand_path('../lib/gametools/version.rb', __FILE__)

Gem::Specification.new { |s|
  s.name        = 'gametools'
  s.version     = GT::GAMETOOLS_VERSION
  s.date        = GT::GAMETOOLS_DATE
  s.summary     = 'Tools for Ruby game development'
  s.description = 'A gem of tools for Ruby game development using GLFW 3 and OpenGL.'
  s.authors     = [ 'Noel Raymond Cower' ]
  s.email       = 'ncower@gmail.com'
  s.files       = Dir.glob('lib/**/*.rb') +
                  [ 'COPYING', 'README.md' ]
  s.homepage    = 'https://github.com/nilium/ruby-gametools'
  s.license     = GT::GAMETOOLS_LICENSE_BRIEF
  s.has_rdoc    = true
  s.extra_rdoc_files = [
      'README.md',
      'COPYING'
  ]
  s.add_dependency 'glfw3',       '>= 0.4.4'
  # s.add_dependency 'opengl-core', '>= 1.3.1'
  # s.add_dependency 'snow-math',   '>= 1.6.0'
  # s.add_dependency 'snow-data',   '>= 1.3.0'
  # s.add_dependency 'stb-image',   '>= 1.0.1'
}
