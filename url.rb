class Url
  include DataMapper::Resource

  property :id,   Serial
  property :url,  String, :length => 255
  property :slug, String

  before :create do
    self.slug = UniqueSLUG.next
  end

  def self.shorten url
    Url.first_or_create :url => url
  end

end
