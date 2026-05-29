FactoryBot.define do
  factory :pastoral_note do
    association :church
    association :member
    association :pastor, factory: :user
    title { "Reunion pastoral" }
    body { "Conversamos sobre temas familiares y oramos juntos." }
    note_type { "general" }

    after(:build) do |note|
      note.church ||= note.member&.church
      note.member&.update_columns(church_id: note.church_id) if note.member && note.member.church_id != note.church_id
    end
  end
end
