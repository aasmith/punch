require "cgi"
require "date"
require "uri"

require "mechanize"

class Punch
  VERSION = "1.0.0"

  HOST = "adpeet.adp.com"
  URL  = "https://%s/%s/applications/wpk/html/kronos-logonbody.jsp?ESS=true"

  attr_reader :url

  # Initializes Punch with either a client ID or a URL. An optional
  # host can also be specified. If a URL is provided, all other args
  # are ignored.

  def initialize(client_id: nil, host: HOST, url: nil, user_agent_alias: nil)
    fail "Need client_id or url" unless client_id or url

    self.url = url || URL % [host || HOST, client_id]

    @agent = Mechanize.new do |a|
      a.ssl_version = :TLSv1
      a.user_agent_alias = user_agent_alias ||
        self.class.random_user_agent_alias
    end
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

    check_errors form.submit
  end

  def check_errors(page)
    # Still showing a login page?
    if page.frame_with(href: /kronos-logonbody/)
      frame = page.frame_with(href: /kronos-logonbody/).click

      errors = frame.parser.css("#ErrorMessageDiv").join("\n")

      fail errors.empty? ? "Unable to log in" : errors
    else
      page
    end
  end

  def fetch_timecard(home_page)
    nav = home_page.iframe("contentPane").click
    Timecard.new nav.link_with(text: "My Timecard").click
  end

  USER_AGENT_ALIASES =
    Mechanize::AGENT_ALIASES.keys.grep(/(mac|win).*?(firefox|chrome|mozilla)/i)

  def self.random_user_agent_alias
    USER_AGENT_ALIASES.sample
  end

  # A wrapper around a Mechanize::Page that contains a timecard form.
  #
  # Used to mutate forms so they can be saved or approved.
  #
  # A Timecard contains two forms:
  #
  #   * The display form which starts as the initial state of the time card.
  #     This form is mutated in memory to represent any changes the user
  #     wants to make to the time card.
  #
  #   * The submission form which distills the display form into a compact
  #     version for server submission.

  class Timecard
    ACTIONS = { save: "Save", approve: "approve" }

    attr_accessor :page

    def initialize(page)
      self.page = page
    end

    def display_form
      page.form("pageDisplayForm")
    end

    alias form display_form

    def employee_id
      form["employeeId"]
    end

    def start_date
      Date.strptime(form["beginTimeframeDate"], "%m/%d/%Y")
    end

    def end_date
      Date.strptime(form["endTimeframeDate"], "%m/%d/%Y")
    end

    def xfer_fields
      form.fields.select do |field|
        field.name =~ /^T\d+R\d+C3$/
      end
    end

    # Populate the timecard. It seems eTime cards for FTEs are already
    # filled out with hours, so only the xfer code is required.
    def populate(xfer:)
      xfer_fields.each do |field|
        field.value = xfer
      end
    end

    def submission_form
      page.form("com.kronos.wfc.command")
    end

    def prepare_submission(action: :save)
      unless ACTIONS.keys.include? action
        fail "action must be one of :approve or :save"
      end

      populate_employee_ids employee_id
      populate_action action
      populate_data
    end

    def populate_fields(field_names:, value:, form: submission_form)
      [*field_names].each do |field_name|
        field = form.field(field_name)
        field.value = value
      end
    end

    def populate_employee_ids(employee_id)
      populate_fields(
        field_names: %w(employeeId employeeIds personIds),
        value: employee_id
      )
    end

    def populate_action(action)
      populate_fields(
        field_names: "com.kronos.wfc.ACTION",
        value: ACTIONS.fetch(action)
      )
    end

    def populate_data
      populate_fields(
        field_names: "com.kronos.wfc.CMD_DATA",
        value: serialize_fields
      )
    end

    def serialize_fields
      out = []

      out << xfer_fields.map do |xfer_field|
        [xfer_field.name, CGI.escape(xfer_field.value)].join("=")
      end

      # We could've used CGI::encode_www_form if it wasn't for this:
      out.join(",")
    end

    def save
      prepare_submission
      submission_form.submit
    end

    def approve
      prepare_submission action: :approve
      submission_form.submit
    end

    def suggest_save_or_approve(todays_date = Date.today)
      todays_date > end_date ? :approve : :save
    end

    def employee_name_and_info
      page.parser.css(".CPerson td:first").text.strip
    end

    def pretty
      out = []

      items = form.fields.select do |field|
        field.name =~ /T\d+R\d+C\d+/
      end

      header = <<HEADER.chomp
Timecard for Employee %s
%s

Period %s to %s
HEADER

      out << header % [
        employee_id,
        employee_name_and_info,
        start_date,
        end_date
      ]

      current_date = start_date
      current_week = nil

      days_or_depts = items.sort_by { |x| x.name.scan(/\d+/).map(&:to_i) }

      days_or_depts.each do |day_or_dept|
        day_or_dept.name =~ /T(\d+)R\d+C(\d+)/ or raise "Unknown day/dept"

        week, day = $1.to_i, $2.to_i

        if current_week != week
          out << ""
          out << "Week #{week}"
          out << "------"
          current_week = week
        end

        case day
        when 2     then out << format_other("Dept", day_or_dept.value)
        when 3     then out << format_other("Xfer", day_or_dept.value)
        when 4..10 then
          out << format_day(day, current_date, day_or_dept.value)
          current_date += 1
        end
      end

      out.join("\n")
    end

    def format_other(title, value)
      "%s: %s" % [title, value.empty? ? "-" : value]
    end

    def format_day(day, date, hours)
      unless (day - 4) == date.wday
        fail "Sanity check failed, days of week do not match"
      end

      "%s %s: %s" % [
        Date::ABBR_DAYNAMES[day - 4], date, hours.empty? ? "None" : hours
      ]
    end

    def marshal_dump
      [page.response, page.body]
    end

    def marshal_load(values)
      response, body = values

      @page = Mechanize::Page.new nil, response, body, nil, Mechanize.new
    end

  end

end

