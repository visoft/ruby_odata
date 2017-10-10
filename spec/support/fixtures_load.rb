class Fixtures

  FIXTURES = File.expand_path('../../fixtures', __FILE__)

  def self.load(file)
    File.new(FIXTURES + "/" + file)
  end
end