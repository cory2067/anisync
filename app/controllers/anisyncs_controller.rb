class AnisyncsController < ApplicationController
  def index
    @anisync = Anisync.new
    @anisyncs = Anisync.all
  end

  def create
    parameters = {:grant_type => "authorization_pin", :client_id => "cor-loasb",
      :client_secret => ENV["CLIENT_SECRET"], :code => params[:anisync][:token]}
    puts parameters
    a = HTTP.post("http://anilist.co/api/auth/access_token", :params => parameters)
    auth = JSON.parse(a.to_s)
    params[:anisync][:refresh] = auth["refresh_token"]
    params[:anisync][:token] = auth["access_token"]
    @anisync = Anisync.new(anisync_params)
    @anisync.save

    redirect_to "/anisyncs"
  end

  private
    def anisync_params
      params.require(:anisync).permit(:username, :password, :token, :refresh)
    end
end
