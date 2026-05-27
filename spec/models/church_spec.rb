require "rails_helper"

RSpec.describe Church do
  describe "public URLs" do
    it "keeps public_id lookups available for church routes" do
      church = create(:church)

      expect(described_class.find_by_public_id!(church.public_id)).to eq(church)
    end
  end
end
