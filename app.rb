require 'sinatra/base'
require 'slack-ruby-client'
require_relative 'db_funcs'

class API < Sinatra::Base
  
  post '/events' do
    
    request_data = JSON.parse(request.body.read)
    
    case request_data['type']
    when 'url_verification'
      request_data['challenge']
      
    when 'event_callback'
      if SLACK_CONFIG[:slack_verification_token] == request_data['token']
        event_data = request_data['event']
        team_id = request_data['team_id']
        
        case event_data['type']
        when 'message'
          Events.on_message(team_id, event_data)

        when 'app_uninstall'
          remove_team team_id
        end
        
        status 200
      else
        halt 403, "Invalid Slack verification token"
      end
    end
  end 
  
  post '/commands' do
    team_id = params['team_id']
    user = params['user_id']
    
    if params['token'] == SLACK_CONFIG[:slack_verification_token]
      
      case params['command']
      when '/announce'
        puts "running annouce command"
        Commands.announce(team_id, user, params['text'])
      end
      
      status 200
    else
      status 403
      body "invalid token"
    end
  end
  
  
  class Commands
    
    def self.announce(team, user, text)
      if $teams[team]['botclient'].users_info(user: user).user.is_admin
        $teams[team]['botclient'].chat_postMessage channel: SLACK_CONFIG[:read_only_channel], text: "<!everyone> #{text}"
      end
    end
    
  end
  
  
  class Events
    
    def self.on_message(team, event)
      channel = event['channel']
      user = event['user']

      unless event['subtype']
        if $teams[team][:botclient].channels_id(channel: SLACK_CONFIG[:read_only_channel]).channel.id == channel &&
           $teams[team][:bot_user_id] != user
          $teams[team][:userclient].chat_delete channel: channel, ts: event['ts'], as_user: true
        end
      end
    end
    
  end
end
