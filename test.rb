require './quack'
require 'net/http'
require 'minitest/autorun'
require 'json'

class TestGet < Minitest::Test

  def setup
    @index = 'index.html'
    @body = "<h1>Squids are fun!</h1>"
    File.write(@index, @body)
  end

  def test_valid_route_returns_200
    uri = URI("http://0.0.0.0:4444/#{@index}")
    response = make_get uri
    assert_equal response.code, '200'
  end

  def test_it_serves_up_the_requested_file
    uri = URI("http://0.0.0.0:4444/#{@index}")
    response = make_get uri
    assert_equal response.body, @body
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

class TestPut < Minitest::Test
  def setup
    request = Net::HTTP::Put.new(path, header)
    request.body = {id: 81, state: 'swell', predeliction: 'good challenges'}.to_json
    @response = Net::HTTP.new(host, port).start {|http| http.request(request) }
  end

  def test_it_returns_a_204
    assert_equal @response.code, '204'
  end

  def port
    4444
  end

  def host
    '0.0.0.0'
  end

  def header
    {'Content-Type' => 'application/json'}
  end

  def path
    '/81.json'
  end
end

