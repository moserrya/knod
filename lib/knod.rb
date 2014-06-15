require 'socket'
require 'uri'
require 'fileutils'
require 'json'
require 'forwardable'
require 'knod/file_utilities'
require 'knod/request'
require 'knod/patch_merge'
require 'knod/server'
require 'knod/version'

module Knod
  def self.start(options = {})
    Server.new(options).start
  end
end

Knod.start if __FILE__ == $PROGRAM_NAME
