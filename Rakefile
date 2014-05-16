require 'yaml'
require_relative 'lib/utils'


def load_env
  YAML.load(File.open("config/servers.yml")).each do |name, args|
    yield Host.new(name, args)
  end
end

desc '任务列表'
task :default do
  puts `rake -T`
end

Dir.glob('lib/tasks/*.rake').each { |r| import r }