require 'open-uri'
require 'tempfile'
require 'feedisco'
require_relative 'adn.rb'
require_relative 'app.rb'
require_relative 'models.rb'
require_relative 'opml.rb'

HELP_TEXT = "Hi, I'm FeedRobot!\nSend me a URL to subscribe;\n'list' for feeds you're subscribed to;\na URL from this list prefixed with a minus to unsubscribe;\n'export' to get an OPML file with your subscriptions;\nan OPML file to import it;\n'help' to see this again."

class Message
  def initialize(adn, data)
    @adn = adn
    @data = data
  end

  def text
    @data['text']
  end

  def author_id
    @data['user']['id']
  end

  def author_username
    @data['user']['username']
  end

  def user
    @user ||= User.find_or_create(:uid => author_id)
  end

  def reply(params)
    @adn.send_msg @data['channel_id'], params
  end

  def process
    puts "Processing: #{text}"
    case text
    when /-http(.*)$/ then unsubscribe "http#{$1}"
    when /http(.*)$/ then subscribe "http#{$1}"
    when "list" then list
    when "export" then export
    when "help", "'help'" then reply :text => HELP_TEXT
    else
      if attachments = @data['annotations'].find { |a| a['type'] == 'net.app.core.attachments' }
        import attachments
      else
        reply :text => "I don't understand! Send 'help' to see how to talk to me."
      end
    end
  end

  #### Actions ####

  def subscribe(url)
    if url = Feedisco.find(url).first
      Subscription.subscribe_user url, author_id
      sub = $superfeedr.subscribe url
      unless sub
        reply :text => "Error: #{$superfeedr.error}"
      else
        reply :text => "Subscribed to #{url}!"
      end
    else
      reply :text => "Feed not found at #{url} :-("
    end
  end

  def unsubscribe(url)
    Subscription.unsubscribe_user url, author_id
    reply :text => "Unsubscribed from #{url}!"
  end

  def list
    user.secret = SecureRandom.uuid
    user.save
    reply :text => "Here are the feeds you're subscribed to:\nhttps://#{HOST}/subscriptions/#{user.uid}/#{user.secret}"
  end

  def export
    title = "Exported subscriptions from the App.net Feed Robot for @#{author_username}"
    xml = OPML.dump title, user.feed_urls
    filename = "feedrobot-export-#{author_username}-#{DateTime.now.to_s}.xml"
    file = Tempfile.new filename
    begin
      file.write xml
      file.rewind
      adnfile = @adn.new_file file, 'application/xml', filename, :type => 'org.opml'
      if adnfile.status == 200
        reply :text => "Sent you an OPML file as an attachment to this message.",
          :annotations => [ADN.gen_attachment(adnfile.body['data'])]
      else
        p adnfile
        reply :text => "Can't upload the file :-( Tell @myfreeweb about this!"
      end
    ensure
      file.close
      file.unlink
    end
  end

  def import(attachments)
    files = attachments['value']['net.app.core.file_list']
    if files.empty?
      reply :text => "No files found."
    else
      files.each do |file|
        OPML.parse(open(file['url'])).each do |feed|
          Subscription.subscribe_user feed, author_id
        end
      end
      reply :text => "Successfully imported feeds!"
      list
    end
  end
end
