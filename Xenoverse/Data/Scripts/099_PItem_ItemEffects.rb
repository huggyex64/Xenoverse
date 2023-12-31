#===============================================================================
# This script implements items included by default in Pokemon Essentials.
#===============================================================================

#===============================================================================
# UseFromBag handlers
# Return values: 0 = not used
#                1 = used, item not consumed
#                2 = close the Bag to use, item not consumed
#                3 = used, item consumed
#                4 = close the Bag to use, item consumed
#===============================================================================

def pbRepel(item,steps)
  if $PokemonGlobal.repel>0
    Kernel.pbMessage(_INTL("But the effects of a Repel lingered from earlier."))
    return 0
  else
    Kernel.pbMessage(_INTL("{1} used the {2}.",$Trainer.name,PBItems.getName(item)))
    $PokemonGlobal.repel=steps
    return 3
  end
end

ItemHandlers::UseFromBag.add(:REPEL,proc{|item|  pbRepel(item,100)  })

ItemHandlers::UseFromBag.add(:SUPERREPEL,proc{|item|  pbRepel(item,200)  })

ItemHandlers::UseFromBag.add(:MAXREPEL,proc{|item|  pbRepel(item,250)  })

Events.onStepTaken+=proc {
   if $game_player.terrain_tag!=PBTerrain::Ice   # Shouldn't count down if on ice
     if $PokemonGlobal.repel>0
       $PokemonGlobal.repel-=1
       if $PokemonGlobal.repel<=0
         Kernel.pbMessage(_INTL("Repel's effect wore off..."))
         ret=pbChooseItemFromList(_INTL("Do you want to use another Repel?"),1,
            :REPEL,:SUPERREPEL,:MAXREPEL)
         pbUseItem($PokemonBag,ret) if ret>0
       end
     end
   end
}

ItemHandlers::UseFromBag.add(:BLACKFLUTE,proc{|item|
   Kernel.pbMessage(_INTL("{1} used the {2}.",$Trainer.name,PBItems.getName(item)))
   Kernel.pbMessage(_INTL("Wild Pokémon will be repelled."))
   $PokemonMap.blackFluteUsed=true
   $PokemonMap.whiteFluteUsed=false
   next 1
})

ItemHandlers::UseFromBag.add(:WHITEFLUTE,proc{|item|
   Kernel.pbMessage(_INTL("{1} used the {2}.",$Trainer.name,PBItems.getName(item)))
   Kernel.pbMessage(_INTL("Wild Pokémon will be lured."))
   $PokemonMap.blackFluteUsed=false
   $PokemonMap.whiteFluteUsed=true
   next 1
})

ItemHandlers::UseFromBag.add(:HONEY,proc{|item|  next 4  })


ItemHandlers::UseFromBag.add(:ESCAPEROPE,proc{|item|
     Kernel.pbMessage(_INTL("Sembra inutilizzabile..."))
     next 0
=begin
   if $game_player.pbHasDependentEvents?
     Kernel.pbMessage(_INTL("It can't be used when you have someone with you."))
     next 0
   end
   if ($PokemonGlobal.escapePoint rescue false) && $PokemonGlobal.escapePoint.length>0
     next 4 # End screen and consume item
   else
     Kernel.pbMessage(_INTL("Can't use that here."))
     next 0
   end
=end
})

ItemHandlers::UseFromBag.add(:SACREDASH,proc{|item|
   revived=0
   if $Trainer.pokemonCount==0
     Kernel.pbMessage(_INTL("There is no Pokémon."))
     next 0
   end
   pbFadeOutIn(99999){
      scene=PokemonScreen_Scene.new
      screen=PokemonScreen.new(scene,$Trainer.party)
      screen.pbStartScene(_INTL("Using item..."),false)
      for i in $Trainer.party
       if i.hp<=0 && !i.isEgg?
         revived+=1
         i.heal
         screen.pbDisplay(_INTL("{1}'s HP was restored.",i.name))
       end
     end
     if revived==0
       screen.pbDisplay(_INTL("It won't have any effect."))
     end
     screen.pbEndScene
   }
   next (revived==0) ? 0 : 3
})

ItemHandlers::UseFromBag.add(:BICYCLE,proc{|item|
  next pbBikeCheck ? 2 : 0
})

ItemHandlers::UseFromBag.add(:POKEBOARD,proc{|item|  
  next pbBikeCheck ? 2 : 0
})

ItemHandlers::UseFromBag.copy(:BICYCLE,:MACHBIKE,:ACROBIKE, :POKEBOARD)

ItemHandlers::UseFromBag.add(:OLDROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction,$game_player)
   if (pbIsWaterTag?(terrain) && !$PokemonGlobal.surfing && notCliff) ||
      (pbIsWaterTag?(terrain) && $PokemonGlobal.surfing)
     next 2
   else
     Kernel.pbMessage(_INTL("Can't use that here."))
     next 0
   end
})

ItemHandlers::UseFromBag.copy(:OLDROD,:GOODROD,:SUPERROD)

ItemHandlers::UseFromBag.add(:SPECIALROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if (pbIsWaterTag?(terrain) && !$PokemonGlobal.surfing && notCliff) ||
      (pbIsWaterTag?(terrain) && $PokemonGlobal.surfing)
     pbTreasureHook
     next 0
   else
     Kernel.pbMessage(_INTL("Can't use that here."))
     next 0
   end
})

ItemHandlers::UseFromBag.add(:MASTERAMO,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if (pbIsWaterTag?(terrain) && !$PokemonGlobal.surfing && notCliff) ||
      (pbIsWaterTag?(terrain) && $PokemonGlobal.surfing)
     pbTreasureHook
     next 0
   else
     Kernel.pbMessage(_INTL("Can't use that here."))
     next 0
   end
})

ItemHandlers::UseFromBag.copy(:OLDROD,:GOODROD,:SUPERROD, :MASTERAMO)

ItemHandlers::UseFromBag.add(:ITEMFINDER,proc{|item| next 2 })

ItemHandlers::UseFromBag.copy(:ITEMFINDER,:DOWSINGMCHN)

