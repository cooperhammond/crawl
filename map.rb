class Map
  attr_reader :width, :height, :grid
  def initialize(x, y)
    @width = x
    @height = y
    @object_definitions = {}
    @grid = {}
    @space = {symbol: ' ', type: 'block'}
    define_object("player", {
      symbol: "@",
      type: 'dynamic',
      color: Gosu::Color::rgb(28, 185, 25),
      inventory: [],
    })
  end

  def reset
    @grid = {}
  end

  def place_player(x, y)
    @grid["#{x} #{y}"] = place_object(x, y, "player", {inventory: player[:inventory]})
  end

  def update
    @grid.each do |loc, object|
      if object[:type] == "item"
        if "#{player[:x]} #{player[:y]}" == "#{object[:x]} #{object[:y]}"
          @grid.delete(loc)
          player[:inventory].push(object)
        end
      end
    end
  end

  def define_object(name, properties={})
    # properties must resemble something like:
    # define_object("<new-name>", {
    #   symbol: "g",   # cannot be longer than one character long
    #   type: "item",   # possible types: dynamic, item, block
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
    @object_definitions[name] = properties
  end

  def place_object(x, y, name, args={})
    raise "\nthere is no object called '#{name}'" if !@object_definitions.key?(name)
    @grid["#{x} #{y}"] = @object_definitions[name].merge({name: name, x: x, y: y, args: args})
    if @grid["#{x} #{y}"].key?(:initialize)
      @grid["#{x} #{y}"][:initialize].call(args)
    end
  end

  def place_char(x, y, char, opts={})
    if !opts.is_a?(Hash)
      opts = {}
    end
    @grid["#{x} #{y}"] = {
      symbol: char,
      x: x,
      y: y,
      color: Gosu::Color::rgb(138, 138, 138),
      type: "block",
    }.merge(opts)
  end

  def player
    @grid.each do |loc, props|
      if props[:name] == "player"
        return props
      end
    end
    raise "Must define player first!"
  end

  def get_object(x, y)
    if @grid.key?("#{x} #{y}")
      return @grid["#{x} #{y}"]
    else
      @space[:x] = x
      @space[:y] = y
      return @space
    end
  end

  def get_object_by_id(id)
    @grid.each do |loc, props|
      begin
        if props[:args][:id] == id
          return @grid[loc]
        end
      rescue
        next
      end
    end
  end

  def get_objects_by_name(name)
    arr = []
    @grid.each do |loc, props|
      if props[:name] == name
        arr.push(@grid[loc])
      end
    end
    return arr
  end

  def get_object_by_name(name)
    @grid.each do |loc, props|
      if props[:name] == name
        return (@grid[loc])
      end
    end
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
    @grid.each do |loc, props|
      if "#{props[:x]} #{props[:y]}" == "#{object[:x] + n[0]} #{object[:y] + n[1]}" and props[:type] == "block"
        return false
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

end
