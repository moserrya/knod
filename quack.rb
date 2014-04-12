require 'socket'
require 'uri'
require 'pry-debugger'
require 'fileutils'

class TinyServer
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
    path = requested_file(request_line)
    path = File.join(path, 'index.html') if File.directory?(path)

    if is_file?(path)
      File.open(path, 'rb') do |file|
        socket.print "HTTP/1.1 200 OK\r\n" <<
                     "Content-Type: #{content_type(file)}\r\n" <<
                     "Content-Length: #{file.size}\r\n" <<
                     "Connection: close\r\n\r\n"

        IO.copy_stream(file, socket) unless head
      end
    else
      message = "File not found\n"

      socket.print "HTTP/1.1 404 Not Found\r\n" <<
                   "Content-Type: text/plain\r\n" <<
                   "Content-Length: #{message.size}\r\n" <<
                   "Connection: close\r\n\r\n"

      socket.print message unless head
    end
  end

  def do_HEAD
    do_GET(head=true)
  end

  def do_DELETE
    path = requested_file(request_line)
    if is_file?(path)
      File.delete(path)
    end
    message = "#{path} deleted"
    socket.print response_header(204, message)
    socket.print message
  end

  def do_PUT
    response = RequestObject.new(socket)
    route = requested_file(request_line)
    directory = File.dirname(route)
    FileUtils.mkdir_p(directory)
    File.write(route, response.body)
    message = "Not Implemented"
    socket.print response_header(204, message)
    socket.print message
  end

  def do_POST
    response = RequestObject.new(socket)
    route = requested_file(request_line)
    FileUtils.mkdir_p(route)
    records = Dir.glob(route + "/*.json")
    next_id = (records.map {|r| File.basename(r, ".json") }.map(&:to_i).max || 0) + 1
    File.write(File.join(route, "#{next_id}.json"), response.body)
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

  def response_header(status_code, message)
    "HTTP/1.1 #{status_code} #{STATUS_CODE_MAPPINGS[status_code]}\r\n" <<
    "Content-Type: text/plain\r\n" <<
    "Content-Length: #{message.size}\r\n" <<
    "Connection: close\r\n\r\n"
  end

  def is_file?(path)
    File.exist?(path) && !File.directory?(path)
  end

  def requested_http_verb
    HTTP_VERBS.find {|verb| request_line.start_with? verb}
  end

  CONTENT_TYPE_MAPPING = {
    'html' => 'text/html',
    'json' => 'application/json',
    'txt'  => 'text/plain',
    'png'  => 'image/png',
    'jpg'  => 'image/jpeg'
  }

  DEFAULT_CONTENT_TYPE = 'application/octet-stream'

  def content_type(path)
    ext = File.extname(path).split('.').last
    CONTENT_TYPE_MAPPING[ext] || DEFAULT_CONTENT_TYPE
  end

  WEB_ROOT = './'

  def requested_file(request_line)
    request_uri = request_line.split[1]
    path = URI.unescape(URI(request_uri).path)

    clean = []

    parts = path.split("/")

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
  TinyServer.new.start
end

