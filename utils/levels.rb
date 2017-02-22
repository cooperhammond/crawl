require_relative 'utils.rb'

class Standard
  def initialize(level)
    @level = level
    @map = level.map
    @window = @level.window
  end

  def place_stuff

  end

  def update

  end
end

class TitleScreen < Standard

  def place_stuff
    @window.display_pane = false
    @map.create_from_grid(0, 0, '
    ___   ___     _    __      __  _
   / __| | _ \   /_\   \ \    / / | |
   |(__  |   /  / _ \   \ \/\/ /  | |__
   \___| |_|_\ /_/ \_\   \_/\_/   |____|

    The point is to get the high score.
          Move with arrow keys.
         Attack with arrow keys.

                @
  stairs---- >                * ----leaderboard

 Your first task is to move down the stairs



                                                                            No secrets out here.                                                           Not one.                                                                               Probs not gonna happen.                                                                              Magical Ampersand: &                                                                                                                                         Nothin\' to see out here.                                                                                                                 Nothin\' but the empty void.                                                                                                                       What a wonderful abyss it is that we live in.                                                                                                                                         You should read some Nietzche sometime.                                                                                                                              He\'s got some good points.                                                                                              *vague humming*                                                                                                         *distinct humming to the tune of "The Man Who Sold The World"*                                                                                                       I really wish david bowie and kurt cobain hadn\'t died.                                                                                                        -GOD                                                                                                          ?




   Move down the stairs with the . key
      Move up stairs with the , key


          Secrets to the right.
'.split("\n"), {
      "#" => ["wall"],
      "@" => ["player"],
      ">" => ["stairs", {num: -1, id: "descend"}],
      "_" => {color: Gosu::Color::rgb(255, 0, 0)},
      "/" => {color: Gosu::Color::rgb(255, 0, 0)},
      "|" => {color: Gosu::Color::rgb(255, 0, 0)},
      "(" => {color: Gosu::Color::rgb(255, 0, 0)},
      '\\' => {color: Gosu::Color::rgb(255, 0, 0)},
      '&' => {color: Gosu::Color::rgb(255, 0, 252)},
      'G' => {color: Gosu::Color::rgb(0, 255, 0)},
      'O' => {color: Gosu::Color::rgb(0, 255, 0)},
      'D' => {color: Gosu::Color::rgb(0, 255, 0)},

      # def GOD
      '?' => {
        color: Gosu::Color::rgb(255, 255, 255),
        behavior: ->(args) {
          passive_damage(@map.get_object_by_id(args[:id]))
        },
        hp: 1,
        dmg: 100000000,
        killed_by: "                            -GOD",
        args: {id: gen_id},
      },
    })
  end

  def update

  end
end

class Endgame < Standard
  def place_stuff
    @window.display_pane = false
    @map.create_from_grid(0, 0, '

             WELC0ME TO THE END OF THE WORLD.
              Here\'s where you\'ll get that
             wierd orb you were searching for.
           (You were searching for that, right?)

                         @












               (It\'s the "o" in "Welcome.")


    '.split("\n"), {
      "@" => ["player"],
      "0" => {type: "item", name: "the orb"}
    })
  end

  def update
    if @map.has_item?("the orb")
      win()
    end
  end

end


class RandomFloor < Standard
  def initialize(level)
    @level = level
    @map = level.map
    @window = level.window

    @map.define_object("alien", {
      symbol: "A",
      type: "enemy",
      hp: rand(50..150),
      dmg: rand(5..20),
      color: Gosu::Color::rgb(100, 255, 100),
      killed_by: ["When trying to kiss an alien, it decided to eat you. Sicko.", "You were killed by an alien.", "Alien spit, does, in fact, burn.", "Once upon a time, you died.", "In the name of science, you discovered what an alien's stomach looks like.", "When unarmed, don't attempt battle.", "The key to success is not dying.", "What a surprise, you died.", "You were supposed to stay alive.", "*snide 'you died' comment*", "Here's a grave because we reward failure."][rand(0..10)],
      behavior: ->(args) {
        me = @map.get_object_by_id(args[:id])
        passive_damage(me)
        if distance_from(me, @map.player) < 7
          chase(me, @map.player)
        else
          move_randomly(me)
        end
      },
      initialize: ->(args) {
        me = @map.get_object_by_id(args[:id])
        if args[:color] == "orange"
          me[:color] = Gosu::Color::rgb(244, 191, 66)
          me[:hp] = rand(150..250)
          me[:dmg] = rand(20..40)
        end
        if args[:color] == "red"
          me[:color] = Gosu::Color::rgb(255, 10, 10)
          me[:hp] = rand(350..500)
          me[:dmg] = rand(70..90)
        end
      }
    })

    options = {
      width:  @map.width,
      height: @map.height,
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
    @window.display_pane = true
    @window.pane_text("'h' for help")

    @map.create_from_grid(-1, -1, @floor, {
      "#" => ["wall", {color: Gosu::Color::rgb(255, 255, 255)}],
      ">" => ["player"],
    })

    (0..7).each do |n|
      if @map.player_floor * -1 >= 2
        color = ["orange", "", ""][rand(0..2)]
      end
      if @map.player_floor * -1 >= 4
        color = ["red", "orange", ""][rand(0..2)]
      end
      if @map.player_floor * -1 >= 6
        color = ["red", "orange", "orange"][rand(0..2)]
      end
      if @map.player_floor * -1 >= 8
        color = ["red", "red", "orange"][rand(0..2)]
      end
      if @map.player_floor * -1 >= 10
        color = "red"
      end

      @level.randomly_place_object("alien", id: gen_id, color: color)
    end

    @level.randomly_place_object("stairs", id: "descend", num: -1)
    if @status == "next"
      @level.randomly_place_object("stairs", id: "ascend", num: 1)
      @level.randomly_place_object("player")
      @map.player[:x] = (@map.get_object_by_id("ascend")[:x])
      @map.player[:y] = (@map.get_object_by_id("ascend")[:y])
      @level.offset_map_by_name("player")

    else
      @level.randomly_place_object("player")
      while !@map.level.grid.key?("#{@map.player[:x]} #{@map.player[:y]}")
        @map.delete_object_by_name("player")
        @level.randomly_place_object("player")
      end
      @level.offset_map_by_name("player")
    end

    @map.set_weapon("weapon")
  end
  def floor
    return @floor
  end
end
