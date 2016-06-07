anisyncs = Anisync.all.each do |u|
  puts "Refreshing user #{u.alusername}"
  parameters = {:grant_type => "refresh_token", :client_id => "cor-loasb",
      :client_secret => ENV["CLIENT_SECRET"], :refresh_token => u[:refresh]}
puts parameters
  a = HTTP.post("http://anilist.co/api/auth/access_token", :params => parameters)
  
puts a.to_s
auth = JSON.parse(a.to_s)
  refreshed = auth["access_token"]
puts refreshed 
puts u.token 
u.update(:token => refreshed)
puts u.token
end

puts "Refresh complete."
