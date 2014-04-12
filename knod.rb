require 'socket'
require 'uri'
require 'pry-debugger'
require 'fileutils'

class Knod
  attr_reader :server, :port, :socket, :request_line

  DEFAULT_PORT = 4444

  def initialize(options = {})
    @port = options[:port] || DEFAULT_PORT
    @server = TCPServer.new('localhost', @port)
  end

  def start
    STDERR.puts "Starting server on port #{port}"
    loop do
      @socket = server.accept
      @request_line = socket.gets
      STDERR.puts request_line
      public_send "do_#{requested_http_verb}"
      socket.close
    end
  end

  HTTP_VERBS = %w{GET HEAD PUT POST DELETE}

  def do_GET(head=false)
    path = requested_file
    path = File.join(path, 'index.html') if File.directory?(path)

    if is_file?(path)
      File.open(path, 'rb') do |file|
        socket.print file_response_header(file)
        IO.copy_stream(file, socket) unless head
      end
    else
      message = "\"File not found\""
      socket.print response_header(404, message)
      socket.print message unless head
    end
  end

  def do_HEAD
    do_GET(head=true)
  end

  def do_DELETE
    path = requested_file
    File.delete(path) if is_file?(path)
    socket.print response_header(204)
  end

  def do_PUT
    response = RequestObject.new(socket)
    path = requested_file
    directory = File.dirname(path)
    FileUtils.mkdir_p(directory)
    File.write(path, response.body)
    socket.print response_header(204)
  end

  def do_POST
    response = RequestObject.new(socket)
    path = requested_file
    FileUtils.mkdir_p(path)
    records = Dir.glob(path + "/*.json")
    next_id = (records.map {|r| File.basename(r, ".json") }.map(&:to_i).max || 0) + 1
    File.write(File.join(path, "#{next_id}.json"), response.body)
    message = "{\"id\":#{next_id}}"
    socket.print response_header(201, message)
    socket.print message
  end

  private

  STATUS_CODE_MAPPINGS = {
    200 => "OK",
    201 => "Created",
    204 => "No Content",
    404 => "Not Found",
    500 => "Internal Server Error",
    501 => "Not Implemented"
  }

  def response_header(status_code, message='')
    header = "HTTP/1.1 #{status_code} #{STATUS_CODE_MAPPINGS[status_code]}\r\n"
    header << "Content-Type: application/json\r\n" unless message.empty?
    header << "Content-Length: #{message.size}\r\n"
    header << "Connection: close\r\n\r\n"
  end

  def file_response_header(file)
    "HTTP/1.1 200 OK\r\n" <<
    "Content-Type: #{content_type(file)}\r\n" <<
    "Content-Length: #{file.size}\r\n" <<
    "Connection: close\r\n\r\n"
  end

  def is_file?(path)
    File.exist?(path) && !File.directory?(path)
  end

  def requested_http_verb
    HTTP_VERBS.find {|verb| request_line.start_with? verb}
  end

  CONTENT_TYPE_MAPPING = {
    'json' => 'application/json',
    'bmp'  => 'image/bmp',
    'gif'  => 'image/gif',
    'jpg'  => 'image/jpeg',
    'png'  => 'image/png',
    'css'  => 'text/css',
    'html' => 'text/html',
    'txt'  => 'text/plain',
    'xml'  => 'text/xml'
  }

  DEFAULT_CONTENT_TYPE = 'application/octet-stream'

  def content_type(path)
    ext = File.extname(path).split('.').last
    CONTENT_TYPE_MAPPING[ext] || DEFAULT_CONTENT_TYPE
  end

  WEB_ROOT = './'

  def requested_file
    request_uri = request_line.split[1]
    local_path = URI.unescape(URI(request_uri).path)

    clean = []

    parts = local_path.split("/")

    parts.each do |part|
      next if part.empty? || part == '.'
      part == '..' ? clean.pop : clean << part
    end

    File.join(WEB_ROOT, *clean)
  end
end

class RequestObject
  attr_reader :socket, :headers

  def initialize(socket)
    @socket = socket
    parse_response
  end

  def parse_response
    headers = {}
    loop do
      line = socket.gets
      break if line == "\r\n"
      name, value = line.strip.split(": ")
      headers[name] = value
    end
    @headers = headers
  end

  def content_length
    headers["Content-Length"].to_i
  end

  def content_type
    headers["Content-Type"]
  end

  def body
    @body ||= socket.read(content_length)
  end
end

if __FILE__ == $0
  Knod.new.start
end

