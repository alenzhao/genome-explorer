require './environment.rb'
require 'sinatra'

# models must be required *after* calling Sequel.connect
Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each { |f| require f }

class App < Sinatra::Base

  enable :sessions

  register Sinatra::AssetPack

  assets do
    serve '/js',     from: 'assets/js'
    serve '/css',    from: 'assets/css'
    serve '/images', from: 'assets/images'

    css :main, ['/css/*.css']
    js :main, ['/js/jquery.*.js', '/js/bootstrap.*.js']

    css_compression :simple
    js_compression :uglify
  end

  get '/' do
    @genomes = Genome.all
    haml :home
  end

  get '/genome/:id' do
    @genome = Genome[params[:id]]
    haml :'genome/view'
  end

  get '/feature/:id' do
    @feature = Feature[params[:id]]
    haml :'feature/view'
  end

end
