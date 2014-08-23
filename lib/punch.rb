require "mechanize"

class Punch
  VERSION = "1.0.0"

  HOST = "adpeet.adp.com"
  URL  = "https://%s/%s/applications/wpk/html/kronos-logonbody.jsp"

  attr_reader :url

  # Initializes Punch with either a client ID or a URL. An optional
  # host can also be specified. If a URL is provided, all other args
  # are ignored.

  def initialize(client_id: nil, host: HOST, url: nil)
    fail "Need client_id or url" unless client_id or url

    self.url = url || URL % [host || HOST, client_id]

    @agent = Mechanize.new do |a|
      a.ssl_version = :TLSv1
    end
  end

  def url=(url)
    @url = URI.parse url
  end

end
