#===============================================================================
# ■ Overworld Shadows by KleinStudio V1.1
# http://pokemonfangames.com
#
# * Making a overworld shadowless
# ** Method 1
#   - Add /noShadow/ to the event name
# ** Method 2
#   - Add the event name to Shadowless_EventNames
#     this is useful for doors for example.
# ** Method 3
#   - Create a new comment in the event and type "NoShadow"
#     If the event is a dependent event you have to put the comment
#     in the common event.
#===============================================================================
# Shadowless event names
Shadowless_EventNames=[
  "NoShadow",
  "BerryPlant",
  "OutdoorLight",
  "Light",
  "HeadbuttTree"
]

# Overworld shadow bitmap
Shadow_Bitmap="Graphics/Pictures/overworldshadow.png"

# Enable shadows for dependent events
Shadows_In_DependentEvents=true

class ShadowSprite
  def initialize(sprite,event,viewport=nil,map=nil,deventname=nil,test=false)
    @rsprite=sprite
    @sprite=Sprite.new(viewport)
    @sprite.bitmap=BitmapCache.load_bitmap(Shadow_Bitmap)
    @event=event
    @map=map
    @disposed=false
    @deventname=deventname
    @viewport=viewport
    @test=test
    update
  end

  def dispose
    if !@disposed
      @sprite.dispose if @sprite
      @sprite=nil
      @disposed=true
    end
  end
 
  def checkNoShadowNames(eventname)
    return true if eventname.include?("/noShadow/")
    for shadowlessnames in Shadowless_EventNames
      if eventname==shadowlessnames
        return true
      end
    end
    return false
  end
  
  def update 
    return if @disposed
    if @rsprite.disposed?
      dispose
      return
    end
    
    if !(@event==$game_player)
      eventname=@deventname.nil? ? @event.name : @deventname
      @sprite.visible=!(@event.character_name=="" or @event.character_name=="nil" or 
        @event.bush_depth>0 or checkNoShadowNames(eventname) or !@rsprite.visible)
    else
      @sprite.visible=!(@event.bush_depth>0 or !(@map.id==$game_map.id) or $PokemonGlobal.surfing or $PokemonGlobal.bicycle)
    end
		
    if @event!=$game_player
      @sprite.visible=false if pbEventCommentInput(@event,0,"NoShadow")
    end
    
    
    @sprite.visible = false if @event == $game_player && $game_switches[44] == false || pbGetTerrainTag == PBTerrain::Mud
    
    x=@rsprite.x-@rsprite.ox
    character=@rsprite.character
    y=(character.real_y - character.map.display_y + 3)/4+(Game_Map::TILEHEIGHT)
    width=@rsprite.src_rect.width
    height=@rsprite.src_rect.height
    @sprite.x=x+width/2
    @sprite.y=y
    @sprite.ox=@sprite.bitmap.width/2
    @sprite.oy=@sprite.bitmap.height/2+@sprite.bitmap.height/4
    @sprite.z=@rsprite.z-1
    @sprite.opacity = @event.opacity / 5
  end 
end

class Spriteset_Map
  alias klein_shadow_initialize initialize
  def initialize(map=nil)
    @shadowSprites=[]
    klein_shadow_initialize(map)
    @oldDepedents=dependentEventsSprites.sprites.length
    for sprite in @character_sprites
      next if sprite.character!=$game_player && pbEventCommentInput(sprite.character,0,"NoShadow") 
      @shadowSprites.push(ShadowSprite.new(sprite,sprite.character,@viewport1))
    end
    @shadowSprites.push(ShadowSprite.new(@playersprite,$game_player,@viewport1,@map))
  end
  
  alias klein_shadow_dispose dispose
  def dispose
    klein_shadow_dispose
    for sprite in @shadowSprites
      sprite.dispose
    end
  end
  
  def dependentEventsSprites
    for i in 0...@usersprites.length
      return @usersprites[i] if @usersprites[i].is_a?(DependentEventSprites)
    end
  end
      
  alias klein_shadow_update update
  def update
    klein_shadow_update
    if Shadows_In_DependentEvents && @oldDepedents!=dependentEventsSprites.sprites.length
      for i in 0...$PokemonGlobal.dependentEvents.length      
        event=$PokemonTemp.dependentEvents.realEvents[i]
        sprite=dependentEventsSprites.sprites[i]
        eventname=$PokemonGlobal.dependentEvents[i][8]
        next if sprite.nil? || event.nil?
        next if event!=$game_player && pbEventCommentInput(event,0,"NoShadow") 
        @shadowSprites.push(ShadowSprite.new(sprite,event,@viewport1,nil,eventname, true))
      end
      @oldDepedents=dependentEventsSprites.sprites.length
    end
    
    for sprite in @shadowSprites
      sprite.update
    end
  end 
end

class DependentEvents
  attr_accessor :realEvents
  alias klein_shadows_addevent addEvent
  def addEvent(event,eventName=nil,commonEvent=nil)
    if event && !event.nil?
      if eventName.nil?
        eventName=event.name 
      end
    end
    klein_shadows_addevent(event,eventName,commonEvent)
  end
end

class DependentEventSprites
  attr_accessor :sprites
end