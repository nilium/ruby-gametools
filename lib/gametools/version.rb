module GT
  GAMETOOLS_VERSION       = '0.0.1pre2'
  GAMETOOLS_DATE          = '2013-07-28'
  GAMETOOLS_LICENSE_BRIEF = 'Simplified BSD'
  GAMETOOLS_PATH          = File.expand_path("../../../", __FILE__)
  GAMETOOLS_LICENSE_FULL  = File.open("#{GAMETOOLS_PATH}/COPYING") { |io| io.read }
end