ItemHandlers::UseFromBag.add(:TOWNMAP,proc{|item|
   pbShowMap(-1,false)
   next 1 # Continue
})

ItemHandlers::UseFromBag.add(:COINCASE,proc{|item|
   Kernel.pbMessage(_INTL("Coins: {1}",$PokemonGlobal.coins))
   next 1 # Continue
})

ItemHandlers::UseFromBag.add(:POKEBLOCKCASE,proc{|item| next 2 })

ItemHandlers::UseFromBag.add(:ITEMCRAFTER,proc{|item|
    Kernel.pbMessage(_INTL("{1} used the {2}.",$Trainer.name,PBItems.getName(item)))
        ItemCrafterScene.new
      next 1
   })

ItemHandlers::UseFromBag.add(:PERGAMENA1,proc{|item|
    show_MLG_Item("pergamena1", string=nil)
 })
 
ItemHandlers::UseFromBag.add(:PERGAMENA2,proc{|item|
    show_MLG_Item("pergamena2", string=nil)
 })
 
ItemHandlers::UseFromBag.add(:PERGAMENA3,proc{|item|
    show_MLG_Item("pergamena3", string=nil)
 })
 
ItemHandlers::UseFromBag.add(:PERGAMENA4,proc{|item|
    show_MLG_Item("pergamena4", string=nil)
 })

# NATURE CHANGING MINTS
ItemHandlers::UseOnPokemon.add(:ADAMANTMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:ADAMANT)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:ADAMANT)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:BOLDMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:BOLD)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:BOLD)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:BRAVEMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:BRAVE)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:BRAVE)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:CALMMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:CALM)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:CALM)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:CAREFULMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:CAREFUL)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:CAREFUL)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:GENTLEMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:GENTLE)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:GENTLE)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:HASTYMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:HASTY)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:HASTY)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:IMPISHMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:IMPISH)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:IMPISH)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:JOLLYMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:JOLLY)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:JOLLY)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:LAXMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:LAX)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:LAX)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:LONELYMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:LONELY)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:LONELY)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:MILDMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:MILD)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:MILD)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:MODESTMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:MODEST)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:MODEST)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:NAIVEMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:NAIVE)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:NAIVE)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:NAUGHTYMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:NAUGHTY)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:NAUGHTY)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:QUIETMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:QUIET)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:QUIET)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:RASHMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:RASH)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:RASH)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:RELAXEDMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:RELAXED)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:RELAXED)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:SASSYMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:SASSY)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:SASSY)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:SERIOUSMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:SERIOUS)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:SERIOUS)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

ItemHandlers::UseOnPokemon.add(:TIMIDMINT,proc{|item,pokemon,scene|
  if pokemon.nature==(:TIMID)
    scene.pbDisplay(_INTL("It won't have any effect."))
  else
    pokemon.setNature(:TIMID)
    pokemon.calcStats
    scene.pbDisplay(_INTL("{1} mangia la {2}.",pokemon.name,PBItems.getName(item)))
 end
})

# Rare candies
ItemHandlers::UseOnPokemon.add(:SUPERRARECANDY,proc{|item,pokemon,scene|
  if pokemon.level>=PBExperience::MAXLEVEL || (pokemon.isShadow? rescue false)
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  else
    pbChangeLevel(pokemon,pokemon.level+5,scene)
    scene.pbHardRefresh
    next true
  end
})
ItemHandlers::UseOnPokemon.add(:ULTRARARECANDY,proc{|item,pokemon,scene|
  if pokemon.level>=PBExperience::MAXLEVEL || (pokemon.isShadow? rescue false)
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  else
    pbChangeLevel(pokemon,pokemon.level+10,scene)
    scene.pbHardRefresh
    next true
  end
})


ItemHandlers::UseOnPokemon.add(:ABILITYCAPSULE,proc{|item,pokemon,scene|
  abils=pokemon.getAbilityList
  abil1=0; abil2=0
  for i in abils
    abil1=i[0] if i[1]==0
    abil2=i[0] if i[1]==1
  end
  if abil1<=0 || abil2<=0 || pokemon.hasHiddenAbility?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  newabil=(pokemon.abilityIndex+1)%2
  newabilname=PBAbilities.getName((newabil==0) ? abil1 : abil2)
  if scene.pbConfirm(_INTL("Would you like to change {1}'s Ability to {2}?",
    pokemon.name,newabilname))
    pokemon.setAbility(newabil)
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1}'s Ability changed to {2}!",pokemon.name,
    PBAbilities.getName(pokemon.ability)))
    next true
  end
  next false
})

ItemHandlers::UseOnPokemon.add(:ABILITYPATCH,proc{|item,pkmn,scene|
  current_abil = pkmn.abilityIndex
  normal_abil = pkmn.personalID&1
  dexdata=pkmn.ability.pbOpenDexData
  pkmn.ability.pbDexDataOffset(dexdata,pkmn.species,40)
  hidden_abil=dexdata.fgetb
  dexdata.close
  if hidden_abil > 0 && current_abil<2
    if scene.pbConfirm(_INTL("Would you like to change {1}'s Ability?",pkmn.name))
      pkmn.setAbility(2)
      scene.pbDisplay(_INTL("{1}'s Ability changed to its Hidden Ability!", pkmn.name))
      next true
    end
  elsif hidden_abil > 0 && current_abil == 2
    if scene.pbConfirm(_INTL("Would you like to change {1}'s Ability?",pkmn.name))
      pkmn.setAbility(normal_abil)
      scene.pbDisplay(_INTL("{1}'s Ability changed to its normal Ability!", pkmn.name))
      next true
    end
  elsif hidden_abil == 0 ||  pkmn.species == 718
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  next false
})

