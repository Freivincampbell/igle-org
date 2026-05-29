require "rails_helper"

RSpec.describe Member do
  it "requires core profile fields" do
    member = described_class.new

    expect(member).not_to be_valid
    expect(member.errors[:first_name]).to be_present
    expect(member.errors[:last_name]).to be_present
    expect(member.errors[:second_last_name]).to be_present
    expect(member.errors[:phone]).to be_present
    expect(member.errors[:birth_date]).to be_present
  end

  it "allows blank email" do
    member = build(:member, email: nil)

    expect(member).to be_valid
  end

  it "keeps email unique inside the church" do
    church = create(:church)
    create(:member, church:, email: "persona@example.test")

    duplicate = build(:member, church:, email: "persona@example.test")

    expect(duplicate).not_to be_valid
  end

  it "allows the same email in different churches" do
    create(:member, email: "persona@example.test")

    member = build(:member, email: "persona@example.test")

    expect(member).to be_valid
  end

  it "rejects future dates" do
    member = build(:member, birth_date: Date.tomorrow, baptized_on: Date.tomorrow, official_membership_on: Date.tomorrow)

    expect(member).not_to be_valid
    expect(member.errors[:birth_date]).to include("no puede estar en el futuro")
    expect(member.errors[:baptized_on]).to include("no puede estar en el futuro")
    expect(member.errors[:official_membership_on]).to include("no puede estar en el futuro")
  end

  it "links only users who belong to the same church" do
    member = build(:member, user: create(:user))

    expect(member).not_to be_valid
    expect(member.errors[:user]).to include("debe pertenecer a la iglesia")
  end

  describe ".search_by_name" do
    it "encuentra miembros por prefijo de nombre o apellido" do
      church = create(:church)
      ana = create(:member, church:, first_name: "Ana", last_name: "Rojas")
      _luis = create(:member, church:, first_name: "Luis", last_name: "Mora")

      results = church.members.search_by_name("ro")

      expect(results).to include(ana)
      expect(results).not_to include(_luis)
    end

    it "ignora mayúsculas" do
      church = create(:church)
      ana = create(:member, church:, first_name: "Ana", last_name: "Rojas")

      expect(church.members.search_by_name("ANA")).to include(ana)
    end
  end
end
