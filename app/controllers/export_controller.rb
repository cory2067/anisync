class ExportController < ApplicationController
  $progress = {}

  def index
    @anisync = Anisync.new
  end

  def create
    @user = params[:anisync][:alusername]
    respond_to do | format |
      format.html { redirect_to export_url }
      format.js
    end

    process = Thread.new(@user) do |user|
      parameters = {:grant_type => "authorization_pin", :client_id => "cor-loasb",
        :client_secret => ENV["CLIENT_SECRET"], :code => params[:anisync][:token]}
      a = HTTP.post("http://anilist.co/api/auth/access_token", :params => parameters)
      @auth = JSON.parse(a.to_s)
      if @auth['access_token'] != nil
        $progress[user] = "<p>Account succesfully authenticated. Exporting, this may take a while.</p><p>Downloading your list...</p>"
      else
        $progress[user] = "<p>Error! Could not authenticate. Refresh and try again.</p>"
        return
      end

      output = '''<?xml version="1.0" encoding="UTF-8" ?>
  <!--
  Created by AniSync
  Programmed by Cor
  -->

<myanimelist>
  <myinfo>
    <user_id>5459046</user_id>
    <user_name>testcor</user_name>
    <user_export_type>1</user_export_type>
    <user_total_anime>0</user_total_anime>
    <user_total_watching>0</user_total_watching>
    <user_total_completed>0</user_total_completed>
    <user_total_onhold>0</user_total_onhold>
    <user_total_dropped>0</user_total_dropped>
    <user_total_plantowatch>0</user_total_plantowatch>
  </myinfo>
'''

      list = HTTP.auth("Bearer " + @auth['access_token']).get("http://anilist.co/api/user/" + user + "/animelist").to_s

      #should probably move this somewhere else
      def get_mal(anime)
        return anime['id'].to_s if anime['id'].to_i < 19285
        existing = Anime.where(:alid => anime['id']).all
        return existing[0][:malid].to_s if existing.size > 0
        show = {'q' => anime['title_romaji']}
        r = HTTP.get("http://myanimelist.net/anime.php", :params => show)
        c = r.to_s
	n = 1
	ani_id = 0
	while ani_id.to_i < 19285
        	ani_id = (c.split('<a class="hoverinfo_trigger')[n].split('http://myanimelist.net/anime/')[1].split("/")[0])
		n += 1
	end
        puts "Adding this with mal id: " + ani_id
        b = Anime.new({:alid => anime['id'], :malid => ani_id})
        b.save
        return ani_id
      end

      #$progress[@user] += list
      count = 0
      puts "doin a thing"
      all = JSON.parse(list)
      all['lists'].merge(all['custom_lists']).each do |t, sublist|
        sublist.each do |anime|
	type = anime['list_status']
	  next if type == ""
	  count += 1
          output += "\t<anime>\n"
          #$progress[user] += '<p>' + anime['list_status'] + " " + anime['anime']['id'].to_s + " " + anime['episodes_watched'].to_s + '</p>'
          score = anime['score_raw']
	  score += 5 if score < 5 && score > 0
	  score = (score + 5) / 10
          output += "\t\t<update_on_import>1</update_on_import>\n"
          output += "\t\t<series_animedb_id>" + get_mal(anime['anime']).to_s + "</series_animedb_id>\n"
          output += "\t\t<my_watched_episodes>" + anime['episodes_watched'].to_s + "</my_watched_episodes>\n"
          output += "\t\t<my_status>" + {"watching" => "Watching", "completed" => "Completed", "plan to watch" => "Plan to Watch", "on-hold" => "On-Hold", "dropped" => "Dropped"}[type] + "</my_status>\n"
          output += "\t\t<my_score>" + score.to_s + "</my_score>\n"
          #$progress[user] += get_mal(anime['anime'])
          $progress[user] = "<p>Account succesfully authenticated. Exporting, this may take a while.</p><p>Titles finished: #{count}</p>"
          output += "\t</anime>\n"
        end
      end

      output += '</myanimelist>'
      puts "done"
      File.write('app/assets/images/' + user + '.xml', output)
      $progress[user] = "<a href=http://cory.pw/assets/" + user + ".xml>http://cory.pw/assets/" + user + '.xml</a>
      <p>To save this file, right click and hit "Save link as..."</p>'
    end
  end

  def prog
    puts params
    respond_to do |format|
      format.text { render :text => $progress[params[:name]]}
    end
  end
end