# X GENE AND ESCAPEROPE +
ItemHandlers::UseOnPokemon.add(:INDUCTIVERING,proc{|item,pokemon,scene|
  newspecies=pbCheckMakeX(pokemon)
  if newspecies<=0
    scene.pbDisplay(_INTL("Non avrebbe alcun effetto."))
    next false
  end
  if Kernel.pbConfirmMessage(_INTL("Attenzione! Usare l'Anello Induttivo su un Pokémon cambierà la sua specie permanentemente. Vuoi procedere comunque?"))
    if Kernel.pbConfirmMessage(_INTL("Sei veramente sicuro di voler procedere comunque?"))
      scene.makeX(pokemon)
    end
    next true
  else
    next false
  end
})

AVAILABLE_MAPS = {
  #Bunker
  592=>[135,33,13,2],
  593=>[135,33,13,2],
  594=>[135,33,13,2],
  595=>[135,33,13,2],
  596=>[135,33,13,2],
  597=>[135,33,13,2],
  598=>[135,33,13,2],
  599=>[135,33,13,2],
  600=>[135,33,13,2],
  601=>[135,33,13,2],
  602=>[135,33,13,2],
  603=>[135,33,13,2],
  604=>[135,33,13,2],
  605=>[135,33,13,2],
  606=>[135,33,13,2],
  607=>[135,33,13,2],
  608=>[135,33,13,2],
  609=>[135,33,13,2],
  610=>[135,33,13,2],
  611=>[135,33,13,2],
  612=>[135,33,13,2],
}

ItemHandlers::UseFromBag.add(:DIARIOTAMARA,proc{|item|
  SecretReportScreen.new(SecretReports.get(:TamaraReports))
  next 0
})

ItemHandlers::UseFromBag.add(:FUNEDIFUGAPLUS,proc{|item|
  if !AVAILABLE_MAPS.keys.include?($game_map.map_id)
    Kernel.pbMessage(_INTL("Non può essere usato qui."))
    next 0
  else
    next 2
  end
})

ItemHandlers::UseInField.add(:FUNEDIFUGAPLUS,proc{|item|
  
  echoln "Map ID: #{$game_map.map_id} "
  #135, 98, 48, 2
  if !AVAILABLE_MAPS.keys.include?($game_map.map_id)
    Kernel.pbMessage(_INTL("Non può essere usato qui."))
    next
  end
  escape=AVAILABLE_MAPS[$game_map.map_id]#($PokemonGlobal.escapePoint rescue nil)
  if escape == [135,33,13,2]
    $game_switches[1089] = false
    $game_switches[1090] = false
    $game_switches[1093] = false
    for i in 1096..1118
      $game_switches[i] = false
    end
  end
  if !escape || escape==[]
    Kernel.pbMessage(_INTL("Non può essere usato qui."))
    next
  end
  if $game_player.pbHasDependentEvents?
    Kernel.pbMessage(_INTL("Non può essere usato quando hai qualcuno con te."))
    next
  end
  Kernel.pbMessage(_INTL("{1} usa la Fune di fuga +.",$Trainer.name))
  pbFadeOutIn(99999){
     Kernel.pbCancelVehicles
     $game_temp.player_new_map_id=escape[0]
     $game_temp.player_new_x=escape[1]
     $game_temp.player_new_y=escape[2]
     $game_temp.player_new_direction=escape[3]
     $scene.transfer_player
     $game_map.autoplay
     $game_map.refresh
  }
  #pbEraseEscapePoint
})
#===============================================================================
# UseOnPokemon handlers
#===============================================================================

ItemHandlers::UseOnPokemon.add(:FIRESTONE,proc{|item,pokemon,scene|
   if (pokemon.isShadow? rescue false)
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   end
   newspecies=pbCheckEvolution(pokemon,item)
   if newspecies<=0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pbFadeOutInWithMusic(99999){
        evo=PokemonEvolutionScene.new
        evo.pbStartScreen(pokemon,newspecies)
        evo.pbEvolution(false)
        evo.pbEndScreen
        scene.pbRefreshAnnotations(proc{|p| pbCheckEvolution(p,item)>0 })
        scene.pbRefresh
     }
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:FIRESTONE,
   :THUNDERSTONE,:WATERSTONE,:LEAFSTONE,:MOONSTONE,
   :SUNSTONE,:DUSKSTONE,:DAWNSTONE,:SHINYSTONE,:PIETRAGHIACCIO,
   :BOTPSICO,:BOTMEGA,:BOTMEGATONE,:BOTMEGATONEALOLA,:BOTOMBRA,
   :BOTFERRO,:BOTCHELE,:BOTVIRTUALE,:BOTABISSO,:BOTMARINO,
   :BOTTRAPANO,:BOTSAETTA,:BOTPRESSIONE,:BOTFORZA,:BOTPANNA,
   :BOTANTICO,:BOTTENEREZZA,:BOTERRORE,:BOTWES,:XENOLITE,
   :ICESTONE,:EVOPUPPILLON,:PEZZIDIRICAMBIO,:BOTINFERNO,
   :BOTDRAGO,:POISONSTONE,:BOTPINZA,:BOTREGALE,
   :ARMFAUSTA,:ARMINFAUSTA,:BOTSGUSCIATO,:BOTCAVALIERE)

ItemHandlers::UseOnPokemon.add(:ANCIENTSTONE,proc{|item,pokemon,scene|
    if (pokemon.isShadow? rescue false)
      scene.pbDisplay(_INTL("It won't have any effect."))
      next false
    end
    newspecies=pbCheckEvolution(pokemon,item)
    if newspecies<=0
      scene.pbDisplay(_INTL("It won't have any effect."))
      next false
    else
      pbFadeOutInWithMusic(99999){
         evo=PokemonEvolutionScene.new
         evo.pbStartScreen(pokemon,newspecies,PBItems::ANCIENTSTONE)
         evo.pbEvolution(false,PBItems::ANCIENTSTONE)
         evo.pbEndScreen
         scene.pbRefreshAnnotations(proc{|p| pbCheckEvolution(p,item)>0 })
         scene.pbRefresh
      }
      next true
    end
 })

ItemHandlers::UseOnPokemon.add(:PINKSTONE,proc{|item,pokemon,scene|
  if (pokemon.isShadow? rescue false)
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  canChange = pbCheckSwapStyle(pokemon)
  if !canChange
    scene.pbDisplay(_INTL("Non avrebbe alcun effetto."))
    next false
  end
  if Kernel.pbConfirmMessage(_INTL("Do you want to use the Pink Stone on {1}?",pokemon.name))
    scene.swapStyle(pokemon)
    next true
  else
    next false
  end
})



ItemHandlers::UseOnPokemon.add(:POTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:SUPERPOTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,50,scene)
})

