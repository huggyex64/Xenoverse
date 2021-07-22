RETROMON = {
				:BULBASAUR => :BULBASAURVINTAGE,
				:CHARMANDER => :CHARMANDERVINTAGE,
				:SQUIRTLE => :SQUIRTLEVINTAGE,
				:WEEDLE => :WEEDLEVINTAGE,
				:KAKUNA=> :KAKUNAVINTAGE,
				:RATTATA=> :RATTATAVINTAGE,
				:RATICATE=> :RATICATEVINTAGE,
				:EKANS=> :EKANSVINTAGE,
				:ARBOK=> :ARBOKVINTAGE,
				:PIKACHU=> :PIKACHUVINTAGE,
				:SANDSHREW=> :SANDSHREWVINTAGE,
				:SANDSLASH=> :SANDSLASHVINTAGE,
				:VULPIX=> :VULPIXVINTAGE,
				:NINETALES=> :NINETALESVINTAGE,
				:JIGGLYPUFF=> :JIGGLYPUFFVINTAGE,
				:ZUBAT=> :ZUBATVINTAGE,
				:GOLBAT=> :GOLBATVINTAGE,
				:ODDISH=> :ODDISHVINTAGE,
				:GLOOM=> :GLOOMVINTAGE,
				:DIGLETT=> :DIGLETTVINTAGE,
				:DUGTRIO=> :DUGTRIOVINTAGE,
				:MEOWTHELDIW=> :MEOWTHVINTAGE,
				:ABRA=> :ABRAVINTAGE,
				:KADABRA=> :KADABRAVINTAGE,
				:KADABRA=> :KADABRAVINTAGE,
				:GEODUDE=> :GEODUDEVINTAGE,
				:GRAVELER=> :GRAVELERVINTAGE,
				:PONYTA=> :PONYTAVINTAGE,
				:RAPIDASH=> :RAPIDASHVINTAGE,
				:MAGNEMITE=> :MAGNEMITEVINTAGE,
				:MAGNETON=> :MAGNETONVINTAGE,
				:SEEL=> :SEELVINTAGE,
				:DEWGONG=> :DEWGONGVINTAGE,
				:GRIMER=> :GRIMERVINTAGE,
				:MUK=> :MUKVINTAGE,
				:GASTLY=> :GASTLYVINTAGE,
				:HAUNTER=> :HAUNTERVINTAGE,
				:ONIX=> :ONIXVINTAGE,
				:DROWZEE=> :DROWZEEVINTAGE,
				:KADABRA=> :KADABRAVINTAGE,
				:EXEGGCUTE=> :EXEGGCUTEVINTAGE,
				:EXEGGUTOR=> :EXEGGUTORVINTAGE,
				:CUBONE=> :CUBONEVINTAGE,
				:KOFFING=> :KOFFINGVINTAGE,
				:RHYHORN=> :RHYDONVINTAGE,
				:CHANSEY=> :CHANSEYVINTAGE,
				:STARYU=> :STARYUVINTAGE,
				:STARMIE=> :STARMIEVINTAGE,
				:SCYTHER=> :SCYTHERVINTAGE,
				:ELECTABUZZ=> :ELECTABUZZVINTAGE,
				:TAUROS=> :TAUROSVINTAGE,
				:MAGIKARP=> :MAGIKARPVINTAGE,
				:GYARADOS=> :GYARADOSVINTAGE,
				:LAPRAS=> :LAPRASVINTAGE,
				:DITTO=> :DITTOVINTAGE,
				:EEVEE=> :EEVEEVINTAGE,
				:PORYGON=> :PORYGONVINTAGE,
				:DRATINI=> :DRATINIVINTAGE,
				:CHIKORITA=> :CHIKORITAVINTAGE,
				:CYNDAQUIL=> :CYNDAQUILVINTAGE,
				:TOTODILE=> :TOTODILEVINTAGE,
				:LEDYBA=> :LEDYBAVINTAGE,
				:LEDIAN=> :LEDIANVINTAGE,
				:CROBAT=> :CROBATVINTAGE,
				:NATU=> :NATUVINTAGE,
				:XATU=> :XATUVINTAGE,
				:MAREEP=> :MAREEPVINTAGE,
				:FLAAFFY=> :FLAAFFYVINTAGE,
				:AIPOM=> :AIPOMVINTAGE,
				:YANMA=> :YANMAVINTAGE,
				:MURKROW=> :MURKROWVINTAGE,
				:GIRAFARIG=> :GIRAFARIGVINTAGE,
				:STEELIX=> :STEELIXVINTAGE,
				:SNUBBULL=> :SNUBBULLVINTAGE,
				:SHUCKLE=> :SHUCKLEVINTAGE,
				:HERACROSS=> :HERACROSSVINTAGE,
				:SNEASEL=> :SNEASELVINTAGE,
				:TEDDIURSA=> :TEDDIURSAVINTAGE,
				:CORSOLA=> :CORSOLAVINTAGE,
				:REMORAID=> :REMORAIDVINTAGE,
				:OCTILLERY=> :OCTILLERYVINTAGE,
				:MANTINE=> :MANTINEVINTAGE,
				:HOUNDOUR=> :HOUNDOURMVINTAGE,
				:SMEARGLE=> :SMEARGLEVINTAGE,
				:MILTANK=> :MILTANKVINTAGE,
				:LARVITAR=> :LARVITARVINTAGE,
				:PUPITAR=> :PUPITARVINTAGE,
				:GROWLITHE=> :GROWLITHEVINTAGE,
				:ARCANINE=> :ARCANINEVINTAGE,
				:MAGBY=> :MAGBYVINTAGE,
				:MAGMAR=> :MAGMARVINTAGE,
				:HORSEA=> :HORSEAVINTAGE,
				:SEADRA=> :SEADRAVINTAGE,
				:KINGDRA=> :KINGDRAVINTAGE,
				:PSYDUCK=> :PSYDUCKVINTAGE,
				:GOLDUCK=> :GOLDUCKVINTAGE,
				:WOOPER=> :WOOPERVINTAGE,
				:QUAGSIRE=> :QUAGSIREVINTAGE

}

