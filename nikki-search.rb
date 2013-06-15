require "sinatra"
require "haml"
require "uri"
require_relative "lib/groonga_database"

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

get "/register" do
  register(params[:uri]) rescue $stderr.puts $!.message
  haml :index
end

private
def register(uri)
  parsed_uri = URI.parse(uri)
  scheme= parsed_uri.scheme
  hostname = parsed_uri.hostname

  require "open-uri"
  links = []
  open(uri) do |page|
    page.each_line do |line|
      p line
      links << line.scan(/['"]((?:\.|#{scheme}:\/\/#{hostname})[^'"]+\.html?)['"]/)
    end
  end

  GroongaDatabase.new.open("db") do |database|
    links.flatten.uniq.each do |link|
      html = open(link.sub(/^\./, "#{scheme}://#{hostname}")).read
      database.add(link, html)
    end
  end
end
