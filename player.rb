$LOAD_PATH << File.dirname(__FILE__)

require 'jukebox'
require 'track'
require 'mpg123_control'

class Player
  SLEEP_DURATION = 1
  PAUSED = 'pause'
  PLAYING = 'play'

  def initialize jukebox_url
    @mpg123 = Mpg123Control.new
    @jukebox = Jukebox.new jukebox_url
  end

  def run
    loop do
      handle_pause or handle_hammertime or handle_playlist or sleep(SLEEP_DURATION)
    end
  end

  protected

  def handle_pause
    return false if @state == @jukebox.state

    @state = @jukebox.state
    if playing?
      play current_track
    else 
      current_track.start_time = @mpg123.current_track_time[:seconds_played]
      @mpg123.toggle_pause
    end
    true
  end

  def handle_hammertime
    if !hammertime_playing? && current_hammertime
      current_track.start_time ||= @mpg123.current_track_time[:seconds_played]
      play current_hammertime
      return true
    end
    if hammertime_playing? && hammertime_done?
      if @current_hammertime.pause_after?
        @jukebox.pause 
      else
        play current_track
      end
      @current_hammertime = nil 
      return true
    end
    false
  end

  def handle_playlist
    return false unless playing? and (@jukebox.skip? or @mpg123.done_playing?)
    @current_track = nil
    play current_track
  end

  def current_track
    @current_track ||= next_track
  end

  def current_hammertime
    @current_hammertime ||= next_hammertime
  end

  def playing?
    @state == PLAYING
  end

  def hammertime_playing?
    !@current_hammertime.nil?
  end

  def hammertime_done?
    @mpg123.current_track_time[:seconds_played] >= @current_hammertime.end_time
  end

  def play track
    return unless track && track.file_location
    @mpg123.play track.file_location, track.start_time
    true
  end

  def next_track
    file_location = @jukebox.next_track
    return if file_location.nil? || file_location == ""

    Track.new [file_location] rescue nil
  end

  def next_hammertime
    track_attributes = @jukebox.next_hammertime
    return if track_attributes.nil? || track_attributes.empty?

    Track.new track_attributes rescue nil
  end
end

jukebox_url = ARGV.last

pid = fork do
  Signal.trap('HUP', 'IGNORE') # Don't die upon logout
  Player.new(jukebox_url).run
end

Process.detach pid