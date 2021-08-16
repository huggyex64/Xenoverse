#####################################################################
# ONLINE BATTLES
#####################################################################
class OnlineLobby
  attr_accessor(:playerList)

  def initialize()
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites={}
    #ID - Name - Debug - Status
    @playerList=[]
  end

  def pbDisplayAvaiblePlayerList(list)
    # Updating the list every time it gets updated on screen
    if list != @playerlist
      @playerList = list
    end
    # Disposing of old sprites
    if @sprites["list"] != nil
      @sprites["list"].dispose
    end
    @sprites["list"] = Sprite.new(@viewport)
    @sprites["list"].bitmap = Bitmap.new(256,300)
    @sprites["list"].bitmap.fill_rect(0,0,256,200,Color.new(30,30,30,200))
    for entry in list
      @sprites["list"].bitmap.draw_text(6,6+30*list.index(entry),250,30,"#{"%05d" % entry[0]}:#{entry[1]}-#{entry[3]}")
    end
  end

  def dispose
    @viewport.dispose
    for sprite in @sprites.values
      sprite.dispose
    end
  end
end

class BattleRequest
  #weedleteam
  #@@url = "https://www.weedleteam.com/request.php"

  @@url = "http://xntst.altervista.org/BattleRequest.php"

  ### MAIN UTILITY METHODS HERE
  def self.makeRequest(type, data = {})
      data["type"] = type
      return pbPostData(@@url,data)
  end

  def self.requestGift(type, code, data = {})
      data["type"] = type
      data["code"] = code
      return pbPostData(@@url,data)
  end

  def self.exists(type, code, data={})
      data["type"] = type
      data["code"] = code
      return pbPostData(@@url,data)
  end
  
  ### SHORTHANDS
  def self.getPlayerList()
    data={}
    data["type"] = "getPlayerList"
    res = pbPostData(@@url,data)
    playerlist = []
    for entry in res.split("\r\n")
      playerlist.push(entry.split("</s>"))
    end
    return playerlist
  end


end

def pbTOB
  roomno = rand(100000)
  res = BattleRequest.makeRequest("makeRoom",{"RoomNo"=>roomno})
  echoln res

  alive = true
  while(alive)
    #checks the room status every second. 
    pbWait(60)
    echoln BattleRequest.makeRequest("getDebug",{"RoomNo"=>roomno})

    if(Input.trigger?(Input::B))
      alive = false
    end
  end
end

def pbTO(roomno)
  alive = true
  while(alive)
    #checks the room status every second. 
    pbWait(60)
    echoln BattleRequest.makeRequest("getDebug",{"RoomNo"=>roomno})

    if(Input.trigger?(Input::B))
      alive = false
    end
  end
end