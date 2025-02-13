module Helpers
  module MediaHelper
    def sample_image
      Rack::Test::UploadedFile.new(StringIO.new('fake image content'), 'image/png', original_filename: 'test_image.png')
    end
  end
end
