source 'https://rubygems.org'

# serving
gem "thin"
gem "sinatra"
gem "rack-superfeedr"

# requesting
gem "typhoeus"
gem "em-http-request"
gem "faraday"
gem "faraday_middleware"
gem "faraday_middleware-multi_json"
gem "omniauth"
gem "omniauth-appdotnet"
gem "feedisco", :git => "git://github.com/rchampourlier/feedisco.git"

# storing
gem "hiredis"
gem "ohm"

# etc
gem "oj"
gem "sentry-raven"
gem "rumonade"
gem "builder"
gem "rufus-scheduler"

group :development, :test do
  gem "rspec"
  gem "rack-test"
  gem "shotgun"
end

group :production do
  gem "newrelic_rpm"
end
