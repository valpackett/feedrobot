require 'rubygems'
require 'faraday'
require 'raven'
require './app/app.rb'
require './app/worker.rb'

Thread.abort_on_exception = true

Thread.new do
  Worker.start
end

Thread.new do
  # make a request to set the superfeedr global
  Faraday.get "http://#{HOST}"
end

use Raven::Rack
use Rack::CommonLogger

run FeedRobot
