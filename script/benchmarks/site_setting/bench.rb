require 'benchmark/ips'
require File.expand_path('../../../../config/environment', __FILE__)

# Put pre conditions here
# Used db but it's OK in the most cases

# build the cache
SiteSetting.title = SecureRandom.hex
SiteSetting.default_locale = SiteSetting.default_locale == 'en' ? 'zh_CN' : 'en'
SiteSetting.refresh!

tests = [
  ["current cache", lambda do
    SiteSetting.title
    SiteSetting.enable_sso
  end
  ],
  ["change default locale with current cache refreshed", lambda do
    SiteSetting.default_locale = SiteSetting.default_locale == 'en' ? 'zh_CN' : 'en'
  end
  ],
  ["change site setting", lambda do
    SiteSetting.title = SecureRandom.hex
  end
  ],
]

Benchmark.ips do |x|
  tests.each do |test, proc|
    x.report(test, proc)
  end
end


# 28-07-2017 - Erick's Site Setting change

# Before
# Calculating -------------------------------------
# current cache    400.339k (± 4.5%) i/s -      2.030M in   5.081421s
# change default locale with current cache refreshed
# 181.503  (± 5.0%) i/s -    918.000  in   5.071343s
# change site setting    172.146  (± 4.1%) i/s -    864.000  in   5.028832s


# After
# Calculating -------------------------------------
# current cache    389.542k (± 4.5%) i/s -      1.953M in   5.022523s
# change default locale with current cache refreshed
# 136.545  (± 5.1%) i/s -    686.000  in   5.039420s
# change site setting    151.618  (± 4.6%) i/s -    765.000  in   5.056182s
