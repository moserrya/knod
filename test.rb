require './quack'
require 'net/http'
require 'minitest/autorun'

class TestGet < Minitest::Test

  def setup
    @index = 'index.html'
  end

  def test_valid_route_returns_200
    File.write(@index, "<h1>Squids are fun!</h1>")
    uri = URI("http://0.0.0.0:4444/#{@index}")
    response = make_get uri
    assert_equal response.code, '200'
  end

  def test_invalid_route_returns_404
    file = 'squidbat.html'
    File.delete(file) if File.exists?(file)
    uri = URI("http://0.0.0.0:4444/#{file}")
    response = make_get uri
    assert_equal response.code, '404'
  end

  def teardown
    File.delete(@index) if File.exists?(@index)
  end

  def make_get(uri)
    Net::HTTP.get_response uri
  end
end

