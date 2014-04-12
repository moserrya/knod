require './knod'
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

class BaseTest < Minitest::Test
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
    raise 'not implemented'
  end

  def local_path
    File.join('.', path)
  end
end

class TestPut < BaseTest
  def setup
    request = Net::HTTP::Put.new(path, header)
    request.body = {state: 'swell', predeliction: 'good challenges'}.to_json
    @response = Net::HTTP.new(host, port).start {|http| http.request(request) }
  end

  def test_it_returns_a_204
    assert_equal @response.code, '204'
  end

  def test_there_is_no_body
    assert_equal @response.body, nil
  end

  def test_writing_to_the_expected_path
    assert File.exists?(local_path) && !File.directory?(local_path)
  end

  def path
    '/items/81.json'
  end

  def teardown
    File.delete(local_path)
  end
end

class TestPost < BaseTest
  def setup
    FileUtils.mkdir_p(local_path)
    2.times {|i| File.write(File.join(".", path, "#{i+1}.json"), {state: 'noodles'})}
    request = Net::HTTP::Post.new(path, header)
    request.body = {id: 81, state: 'swell', predeliction: 'good challenges'}.to_json
    @response = Net::HTTP.new(host, port).start {|http| http.request(request) }
  end

  def test_it_returns_a_201
    assert_equal @response.code, '201'
  end

  def test_it_returns_the_id
    assert_equal @response.body, {id: 3}.to_json
  end

  def test_it_returns_json
    assert_equal @response.content_type, 'application/json'
  end

  def test_writing_to_appopriate_path
    assert File.exists?(File.join(local_path, '3.json'))
  end

  def path
    '/items/'
  end

  def teardown
    FileUtils.rm_r(local_path)
  end
end

class TestDelete < BaseTest
  def setup
    File.write(local_path, 'anything')
    @response = Net::HTTP.new(host, port).delete(path)
  end

  def test_file_deletion
    refute File.exists?(path)
  end

  def test_returns_a_204
    assert_equal @response.code, '204'
  end

  def path
    '/ducklet.txt'
  end
end
