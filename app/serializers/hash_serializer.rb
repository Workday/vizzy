class HashSerializer
  def self.dump(hash)
    hash.to_json
  end

  def self.load(hash)
    if hash.blank?
      {}
    else
      JSON.parse(hash)
    end.deep_symbolize_keys!
  end
end