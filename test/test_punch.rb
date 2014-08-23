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

end
