require_relative 'const.rb'
require_relative 'adn.rb'
require_relative 'app.rb'
require_relative 'models.rb'
require_relative 'message.rb'
require 'em-http-request'
require 'multi_json'

class Worker
  def self.start
    while $superfeedr.nil?
      puts "No Superfeedr yet..."
      sleep 10
    end
    EM.run do
      work
    end
  end

  def self.reconnect(*args)
    EM.add_timer 10 do
      puts "Reconnecting!"
      work
    end
  end

  def self.work
    adn = ADN.global
    http = EM::HttpRequest.new('https://stream-channel.app.net/stream/user', :inactivity_timeout => 0).get(
      :head => {'Authorization' => "Bearer #{adn.token}"},
      :keepalive => true,
      :query => {'connection_id' => Ohm.redis.get('conn')}
    )

    http.errback &method(:reconnect)
    http.callback &method(:reconnect)

    http.headers do |hash|
      id = hash['CONNECTION_ID']
      adn.stream 'channels?include_annotations=1', id
      puts 'Stream started'
      puts "Headers: #{hash}"
      Ohm.redis.set 'conn', id
    end

    buffer = ''
    http.stream do |chunk|
      begin
        buffer += chunk
        while line = buffer.slice!(/.+\r\n/)
          puts 'Processing chunk'
          buffer = ''
          e = MultiJson.load line
          e['data'].each do |msg|
            Message.new(adn, msg).process if msg['user']['id'] != adn.my_id
          end
        end
      rescue MultiJson::LoadError => err
        puts err
      end
    end
  end

  def self.process_followers
    adn = ADN.global
    adn.follow_followers.each do |uid|
      puts "Follow follower #{uid}"
      adn.send_pm :destinations => [uid], :text => HELP_TEXT
    end
    adn.unfollow_unfollowers
  end

  def self.ensure_subscriptions
    Feed.all.each do |f|
      $superfeedr.subscribe f.url
    end
  end
end
