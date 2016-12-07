require_relative 'walker.rb'
require_relative 'arena.rb'

def create_dungeon(arena, walk_length, have_stairs = true, walker = Walker.new )
  while(walk_length>0)
    walk_length -=1

    # Cut out a bit of tunnel where I am.
    arena[*walker.position] = ' '
    walker.wander

    # Bosh down a room occasionally.
    if(walk_length%80==0)
      create_room(arena, walker)
    end

    # Spawn off a child now and then. Split the remaining walk_length
    # with it. Only one of us gets the stairs though.
    if(walk_length%40==0)
      child_walk_length = rand(walk_length)
      walk_length -= child_walk_length
      if child_walk_length > walk_length
        create_dungeon( arena, child_walk_length, have_stairs,
                                                  walker.create_child )
        have_stairs = false
      else
        create_dungeon( arena, child_walk_length, false, walker.create_child )
      end
    end
  end

  # Put in the down stairs, if I have them.
  if(have_stairs)
    arena[*(walker.position)] = '>'
  end
end

def create_room(arena, walker)
  max = 10
  width = -rand(max)..rand(max)
  height = -rand(max)..rand(max)
  height.each do |y|
    width.each do |x|
      arena[x+walker.x, y+walker.y] = ' '
    end
  end
end

# Create an arena, and set of a walker in it.
$arena = Arena.new
create_dungeon($arena, 400)

# Put in the up stairs.
$arena[0,0] = '<'

# Show the dungeon.
