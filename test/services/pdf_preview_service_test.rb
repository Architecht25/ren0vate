require "test_helper"

class PdfPreviewServiceTest < ActiveSupport::TestCase
  def setup
    @document = documents(:pdf_document) # Assumons qu'il existe un fixture PDF
  end

  test "should generate preview for PDF document" do
    skip "Requires Cloudinary setup" unless Rails.env.test? && ENV['CLOUDINARY_URL']

    # Mock Cloudinary response
    mock_result = {
      'public_id' => 'pdf_previews/test_doc',
      'secure_url' => 'https://res.cloudinary.com/test/image/upload/test.jpg'
    }

    Cloudinary::Uploader.stub :upload, mock_result do
      url = PdfPreviewService.generate_preview_for_document(@document)
      assert_not_nil url
      assert url.include?('cloudinary.com')
      assert url.include?('pg_1') # Page 1 transformation
    end
  end

  test "should return nil for non-PDF documents" do
    @document.file.stub :content_type, 'image/png' do
      @document.stub :is_pdf?, false do
        url = PdfPreviewService.generate_preview_for_document(@document)
        assert_nil url
      end
    end
  end

  test "should use cache for repeated calls" do
    skip "Requires Cloudinary setup" unless Rails.env.test? && ENV['CLOUDINARY_URL']

    cache_key = "pdf_preview_#{@document.id}_#{@document.file.blob.checksum}"
    expected_url = "https://example.com/test.jpg"

    Rails.cache.write(cache_key, expected_url)

    # Ne devrait pas appeler Cloudinary car en cache
    Cloudinary::Uploader.expect :upload, nil do
      url = PdfPreviewService.generate_preview_for_document(@document)
      assert_equal expected_url, url
    end
  end
end
