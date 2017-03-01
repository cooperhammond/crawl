require 'gosu'
Dir.glob("utils/*.rb").each { |file| require_relative file }
Dir.glob("assets/*.rb").each { |file| require_relative file }
Dir.glob("engines/*.rb").each { |file| require_relative file }

class GameWindow < Gosu::Window
  attr_accessor :texts, :display_pane, :winning, :score
  attr_reader :map, :level, :zoom
  def initialize(map)
	  @font = Gosu::Font.new(25)

	  temp = Gosu::Window.new(1, 1)
    @scale = 25
    @text_height = @scale
    @zoom = 1.6
    @font = Gosu::Font.new(temp, "./assets/courier.ttf", @text_height)

    @texts = []
    @text_width = @font.text_width("!")
    @texts_height

    @map = map

    @box_width = 20
    @display_pane = true
    super((@map.width * @text_width).round + (@text_width * @box_width).round, (@map.height * @text_height).round + @text_height)
    self.caption = ""
    self.fullscreen = false

    @pending = []
    @timer = Time.new
	  $window = self
    @map.give_window(self)
    @map.start_running
	  @map.get_object_by_loc(0, 0)

    @height = self.height.to_s.to_f

    @winning = false
    @winning_graphics = Winning.new(self)
    @score = 0
  end

  def update
    universal_controls(self) # Universal controls.
    if @winning == false

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
        if e.to_s  == "exit"
          exit
        end
    		puts e.backtrace
        puts e
    	end
      if @pending.any?
        send(@pending[0], @pending[1])
        @pending = []
      end
    else
      @winning_graphics.winning
    end
  end


  def draw
      if @winning == false
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
      if @display_pane == true
        Gosu::draw_rect(self.width - (@text_width * @box_width), 0, self.width - (self.width / (@text_width * @box_width)), self.height, Gosu::Color::rgb(0, 0, 0), 2)
      end
    elsif @winning == true
      @winning_graphics.draw
      @winning_graphics.update
    end
  end

  def new_text(words, opts={})
    @texts.push(Text.new(self, words, "./assets/courier.ttf", 30, opts))
  end

  def pane_text(words, opts={})
    if @texts.size >= 8
      @texts = []
    end

    temp_text = Text.new(self, words, "./assets/courier.ttf", 30, \
      opts.merge({x_loc: (self.width - (@text_width * @box_width)) / self.width, \
      new_line: @text_height, sound: "./text.wav"}))

    if complete_text_height * @height >= @height - 100

      first_text_height = @texts[0].total_text_height

      @texts.shift
      @texts.each do |text|
        text.y_loc -= temp_text.total_text_height
      end
    end

    @texts.push(Text.new(self, words, "./assets/courier.ttf", 30, \
      opts.merge({x_loc: (self.width - (@text_width * @box_width)) / self.width, \
      y_loc: complete_text_height,\
      new_line: @text_height, sound: "./text.wav"})))
  end

  def complete_text_height()
    height = 0
    @texts.each do |text|
      height += text.total_text_height
    end
    return (height) / self.height.to_s.to_f
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