ItemHandlers::UseOnPokemon.add(:RISOTTO,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,50,scene)
})

ItemHandlers::UseOnPokemon.add(:HYPERPOTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,200,scene)
})

ItemHandlers::UseOnPokemon.add(:BLUMELE,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,80,scene)
})

ItemHandlers::UseOnPokemon.add(:MAXPOTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,pokemon.totalhp-pokemon.hp,scene)
})

ItemHandlers::UseOnPokemon.add(:BERRYJUICE,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:RAGECANDYBAR,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:SWEETHEART,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:FRESHWATER,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,50,scene)
})

ItemHandlers::UseOnPokemon.add(:SODAPOP,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,60,scene)
})

ItemHandlers::UseOnPokemon.add(:LEMONADE,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,80,scene)
})

ItemHandlers::UseOnPokemon.add(:MOOMOOMILK,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,100,scene)
})

ItemHandlers::UseOnPokemon.add(:ORANBERRY,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,10,scene)
})

ItemHandlers::UseOnPokemon.add(:SITRUSBERRY,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,(pokemon.totalhp/4).floor,scene)
})

ItemHandlers::UseOnPokemon.add(:AWAKENING,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::SLEEP
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} woke up.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:AWAKENING,:CHESTOBERRY,:BLUEFLUTE,:POKEFLUTE)

ItemHandlers::UseOnPokemon.add(:ANTIDOTE,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::POISON
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} was cured of its poisoning.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:ANTIDOTE,:PECHABERRY)

ItemHandlers::UseOnPokemon.add(:BURNHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::BURN
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s burn was healed.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:BURNHEAL,:RAWSTBERRY)

ItemHandlers::UseOnPokemon.add(:PARLYZHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::PARALYSIS
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} was cured of paralysis.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:PARLYZHEAL,:CHERIBERRY)

ItemHandlers::UseOnPokemon.add(:ICEHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::FROZEN
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} was thawed out.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:ICEHEAL,:ASPEARBERRY)

ItemHandlers::UseOnPokemon.add(:FULLHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} became healthy.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:FULLHEAL,
   :LAVACOOKIE,:OLDGATEAU,:CASTELIACONE,:LUMBERRY)

ItemHandlers::UseOnPokemon.add(:FULLRESTORE,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || (pokemon.status==0 && pokemon.hp==pokemon.totalhp)
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     hpgain=pbItemRestoreHP(pokemon,pokemon.totalhp-pokemon.hp)
     pokemon.status=0
     pokemon.statusCount=0
     scene.pbRefresh
     if hpgain>0
       scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.",pokemon.name,hpgain))
     else
       scene.pbDisplay(_INTL("{1} became healthy.",pokemon.name))
     end
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:REVIVE,proc{|item,pokemon,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.hp=(pokemon.totalhp/2).floor
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP was restored.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:MAXREVIVE,proc{|item,pokemon,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.hp=pokemon.totalhp
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP was restored.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:ENERGYPOWDER,proc{|item,pokemon,scene|
   if pbHPItem(pokemon,50,scene)
     pokemon.changeHappiness("powder")
     next true
   end
   next false
})

ItemHandlers::UseOnPokemon.add(:ENERGYROOT,proc{|item,pokemon,scene|
   if pbHPItem(pokemon,200,scene)
     pokemon.changeHappiness("Energy Root")
     next true
   end
   next false
})

ItemHandlers::UseOnPokemon.add(:HEALPOWDER,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     pokemon.changeHappiness("powder")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} became healthy.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:REVIVALHERB,proc{|item,pokemon,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.hp=pokemon.totalhp
     pokemon.changeHappiness("Revival Herb")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP was restored.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:ETHER,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("Restore which move?"))
   if move>=0
     if pbRestorePP(pokemon,move,10)==0
       scene.pbDisplay(_INTL("It won't have any effect."))
       next false
     else
      scene.pbDisplay(_INTL("PP was restored."))
      next true
    end
  end
  next false
})

ItemHandlers::UseOnPokemon.copy(:ETHER,:LEPPABERRY)

ItemHandlers::UseOnPokemon.add(:MAXETHER,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("Restore which move?"))
   if move>=0
     if pbRestorePP(pokemon,move,pokemon.moves[move].totalpp-pokemon.moves[move].pp)==0
       scene.pbDisplay(_INTL("It won't have any effect."))
       next false
     else
       scene.pbDisplay(_INTL("PP was restored."))
       next true
     end
   end
   next false
})

ItemHandlers::UseOnPokemon.add(:ELIXIR,proc{|item,pokemon,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbRestorePP(pokemon,i,10)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("PP was restored."))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:MAXELIXIR,proc{|item,pokemon,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbRestorePP(pokemon,i,pokemon.moves[i].totalpp-pokemon.moves[i].pp)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("PP was restored."))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:PPUP,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("Boost PP of which move?"))
   if move>=0
     if pokemon.moves[move].totalpp==0 || pokemon.moves[move].ppup>=3
       scene.pbDisplay(_INTL("It won't have any effect."))
       next false
     else
       pokemon.moves[move].ppup+=1
       movename=PBMoves.getName(pokemon.moves[move].id)
       scene.pbDisplay(_INTL("{1}'s PP increased.",movename))
       next true
     end
   end
})

ItemHandlers::UseOnPokemon.add(:PPMAX,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("Boost PP of which move?"))
   if move>=0
     if pokemon.moves[move].totalpp==0 || pokemon.moves[move].ppup>=3
       scene.pbDisplay(_INTL("It won't have any effect."))
       next false
     else
       pokemon.moves[move].ppup=3
       movename=PBMoves.getName(pokemon.moves[move].id)
       scene.pbDisplay(_INTL("{1}'s PP increased.",movename))
       next true
     end
   end
})

