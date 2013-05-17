require 'sinatra/base'
require 'rumonade'
require 'faraday'
require 'faraday_middleware'
require 'faraday_middleware/multi_json'
require 'typhoeus/adapters/faraday'
require_relative 'const'

class ADN
  class << self
    attr_accessor :global
  end

  def initialize(token)
    @api = Faraday.new(:url => 'https://alpha-api.app.net/stream/0/') do |adn|
      adn.request  :authorization, 'Bearer', token
      adn.request  :multipart
      adn.request  :multi_json
      adn.response :multi_json
      adn.adapter  :typhoeus
    end
  end

  def method_missing(*args)
    @api.send *args
  end

  def me
    @api.get('users/me').body['data']
  end

  def my_id
    @my_id ||= me['id']
  end

  def send_pm(params)
    o = @api.post 'channels/pm/messages', params
    set_channel_marker o.body['data']['channel_id'], o.body['data']['id']
    o
  end

  def send_msg(cid, params)
    o = @api.post "channels/#{cid}/messages", params
    set_channel_marker cid, o.body['data']['id']
    o
  end

  def set_channel_marker(cid, id)
    @api.post "posts/marker", :name => "channel:#{cid}", :id => id
  end

  def follow_followers
    @api.get('users/me/followers', :count => 200).body['data'].map do |usr|
      unless usr['you_follow'] || usr['id'] == '18614' # ignore @welcome
        fol = @api.post("users/#{usr['id']}/follow")
        if fol.status == 200
          usr['id']
        else
          puts "Failed following"
          puts fol
          nil
        end
      end
    end.compact
  end

  def unfollow_unfollowers
    @api.get('users/me/following', :count => 200).body['data'].each do |usr|
      @api.delete("users/#{usr['id']}/follow") unless usr['follows_you']
    end
  end

  def unread_pm_channel_ids
    @api.get('channels', :include_read => 0,
             :channel_types => 'net.app.core.pm').body['data'].map { |c|
      c['id']
    }
  end

  def unread_messages(cid)
    b = @api.get("channels/#{cid}/messages", :include_marker => 1,
                 :include_message_annotations => 1).body
    marker = Option(b['meta']['marker']['last_read_id']).map(&:to_i).get_or_else 0
    b['data'].select { |msg|
      msg['id'].to_i > marker && msg['user']['id'] != my_id
    }
  end

  def new_file(file, type, filename, params={})
    params[:content] = Faraday::UploadIO.new file, type, filename
    @api.post 'files', params
  end

  def self.gen_attachment(filedata)
    {:type  => 'net.app.core.attachments',
     :value => {'+net.app.core.file_list' => [
       {:file_token => filedata['file_token'],
        :file_id    => filedata['id'],
        :format     => :metadata}
     ]}}
  end
end

ADN.global = ADN.new ADN_TOKEN
