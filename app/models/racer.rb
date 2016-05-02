class Racer
  include ActiveModel::Model

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  # Add an initializer that can set the properties of the class
  # using the keys from a racers document.
  def initialize(params={})
    @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end
  def updated_at
    nil
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

  # update the values for this instance
  def update(params)
    Rails.logger.debug {"updating #{self} with #{params}"}

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

  # remove the document associated with this instance form the DB
  def destroy
    Rails.logger.debug {"destroying #{self}"}

    self.class.collection.find(
                            :_id => BSON::ObjectId.from_string(@id)
                            ).delete_one

  end

  #implememts the will_paginate paginate method that accepts
  # page - number >= 1 expressing offset in pages
  # per_page - row limit within a single page
  # also take in some custom parameters like
  # sort - order criteria for document
  # (terms) - used as a prototype for selection
  # This method uses the all() method as its implementation
  # and returns instantiated Racer classes within a will_paginate
  # page
  def self.paginate(params)
    page = (params[:page] || 1).to_i
    limit = (params[:per_page] || 30).to_i
    skip = (page - 1) * limit
    sort = {'number': 1}

    #get the associated page of Racers -- eagerly convert doc to Racer
    racers = []

    # Goal: find all 'racers' --> all({}, x, y, z).....
    # use {} not need parameters for filter
    all({}, sort, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end

    # Goal: find all 'racers' and get number total of elements
    # use {} not need parameters for filter
    total = all({}, sort, 0, 1).count
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end

  end
end
