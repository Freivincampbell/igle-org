require "rails_helper"

RSpec.describe ProfileChangeRequest do
  describe "validations" do
    it "rejects disallowed payload keys" do
      church = create(:church)
      member = create(:member, church:)
      req = build(:profile_change_request, church:, member:, changes_payload: { "member_status" => "inactive" })

      expect(req).not_to be_valid
      expect(req.errors[:changes_payload]).to be_present
    end

    it "requires non-empty payload" do
      church = create(:church)
      member = create(:member, church:)
      req = build(:profile_change_request, church:, member:, changes_payload: {})

      expect(req).not_to be_valid
    end
  end

  describe "#approve!" do
    it "applies the changes to the member" do
      church = create(:church)
      member = create(:member, church:, phone: "111", email: "old@example.test")
      reviewer = create(:user)
      req = create(:profile_change_request, church:, member:, changes_payload: { "phone" => "999", "email" => "new@example.test" })

      expect(req.approve!(reviewer:, notes: "OK")).to be(true)

      expect(member.reload.phone).to eq("999")
      expect(member.email).to eq("new@example.test")
      expect(req.reload).to be_approved
      expect(req.reviewed_by).to eq(reviewer)
    end

    it "does not approve an already reviewed request" do
      church = create(:church)
      member = create(:member, church:)
      reviewer = create(:user)
      req = create(:profile_change_request, church:, member:)
      req.approve!(reviewer:)

      expect(req.approve!(reviewer:)).to be(false)
    end
  end

  describe "#reject!" do
    it "marks as rejected and stores notes" do
      church = create(:church)
      member = create(:member, church:)
      reviewer = create(:user)
      req = create(:profile_change_request, church:, member:)

      expect(req.reject!(reviewer:, notes: "Datos incorrectos")).to be_truthy
      expect(req.reload).to be_rejected
      expect(req.review_notes).to eq("Datos incorrectos")
    end
  end
end
