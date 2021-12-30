class PatchFix
	attr_accessor	:switch
	attr_accessor	:funct
	
	def initialize(switch, funct)
		@switch = switch
		@funct = funct
	end
	
	def applyPatch
		if !$game_switches[@switch]
			@funct.call
			$game_switches[@switch] = true
		end
	end
	
	def setPatched
		$game_switches[@switch] = true
	end
	
	class << self
			
		def setPatched
			SWITCH_FIXED.each_value {|value| value.setPatched}
		end
		
		def applyPatch
			SWITCH_FIXED.each_value {|value| value.applyPatch}
		end
		
		def v101
			Log.d("APPLY_FIX","Chiamato metodo v101")
			# Disattiva Following attivato erroneamente
			if $game_switches[Toggle_Following_Switch]==true
				$PokemonTemp.pbSwap
				if $PokemonTemp.dependentEvents.getEventByName("Dependent")
					pbRemoveDependency2("Dependent")
				end
				pbWait(1)
				$game_switches[Toggle_Following_Switch]=false
			end
			
			# Disattiva switch Druddigon
			$game_switches[230] = false
			
			# Disattiva switch per pulizia
=begin
			if !$game_switches[97] && $game_map.map_id != 86
				$game_switches[96] = false
				$game_switches[95] = false
				$game_switches[94] = false
				$game_switches[93] = false
				$game_switches[92] = false
				$game_switches[98] = false
			end
=end
			Kernel.pbMessage(_INTL("Sono state applicate alcune modifiche al tuo salvataggio dalla patch 1.0.1, salva per applicare le modifiche."))
		end
    
    def v102
			Log.d("APPLY_FIX","Chiamato metodo v102")
      # Se il giocatore ha finito il gioco, controlla che abbia Scaleon di Oleandro in party e lo elimina,
      # e disattiva la switch del drop di Anello Xenoverse.
      if $game_switches[207] == true
        for i in 0...$Trainer.party.length
          if $Trainer.party[i].species == PBSpecies::SCALEONOLEANDRO
            $Trainer.party.delete_at(i)
          end
        end 
        #pbTakeScaleon
        $game_switches[215]=false
      end
      
      # Controlla che il player non abbia il follow pokèmon
      if $game_player.pbHasDependentEvents? && $game_switches[160]==false
				$PokemonTemp.pbSwap
				#if $PokemonTemp.dependentEvents.getEventByName("Dependent")
					pbRemoveDependencies()
				#end
				pbWait(1)
				$game_switches[Toggle_Following_Switch]=false
			end
      
      #if $PokemonBag.pbQuantity(:ANELLOX) > 0
      #  $PokemonBag.pbDeleteItem(:ANELLOX,999)
      #  $PokemonBag.pbStoreItem(:ANELLOX,1)
      #end
        
      
		
			Kernel.pbMessage(_INTL("Sono state applicate alcune modifiche al tuo salvataggio dalla patch 1.0.2, salva per applicare le modifiche."))
		end
		
		def v103
			Log.d("APPLY_FIX","Chiamato metodo v103")
			
			# Disattiva switch Uncatch Pokémon
			$game_switches[230] = false

			Kernel.pbMessage(_INTL("Sono state applicate alcune modifiche al tuo salvataggio dalla patch 1.0.3, salva per applicare le modifiche."))
		end
	end
end

SWITCH_FIXED = {"1.0.1" => PatchFix.new(257, PatchFix.method("v101")),
	"1.0.2" => PatchFix.new(258, PatchFix.method("v102")),
	"1.0.3" => PatchFix.new(259, PatchFix.method("v103"))}

PATCHFIXES = {
	"1.3.13" => proc{
		 #apply 1.3.11 patchfix
		 Log.i("Patch Fix","Applying patch fixes for version 1.3.13")
			for p in $Trainer.party
				if (p != nil)
					if p.species == PBSpecies::SHULONG
						p.pbDeleteMove(PBMoves::SWORDSDANCE)
					end
					p.calcStats
				end
			end
			for b in $PokemonStorage.boxes
				for poke in b.pokemon
					if poke != nil
						poke.pbDeleteMove(PBMoves::SWORDSDANCE) if poke.species == PBSpecies::SHULONG
						poke.calcStats
					end
				end
			end
		}
}


class Patcher 
	def self.apply()
		for key in PATCHFIXES.keys
			if $Trainer.lastGameVersion && $Trainer.lastGameVersion < Version.new(key)
				PATCHFIXES[key].call
			end
		end
	end
end