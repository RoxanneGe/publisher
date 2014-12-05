class RemoveExpectations < Mongoid::Migration
  def self.up
    Edition.where(:expectation_ids.exists => true).each { |e| e.unset(:expectation_ids) }
    Expectation.collection.drop
  end

  def self.down
  end
end

class Expectation
  include Mongoid::Document
end
