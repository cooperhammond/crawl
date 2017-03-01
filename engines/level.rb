require 'meiro'
Dir.glob("../utils/*.rb").each { |file| require_relative file }

class RandomRoom
  attr_accessor :grid, :reset_dir
  attr_reader :map, :window
  def initialize(map, status, window, floor)
    @floor_level = floor
    @status = status
    @map = map
    @window = window
    @move_timer = Time.new
    @timer = Time.new
    @freeze = false
    @grid = {}
    default_definitions()

    @width = rand(40..60)
    @height = rand(20..30)

    @reset_dir = [0, 0]

    # Level decisions
    if @floor_level == 0
      @level = TitleScreen.new(self)
    elsif @floor_level == 1
      @level = Leaderboard.new(self)
    elsif @floor_level == -10
      @level = Endgame.new(self)
    else
      @level = RandomFloor.new(self)
      @floor = @level.floor
    end
  end

  def place_stuff
    @level.place_stuff
  end

  def update
    @level.update
    object_controls(@map.player) # This must be the final line
  end

  def offset_map_by_name(name)
    offset_to = @map.get_object_by_name(name)
    @map.player_offset_x = -(offset_to[:x] - @map.width / (@window.zoom / 0.5)).round
    @map.player_offset_y = -(offset_to[:y] - @map.height / (@window.zoom / 0.5)).round
  end

  def player_died
    everything(@reset_dir.map{ |x| x * -1 })
    @window.texts = []
    @window.pane_text("You got killed!")
    @window.pane_text("-1 life")
    @window.pane_text("You've got #{@map.player_lives} left.")
    @map.level.reset_dir = [0, 0]
  end

  def randomly_place_object(object, args={})
    x = -1
    y = -1
    possible_locs = []
    @floor.each do |layer|
      y += 1
      x = -1
      layer.split(//).each do |char|
        x += 1
        if char == " "
          possible_locs.push([x, y])
        end
      end
    end
    where = possible_locs[rand(0..possible_locs.size - 1)]
    @map.place_object(where[0], where[1], object, args)
  end
end
