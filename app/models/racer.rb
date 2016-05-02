class Racer
  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  #Add an initializer that can set the properties of the class
  #using the keys from a racers document.
  def initialize(params={})
    @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client['racers']
  end


  def self.all(prototype={}, sort={:number => 1}, skip=0, limit=nil)
    results = self.collection.find(prototype).sort(sort).skip(skip)
    results = results.limit(limit) if !limit.nil?

    return results

  end

  # locate a specific document. Use initialize(hash) on the result to
  # get in class instance form
  def self.find id

  	result = collection.find(:_id => BSON::ObjectId.from_string(id))
                .projection(
                    {
                      _id: true,
                      number: true,
                      first_name: true,
                      last_name: true,
                      gender: true,
                      group: true,
                      secs: true
                    }
                  ).first

  	return result.nil? ? nil : Racer.new(result)
  end

  # create a new document using the current instance
  def save
    Rails.logger.debug {"saving #{self}"}

    result = self.class.collection
              .insert_one(
                          _id: @id,
                          number: @number,
                          first_name: @first_name,
                          last_name: @last_name,
                          gender: @gender,
                          group: @group,
                          secs: @secs
                          )
    @id = result.inserted_id
  end

  def update(params)
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i

    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs)

    self.class.collection
  	            .find(:_id=>BSON::ObjectId.from_string(@id))
  	            .update_one(params)
  end

end
