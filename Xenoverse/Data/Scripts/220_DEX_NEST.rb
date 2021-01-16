class DexNest
	
	def initialize(viewport,species)
		@viewport = viewport
		@sprites={}
		@frame = 60
		@maxframe = 80
		
		pointsize = 16
		
		@sprites["region"] = Sprite.new(@viewport)
		@sprites["region"].z = 40
		
		@sprites["region"].bitmap = pbBitmap("Graphics/Pictures/mapRegion0")
		
		monsterIcon = pbBitmap("Graphics/Pictures/monsterIcon")
		@xsize = 512/pointsize
		@ysize = 384/pointsize
		
		@points = {}
		for y in 0..@ysize
			@points[y] = Hash.new
			for x in 0..@xsize
				@points[y][x] = Sprite.new(@viewport)
				@points[y][x].z = 41
				@points[y][x].x = x*pointsize
				@points[y][x].y = y*pointsize
				@points[y][x].zoom_x = 0.5
				@points[y][x].zoom_y = 0.5
			end
		end
		
		pbRgssOpen("Data/townmap.dat","rb"){|f|
			@mapdata=Marshal.load(f)
		}
		region = 0
		encdata=load_data("Data/encounters.dat")
		points=[]
		mapwidth=1+PokemonRegionMapScene::RIGHT-PokemonRegionMapScene::LEFT
		for enc in encdata.keys
			enctypes=encdata[enc][1]
			if pbFindEncounter(enctypes,species)
				mappos=pbGetMetadata(enc,MetadataMapPosition)
				if mappos && mappos[0]==region
					showpoint=true
					for loc in @mapdata[region][2]
						showpoint=false if loc[0]==mappos[1] && loc[1]==mappos[2] &&
						loc[7] && !$game_switches[loc[7]]
					end
					if showpoint
						mapsize=pbGetMetadata(enc,MetadataMapSize)
						if mapsize && mapsize[0] && mapsize[0]>0
							sqwidth=mapsize[0]
							sqheight=(mapsize[1].length*1.0/mapsize[0]).ceil
							for i in 0...sqwidth
								for j in 0...sqheight
									if mapsize[1][i+j*sqwidth,1].to_i>0
										points[mappos[1]+i+(mappos[2]+j)*mapwidth]=true
									end
								end
							end
						else
							points[mappos[1]+mappos[2]*mapwidth]=true
						end
					end
				end
			end
		end
		if points.include?(true)
			for point in 0...points.length
				@points[point/@xsize][point% (@xsize)].bitmap = monsterIcon if points[point]
			end
		else
			@sprites["unknown"] = Sprite.new(@viewport)
			@sprites["unknown"].z = 42
			@sprites["unknown"].bitmap = pbBitmap(Dex::PATH + "unknownBG")
			@sprites["unknown"].bitmap.font.name = "Barlow Condensed"
			@sprites["unknown"].bitmap.font.size = $MKXP ? 28 : 30
			pbDrawTextPositions(@sprites["unknown"].bitmap,[[_INTL("Unknown"),256,177,2,Color.new(248,248,248)]])
			
		end
		echoln points
		
	end
	
	def update
		@frame+=1
		if @frame > @maxframe
			@frame = 0
		end
		for y in 0..@ysize
			for x in 0..@xsize
				if @points[y][x] && @points[y][x].bitmap
					@points[y][x].opacity-=255/19 if @frame>=60
					@points[y][x].opacity+=255/19 if @frame<=20
				end
			end
		end
		
	end
	
	
	def close
		pbDisposeSpriteHash(@sprites)
		for hash in @points.values
			pbDisposeSpriteHash(hash)
		end
	end
end