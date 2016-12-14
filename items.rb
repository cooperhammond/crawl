class Weapon
	attr_reader :name, :damage
	def initailize(tier, type)
		@tiers = {
            '1' => {'0' => "iron"},
            '2' => {'0' => "steel"},
			'3' => {'0' => "orcish"},
			'4' => {'0' => "elvish"},
			'5' => {'0' => "dwarvish"},
			'6' => {'0' => "demonic"},
			'7' => {'0' => "draconic"}
            }
		@weapon_type = "sword  war axe  mace  greatsword  great axe  war hammer  great club  ultra greatsword".split("  ")
		@up_tiers_name1 = "Ebony Sword  Ebony War Axe  Ebony Mace  Ebony Greatsword  Ebony Great Axe  Ebony Battle Axe  Ebony War Hammer  Ebony Great Club  Ebony Ultra Greatsword".split("  ")
		@up_tiers_name2 = "of Fire  of Slaughter  of Ice  of the Inferno  the Soul Eater  of Necrosis  that Devours  of Lightning  of Blizzards  of the Storm  of Corrosion".split("  ")

		if tier <= 0
			tier = 1
		end
		if tier <= 7
		type = rand(0..@weapon_type.length-1)
			@name = @tiers["#{tier}"]['0'] + " " + @weapon_type[type]
		else
			@name = @up_tiers_name1[rand(0..@up_tiers_name1.length-1)] + " " + @up_tiers_name2[rand(0..@up_tiers_name2.length-1)]
		end

		#damage
		if tier <=7
			@damage = ((tier*tier) * 2) + (type * 3)
		else
			@damage = rand((tier*tier*2)..(tier*tier*3))
		end
	end
end
