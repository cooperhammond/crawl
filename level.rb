require_relative 'game.rb'

class RandomRoom
  attr_accessor :grid
  def initialize(map, direction)
    @map = map
    @move_timer = Time.new
    @timer = Time.new
    @freeze = false
    @grid = {}
    default_definitions()

    @width = rand(40..60)
    @height = rand(20..30)

    enter_room(direction)
    @map.define_object("vampire", {
      symbol: "V",
      type: "dynamic",
      color: Gosu::Color::rgb(255, 0, 0),
      behavior: ->(args) {
        chase(@map.get_object_by_id(args[:id]), @map.player)
        kill_player_if_touching(args[:id], args[:words])
      }
    })
  end

  def place_stuff
    level_box(width: @width, height: @height, x: "center", y: "center")
    @map.place_object(@start_x, @start_y, "player")
	(rand(0..5)).times do
		@map.place_object(rand(10..40), rand(10..40), "vampire", id: gen_id, words: "A vampire killed you.")
	end
  end

  def update
    object_controls(@map.player)
  end

  def enter_room(direction, player=false)
    case direction
    when "new"
      @start_x = 30
      @start_y = 25
    when "up"
      @start_x = (@map.width / 2).floor
      @start_y = ((@map.height / 2) + (@height / 2)).floor - 1
    when "down"
      @start_x = (@map.width / 2).floor
      @start_y = ((@map.height / 2) - (@height / 2)).floor + 1
    when "left"
      @start_x = ((@map.width / 2) + (@width / 2)).floor - 1
      @start_y = (@map.height / 2).floor
    when "right"
      @start_x = ((@map.width / 2) - (@width / 2)).floor + 1
      @start_y = (@map.height / 2).floor
    end
    if player == true
      @map.level.grid.delete(@map.get_object_locs_by_name("player")[0])
      @map.place_object(@start_x, @start_y, "player")
    end
  end
end
