class Racer


  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client['racers']
  end

  def self.all(prototype={...}, sort={...}, skip=0, limit=nil)

    results = self.collection.find(prototype).sort(sort).skip(skip)
    results = results.limit(limit) if !limit.nil?

    return results
    
  end


end
