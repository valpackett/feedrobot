require 'rumonade'
require 'feedisco'
require_relative 'adn.rb'
require_relative 'app.rb'

HELP_TEXT = "Hi, I'm FeedRobot! Send me a feed URL to subscribe, the URL prefixed with a minus to unsubscribe, 'list' to see feeds you're subscribed to, 'help' to see this message again."

class Worker
  def self.start
    loop do
      if $superfeedr
        work
      else
        puts "No Superfeedr yet..."
      end
      sleep 10
    end
  end

  def self.work
    adn = @adn = ADN.global
    adn.follow_followers.each do |uid|
      p "Follow follower #{uid}"
      adn.send_pm :destinations => [uid], :text => HELP_TEXT
    end
    adn.unread_pm_channel_ids.each do |cid|
      p "Unread pm channel #{cid}"
      adn.unread_messages(cid).each do |msg|
        process_msg msg
      end
    end
  end

  def self.reply(msg, params)
    @adn.send_msg msg['channel_id'], params
  end

  def self.subscribe(msg, url)
    url = Feedisco.find(url).first
    if url
      feed = Feed.find_or_create :url => url
      user = User.find_or_create :uid => msg['user']['id']
      feed.users.add user
      feed.save
      user.feeds.add feed
      user.save
      sub = $superfeedr.subscribe url
      unless sub
        reply msg, :text => "Error: #{$superfeedr.error}"
      else
        reply msg, :text => "Subscribed to #{url}!"
      end
    else
      reply msg, :text => "Feed not found at #{url} :-("
    end
  end

  def self.unsubscribe(msg, url)
    feed = Feed.find_or_create :url => url
    user = User.find_or_create :uid => msg['user']['id']
    feed.users.delete user
    feed.save
    user.feeds.delete feed
    user.save
    reply msg, :text => "Unsubscribed from #{url}!"
  end

  def self.list(msg)
    user = User.find_or_create :uid => msg['user']['id']
    feedlist = user.feeds.map(&:url).join "\n"
    reply msg, :text => "Here are the feeds you're subscribed to:\n#{feedlist}"
  end

  def self.process_msg(msg)
    p "Processing: #{msg['text']}"
    case msg['text']
    when /-http(.*)$/ then unsubscribe msg, "http#{$1}"
    when /http(.*)$/ then subscribe msg, "http#{$1}"
    when "list" then list msg
    when "help", "'help'" then reply msg, :text => HELP_TEXT
    else reply msg, :text => "I don't understand! Send 'help' to see how to talk to me."
    end
  end
end
