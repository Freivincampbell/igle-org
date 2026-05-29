require "rails_helper"

RSpec.describe Board do
  describe "validations" do
    it "requires church, name and starts_on" do
      board = Board.new

      board.valid?

      expect(board.errors).to include(:church, :name, :starts_on)
    end

    it "rejects ends_on before or equal to starts_on" do
      board = build(:board, starts_on: Date.current, ends_on: Date.current)

      expect(board).not_to be_valid
      expect(board.errors[:ends_on]).to be_present
    end
  end

  describe "scopes" do
    it "isolates per church" do
      church_a = create(:church)
      church_b = create(:church)
      board_a = create(:board, church: church_a)
      board_b = create(:board, church: church_b)

      expect(church_a.boards).to include(board_a)
      expect(church_a.boards).not_to include(board_b)
    end
  end
end
