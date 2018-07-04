require 'spec_helper'
describe 'includable' do
  context 'with default values for all parameters' do
    it { should contain_class('includable') }
  end
end
