# app/services/pdf_processor.rb
class PDFProcessor
    require 'pdf/reader'
    require 'tempfile'
  
    def self.extract_page(file_attachment, page_number)
      # Download PDF from S3 to temporary file
      temp_file = download_to_temp(file_attachment)
      
      begin
        reader = PDF::Reader.new(temp_file.path)
        
        # Validate page number
        return nil if page_number < 1 || page_number > reader.page_count
        
        # Extract page content
        page = reader.page(page_number)
        raw_text = page.text
        
        # Convert to HTML with basic formatting
        formatted_content = format_page_content(raw_text, page_number)
        
        formatted_content
        
      rescue => e
        Rails.logger.error "PDF processing error: #{e.message}"
        return fallback_content(page_number)
      ensure
        temp_file&.close
        temp_file&.unlink
      end
    end
    
    def self.get_page_count(file_attachment)
      temp_file = download_to_temp(file_attachment)
      
      begin
        reader = PDF::Reader.new(temp_file.path)
        reader.page_count
      rescue => e
        Rails.logger.error "PDF page count error: #{e.message}"
        250 # Default fallback
      ensure
        temp_file&.close
        temp_file&.unlink
      end
    end
    
    private
    
    def self.download_to_temp(file_attachment)
      temp_file = Tempfile.new(['book', '.pdf'])
      temp_file.binmode
      
      # Download from S3/Active Storage
      file_attachment.download do |chunk|
        temp_file.write(chunk)
      end
      
      temp_file.rewind
      temp_file
    end
    
    def self.format_page_content(raw_text, page_number)
      # Clean and format the extracted text
      cleaned_text = raw_text.gsub(/\s+/, ' ').strip
      
      # Split into paragraphs (basic heuristic)
      paragraphs = cleaned_text.split(/(?:\r?\n){2,}/).reject(&:empty?)
      
      # Convert to HTML
      html_content = paragraphs.map do |paragraph|
        "<p>#{CGI.escapeHTML(paragraph.strip)}</p>"
      end.join("\n")
      
      <<~HTML
        <div class="page-content" data-page="#{page_number}">
          #{html_content}
        </div>
      HTML
    end
    
    def self.fallback_content(page_number)
      <<~HTML
        <div class="page-content error">
          <p><em>Content temporarily unavailable for page #{page_number}. Please try again.</em></p>
        </div>
      HTML
    end
  end