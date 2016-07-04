def get_mal(anime)
  return anime['id'].to_s if anime['id'].to_i < 19285
  existing = Anime.where(:alid => anime['id']).all
  return existing[0][:malid].to_s if existing.size > 0
  show = {'q' => anime['title_romaji']}
  r = HTTP.get("http://myanimelist.net/anime.php", :params => show)
  c = r.to_s
  ani_id = (c.split('<a class="hoverinfo_trigger')[1].split('http://myanimelist.net/anime/')[1].split("/")[0])
  puts "Adding this with mal id: " + ani_id
  b = Anime.new({:alid => anime['id'], :malid => ani_id})
  b.save
  return ani_id
end

def get_method(id)
  if $list == nil
    puts "Fetching MAL info..."
    $list = HTTP.get("http://myanimelist.net/malappinfo.php?u=" + $user.username + "&status=all&type=anime").to_s
    $list = $list.split('<').delete_if {|x| !(x.include? "animedb_id")}.join.gsub("series_animedb_id","")
  end
  if $list.to_s.include? ('>' + id.to_s + '/') then 'update' else 'add' end
end

anisyncs = Anisync.all.each do |u|
  puts "Beginning sync for user " + u.alusername + " / " + u.username
  success = true
  begin
  $list = nil
  $user = u
  puts "Fetching Anilist recent activity..."
  a = HTTP.auth("Bearer " + u.token).get("http://anilist.co/api/user/" + u.alusername + "/activity?page=1")
  if a.code == 401
    puts "Heck! Can't authenticate Anilist."
    next
  end
  #	puts a.to_s
  anilist = JSON.parse(a.to_s).reverse
  #latest = DateTime.parse(anilist[0]['created_at'])
  if u.sync != nil
    anilist = anilist.delete_if {|x| DateTime.parse(x['created_at']) < u.sync}
  end
  updates = {}

  puts "Synchronizing changes..."
  anilist.each do |entry|
    type = 0
    begin
   	 type = 1 if entry['series']['series_type'] == 'manga'
    rescue StandardError
         next
    end
    next if type == 1 #temporary
    add = 0
    if entry['status'] == 'plans to watch' or entry['status'] == 'plans to read'
      add = 6
    elsif entry['status'] == 'completed'
      add = 2
    elsif entry['status'] == 'paused watching' or entry['status'] == 'paused reading'
      add = 3
    elsif entry['status'] == 'dropped'
      add = 4
    end
    if add > 0
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<entry>
  <status>#{add}</status>
</entry>
"
    next if entry['series'] == nil #sometimes happens for some odd reason
    ani_id = get_mal(entry['series'])
    stat = [nil, nil, 'completed', 'paused', 'dropped', nil, 'plans to watch']
    puts(entry['series']['title_romaji'] + ": " + stat[add])
  	r = HTTP.basic_auth(:user => u.username, :pass => u.password).get("http://myanimelist.net/api/animelist/"+
                        get_method(ani_id) +"/"+ani_id+".xml", :params => {"data" => xml})
     if r.code > 201
   	 puts ("ERROR: Failed to update -- " + r.to_s)
         success = false
     end
     next
   end

  	if entry['status'] != 'watched episode' and entry['status'] != 'read chapter'
  		next
    end

  	anime = entry['series']
  	episode = entry['value'].split(' ')[-1]
  	updates[anime] = episode
  end

  updates.each do |a, ep|
  	puts(a['title_romaji'] + ': watched episode ' + ep.to_s)
  	ani_id = get_mal(a)
    xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<entry>
  <episode>#{ep}</episode>
  <status>1</status>
</entry>
"
    #submit = {'data':xml.format(ep)}
  	r = HTTP.basic_auth(:user => u.username, :pass => u.password).get("http://myanimelist.net/api/animelist/"+get_method(ani_id)+"/"+ani_id+".xml", :params => {"data" => xml})
     if r.code > 201
   	 puts ("ERROR: Failed to update -- " + r.to_s)
         success = false
     end
end

  #idk what time zone anilist is, but it's a bit past utc
  u.update(:sync => (DateTime.now.utc + 0.3)) if success
  rescue StandardError => kablooey
  puts "ERROR: " + kablooey.to_s
  end
  puts "User synchronized!"
end
