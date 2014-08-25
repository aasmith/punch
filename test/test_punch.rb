require "minitest/autorun"
require "punch"

class TestPunch < Minitest::Test

  def test_init_with_url
    p = Punch.new url: "http://derp"

    assert_equal p.url.to_s, "http://derp"
  end

  def test_init_with_client_id
    p = Punch.new client_id: "123"

    assert_equal p.url.to_s, Punch::URL % [Punch::HOST, "123"]
  end

  def test_init_with_client_id_and_host
    p = Punch.new client_id: "123", host: "derp"

    assert_equal p.url.to_s, Punch::URL % ["derp", "123"]
  end

  def test_init_with_nothing
    assert_raises RuntimeError do
      Punch.new
    end
  end

  def test_populate_timecard_with_xfer
    load_example_timecard

    @timecard.populate xfer: "/derp//"

    @timecard.xfer_fields.each do |field|
      assert_equal "/derp//", field.value
    end
  end

  def test_timecard_prints
    load_example_timecard

    expected = File.read "test/expected_tcard.txt"

    assert_equal expected, @timecard.pretty
  end

  def test_timecard_prepare_submission
    load_example_timecard

    @timecard.populate xfer: "/derp//"
    @timecard.prepare_submission

    form = @timecard.submission_form

    %w(employeeId employeeIds personIds).each do |employee_field_name|
      field = form.field_with(name: employee_field_name)

      assert_equal @timecard.employee_id, field.value
    end

    action = form.field_with(name: "com.kronos.wfc.ACTION")
    assert_equal "Save", action.value

    serialized_fields = "T0R0C3=%2Fderp%2F%2F,T1R0C3=%2Fderp%2F%2F,\
                         T2R0C3=%2Fderp%2F%2F,T3R0C3=%2Fderp%2F%2F".delete(" ")

    cmd = form.field_with(name: "com.kronos.wfc.CMD_DATA")
    assert_equal serialized_fields, cmd.value
  end

  def test_suggest_save_or_approve
    load_example_timecard

    too_soon   = @timecard.end_date - 1
    too_eager  = @timecard.end_date
    just_right = @timecard.end_date + 1

    assert_equal :save,    @timecard.suggest_save_or_approve(too_soon)
    assert_equal :save,    @timecard.suggest_save_or_approve(too_eager)
    assert_equal :approve, @timecard.suggest_save_or_approve(just_right)
  end

  def load_example_timecard
    @timecard = Marshal.load File.open("test/tcard.dump")
  end

end
