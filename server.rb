require "sinatra"
require "./tagger.rb"
require "json"

$tagger = Tagger.new

get "/tag" do
  $tagger.tag(params[:text]).to_json
end

post "/tag" do
  $tagger.tag(params[:text]).to_json
end
