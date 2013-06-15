require "sinatra"
require "haml"
require "uri"
require_relative "lib/groonga_database"

get "/" do
  haml :index
end

post "/search" do
  begin
    @links = search(params[:word])
  rescue
    $stderr.puts $!.message
  end

  @params = params
  haml :index
end

get "/register" do
  register(params[:uri]) rescue $stderr.puts $!.message
  haml :index
end

private
def search(word)
  links = []
  GroongaDatabase.new.open("db") do |database|
    pages = database.pages.select do |v|
      v.html =~ word
    end

    pages.each do |page|
      links << page.link
    end
  end
  links
end

def register(uri)
  parsed_uri = URI.parse(uri)
  scheme= parsed_uri.scheme
  hostname = parsed_uri.hostname

  require "open-uri"
  links = []
  open(uri) do |page|
    page.each_line do |line|
      links << line.scan(/['"]((?:\.|#{scheme}:\/\/#{hostname})[^'"]+\.html?)['"]/)
    end
  end

  GroongaDatabase.new.open("db") do |database|
    links.flatten.uniq.each do |link|
      expanded_link = link.sub(/^\./, "#{scheme}://#{hostname}")
      html = open(expanded_link).read.force_encoding("UTF-8")
      database.add(expanded_link, html)
    end
  end
end
