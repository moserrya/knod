require_relative '../lib/knod'
require 'net/http'
require 'minitest/autorun'
require 'json'
require 'fileutils'

knod  = Knod.new port: 0
$port = knod.port

Thread.new do
  knod.start
end

class RetrieveTest < Minitest::Test
  def setup
    @index = 'index.html'
    @body = "<h1>Squids are fun!</h1>"
    File.write(@index, @body)
  end

  def teardown
    File.delete(@index) if File.exists?(@index)
  end

  def host
    '0.0.0.0'
  end

  def base_uri
    "http://#{host}:#{$port}"
  end
end

class TestGet < RetrieveTest
  def test_valid_route_returns_200
    uri = URI("#{base_uri}/#{@index}")
    response = make_get uri
    assert_equal response.code, '200'
  end

  def test_it_serves_up_the_requested_file
    uri = URI("#{base_uri}/#{@index}")
    response = make_get uri
    assert_equal response.body, @body
  end

  def test_invalid_route_returns_404
    file = 'squidbat.html'
    File.delete(file) if File.exists?(file)
    uri = URI("#{base_uri}/#{file}")
    response = make_get uri
    assert_equal response.code, '404'
  end

  def make_get(uri)
    Net::HTTP.get_response uri
  end
end

class TestHead < RetrieveTest
  def test_it_does_notserve_up_the_requested_file
    uri = URI("#{base_uri}/#{@index}")
    response = Net::HTTP.new(host, $port).head(uri)
    assert_equal response.body, nil
  end
end

class BaseTest < Minitest::Test

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

  def teardown
    FileUtils.remove_entry(local_path, true)
  end
end

class TestPut < BaseTest
  def setup
    request = Net::HTTP::Put.new(path, header)
    request.body = {state: 'swell', predeliction: 'good challenges'}.to_json
    @response = Net::HTTP.new(host, $port).start {|http| http.request(request) }
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
end

class TestPost < BaseTest
  def setup
    FileUtils.mkdir_p(local_path)
    2.times {|i| File.write(File.join(".", path, "#{i+1}.json"), {state: 'noodles'})}
    request = Net::HTTP::Post.new(path, header)
    request.body = {id: 81, state: 'swell', predeliction: 'good challenges'}.to_json
    @response = Net::HTTP.new(host, $port).start {|http| http.request(request) }
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
end

class TestDelete < BaseTest
  def setup
    File.write(local_path, 'anything')
    @response = Net::HTTP.new(host, $port).delete(path)
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

class TestUnsupportedMethod < BaseTest
  def setup
    @response = Net::HTTP.new(host, $port).options(path)
  end

  def test_returns_a_501
    assert_equal @response.code, '501'
  end

  def path
    '/items/1.json'
  end
end
