#####################################################################
# ONLINE BATTLES
#####################################################################
class OnlineTest
  
end

class BattleRequest
  #weedleteam
  #@@url = "https://www.weedleteam.com/request.php"

  @@url = "http://xntst.altervista.org/BattleRequest.php"

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