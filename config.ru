require './auth'
require './app'

run Rack::Cascade.new [API, Auth]