EXCLUSIVERETROMON = {
	#MEOWSY
	38 => [1396],
	#SUNMOLA
	351 => [1431],
	#BOMSEAKER
	109 => [1434],
	119 => [1434],
	120 => [1434],
	121 => [1434],
	122 => [1434],
	123 => [1434],
	124 => [1434],
	126 => [1434],
	129 => [1434],
	252 => [1434],
	253 => [1434],
	282 => [1434],
	283 => [1434],
	284 => [1434],
	285 => [1434],
	455 => [1434],
	#TIGRETTE
	181 => [1435],
	#WOLFMAN
	281 => [1437]
}
for k in RETROMON.keys
	RETROMON[getID(PBSpecies,k)] = getID(PBSpecies,RETROMON[k])
end


$allRetro=false

RETROMONSWITCH = 950

def pbEncounter(enctype)
	echoln "triggered encounter"
  if $PokemonGlobal.partner
    encounter1=$PokemonEncounters.pbEncounteredPokemon(enctype)
    return false if !encounter1
    encounter2=$PokemonEncounters.pbEncounteredPokemon(enctype)
    return false if !encounter2
    $PokemonTemp.encounterType=enctype
    pbDoubleWildBattle(encounter1[0],encounter1[1],encounter2[0],encounter2[1])
    $PokemonTemp.encounterType=-1
    return true
  else
    encounter=$PokemonEncounters.pbEncounteredPokemon(enctype)
    return false if !encounter
    $fishing = true if enctype == EncounterTypes::OldRod || enctype ==EncounterTypes::GoodRod || enctype ==EncounterTypes::SuperRod
    $PokemonTemp.encounterType=enctype
    if $Trainer.retrochain[encounter[0]]==nil
      $Trainer.retrochain[encounter[0]]=0
    end
	ch = 1 + $Trainer.retrochain[encounter[0]]/63
	echoln encounter[0]
	echoln RETROMON[getConst(PBSpecies,encounter[0])]
	if (($game_switches[RETROMONSWITCH] && rand(4000)<ch) || $allRetro)
		echoln "triggered retro"
		if RETROMON[encounter[0]] != nil
			#if i'm in a special area, i want a 50/50 chance of encountering a special retromon if i would encounter a retromon
			if (EXCLUSIVERETROMON.has_key?($game_map.map_id))
				if (rand(100)>50)
					pbWildBattle(RETROMON[encounter[0]],encounter[1])
				else
					pbWildBattle(EXCLUSIVERETROMON[$game_map.map_id][0],encounter[1])
				end
			else
				pbWildBattle(RETROMON[encounter[0]],encounter[1])
			end
		elsif !RETROMON.has_key?(encounter[0]) && EXCLUSIVERETROMON.has_key?($game_map.map_id)
			#if i wouldn't find a retromon, i still check if i could encounter any exclusive
			pbWildBattle(EXCLUSIVERETROMON[$game_map.map_id][0],encounter[1])
		else
			pbWildBattle(encounter[0],encounter[1])
		end
	end
	$PokemonTemp.encounterType=-1
    $fishing = false if enctype == EncounterTypes::OldRod || enctype ==EncounterTypes::GoodRod || enctype == EncounterTypes::SuperRod
    return true
  end
