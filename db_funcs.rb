require 'mysql2'
require 'yaml'

=begin

SCHEMA
team TEXT, user_token TEXT, bot_token TEXT, bot_id TEXT, 

=end

$db_data = {}

def remove_team team
  DB_Client.query("DELETE FROM #{$db_data[:table]} WHERE team = #{team}")
end

def db_from_file
  $db_data = YAML.load_file('db.yml')

  Mysql2::Client.new( :host => $db_data[:host],
                     :username => $db_data[:user],
                     :password => $db_data[:pass],
                     :port => $db_data[:port],
                     :database => $db_data[:database],
                     :reconnect => true
                   )
end

def read_db

  begin
    results = DB_Client.query("SELECT * from #{$db_data[:table]}")
    
    if results.count > 0
      results.each do |row|
        
        $teams[row["team"]] = {
          user_access_token: row['access_token'],
          bot_access_token: row['bot_access_token'],
          bot_user_id: row['bot_id'],
          botclient: create_slack_client(row['bot_access_token']),
          userclient: create_slack_client(row['user_access_token'])
        }
        
      end
    end
  rescue Mysql2::Error => mye
    DB_Client.query "CREATE TABLE #{$db_data[:table]} ( team TEXT, user_access_token TEXT, bot_access_token TEXT, bot_id TEXT )"
  end
  
end

def write_db_data(team, user_token, bot_token, bot_id)
  DB_Client.query "INSERT INTO #{$db_data[:table]} VALUES ( \"#{team}\", \"#{user_token}\", \"#{bot_token}\",  \"#{bot_id}\")"
end
