require 'sinatra/base'

class TestApp < Sinatra::Application

  configure do
    set :bind, '0.0.0.0'
  end
  
  get '/' do
    "
      <h1>Visit us @ www.conjur.org!</h1>

      <h3>Space-wide Secrets</h3>
      <p>Database Username: #{ENV['SPACE_USERNAME']}</p>
      <p>Database Password: #{ENV['SPACE_PASSWORD']}</p>
    "
  end

end
