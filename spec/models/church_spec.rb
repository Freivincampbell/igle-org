require "rails_helper"

RSpec.describe Church do
  describe "public URLs" do
    it "uses public_id instead of the database id" do
      church = create(:church)

      expect(church.to_param).to eq(church.public_id)
      expect(church.to_param).not_to eq(church.id.to_s)
    end

    it "rejects non-UUID lookup values" do
      expect { described_class.find_by_public_id!("1") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
