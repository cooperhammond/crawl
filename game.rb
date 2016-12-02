require 'gosu'
Dir["./*.rb"].each {|file| require file }
Dir["./levels/*.rb"].each {|file| require file }


class GameWindow < Gosu::Window
  attr_accessor :texts
  attr_reader :map, :level
  def initialize(map)
    temp = Gosu::Window.new(1, 1)
    @scale = 20
    @text_height = @scale
    @font = Gosu::Font.new(temp, "./courier.ttf", @text_height)
    @texts = []
    @text_width = @font.text_width("!")
    @map = map
    super((@map.width * @text_width).round, (@map.height * @text_height).round + @text_height)
    self.caption = "ASCII"
    @clear = false

    @level_num = 0
    next_level
    @pending = []
    @timer = Time.new

  end

  def update
    # Universal controls.
    if Gosu::button_down?(Gosu::KbQ) and Gosu::button_down?(Gosu::KbP) and Time.new - @timer > 0.5
      @timer = Time.new
      exit
    end

    # Level updating and turns as well as any pending actions.
    @level.turns
    @map.update
    if @pending.any?
      send(@pending[0], @pending[1])
      @pending = []
    end
  end

  def draw
    if @clear != true
      @map.grid.each do |point, props|
        @font.draw(props[:symbol], props[:x] * @text_width, props[:y] * @text_height, 1,
        1, 1, props[:color])
      end
      @font.draw("Items: ", 0, (@map.height * @text_height).round, 1, 1, 1, Gosu::Color::rgb(150, 150, 150))
      @map.player[:inventory].each do |item|
        @font.draw(item[:symbol], (@map.player[:inventory].index(item) *
        (@text_width * 2)) + @text_width * 7, (@map.height * @text_height).round,
        1, 1, 1, item[:color])
      end
    end
    @texts.uniq
    @texts.each do |text|
      text.draw
    end
  end

  def next_level
    @level_num += 1
    @map.reset
    @level = (Object.const_get("Level#{@level_num}").new(self))
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

  def clear
    @clear = true
  end

  def set_pending(method, args=[])
    @pending.push(method)
    @pending.push(args)
  end
end

GameWindow.new(Map.new(50, 25)).show()
