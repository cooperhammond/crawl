require_relative 'game.rb'
require 'meiro'

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

    @map.define_object("vampire", {
      symbol: "V",
      type: "dynamic",
      color: Gosu::Color::rgb(255, 0, 0),
      behavior: ->(args) {
        chase(@map.get_object_by_id(args[:id]), @map.player)
        kill_player_if_touching(args[:id], args[:words] || "You were killed by a vampire.")
      }
    })

    options = {
      width:  75,
      height: 37,
      min_room_number: 3,
      max_room_number: 10,
      min_room_width:  5,
      max_room_width: 20,
      min_room_height: 3,
      max_room_height: 10,
      block_split_factor: 3.0,
    }
    dungeon = Meiro.create_dungeon(options)
    floor = dungeon.generate_random_floor

    floor.classify!(:rogue_like)
    @floor = floor.to_s
    replacements = {
      " " => "q",
      "#" => ".",
      "q" => "#",
      "|" => "#",
      "-" => "#",
      "." => " ",
      "+" => " ",
    }
    replacements.each do |char, replacement|
      @floor = @floor.tr(char, replacement)
    end

    #add_corridors()
    @floor = @floor.split("\n")
  end

  def place_stuff
    @map.create_from_grid(-1, -1, @floor, {
      "#" => ["wall", {color: Gosu::Color::rgb(255, 255, 255)}],
      ">" => ["player"],
    })
    randomly_place_object("player")
    randomly_place_object("vampire", id: gen_id)
  end

  def update
    object_controls(@map.player)
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
