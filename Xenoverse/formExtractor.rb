def toSymbol(sym,modulo)
    if sym.is_a?(Symbol) || sym.is_a?(String)
        return sym.to_sym
    else
        mod=Object.const_get(modulo) rescue nil
        echoln "NO MOD!" if !mod
        return nil if !mod
        for key in mod.constants
            if mod.const_get(key)==sym
                ret=key.to_sym
                break
            end
        end
        return ret
    end
end

def extract
	unless FileTest.directory?("Output")
		Dir.mkdir("Output")
	end
	file = File.new("Output/FormData.txt","w+")
    mf_symbols = []


	for k in MultipleForms.get.hash.keys
        spe = k
        #echoln k.type
        if (!k.is_a?(Symbol))
            spe = MultipleForms.get.toSymbol(k)
        else
            #echoln k
        end
        mf_symbols.push(spe) if !mf_symbols.include?(spe)
    end

    mf_symbols = mf_symbols.sort {|x, y| getID(PBSpecies,x).to_i <=> getID(PBSpecies,y).to_i }

    mf_important_forms={}

    for sp in mf_symbols
        if (!mf_important_forms.has_key?(sp))
            mf_important_forms[sp]=[]
        end
        for i in 0..99
            if File.exists?("Graphics/Pictures/DexNew/Icon/#{getID(PBSpecies,sp)}_#{i}.png")
                mf_important_forms[sp].push(i) if !mf_important_forms[sp].include?(i)
            end
        end
        if (File.exists?("Graphics/Pictures/DexNew/Icon/#{getID(PBSpecies,sp)}d.png")) #Alola form
            mf_important_forms[sp].push("d")
        end
    end

    echoln mf_important_forms

    for species in mf_symbols
        next if mf_important_forms[species].length == 0
        echoln species
        echoln mf_important_forms[species]
        for f in mf_important_forms[species]
            file.puts("[#{getID(PBSpecies,species)}_#{f}]")
            file.puts("SPECIES=#{species}")
            file.puts("FORMID=#{f}")
            p = pbGenerateWildPokemon(species,50)
            if f!="d"
                p.forcedForm = f
            else
                p.makeDelta
            end
            mega = false
            mega = true if MultipleForms.call("getUnmegaForm",p) != nil    
            file.puts("ISMEGA=#{mega}")
            file.puts("ISDELTA=#{f.is_a?(String) && f=="d"}")
            formname = mega ? MultipleForms.call("getMegaName",p) : MultipleForms.call("getFormName",p)
            if (formname != nil)
                file.puts("FORMNAME=#{formname}")
            end
            stats = ""
            for s in p.baseStats
                stats+="#{s},"
            end
            file.puts("TYPE1=#{toSymbol(p.type1,:PBTypes)}")
            file.puts("TYPE2=#{toSymbol(p.type2,:PBTypes)}")
            file.puts("BASESTATS=#{stats[0...(stats.length-1)]}")
            file.puts("ABILITYOVERRIDE=#{MultipleForms.call("ability",p)!=nil}")
            file.puts("ABILITY=#{toSymbol(p.ability,:PBAbilities)}")
            
            abilities = ""
            hidden = ""
            for a in p.getAbilityList
                if a[1]==2
                    hidden = toSymbol(a[0],:PBAbilities)
                else
                    abilities+="#{toSymbol(a[0],:PBAbilities)},"
                end
            end

            file.puts("ABILITIES=#{abilities[0...(abilities.length-1)]}")
            file.puts("HIDDENABILITY=#{hidden}")
            moves = ""
            echoln "Moves for Form #{f}"
            echoln p.getMoveList
            for m in p.getMoveList
                moves+="[#{toSymbol(m[1],:PBMoves)},#{m[0]}],"
            end
            file.puts("MOVES=#{moves[0...(moves.length-1)]}")
            moveCompat = MultipleForms.call("getMoveCompatibility",p)
            if (moveCompat!=nil)
                tms=""
                for tm in moveCompat
                    tms+="#{toSymbol(tm,:PBMoves)},"
                end
                file.puts("MOVESTM=#{tms[0...(tms.length-1)]}")
            end
            eggmoves = ""
            for em in p.possibleEggMoves
                eggmoves+="#{toSymbol(em,:PBMoves)},"
            end
            file.puts("EGGMOVES=#{eggmoves[0...(eggmoves.length-1)]}")
            #da vedere dopo
            file.puts("HEIGHT=#{p.height.to_f/100.0}")
            file.puts("WEIGHT=#{p.weight.to_f/100.0}")


        end
    end

    #close file when i'm done
    file.close()
end

extract()