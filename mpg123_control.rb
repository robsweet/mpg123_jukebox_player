#  Hacked from:
# ---    MP3 Control    ---
#
# Author:   Magnus Engström
# Email:    magnus@gisab.se
# File:   mp3controld
#

# --- MP3Control - the main class ---
class Mpg123Control

  STATUSES = [:done_playing, :paused, :playing ]

  def initialize
    @last_status = :done_playing
    @last_track_times = { :seconds_played => 0, :seconds_left => 0 }
  end

  def find_status
    process_output
    @last_status
  end

  def current_track_time
    process_output
    @last_track_times
  end

  def done_playing?
    find_status == :done_playing
  end

  def paused?
    find_status == :paused
  end

  def playing?
    find_status == :playing
  end

  def init_mpg123
    return if @mpg123
    @mpg123 = IO::popen("mpg123 -R -", 'r+')
  end

  def send_command command
    init_mpg123
    write_log ["mpg123 command: '#{command}'"]
    # puts "mpg123 command: '#{command}'"
    @mpg123.write "#{command}\n"
    @mpg123.flush
  end

  def play mp3_file, start_offset = nil
    send_command "LOAD #{mp3_file}"
    jump_to start_offset if start_offset
    sleep 0.5
  end

  def toggle_pause
    send_command "PAUSE"
  end

  def jump_to sec
    ## A value preceded by a + or - jumps relative to the current position.  An unsigned number is an absolute jump.
    send_command "JUMP #{sec}s"
  end

  protected

  def process_output
    init_mpg123
    lines = @mpg123.read_nonblock(200000).split("\n").reverse
    # puts lines.join("\n")
    write_log lines
    find_last_status lines
    find_last_track_status lines
  rescue Errno::EAGAIN
  end

  def write_log lines
    return
    @log ||= File.open('/tmp/rob.log','w')
    lines.reverse.each { |line| @log.write line + "\n" }
  end

  def find_last_status lines
    last_status_line = lines.detect { |line| line =~ /^@P (\S+)/ }
    @last_status = STATUSES[$1.to_i] if last_status_line
  end

  def find_last_track_status lines
    last_track_line  = lines.detect { |line| line =~ /^@F \S+ \S+ (\S+) (\S+)/ }
    @last_track_times = { :seconds_played => $1.to_f, :seconds_left => $2.to_f } if last_track_line
    write_log ["*** #{@last_track_times.inspect}"]
  end
end
