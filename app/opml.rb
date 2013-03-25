require 'nokogiri'
require 'builder'

class OPML
  def self.dump(title, urls)
    xml = Builder::XmlMarkup.new :indent => 2
    xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    xml.opml(:version => "1.0") { |opml|
      opml.head { |head|
        head.title title
      }
      opml.body { |body|
        urls.each do |feed|
          body.outline :type => "rss", :xmlUrl => feed
        end
      }
    }
  end

  def self.parse(opml)
    Nokogiri::XML(opml).xpath('//body/outline').map { |outline|
      outline['xmlUrl']
    }.compact
  end
end
