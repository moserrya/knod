require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

def gem_version
  @version ||= Dir.glob("*.gem").sort.last
end

def report_error(task)
  puts "There is no .gem file to #{task}"
end

desc 'Run tests'
task :default => :test

desc 'build gem'
task :build do
  puts `gem build knod.gemspec`
end

desc 'Install a locally generated version of the gem'
task :install do |t|
  if gem_version
    puts `gem install ./#{gem_version}`
  else
    report_error(t.name)
  end
end

desc 'Deploy the gem to Rubygems'
task :deploy do |t|
  if gem_version
    puts `gem push #{gem_version}`
  else
    report_error(t.name)
  end
end
