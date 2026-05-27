require "rails_helper"

RSpec.describe PublicIdentifiable do
  [
    [ User, :user ],
    [ Church, :church ],
    [ ChurchMembership, :church_membership ],
    [ Role, :role ],
    [ Permission, :permission ],
    [ RolePermission, :role_permission ],
    [ MembershipRole, :membership_role ]
  ].each do |model_class, factory_name|
    describe model_class.name do
      it "uses public_id instead of the database id" do
        record = create(factory_name)

        expect(record.public_id).to match(PublicIdentifiable::UUID_FORMAT)
        expect(record.to_param).to eq(record.public_id)
        expect(record.to_param).not_to eq(record.id.to_s)
      end

      it "does not resolve numeric database ids as public identifiers" do
        record = create(factory_name)

        expect { model_class.find_by_public_id!(record.id.to_s) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
