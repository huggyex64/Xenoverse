class PokeBattle_Trainer
    attr_accessor(:realBag)
    attr_accessor(:realParty)


    def enterShinobiIsland
        @realBag = $PokemonBag
        $PokemonBag = PokemonBag.new
        @realParty = $Trainer.party

        for item in @realBag.pockets[pbGetPocket(267)]
            $PokemonBag.pbStoreItem(item[0],item[1])
        end
    end


    def exitShinobiIsland

        # Bring back acquired items
        tempBag = $PokemonBag
        $PokemonBag = @realBag if @realBag != nil
        
        index = 0
        for pocket in tempBag.pockets
            if index != pbGetPocket(267)
                echoln(pocket)
                for item in pocket
                    $PokemonBag.pbStoreItem(item[0],item[1])
                end
            end
            index+=1
        end
        

    end


end