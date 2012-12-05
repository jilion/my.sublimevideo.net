require 'spec_helper'

describe Kit do
  let(:site)       { create(:site) }
  let(:app_design) { create(:app_design) }

  describe 'Associations' do
    it { should belong_to :site }
    it { should belong_to(:design).class_name('App::Design') }
  end

  describe 'Validations' do
    [:site, :identifier, :name, :app_design_id].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
    [:name, :app_design_id].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    [:site, :design, :identifier, :name].each do |attr|
      it { should validate_presence_of(attr) }
    end

    describe 'uniqueness of identifier by site_id' do
      it 'adds an error if identifier is not unique for this site' do
        kit = Kit.create({ site: site, app_design_id: app_design.id, name: 'My player 1' }, as: :admin)
        kit.identifier.should eq '1'

        kit2 = Kit.new({ site: site, app_design_id: app_design.id, name: 'My player 2' }, as: :admin)
        kit2.identifier = kit.identifier
        kit2.should_not be_valid
        kit2.should have(1).error_on(:identifier)
      end
    end

    describe 'uniqueness of name by site_id' do
      it 'adds an error if name is not unique for this site' do
        kit = Kit.create({ site: site, app_design_id: app_design.id, name: 'My player' }, as: :admin)
        kit.name.should eq 'My player'

        kit2 = Kit.new({ site: site, app_design_id: app_design.id, name: 'My player' }, as: :admin)
        kit2.should_not be_valid
        kit2.should have(1).error_on(:name)
      end
    end
  end

  describe 'Initialization' do
    let(:kit) { Kit.new({ site: site, app_design_id: nil, name: 'My player' }, as: :admin) }
    before do
      create(:app_design, name: 'flat')
      @classic_design = create(:app_design, name: 'classic')
    end

    describe 'set default design' do
      specify do
        kit.app_design_id.should eq @classic_design.id
      end
    end

    describe 'set identifier' do
      let(:kit) { Kit.new({ site: site, name: 'My player' }, as: :admin) }

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
    let(:kit)  { Kit.create!({ site: site, app_design_id: app_design.id, name: 'My player' }, as: :admin) }
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
#  app_design_id :integer          not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  identifier    :string(255)
#  name          :string(255)      not null
#  settings      :text
#  site_id       :integer          not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_kits_on_app_design_id     (app_design_id)
#  index_kits_on_site_id           (site_id)
#  index_kits_on_site_id_and_name  (site_id,name) UNIQUE
#

