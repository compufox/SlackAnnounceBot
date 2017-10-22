require 'slack-ruby-client'
require 'sinatra/base'

SLACK_CONFIG = {
  slack_client_id: ENV['SLACK_CLIENT_ID'],
  slack_api_secret: ENV['SLACK_API_SECRET'],
  slack_redirect_uri: ENV['SLACK_REDIRECT_URI'],
  slack_verification_token: ENV['SLACK_VERIFICATION_TOKEN'],
  read_only_channel: ENV['CHANNEL']
}

SCOPE = 'bot,commands,channels:history,chat:write:bot,admin,chat:write:user'

$teams = {}

def create_slack_client(slack_api_secret)
  Slack.configure do |config|
    config.token = slack_api_secret
    fail 'Missing API token' unless config.token
  end
  Slack::Web::Client.new
end

class Auth < Sinatra::Base

  slack_button = %(
<a href=\"https://slack.com/oauth/authorize?scope=#{SCOPE}&client_id=#{SLACK_CONFIG[:slack_client_id]}&redirect_uri=#{SLACK_CONFIG[:slack_redirect_uri]}\">
<img alt=\"Add to Slack\" height=\"40\" width=\"139\" src=\"https://platform.slack-edge.com/img/add_to_slack.png\"/>
</a>
)
  
  get '/' do
    redirect '/begin_auth'
  end
  
  get '/begin_auth' do
    status 200
    body slack_button
  end
  
  get '/finish_auth' do
    client = Slack::Web::Client.new
    
    begin
      response = client.oauth_access(
        {
          client_id: SLACK_CONFIG[:slack_client_id],
          client_secret: SLACK_CONFIG[:slack_api_secret],
          redirect_uri: SLACK_CONFIG[:slack_redirect_uri],
          code: params[:code]
        }
      )
      
      team_id = response['team_id']
      $teams[team_id] = {
        user_access_token: response['access_token'],
        bot_user_id: response['bot']['bot_user_id'],
        bot_access_token: response['bot']['bot_access_token']
      }
      
      $teams[team_id]['botclient'] = create_slack_client response['bot']['bot_access_token']
      $teams[team_id]['userclient'] = create_slack_client response['access_token']
      
      status 200
      body 'Auth succeeded!'
    rescue Slack::Web::Api::Error => e
      status 403
      body "Auth Failed! Reason: #{e.message}<br/>#{slack_button}"
    end
  end
end
