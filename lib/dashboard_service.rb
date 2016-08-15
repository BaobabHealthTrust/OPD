module DashBoardService
  require 'yaml'
  CONFIG = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__),
  "../config/dashboard.yml")))

  def self.push_to_couch(data)

     auth_token = RestClient.post(CONFIG['credentials']['url'],
                                  :username =>CONFIG['credentials']['username'],
                                  :password=>CONFIG['credentials']['password'])
     #embedd token with data
     data[:auth_token] = auth_token
     RestClient::Request.execute(:method=>:post,
                                 :url=>CONFIG['credentials']['dashboard_url'],
                                 :payload=>data,
                                 :content_type=>:json)
   rescue RestClient::Exception => e
     raise e.http_body
  end
  def self.hello
    raise "Hello World".inspect
  end
end