ItemHandlers::UseOnPokemon.add(:HPUP,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,0)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:PROTEIN,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,1)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Attack increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:IRON,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,2)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Defense increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:CALCIUM,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,4)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Special Attack increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:ZINC,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,5)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Special Defense increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:CARBOS,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,3)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Speed increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:IVHERBHP,proc{|item,pokemon,scene|
  if !pbLowerIV(scene,pokemon,PBStats::HP)
    next false
  else
    scene.pbDisplay(_INTL("{1}'s HP decreased.",pokemon.name))
    next true
  end
})

ItemHandlers::UseOnPokemon.add(:IVHERBATK,proc{|item,pokemon,scene|
  if !pbLowerIV(scene,pokemon,PBStats::ATTACK)
    next false
  else
    scene.pbDisplay(_INTL("{1}'s Attack decreased.",pokemon.name))
    next true
  end
})

ItemHandlers::UseOnPokemon.add(:IVHERBDEF,proc{|item,pokemon,scene|
  if !pbLowerIV(scene,pokemon,PBStats::DEFENSE)
    next false
  else
    scene.pbDisplay(_INTL("{1}'s Defense decreased.",pokemon.name))
    next true
  end
})

ItemHandlers::UseOnPokemon.add(:IVHERBSPA,proc{|item,pokemon,scene|
  if !pbLowerIV(scene,pokemon,PBStats::SPATK)
    next false
  else
    scene.pbDisplay(_INTL("{1}'s Special Attack decreased.",pokemon.name))
    next true
  end
})

ItemHandlers::UseOnPokemon.add(:IVHERBSPD,proc{|item,pokemon,scene|
  if !pbLowerIV(scene,pokemon,PBStats::SPDEF)
    next false
  else
    scene.pbDisplay(_INTL("{1}'s Special Defense decreased.",pokemon.name))
    next true
  end
})

ItemHandlers::UseOnPokemon.add(:IVHERBSPE,proc{|item,pokemon,scene|
  if !pbLowerIV(scene,pokemon,PBStats::SPEED)
    next false
  else
    scene.pbDisplay(_INTL("{1}'s Speed decreased.",pokemon.name))
    next true
  end
})

