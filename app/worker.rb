require 'open-uri'
require 'tempfile'
require 'rumonade'
require 'feedisco'
require_relative 'adn.rb'
require_relative 'app.rb'
require_relative 'opml.rb'

HELP_TEXT = "Hi, I'm FeedRobot!\nSend me a URL to subscribe;\n'list' for feeds you're subscribed to;\na URL from this list prefixed with a minus to unsubscribe;\n'export' to get an OPML file with your subscriptions;\nan OPML file to import it;\n'help' to see this again."

class Worker
  def self.start
    loop do
      $superfeedr ? work : puts("No Superfeedr yet...")
      sleep 10
    end
  end

  def self.work
    adn = @adn = ADN.global
    adn.follow_followers.each do |uid|
      puts "Follow follower #{uid}"
      adn.send_pm :destinations => [uid], :text => HELP_TEXT
    end
    adn.unread_pm_channel_ids.each do |cid|
      puts "Unread pm channel #{cid}"
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
      Subscription.subscribe_user url, msg['user']['id']
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
    Subscription.unsubscribe_user url, msg['user']['id']
    reply msg, :text => "Unsubscribed from #{url}!"
  end

  def self.list_feeds(msg)
    user = User.find_or_create :uid => msg['user']['id']
    user.feeds.map(&:url)
  end

  def self.list(msg)
    feedlist = list_feeds(msg).join "\n"
    reply msg, :text => "Here are the feeds you're subscribed to:\n#{feedlist}"
  end

  def self.export(msg)
    title = "Exported subscriptions from the App.net Feed Robot for @#{msg['user']['username']}"
    xml = OPML.dump title, list_feeds(msg)
    filename = "feedrobot-export-#{msg['user']['username']}-#{DateTime.now.to_s}.xml"
    file = Tempfile.new filename
    begin
      file.write xml
      file.rewind
      adnfile = @adn.new_file file, 'application/xml', filename, :type => 'org.opml'
      if adnfile.status == 200
        reply msg, :text => "Sent you an OPML file as an attachment to this message.",
          :annotations => [ADN.gen_attachment(adnfile.body['data'])]
      else
        p adnfile
        reply msg, :text => "Can't upload the file :-( Tell @myfreeweb about this!"
      end
    ensure
      file.close
      file.unlink
    end
  end

  def self.import(msg, attachments)
    files = attachments['value']['net.app.core.file_list']
    if files.empty?
      reply msg, :text => "No files found."
    else
      files.each do |file|
        OPML.parse(open(file['url'])).each do |feed|
          Subscription.subscribe_user feed, msg['user']['id']
        end
      end
      reply msg, :text => "Successfully imported feeds!"
      list msg
    end
  end

  def self.process_msg(msg)
    puts "Processing: #{msg['text']}"
    case msg['text']
    when /-http(.*)$/ then unsubscribe msg, "http#{$1}"
    when /http(.*)$/ then subscribe msg, "http#{$1}"
    when "list" then list msg
    when "export" then export msg
    when "help", "'help'" then reply msg, :text => HELP_TEXT
    else
      if attachments = msg['annotations'].find { |a| a['type'] == 'net.app.core.attachments' }
        import msg, attachments
      else
        reply msg, :text => "I don't understand! Send 'help' to see how to talk to me."
      end
    end
  end
end
