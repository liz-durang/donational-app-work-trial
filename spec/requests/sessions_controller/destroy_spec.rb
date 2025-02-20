require 'rails_helper'

RSpec.describe 'DELETE /sessions', type: :request do
  let(:donor) { create(:donor) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ApplicationController).to receive(:log_out!)
  end

  it 'logs out the donor' do
    delete sessions_path
    expect(response).to redirect_to(root_path)
    expect(flash[:success]).to be_nil
  end

  it 'redirects to the root path' do
    delete sessions_path
    expect(response).to redirect_to(root_path)
  end
end
