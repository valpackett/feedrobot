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
    work
  end

  def self.work
    EM.run do
      adn = ADN.global
      http = EM::HttpRequest.new('https://stream-channel.app.net/stream/user', :inactivity_timeout => 0).get(
        :head => {'Authorization' => "Bearer #{adn.token}"},
        :query => {'connection_id' => Ohm.redis.get('conn')}
      )
      http.errback do |e, err|
        puts err
        puts 'HTTP Error/Stop!'
        EM.stop
        adn.send_pm :destinations => [ADMIN_ADN_UID], :text => "HTTP Error!!! Check the logs."
      end

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
          if chunk[-1,1] != "\n"
            puts 'Buffering partial chunk'
            buffer += chunk
          else
            puts 'Processing chunk'
            json = buffer+chunk
            e = MultiJson.load json
            buffer = ''
            if e['data']['user']['id'] != adn.my_id
              type = e['meta']['type']
              case type
              when 'message' then Message.new(adn, e['data']).process
              else puts "Unknown chunk type #{type}"
              end
            end
          end
        rescue MultiJson::LoadError => err
          puts err
        end
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
