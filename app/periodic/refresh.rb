anisyncs = Anisync.select("id, refresh").all.each do |u|
  parameters = {:grant_type => "refresh_token", :client_id => "cor-loasb",
      :client_secret => ENV["CLIENT_SECRET"], :refresh_token => u[:refresh]}

  a = HTTP.post("http://anilist.co/api/auth/access_token", :params => parameters)
  auth = JSON.parse(a.to_s)
  refreshed = auth["access_token"]
  u.update(:token => refreshed)
end