ItemHandlers::UseOnPokemon.add(:HEALTHWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,0,1,false)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:MUSCLEWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,1,1,false)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Attack increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:RESISTWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,2,1,false)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Defense increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:GENIUSWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,4,1,false)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Special Attack increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:CLEVERWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,5,1,false)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Special Defense increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:SWIFTWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,3,1,false)==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("{1}'s Speed increased.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:RARECANDY,proc{|item,pokemon,scene|
   if pokemon.level>=PBExperience::MAXLEVEL || (pokemon.isShadow? rescue false)
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pbChangeLevel(pokemon,pokemon.level+1,scene)
     scene.pbHardRefresh
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:POMEGBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,0,[
      _INTL("{1} adores you!\nThe base HP fell!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base HP can't fall!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base HP fell!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:KELPSYBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,1,[
      _INTL("{1} adores you!\nThe base Attack fell!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Attack can't fall!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Attack fell!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:QUALOTBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,2,[
      _INTL("{1} adores you!\nThe base Defense fell!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Defense can't fall!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Defense fell!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:HONDEWBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,4,[
      _INTL("{1} adores you!\nThe base Special Attack fell!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Special Attack can't fall!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Special Attack fell!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:GREPABERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,5,[
      _INTL("{1} adores you!\nThe base Special Defense fell!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Special Defense can't fall!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Special Defense fell!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:TAMATOBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,3,[
      _INTL("{1} adores you!\nThe base Speed fell!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Speed can't fall!",pokemon.name),
      _INTL("{1} turned friendly.\nThe base Speed fell!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:GRACIDEA,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:SHAYMIN) && pokemon.form==0 &&
      pokemon.hp>=0 && pokemon.status!=PBStatuses::FROZEN &&
      !PBDayNight.isNight?(pbGetTimeNow)
     pokemon.form=1
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} changed Forme!",pokemon.name))
     next true
   else
     scene.pbDisplay(_INTL("It had no effect."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:REVEALGLASS,proc{|item,pokemon,scene|
   if (isConst?(pokemon.species,PBSpecies,:TORNADUS) ||
      isConst?(pokemon.species,PBSpecies,:THUNDURUS) ||
      isConst?(pokemon.species,PBSpecies,:LANDORUS) ||
      isConst?(pokemon.species,PBSpecies,:ENAMORUS)) && pokemon.hp>=0
     pokemon.form=(pokemon.form==0) ? 1 : 0
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} changed Forme!",pokemon.name))
     next true
   else
     scene.pbDisplay(_INTL("It had no effect."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:DNASPLICERS,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:KYUREM) && pokemon.hp>=0
     if pokemon.fused!=nil
       if $Trainer.party.length>=6
         scene.pbDisplay(_INTL("Your party is full! You can't unfuse {1}.",pokemon.name))
         next false
       else
         $Trainer.party[$Trainer.party.length]=pokemon.fused
         pokemon.fused=nil
         pokemon.form=0
         scene.pbHardRefresh
         scene.pbDisplay(_INTL("{1} changed Forme!",pokemon.name))
         next true
       end
     else
       chosen=scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
       if chosen>=0
         poke2=$Trainer.party[chosen]
         if (isConst?(poke2.species,PBSpecies,:RESHIRAM) ||
            isConst?(poke2.species,PBSpecies,:ZEKROM)) && poke2.hp>=0
           pokemon.form=1 if isConst?(poke2.species,PBSpecies,:RESHIRAM)
           pokemon.form=2 if isConst?(poke2.species,PBSpecies,:ZEKROM)
           pokemon.fused=poke2
           pbRemovePokemonAt(chosen)
           scene.pbHardRefresh
           scene.pbDisplay(_INTL("{1} changed Forme!",pokemon.name))
           next true
         elsif pokemon==poke2
           scene.pbDisplay(_INTL("{1} can't be fused with itself!",pokemon.name))
         else
           scene.pbDisplay(_INTL("{1} can't be fused with {2}.",poke2.name,pokemon.name))
         end
       else
         next false
       end
     end
   else
     scene.pbDisplay(_INTL("It had no effect."))
     next false
   end
})

#===============================================================================
# UseInField handlers
#===============================================================================

ItemHandlers::UseInField.add(:HONEY,proc{|item|  
   Kernel.pbMessage(_INTL("{1} used the {2}!",$Trainer.name,PBItems.getName(item)))
   pbSweetScent
})

ItemHandlers::UseInField.add(:ESCAPEROPE,proc{|item|
  Kernel.pbMessage(_INTL("Sembra inutilizzabile..."))
  next
=begin
   escape=($PokemonGlobal.escapePoint rescue nil)
   if !escape || escape==[]
     Kernel.pbMessage(_INTL("Can't use that here."))
     next
   end
   if $game_player.pbHasDependentEvents?
     Kernel.pbMessage(_INTL("It can't be used when you have someone with you."))
     next
   end
   Kernel.pbMessage(_INTL("{1} used the Escape Rope.",$Trainer.name))
   pbFadeOutIn(99999){
      Kernel.pbCancelVehicles
      $game_temp.player_new_map_id=escape[0]
      $game_temp.player_new_x=escape[1]
      $game_temp.player_new_y=escape[2]
      $game_temp.player_new_direction=escape[3]
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
   }
   pbEraseEscapePoint
=end
})

ItemHandlers::UseInField.add(:BICYCLE,proc{|item|
   if pbBikeCheck
     if $PokemonGlobal.bicycle
       Kernel.pbDismountBike
     else
       Kernel.pbMountBike 
     end
   end
})

ItemHandlers::UseInField.add(:POKEBOARD,proc{|item|
   if pbBikeCheck
     if $PokemonGlobal.bicycle
       Kernel.pbDismountBike
     else
       Kernel.pbMountBike 
     end
   end
})

ItemHandlers::UseInField.copy(:BICYCLE,:MACHBIKE,:ACROBIKE,:POKEBOARD)

ItemHandlers::UseInField.add(:OLDROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if !pbIsWaterTag?(terrain) || (!notCliff && !$PokemonGlobal.surfing)
     Kernel.pbMessage(_INTL("Can't use that here."))
     next
   end
   encounter=$PokemonEncounters.hasEncounter?(EncounterTypes::OldRod)
   if pbFishing(encounter,1)
     pbEncounter(EncounterTypes::OldRod)
   end
})

ItemHandlers::UseInField.add(:GOODROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if !pbIsWaterTag?(terrain) || (!notCliff && !$PokemonGlobal.surfing)
     Kernel.pbMessage(_INTL("Can't use that here."))
     next
   end
   encounter=$PokemonEncounters.hasEncounter?(EncounterTypes::GoodRod)
   if pbFishing(encounter,2)
     pbEncounter(EncounterTypes::GoodRod)
   end
})

ItemHandlers::UseInField.add(:SUPERROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if !pbIsWaterTag?(terrain) || (!notCliff && !$PokemonGlobal.surfing)
     Kernel.pbMessage(_INTL("Can't use that here."))
     next
   end
   encounter=$PokemonEncounters.hasEncounter?(EncounterTypes::SuperRod)
   if pbFishing(encounter,3)
     pbEncounter(EncounterTypes::SuperRod)
   end
})

ItemHandlers::UseInField.add(:MASTERAMO,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if (pbIsWaterTag?(terrain) && !$PokemonGlobal.surfing && notCliff) ||
      (pbIsWaterTag?(terrain) && $PokemonGlobal.surfing)
     pbTreasureHook
     next 0
   else
     Kernel.pbMessage(_INTL("Can't use that here."))
     next 0
   end
})

ItemHandlers::UseInField.add(:ITEMFINDER,proc{|item|
   event=pbClosestHiddenItem
   if !event
     Kernel.pbMessage(_INTL("... ... ... ...Nope!\r\nThere's no response."))
   else
     offsetX=event.x-$game_player.x
     offsetY=event.y-$game_player.y
     if offsetX==0 && offsetY==0
       for i in 0...32
         Graphics.update
         Input.update
         $game_player.turn_right_90 if (i&7)==0
         pbUpdateSceneMap
       end
       Kernel.pbMessage(_INTL("The {1}'s indicating something right underfoot!\1",PBItems.getName(item)))
     else
       direction=$game_player.direction
       if offsetX.abs>offsetY.abs
         direction=(offsetX<0) ? 4 : 6         
       else
         direction=(offsetY<0) ? 8 : 2
       end
       for i in 0...8
         Graphics.update
         Input.update
         if i==0
           $game_player.turn_down if direction==2
           $game_player.turn_left if direction==4
           $game_player.turn_right if direction==6
           $game_player.turn_up if direction==8
         end
         pbUpdateSceneMap
       end
       Kernel.pbMessage(_INTL("Huh?\nThe {1}'s responding!\1",PBItems.getName(item)))
       Kernel.pbMessage(_INTL("There's an item buried around here!"))
     end
   end
})

ItemHandlers::UseInField.copy(:ITEMFINDER,:DOWSINGMCHN)

ItemHandlers::UseInField.add(:TOWNMAP,proc{|item|
   pbShowMap(-1,false)
})

ItemHandlers::UseInField.add(:COINCASE,proc{|item|
   Kernel.pbMessage(_INTL("Coins: {1}",$PokemonGlobal.coins))
   next 1 # Continue
})

ItemHandlers::UseInField.add(:POKEBLOCKCASE,proc{|item|
   Kernel.pbMessage(_INTL("Can't use that here."))   
})

#===============================================================================
# BattleUseOnPokemon handlers
#===============================================================================

ItemHandlers::BattleUseOnPokemon.add(:POTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SUPERPOTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,50,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:RISOTTO,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,50,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:HYPERPOTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,200,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:BLUMELE,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,80,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:MAXPOTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,pokemon.totalhp-pokemon.hp,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:BERRYJUICE,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:RAGECANDYBAR,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SWEETHEART,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:FRESHWATER,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,50,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SODAPOP,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,60,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:LEMONADE,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,80,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:MOOMOOMILK,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,100,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:ORANBERRY,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,10,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SITRUSBERRY,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,(pokemon.totalhp/4).floor,scene)
})

ItemHandlers::BattleUseOnBattler.add(:EDENBERRY,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if hasSpeciesX?(battler.pokemon)
     if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
       battler.pbIncreaseStat(PBStats::ATTACK,2,true)
       return true
     else
       scene.pbDisplay(_INTL("But it had no effect!"))
       return false  
     end
   else
     scene.pbDisplay(_INTL("Il Pokémon non resiste al forte aroma e sviene!"))
     battler.hp=(0)
     battler.pbFaint(true)
   end  
})

ItemHandlers::BattleUseOnPokemon.add(:AWAKENING,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::SLEEP
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} woke up.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:AWAKENING,:CHESTOBERRY,:BLUEFLUTE,:POKEFLUTE)

