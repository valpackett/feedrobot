require_relative 'adn.rb'
require_relative 'app.rb'
require_relative 'message.rb'

class Worker
  def self.start
    loop do
      $superfeedr ? work : puts("No Superfeedr yet...")
      sleep 10
    end
  end

  def self.work
    adn = ADN.global
    adn.follow_followers.each do |uid|
      puts "Follow follower #{uid}"
      adn.send_pm :destinations => [uid], :text => HELP_TEXT
    end
    adn.unread_pm_channel_ids.each do |cid|
      puts "Unread pm channel #{cid}"
      adn.unread_messages(cid).each do |msg|
        Message.new(adn, msg).process
      end
    end
  end
end
