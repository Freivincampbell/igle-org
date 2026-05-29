require "rails_helper"

RSpec.describe Church do
  describe "public URLs" do
    it "keeps public_id lookups available for church routes" do
      church = create(:church)

      expect(described_class.find_by_public_id!(church.public_id)).to eq(church)
    end
  end

  describe ".publicly_visible" do
    it "incluye solo iglesias con página habilitada y activas" do
      visible = create(:church, public_page_enabled: true, status: "active")
      create(:church, public_page_enabled: false, status: "active")
      create(:church, public_page_enabled: true, status: "inactive")

      expect(Church.publicly_visible).to contain_exactly(visible)
    end
  end
end