end

def pbBattleOnStepTaken
  if $Trainer.party.length>0
    encounterType=$PokemonEncounters.pbEncounterType
    if encounterType>=0
      if $PokemonEncounters.isEncounterPossibleHere?()
        encounter=$PokemonEncounters.pbGenerateEncounter(encounterType)
        encounter=EncounterModifier.trigger(encounter)
        if $PokemonEncounters.pbCanEncounter?(encounter)
          if $PokemonGlobal.partner
            encounter2=$PokemonEncounters.pbEncounteredPokemon(encounterType)
            if $Trainer.retrochain[encounter[0]]==nil
              $Trainer.retrochain[encounter[0]]=0
            end
            if $Trainer.retrochain[encounter[1]]==nil
              $Trainer.retrochain[encounter[1]]=0
            end
			ch = 1 + $Trainer.retrochain[encounter[0]]/63
			e1 = (($game_switches[RETROMONSWITCH] && rand(4000)<ch) || $allRetro) ? RETROMON[encounter[0]] : encounter[0]
			ch = 1 + $Trainer.retrochain[encounter[0]]/63
			e2 = (($game_switches[RETROMONSWITCH] && rand(4000)<ch) || $allRetro) ? RETROMON[encounter2[0]] : encounter[0]
			if RETROMON[encounter[0]] != nil
				pbDoubleWildBattle(e1,encounter[1],e2,encounter2[1])
			else
				pbDoubleWildBattle(encounter[0],encounter[1],encounter2[0],encounter2[1])
			end
          else
            if $Trainer.retrochain[encounter[0]]==nil
              $Trainer.retrochain[encounter[0]]=0
            end
            ch = 1 + $Trainer.retrochain[encounter[0]]/63
			echoln "encounter #{encounter[0]}"
			echoln "retro encounter #{RETROMON[encounter[0]]}"
			if (($game_switches[RETROMONSWITCH] && rand(4000)<ch) || $allRetro)
				echoln "triggered retro"
				if RETROMON[encounter[0]] != nil
					#if i'm in a special area, i want a 50/50 chance of encountering a special retromon if i would encounter a retromon
					if (EXCLUSIVERETROMON.has_key?($game_map.map_id))
						if (rand(100)>50)
							pbWildBattle(RETROMON[encounter[0]],encounter[1])
						else
							pbWildBattle(EXCLUSIVERETROMON[$game_map.map_id][0],encounter[1])
						end
					else
						pbWildBattle(RETROMON[encounter[0]],encounter[1])
					end
				elsif !RETROMON.has_key?(encounter[0]) && EXCLUSIVERETROMON.has_key?($game_map.map_id)
					#if i wouldn't find a retromon, i still check if i could encounter any exclusive
					pbWildBattle(EXCLUSIVERETROMON[$game_map.map_id][0],encounter[1])
				else
					pbWildBattle(encounter[0],encounter[1])
				end
			end
          end
        end
        EncounterModifier.triggerEncounterEnd()
      end
    end
  end
end

class PokeBattle_Trainer
	attr_accessor(:retrochain)
	
	def retrochain
		if @retrochain==nil
			@retrochain={}
		end
		return @retrochain
	end
	
end
def pbTestRetroChances
	ch = 1 + $Trainer.retrochain[PBSpecies::AIPOM]/63
	for i in 0...500
		echoln "Found [#{rand(4000)<ch}]"
		echo " Found [#{rand(4000)<ch}]"
		echo " Found [#{rand(4000)<ch}]"
	end
end
