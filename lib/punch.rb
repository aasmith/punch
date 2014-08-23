require "mechanize"

class Punch
  VERSION = "1.0.0"

  HOST = "adpeet.adp.com"
  URL  = "https://%s/%s/applications/wpk/html/kronos-logonbody.jsp&ESS=true"

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

    @page = nil
  end

  def url=(url)
    @url = URI.parse url
  end

  def login(username, password)
    page = @agent.get url

    form = page.form("logonForm") do |f|
      f["username"] = username
      f["password"] = password
      f["authenticateWithSecurityQuestion"] = false
    end

    @page = form.submit
  end

  def fetch_timecard
    p @page

    timecard = @page.link_with(:text => 'My Timecard').click

    p timecard
  end

end

