require 'knod'
require 'connection'
require 'minitest/autorun'

$knod = Knod::Server.new(port: 0, logging: false)
$port = $knod.port

Thread.new do
  $knod.start
end

def parse_json_file(file)
  JSON.parse(File.read(file), symbolize_names: true)
end

describe Knod, "a tiny http server" do
  let(:connection) {Connection.new("http://0.0.0.0:#{$port}")}

  describe 'non-writing methods' do
    before do
      @path = 'index.html'
      @body  = "<h1>Squids are fun!</h1>"
      File.write(@path, @body)
    end

    after do
      FileUtils.remove_entry(@path, true)
    end

    it 'responds with 200 when the route is valid' do
      response = connection.get @path
      response.code.must_equal '200'
    end

    it 'responds with the body of the requested file' do
      response = connection.get @path
      response.body.must_equal @body
    end

    it 'implictly serves up the index' do
      response = connection.get "/"
      response.body.must_equal @body
    end

    it 'returns a 404 if the file does not exist' do
      response = connection.get "/squidbat.random"
      response.code.must_equal '404'
    end

    it 'responds to HEAD requests without a body' do
      response = connection.head @path
      response.body.must_be_nil
    end

    it 'responds to unsupported methods with a 501' do
      response = connection.options @path
      response.code.must_equal '501'
    end

    it 'deletes files at the specified path' do
      response = connection.delete @path
      File.exists?(@path).must_equal false
    end

    it 'responds to delete requests with a 204' do
      response = connection.delete @path
      response.code.must_equal '204'
    end
  end

  describe 'PUT' do
    let(:directory) {'index'}
    let(:path) {"#{directory}/81.json"}
    let(:data) {{state: 'swell', predeliction: 'good challenges'}}

    it 'returns a 204 on success' do
      response = connection.put path, data
      response.code.must_equal '204'
    end

    it 'does not return a body' do
      response = connection.put path, data
      response.body.must_be_nil
    end

    it 'writes to the local path' do
      connection.put path, data
      File.file?(path).must_equal true
    end

    it 'writes the data to the file as json' do
      connection.put path, data
      parse_json_file(path).must_equal data
    end

    after do
      FileUtils.remove_entry(directory, true)
    end
  end

  describe 'POST' do
    let(:path) {'/items'}
    let(:local_path) {File.join('.', path)}
    let(:data) {{id: 81, state: 'swell', predeliction: 'good challenges'}}

    before do
      FileUtils.mkdir_p(local_path)
      2.times {|i| File.write(File.join(".", path, "#{i+1}.json"), {state: 'noodles'})}
    end

    after do
      FileUtils.remove_entry(local_path, true)
    end

    it 'returns a 201 on success' do
      response = connection.post path, data
      response.code.must_equal '201'
    end

    it 'creates the required directory if it does not exist' do
      FileUtils.remove_entry(local_path, true)
      connection.post path, data
      Dir.exists?(local_path).must_equal true
    end

    it 'writes to the correct path' do
      connection.post path, data
      File.file?(File.join(local_path, '3.json')).must_equal true
    end

    it 'responds with json' do
      response = connection.post path, data
      response.content_type.must_equal 'application/json'
    end

    it 'returns the id of the file created' do
      response = connection.post path, data
      response.body.must_equal ({id: 3})
    end
  end

  describe 'error handling' do
    before do
      def $knod.do_DELETE
        raise 'boom!'
      end
    end

    it 'responds to server errors with a 500' do
      response = connection.delete '/index.html'
      response.code.must_equal '500'
    end
  end
end



