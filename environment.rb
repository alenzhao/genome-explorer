require 'logger'

require 'bundler'

Bundler.require

class App < Sinatra::Base

  # construct default :public_folder and :views
  set :root, File.dirname(__FILE__)

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
    DB = Sequel.connect('sqlite://development.sqlite')
    DB.loggers << Logger.new($stderr)
  end

  configure :production do
    DB = Sequel.connect(ENV['DATABASE_URL'] ||
                   "postgres://#{ENV['USER']}@127.0.0.1/genome")
  end

  configure :test do
    DB = Sequel.sqlite
    DB.loggers << Logger.new($stderr)
    Sequel.extension :migration
    Sequel::Migrator.run(App::DB, 'migrations')
  end

  # require models after calling Sequel.connect
  Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each { |f| require f }
end
