require 'ohm'
require 'rumonade'
require_relative 'const.rb'

Ohm.connect :url => REDIS_URL, :thread_safe => true

class Model < Ohm::Model
  def self.find_or_create(params)
    Option(find(params).first).get_or_else(create(params))
  end
end

class Feed < Model
  attribute :url
  index :url
  set :users, :User
end

class User < Model
  attribute :uid
  index :uid
  set :feeds, :Feed
end
