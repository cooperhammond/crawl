class Map
  attr_reader :width, :height, :grid, :level, :player_x, :player_y, :player_floor
  attr_accessor :player_offset_x, :player_offset_y, :player_turns, :player_lives
  def initialize(x, y)
    @width = x
    @height = y
    @object_definitions = {}
    @grid = {}
    @space = {symbol: ' ', type: 'block'}

    define_object("player", {
      symbol: "@",
	    lvl: 1,
      type: 'player',
      color: Gosu::Color::rgb(28, 185, 25),
      inventory: [],
      current_weapon: {},
	    hp: 100,
      max_hp: 100,
      killed_by: "You were killed by god."
    })

    @player_floor = 0


    @player_offset_x = 0
    @player_offset_y = 0

    @dead_player = false
    @player_lives = 3

    @player_turns = 0

  end

  def start_running
    @grid[@player_floor] = RandomRoom.new(self, "new", @window, @player_floor)
    level.place_stuff
  end

  def give_window(window)
    @window = window
    @map = self
  end

  def level
    return @grid[@player_floor]
  end

  def reset
	level.grid = {}
  end

  def new_level(id)
    @player_floor += id
    if !@grid.key?(@player_floor)
      @grid[@player_floor] = RandomRoom.new(self, "next", @window, @player_floor)
      level.place_stuff
      player[:lvl] = @player_floor * -1

      player[:max_hp] *= (1 + (0.2 * player[:lvl]))
      player[:current_weapon][:dmg] *= (1 + (0.4 * player[:lvl]))

      player[:max_hp] = player[:max_hp].to_i
      player[:current_weapon][:dmg] = player[:current_weapon][:dmg].to_i

      @window.texts = []
    end
  end

  def place_player(x, y)
    level.grid["#{x} #{y}"] = place_object(x, y, "player", {inventory: player[:inventory]})
  end

  def update
    level.grid.each do |loc, object|
      if object[:type] == "enemy"
        if object[:hp] <= 0
          @window.score += object[:max_hp]
          delete_object_by_true_loc(object)
        end
      end

      if object[:type] == "item"
        if "#{player[:x]} #{player[:y]}" == "#{object[:x]} #{object[:y]}"
          level.grid.delete(loc)
          player[:inventory].push(object)
        end
      end
    end

    if player[:hp] <= 0
      player_died()
    end

    if @player_lives <= 0 and @dead_player != true
      @dead_player = true
      killed_by(player[:killed_by])
    end

    level.offset_map_by_name("player")
  end

  def turns
    if level.update
      level.grid.each do |loc, object|
        if object.key?(:behavior)
          if object[:args] != {}
            object[:behavior].call(object.merge(object[:args]))
          else
            object[:behavior].call
          end
        end
      end
    end
  end

  def attack_movement?(n, obj)
    # n => [x-being-moved, y-being-moved]
    # object => some placed object
    level.grid.each do |loc, properties|
      if "#{properties[:x]} #{properties[:y]}" == "#{obj[:x] + n[0]} #{obj[:y] + n[1]}" and properties[:type] == "enemy"
        return true
      end
    end
    return false
  end

  def attack_object(n, obj, dmg)
    level.grid.each do |loc, object|
      if "#{object[:x]} #{object[:y]}" == "#{obj[:x] + n[0]} #{obj[:y] + n[1]}" and object[:type] == "enemy"
        object[:take_damage].call(object[:args], dmg)
      end
    end
  end

  def damage_player(dmg, words)
    dmg = rand((dmg * 0.8)..(dmg * 1.2)).round
    player[:hp] -= dmg
    player[:killed_by] = words
    @window.pane_text("You took #{dmg}\ndamage!")
  end

  def delete_object_by_id(id)
    level.grid.delete(level.grid.key(get_object_by_id(id)))
  end

  def delete_object_by_name(name)
    level.grid.each do |loc, object|
      if object[:name] == name
        level.grid.delete(loc)
      end
    end
  end

  def delete_object_by_true_loc(obj)
    level.grid.each do |loc, object|
      if obj == object
        level.grid.delete(loc)
      end
    end
  end

  def define_object(name, properties={})
    # properties must resemble something like:
    # define_object("<new-name>", {
    #   symbol: "g",   # cannot be longer than one character long
    #   type: "item",   # possible types: dynamic, item, block, enemy
    #   color: Gosu::Color::rgb(<r>, <g>, <b>),   # optional
    #   id: 1,   # optional. can be pretty much any arbitrary value
    #   function: ->(args) { <pretty-much-any-code } # TODO: make this a thing.
    # })
    # symbols cannot be longer than 1 character
    raise "\nno :symbol supplied" if !properties.key?(:symbol)
    raise "\n:symbols cannot be more than 1 character long: '#{properties[:symbol]}'" if properties[:symbol].length > 1
    raise "\nno :type supplied" if !properties.key?(:type)

    if !properties.key?(:color)
      properties[:color] = Gosu::Color::rgb(138, 138, 138)
    end
    if properties[:type] == "enemy"
      if !properties.key?(:hp)
        properties[:hp] = 100
      end
      if !properties.key?(:take_damage)
        properties[:take_damage] = ->(args, dmg) {
          me = self.get_object_by_id(args[:id])
          me[:hp] -= dmg
        }
      end
    end
    @object_definitions[name] = properties
  end

  def place_object(x, y, name, args={})
    raise "\nthere is no object called '#{name}'" if !@object_definitions.key?(name)
    level.grid["#{x} #{y}"] = @object_definitions[name].merge({name: name, x: x, y: y, args: args})
    if level.grid["#{x} #{y}"].key?(:initialize)
      level.grid["#{x} #{y}"][:initialize].call(args)
    end
  end

  def make_object(name, args={})
    raise "\nthere is no object called '#{name}'" if !@object_definitions.key?(name)
    args = args.merge(id: rand(0..1000000))
    x, y = rand(1000..10000), rand(1000..10000)
    level.grid["#{x} #{y}"] = @object_definitions[name].merge({x: x, y: y, name: name, args: args})
    if level.grid["#{x} #{y}"].key?(:initialize)
      level.grid["#{x} #{y}"][:initialize].call(args)
    end
    return level.grid["#{x} #{y}"]
  end

  def place_char(x, y, char, opts={})
    if !opts.is_a?(Hash)
      opts = {}
    end
    level.grid["#{x} #{y}"] = {
      symbol: char,
      x: x,
      y: y,
      color: Gosu::Color::rgb(138, 138, 138),
      type: "block",
    }.merge(opts)
  end

  def player
    level.grid.each do |loc, object|
      if object[:name] == "player"
        return object
      end
    end
    raise "Must define player first!"
  end

  def get_object(x, y)
    if level.grid.key?("#{x} #{y}")
      return level.grid["#{x} #{y}"]
    else
      @space[:x] = x
      @space[:y] = y
      return @space
    end
  end

  def get_object_by_id(id)
    level.grid.each do |loc, object|
      begin
        if object[:args][:id] == id
          return level.grid[loc]
        end
      rescue
        next
      end
    end
  end

  def get_object_by_loc(x, y, exceptions=[])
	level.grid.each do |loc, object|
	  if "#{x} #{y}" == loc
      if !exceptions.include?(object[:name])
	      return object
      else
        return false
      end
	  end
	end
  end

  def get_object_locs_by_name(name)
    arr = []
    level.grid.each do |loc, object|
      if object[:name] == name
        arr.push(loc)
      end
    end
    return arr
  end

  def get_object_loc_by_id(id)
    level.grid.each do |loc, object|
      begin
        if object[:args][:id] == id
          return loc
        end
      rescue
        next
      end
    end
  end

  def get_objects_by_name(name)
    arr = []
    level.grid.each do |loc, object|
      if object[:name] == name
        arr.push(level.grid[loc])
      end
    end
    return arr
  end

  def get_object_by_name(name)
    level.grid.each do |loc, object|
      if object[:name] == name
        return (level.grid[loc])
      end
    end
  end

  def give_item(object_name)
    player[:inventory].push(self.make_object(object_name))
  end

  def set_weapon(object_name)
    player[:current_weapon] = self.make_object(object_name)
  end

  def has_item?(object_name)
    player[:inventory].each do |item|
      if item[:name] == object_name
        return true
      end
    end
    return false
  end

  def valid_movement?(n, object)
    # n => [x-being-moved, y-being-moved]
    # object => some placed object
    if (object[:x] + n[0] < 0) or (object[:x] + n[0] > @width - 1) or (object[:y] + n[1] < 0) or (object[:y] + n[1] > @height - 1)
      return false
    end
    level.grid.each do |loc, properties|
      if "#{properties[:x]} #{properties[:y]}" == "#{object[:x] + n[0]} #{object[:y] + n[1]}"
        if object[:type] == "enemy" and properties[:type] == "player"
          return false
        end
        if properties[:type] == "block"
          return false
        end
      end
    end
  end

  def create_from_grid(x, y, grid, definitions)
    # Example usage:
    # create_from_grid([
    #   "#####",
    #   "# @ #",
    #   "# - #",
    #   "## ##"],
    #   5, 3,
    #   {
    #     "#" => ["block", {id: gen_id}]
    #     "@" => ["player"]
    #     "-" => {color: Gosu::Color::rgb(255, 255, 255)}
    #   }
    #)
    offset_y = 0
    grid.each do |line|
      offset_y += 1
      chars = line.split(//)
      offset_x = 0
      chars.each do |char|
        offset_x += 1
        next if char == " "
        if definitions[char] and @object_definitions.key?(definitions[char][0])
          if definitions[char][1].nil?
            place_object(offset_x + x, offset_y + y, definitions[char][0])
          else
            place_object(offset_x + x, offset_y + y, definitions[char][0], definitions[char][1])
          end
        else
          place_char(offset_x + x, offset_y + y, char, definitions[char])
        end
      end
    end
  end

  def colliding?(obj1, obj2)
    if "#{obj1[:x]} #{obj1[:y]}" == "#{obj2[:x]} #{obj2[:y]}"
      return true
    end
  end

  def player_has_object?(object_name)
    player.inventory
  end

  def are_touching?(obj1, obj2)
    if "#{obj1[:x]} #{obj1[:y]}" == "#{obj2[:x]} #{obj2[:y]}" or \
      "#{obj1[:x] + 1} #{obj1[:y]}" == "#{obj2[:x]} #{obj2[:y]}" or \
      "#{obj1[:x] - 1} #{obj1[:y]}" == "#{obj2[:x]} #{obj2[:y]}" or \
      "#{obj1[:x]} #{obj1[:y] + 1}" == "#{obj2[:x]} #{obj2[:y]}" or \
      "#{obj1[:x]} #{obj1[:y] - 1}" == "#{obj2[:x]} #{obj2[:y]}"
      return true
    end
  end

  def get_object_definition(definition_name)
    @object_definitions.each do |def_name, object|
      if definition_name == def_name
        return object
      end
    end
  end

  def turns
    @player_turns += 1
    if player[:hp] < player[:max_hp] and @player_turns % 3 == 0
      player[:hp] += 2
    end

    level.grid.each do |loc, object|
      if object.key?(:behavior)
        if object[:args] != {}
          object[:behavior].call(object.merge(object[:args]))
        else
          object[:behavior].call
        end
      end
    end
  end
end