ItemHandlers::BattleUseOnPokemon.add(:ANTIDOTE,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::POISON
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} was cured of its poisoning.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:ANTIDOTE,:PECHABERRY)

ItemHandlers::BattleUseOnPokemon.add(:BURNHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::BURN
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s burn was healed.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:BURNHEAL,:RAWSTBERRY)

ItemHandlers::BattleUseOnPokemon.add(:PARLYZHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::PARALYSIS
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} was cured of paralysis.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:PARLYZHEAL,:CHERIBERRY)

ItemHandlers::BattleUseOnPokemon.add(:ICEHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::FROZEN
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} was thawed out.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:ICEHEAL,:ASPEARBERRY)

ItemHandlers::BattleUseOnPokemon.add(:FULLHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || (pokemon.status==0 && (!battler || battler.effects[PBEffects::Confusion]==0))
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     battler.status=0 if battler
     battler.effects[PBEffects::Confusion]=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} became healthy.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:FULLHEAL,
   :LAVACOOKIE,:OLDGATEAU,:CASTELIACONE,:LUMBERRY)

ItemHandlers::BattleUseOnPokemon.add(:FULLRESTORE,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || (pokemon.status==0 && pokemon.hp==pokemon.totalhp &&
      (!battler || battler.effects[PBEffects::Confusion]==0))
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     hpgain=pbItemRestoreHP(pokemon,pokemon.totalhp-pokemon.hp)
     battler.hp=pokemon.hp if battler
     pokemon.status=0
     pokemon.statusCount=0
    if battler
      echoln "USING FULLRESTORE ON A BATTLER HERE!"
      battler.status=0 
      battler.statusCount=0
     end 
     battler.effects[PBEffects::Confusion]=0 if battler
     scene.pbRefresh
     if hpgain>0
       scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.",pokemon.name,hpgain))
     else
       scene.pbDisplay(_INTL("{1} became healthy.",pokemon.name))
     end
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:REVIVE,proc{|item,pokemon,battler,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.hp=(pokemon.totalhp/2).floor
     for i in 0...$Trainer.party.length
       if $Trainer.party[i]==pokemon
         battler.pbInitialize(pokemon,i,false) if battler
         break
       end
     end
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP was restored.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:MAXREVIVE,proc{|item,pokemon,battler,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.hp=pokemon.totalhp
     for i in 0...$Trainer.party.length
       if $Trainer.party[i]==pokemon
         battler.pbInitialize(pokemon,i,false) if battler
         break
       end
     end
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP was restored.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:ENERGYPOWDER,proc{|item,pokemon,battler,scene|
   if pbBattleHPItem(pokemon,battler,50,scene)
     pokemon.changeHappiness("powder")
     next true
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.add(:ENERGYROOT,proc{|item,pokemon,battler,scene|
   if pbBattleHPItem(pokemon,battler,200,scene)
     pokemon.changeHappiness("Energy Root")
     next true
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.add(:HEALPOWDER,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || (pokemon.status==0 && (!battler || battler.effects[PBEffects::Confusion]==0))
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.statusCount=0
     battler.status=0 if battler
     battler.effects[PBEffects::Confusion]=0 if battler
     pokemon.changeHappiness("powder")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} became healthy.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:REVIVALHERB,proc{|item,pokemon,battler,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     pokemon.status=0
     pokemon.hp=pokemon.totalhp
     for i in 0...$Trainer.party.length
       if $Trainer.party[i]==pokemon
         battler.pbInitialize(pokemon,i,false) if battler
         break
       end
     end
     pokemon.changeHappiness("Revival Herb")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1}'s HP was restored.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:ETHER,proc{|item,pokemon,battler,scene|
   move=scene.pbChooseMove(pokemon,_INTL("Restore which move?"))
   if move>=0
     if pbBattleRestorePP(pokemon,battler,move,10)==0
       scene.pbDisplay(_INTL("It won't have any effect."))
       next false
     else
       scene.pbDisplay(_INTL("PP was restored."))
       next true
     end
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.copy(:ETHER,:LEPPABERRY)

ItemHandlers::BattleUseOnPokemon.add(:MAXETHER,proc{|item,pokemon,battler,scene|
   move=scene.pbChooseMove(pokemon,_INTL("Restore which move?"))
   if move>=0
     if pbBattleRestorePP(pokemon,battler,move,pokemon.moves[move].totalpp-pokemon.moves[move].pp)==0
       scene.pbDisplay(_INTL("It won't have any effect."))
       next false
     else
       scene.pbDisplay(_INTL("PP was restored."))
       next true
     end
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.add(:ELIXIR,proc{|item,pokemon,battler,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbBattleRestorePP(pokemon,battler,i,10)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("PP was restored."))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:MAXELIXIR,proc{|item,pokemon,battler,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbBattleRestorePP(pokemon,battler,i,pokemon.moves[i].totalpp-pokemon.moves[i].pp)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   else
     scene.pbDisplay(_INTL("PP was restored."))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:REDFLUTE,proc{|item,pokemon,battler,scene|
   if battler && battler.effects[PBEffects::Attract]>=0
     battler.effects[PBEffects::Attract]=-1
     scene.pbDisplay(_INTL("{1} got over its infatuation.",pokemon.name))
     next true # :consumed:
   else
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   end
})

ItemHandlers::BattleUseOnPokemon.add(:YELLOWFLUTE,proc{|item,pokemon,battler,scene|
   if battler && battler.effects[PBEffects::Confusion]>0
     battler.effects[PBEffects::Confusion]=0
     scene.pbDisplay(_INTL("{1} snapped out of confusion.",pokemon.name))
     next true # :consumed:
   else
     scene.pbDisplay(_INTL("It won't have any effect."))
     next false
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:YELLOWFLUTE,:PERSIMBERRY)

#===============================================================================
# BattleUseOnBattler handlers
#===============================================================================

ItemHandlers::BattleUseOnBattler.add(:XATTACK,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
     battler.pbIncreaseStat(PBStats::ATTACK,1,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
     battler.pbIncreaseStat(PBStats::ATTACK,2,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
     battler.pbIncreaseStat(PBStats::ATTACK,3,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
     battler.pbIncreaseStat(PBStats::ATTACK,6,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XDEFEND,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
     battler.pbIncreaseStat(PBStats::DEFENSE,1,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XDEFEND2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
     battler.pbIncreaseStat(PBStats::DEFENSE,2,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XDEFEND3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
     battler.pbIncreaseStat(PBStats::DEFENSE,3,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XDEFEND6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
     battler.pbIncreaseStat(PBStats::DEFENSE,6,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPATK,false)
     battler.pbIncreaseStat(PBStats::SPATK,1,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPATK,false)
     battler.pbIncreaseStat(PBStats::SPATK,2,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPATK,false)
     battler.pbIncreaseStat(PBStats::SPATK,3,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPATK,false)
     battler.pbIncreaseStat(PBStats::SPATK,6,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
     battler.pbIncreaseStat(PBStats::SPDEF,1,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
     battler.pbIncreaseStat(PBStats::SPDEF,2,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
     battler.pbIncreaseStat(PBStats::SPDEF,3,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
     battler.pbIncreaseStat(PBStats::SPDEF,6,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPEED,false)
     battler.pbIncreaseStat(PBStats::SPEED,1,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPEED,false)
     battler.pbIncreaseStat(PBStats::SPEED,2,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPEED,false)
     battler.pbIncreaseStat(PBStats::SPEED,3,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::SPEED,false)
     battler.pbIncreaseStat(PBStats::SPEED,6,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
     battler.pbIncreaseStat(PBStats::ACCURACY,1,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
     battler.pbIncreaseStat(PBStats::ACCURACY,2,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
     battler.pbIncreaseStat(PBStats::ACCURACY,3,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
     battler.pbIncreaseStat(PBStats::ACCURACY,6,true)
     return true
   else
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.effects[PBEffects::FocusEnergy]>=1
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false
   else
     battler.effects[PBEffects::FocusEnergy]=1
     scene.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
     return true
   end
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.effects[PBEffects::FocusEnergy]>=2
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false
   else
     battler.effects[PBEffects::FocusEnergy]=2
     scene.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
     return true
   end
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.effects[PBEffects::FocusEnergy]>=3
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false
   else
     battler.effects[PBEffects::FocusEnergy]=3
     scene.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
     return true
   end
})

ItemHandlers::BattleUseOnBattler.add(:GUARDSPEC,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   itemname=PBItems.getName(item)
   scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
   if battler.pbOwnSide.effects[PBEffects::Mist]>0
     scene.pbDisplay(_INTL("But it had no effect!"))
     return false
   else
     battler.pbOwnSide.effects[PBEffects::Mist]=5
     if !scene.pbIsOpposing?(attacker.index)
       scene.pbDisplay(_INTL("Your team became shrouded in mist!"))
     else
       scene.pbDisplay(_INTL("The foe's team became shrouded in mist!"))
     end
     return true
   end
})

#ItemHandlers::BattleUseOnBattler.add(:POKEDOLL,proc{|item,battler,scene|
#   battle=battler.battle
#   if battle.opponent
#     scene.pbDisplay(_INTL("Can't use that here."))
#     return false
#   else
#     playername=battle.pbPlayer.name
#     itemname=PBItems.getName(item)
#     scene.pbDisplay(_INTL("{1} used the {2}.",playername,itemname))
#     return true
#   end
#})

#ItemHandlers::BattleUseOnBattler.copy(:POKEDOLL,:FLUFFYTAIL,:POKETOY)

ItemHandlers::BattleUseOnBattler.addIf(proc{|item|
                pbIsPokeBall?(item)},proc{|item,battler,scene|  # Any Poké Ball
   battle=battler.battle
   if !battler.pbOpposing1.isFainted? && !battler.pbOpposing2.isFainted?
     if !pbIsSnagBall?(item)
       scene.pbDisplay(_INTL("It's no good!  It's impossible to aim when there are two Pokémon!"))
       return false
     end
   end
   if battle.pbPlayer.party.length>=6 && $PokemonStorage.full?
     scene.pbDisplay(_INTL("There is no room left in the PC!"))
     return false
   end
   return true
})

#===============================================================================
# UseInBattle handlers
#===============================================================================

#ItemHandlers::UseInBattle.add(:POKEDOLL,proc{|item,battler,battle|
#   battle.decision=3
#   battle.pbDisplayPaused(_INTL("Got away safely!"))
#})

#ItemHandlers::UseInBattle.copy(:POKEDOLL,:FLUFFYTAIL,:POKETOY)

ItemHandlers::UseInBattle.addIf(proc{|item|
  pbIsPokeBall?(item)},proc{|item,battler,battle|  # Any Poké Ball
    battle.pbThrowPokeBall(battler.index,item)
})