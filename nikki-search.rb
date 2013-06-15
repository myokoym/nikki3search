require "sinatra"
require "haml"

get "/" do
  haml :index
end

post "/search" do
  begin
    @pages = []
  rescue => e
    return "Error: #{e}"
  end

  @params = params
  haml :index
end
