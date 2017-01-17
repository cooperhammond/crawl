require 'gosu'
Dir["./*.rb"].each { |file| require file }

class GameWindow < Gosu::Window
  attr_accessor :texts
  attr_reader :map, :level, :zoom
  def initialize(map)
    temp = Gosu::Window.new(1, 1)
    @scale = 25
    @text_height = @scale
    @zoom = 1.6
    @font = Gosu::Font.new(temp, "./courier.ttf", @text_height)
    @texts = []
    @text_width = @font.text_width("!")
    @map = map
    @box_width = 20
    super((@map.width * @text_width).round + (@text_width * @box_width).round, (@map.height * @text_height).round + @text_height)
    self.caption = ""
    @pending = []
    @timer = Time.new
	  $window = self
    @map.give_window(self)
    @map.start_running
	@map.get_object_by_loc(0, 0)

  end

  def update
    # Universal controls.
    if Gosu::button_down?(Gosu::KbQ) and Gosu::button_down?(Gosu::KbP) and Time.new - @timer > 0.5
      @timer = Time.new
      exit
    end
    if Gosu::button_down?(Gosu::KbZ)
      puts "#{@map.player_offset_x}, #{@map.player_offset_y}"
    end
    if Gosu::button_down?(Gosu::KbF)
      puts Gosu::fps
    end
	if Gosu::button_down?(Gosu::KbA) and Gosu::button_down?(Gosu::KbL) and Time.new - @timer > 0.5
		@timer = Time.new
		initialize(Map.new($x, $y))
	end
    # Level updating and turns as well as any pending actions.
	begin
    @map.level.grid.each do |loc, object|
      if object.key?(:keys)
        if object.key?(:args)
          object[:keys].call(object[:args])
        else
          object[:keys].call
        end
      end
    end
    @map.update
		if @map.level.update or Gosu::button_down?(Gosu::KbW) and Time.new - @timer > 0.06
		  @timer = Time.new
		  @map.turns
		end
	rescue Exception => e
		puts e
	end
    if @pending.any?
      send(@pending[0], @pending[1])
      @pending = []
    end
  end

  def draw
    Gosu::draw_rect(self.width - (@text_width * @box_width), 0, self.width - (self.width / (@text_width * @box_width)), self.height, Gosu::Color::rgb(0, 0, 0), 2)

    @map.level.grid.each do |point, props|
      @font.draw(props[:symbol], (props[:x] * @text_width + @map.player_offset_x * @text_width) * @zoom,
        (props[:y] * @text_height + @map.player_offset_y * @text_height) * @zoom, 1, @zoom, @zoom, props[:color])
    end

    @font.draw("Items: ", 0, (@map.height * @text_height).round * @zoom, 2, @zoom, @zoom, Gosu::Color::rgb(150, 150, 150))

    @map.player[:inventory].each do |item|
      @font.draw(item[:symbol], ((@map.player[:inventory].index(item) *
      (@text_width * 2)) + @text_width * 7) * @zoom, ((@map.height * @text_height).round) * @zoom,
      1, @zoom, @zoom, item[:color])
    end
    @texts.uniq
    @texts.each do |text|
      text.draw
    end
  end

  def new_text(words, opts={})
    @texts.push(Text.new(self, words, "courier.ttf", 30, opts))
  end

  def get_text_by_id(id)
    @texts.each do |text|
      if text.id == id
        return text
      end
    end
    return false
  end

  def set_pending(method, args=[])
    @pending.push(method)
    @pending.push(args)
  end
end

$x = 75
$y = 37

$window = GameWindow.new(Map.new($x, $y))
$window.show()
