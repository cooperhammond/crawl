class LevelBasePlate
  def initialize(window)
    @window = window
    @map = @window.map
    default_definitions()
    @move_timer = Time.new
    @timer = Time.new
    @freeze = false
  end

  def update
  end

  def frozen(val)
    @freeze = val
  end

  def turns
    if @freeze != true
      if update
        @map.grid.each do |loc, props|
          if props.key?(:behavior)
            if props[:args] != {}
              props[:behavior].call(props.merge(props[:args]))
            else
              props[:behavior].call
            end
          end
        end
      end
    end
  end
end
