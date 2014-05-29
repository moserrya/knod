module Knod
  module FileUtilities
    extend Forwardable

    def_delegator :FileUtils, :mkdir_p, :create_directory

    def_delegator :File, :delete, :delete_file
    def_delegator :File, :join,   :join_path
    def_delegator :File, :read,   :read_file
    def_delegator :File, :write,  :write_file

    def_delegators :File, :file?, :dirname, :directory?

    def file_extension(path)
      File.extname(path).split('.').last
    end
  end
end
