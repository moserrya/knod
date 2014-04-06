require 'socket'
require 'uri'
require 'pry-debugger'

class TinyServer
  attr_reader :server

  DEFAULT_PORT = 4444

  def initialize(options = {})
    @server = TCPServer.new('localhost', options[:port] || DEFAULT_PORT)
  end

  def start
    loop do
      socket = server.accept
      request_line = socket.gets

      STDERR.puts request_line

      path = requested_file(request_line)
      path = File.join(path, 'index.html') if File.directory?(path)

      if File.exist?(path) && !File.directory?(path)
        File.open(path, 'rb') do |file|
          socket.print "HTTP/1.1 200 OK\r\n" <<
                       "Content-Type: #{content_type(file)}\r\n" <<
                       "Content-Length: #{file.size}\r\n" <<
                       "Connection: close\r\n\r\n"

          IO.copy_stream(file, socket)
        end
      else
        message = "File not found\n"

        socket.print "HTTP/1.1 404 Not Found\r\n" <<
                     "Content-Type: text/plain\r\n" <<
                     "Content-Length: #{message.size}\r\n" <<
                     "Connection: close\r\n\r\n"

        socket.print message
      end

      socket.close
    end
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

TinyServer.new.start
