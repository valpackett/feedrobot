require 'rubygems'
require 'faraday'
require 'raven'
require './app/app.rb'
require './app/worker.rb'
require './app/const.rb'

Thread.abort_on_exception = true

if ADN_TOKEN
  Thread.new do
    Raven.capture do
      Worker.start
    end
  end

  Thread.new do
    # make a request to set the superfeedr global
    Faraday.get "http://#{HOST}"
  end
else
  puts "No ADN_TOKEN, not running worker"
end

use Raven::Rack
use Rack::CommonLogger

run FeedRobot
