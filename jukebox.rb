require 'net/http'

class Jukebox
  PAUSED = 'pause'
  PLAYING = 'play'

  def initialize jukebox_url
    @jukebox_url = jukebox_url
  end

  def jukebox_url
    "http://localhost:3333"
  end

  def state
    Net::HTTP.get URI.parse("#{@jukebox_url}/playlist/status")
  end

  def skip?
    Net::HTTP.get(URI.parse("#{@jukebox_url}/playlist/skip_requested")) == true.to_s
  end

  def pause
    Net::HTTP.post_form(URI.parse("#{@jukebox_url}/playlist/pause"), {})
  end

  def next_track
    Net::HTTP.get URI.parse("#{@jukebox_url}/playlist/next_entry")
  end

  def next_hammertime
    response = Net::HTTP.get URI.parse("#{@jukebox_url}/playlist/next_hammertime")
    response.split('|')
  end
end
