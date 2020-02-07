require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Frameworks do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ frameworks }).should.be.instance_of Command::Frameworks
      end
    end
  end
end

