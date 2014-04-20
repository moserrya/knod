require 'socket'
require 'uri'
require 'fileutils'
require 'knod/request'
require 'knod/server'

module Knod
  def self.start(options = {})
    Server.new(options).start
  end
end

if __FILE__ == $0
  Knod.start
end

