require_relative '../lib/knod'
require 'connection'
require 'minitest/autorun'
require 'fileutils'

$knod = Knod.new(port: 0, logging: false)
$port = $knod.port

Thread.new do
  $knod.start
end

class RetrieveTest < Minitest::Test
  def setup
    @index = 'index.html'
    @body = "<h1>Squids are fun!</h1>"
    File.write(@index, @body)
  end

  def connection
    Connection.new(base_uri)
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
    response = connection.get "/#{@index}"
    assert_equal response.code, '200'
  end

  def test_it_serves_up_the_requested_file
    response = connection.get "/#{@index}"
    assert_equal response.body, @body
  end

  def test_invalid_route_returns_404
    file = 'squidbat.html'
    File.delete(file) if File.exists?(file)
    response = connection.get "/#{file}"
    assert_equal response.code, '404'
  end
end

class TestHead < RetrieveTest
  def test_it_does_notserve_up_the_requested_file
    response = connection.head "/#{@index}"
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

  def connection
    Connection.new(base_uri)
  end

  def base_uri
    "http://#{host}:#{$port}"
  end

  def teardown
    FileUtils.remove_entry(local_path, true)
  end
end

class TestPut < BaseTest
  def setup
    @response = connection.put path, {state: 'swell', predeliction: 'good challenges'}
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
    data = {id: 81, state: 'swell', predeliction: 'good challenges'}.to_json
    @response = connection.post path, data
  end

  def test_it_returns_a_201
    assert_equal @response.code, '201'
  end

  def test_it_returns_the_id
    assert_equal @response.body, {id: 3}
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
    @response = connection.delete(path)
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
    @response = connection.options(path)
  end

  def test_returns_a_501
    assert_equal @response.code, '501'
  end

  def path
    '/items/1.json'
  end
end

class TestServerError < BaseTest
  def setup
    def $knod.do_DELETE
      raise 'boom!'
    end
    @response = connection.delete(path)
  end

  def test_returns_a_500
    assert_equal @response.code, '500'
  end

  def path
    '/items/1.json'
  end
end

