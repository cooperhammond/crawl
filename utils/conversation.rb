require 'gosu'

class Text
  attr_reader :id
  attr_accessor :x_loc, :y_loc
  def initialize(window, string, font, size, opts={})
    @window = window
    @id = opts[:id]
    @letters = []
    @string = string.split(//)
    @size = size
    @font = Gosu::Font.new(@window, "./#{font}", @size)
    index = 0
    @string.each do |l|
      index += 1
      @letters.push({
        letter: l,
        delay_counter: 0,
        index: index,
        rows_down: 0,
        played: false,
      })
    end

    # OPTIONS:
    # => input - true or false for getting and printing character input.
	  # => right_border - border to wrap on
    # => kerning - for changing the spacing between letters. Defaults to `size / 2`
    # => y_loc - changing where the y is
    # => x_loc - changing where the x is
    # => sound - for the sound to play when the text is printed
    # => delay - for how long each character delays
    # => new_line - the distance between each new line
    # => color - takes an array of [alpha, red, green, blue]
    @input = opts[:input] || false
    @kerning = opts[:kerning] || @font.text_width(string.tr("\n", "")) / string.length
    @color = opts[:color] || Gosu::Color::rgb(255, 255, 255)
    @right_border = opts[:right_border] || @window.width
    if opts[:y_loc] == "center"
      @y_loc = (@window.height / 2) - (size / 2)
    elsif opts[:y_loc] != nil
      @y_loc = (@window.height * opts[:y_loc])
    else
      @y_loc = @window.height * 0.625
    end
    if opts[:x_loc] == "center"
      @x_loc = (@right_border / 2) - (@font.text_width(@string.join("")))
    elsif opts[:x_loc] != nil
      @x_loc = (@right_border * opts[:x_loc])
    else
      @x_loc = 0
    end

    begin
      @sound = Gosu::Sample.new("./#{opts[:sound]}")
    rescue
      @sound = false
    end
    @new_line = opts[:new_line] || @window.height * 0.125
    @sound_delay = opts[:sound_delay] || 4
    @delay = opts[:delay] || 1.5

    @alphabet = "    abcdefghijklmnopqrstuvwxyz1234567890     -=[]\\#;'`,./".split(//)
    @correspo = "    ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()     _+{}|#:\"~<>?".split(//)
    @input_delay = 0

  end

  def draw
    if @input == true
      input
    end
    rows_down = 0
    @x_num = @x_loc
    @y_num = @y_loc
    @letters.each do |l|
      if l[:letter] == "\n"
        @x_num = @x_loc
        @y_num = @y_loc + (@new_line * l[:rows_down])
        rows_down += 1

        l[:rows_down] = rows_down

        next
      end
      l[:delay_counter] += 1
      moved = false
      @x_num += @kerning
      if @x_num >= @right_border * 0.94 and (l[:letter] == ' ')
        @x_num = @x_loc
        @y_num = @y_loc + (@new_line * l[:rows_down])
        rows_down += 1

        l[:rows_down] = rows_down
      else
        if l[:delay_counter] >= @delay * l[:index]
          @font.draw(l[:letter], @x_num, @y_num, 10, 1, 1, @color)
          if l[:played] == false and l[:index] % @sound_delay == 0 and @sound != false and @input != true
            @sound.play(1)
            l[:played] = true
          end
        end
      end
    end
  end

  def total_text_height()
    total_height = @size

    rows_down = 1
    x_num = @x_loc
    y_num = @y_loc

    @letters.each do |l|
      l[:delay_counter] += 1
      moved = false
      x_num += @kerning
      if x_num >= @right_border * 0.94 and (l[:letter] == ' ')
        x_num = x_loc
        y_num = y_loc + (@new_line * l[:rows_down])
        rows_down += 1

        l[:rows_down] = rows_down
      end
    end

    return (rows_down * @size) + (rows_down * @new_line)
  end

  def input
    @input_delay += 0.5
    (4..@alphabet.length() - 1).each do |num|
      if Gosu::button_down?(Gosu::KbLeftShift) or Gosu::button_down?(Gosu::KbRightShift)
        @letter_key = @correspo
      else
        @letter_key = @alphabet
      end
      if Gosu::button_down?(num) and @input_delay >= 4.5
        @sound.play if @sound != false
        @input_delay = 0
        @letters.push({
          letter: @letter_key[num],
          delay_counter: 0,
          index: 0,
          rows_down: 0,
          played: false,
        })
      elsif Gosu::button_down?(Gosu::KbBackspace) and @input_delay >= 2.5
        @input_delay = 0
        @letters.delete_at(-1)
      end
    end
  end
end
