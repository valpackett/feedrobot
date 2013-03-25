require 'ohm'
require_relative 'const.rb'

Ohm.connect :url => REDIS_URL, :thread_safe => true

class Model < Ohm::Model
  def self.find_or_create(params)
    find(params).first || create(params)
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

class Subscription
  def self.find_or_create(url, uid)
    [Feed.find_or_create(:url => url), User.find_or_create(:uid => uid)]
  end

  def self.subscribe_user(url, uid)
    feed, user = find_or_create url, uid
    feed.users.add user
    feed.save
    user.feeds.add feed
    user.save
  end

  def self.unsubscribe_user(url, uid)
    feed, user = find_or_create url, uid
    feed.users.delete user
    feed.save
    user.feeds.delete feed
    user.save
  end
end
