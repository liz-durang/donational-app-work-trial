class DonorPreferencesShouldIncludeAllOrganizationsByDefault < ActiveRecord::Migration[5.1]
  def change
    change_column_default :donors, :include_immediate_impact_organizations, from: nil, to: true
    change_column_default :donors, :include_long_term_impact_organizations, from: nil, to: true
    change_column_default :donors, :include_local_organizations, from: nil, to: true
    change_column_default :donors, :include_global_organizations, from: nil, to: true
  end
end
