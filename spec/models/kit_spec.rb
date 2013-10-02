require 'spec_helper'

describe Kit do
  let(:site)   { create(:site) }
  let(:design) { create(:design) }

  describe 'Associations' do
    it { should belong_to :site }
    it { should belong_to(:design) }
  end

  describe 'Validations' do
    [:site, :design, :identifier, :name].each do |attr|
      it { should validate_presence_of(attr) }
    end
    it { should ensure_length_of(:name).is_at_most(255) }

    describe 'uniqueness of identifier by site_id' do
      it 'adds an error if identifier is not unique for this site' do
        kit = Kit.create(site: site, design_id: design.id, name: 'My player 1')
        kit.identifier.should eq '1'

        kit2 = Kit.new(site: site, design_id: design.id, name: 'My player 2')
        kit2.identifier = kit.identifier
        kit2.should_not be_valid
        kit2.should have(1).error_on(:identifier)
      end
    end

    describe 'uniqueness of name by site_id' do
      it 'adds an error if name is not unique for this site' do
        kit = Kit.create(site: site, design_id: design.id, name: 'My player')
        kit.name.should eq 'My player'

        kit2 = Kit.new(site: site, design_id: design.id, name: 'My player')
        kit2.should_not be_valid
        kit2.should have(1).error_on(:name)
      end
    end
  end

  describe 'Initialization' do
    let(:kit) { Kit.new(site: site, design_id: nil, name: 'My player') }
    before do
      create(:design, name: 'flat')
      @classic_design = create(:design, name: 'classic')
    end

    describe 'set default design' do
      specify do
        kit.design_id.should eq @classic_design.id
      end
    end

    describe 'set identifier' do
      let(:kit) { Kit.new(site: site, name: 'My player') }

      context 'site has no kit yet' do
        specify do
          kit.identifier.should eq '1'
        end
      end

      context 'site has kits' do
        before do
          site.kits.create!(name: 'My player')
          site.kits.should have(1).item
        end

        specify do
          kit.identifier.should eq '2'
        end
      end
    end

  end

  describe '#default?' do
    let(:kit)  { Kit.create!(site: site, design_id: design.id, name: 'My player') }
    let(:site) { create(:site) }
    context 'kit is not default' do
      it { kit.should_not be_default }
    end

    context 'kit is default' do
      before { site.default_kit_id = kit.id }

      it { kit.should be_default }
    end

  end

end

# == Schema Information
#
# Table name: kits
#
#  created_at :datetime
#  design_id  :integer          not null
#  id         :integer          not null, primary key
#  identifier :string(255)
#  name       :string(255)      not null
#  settings   :text
#  site_id    :integer          not null
#  updated_at :datetime
#
# Indexes
#
#  index_kits_on_design_id               (design_id)
#  index_kits_on_site_id                 (site_id)
#  index_kits_on_site_id_and_identifier  (site_id,identifier) UNIQUE
#  index_kits_on_site_id_and_name        (site_id,name) UNIQUE
#

