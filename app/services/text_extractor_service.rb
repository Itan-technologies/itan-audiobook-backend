class TextExtractorService
  def self.extract(book)
    if book.ebook_file.attached?
      case File.extname(book.ebook_file.filename.to_s).downcase
      when '.pdf'
        extract_from_pdf(book.ebook_file)
      when '.epub'
        extract_from_epub(book.ebook_file)
      else
        raise "Unsupported file format: #{book.ebook_file.filename}"
      end
    else
      raise "No ebook file attached"
    end
  end

  private

  def self.extract_from_pdf(attachment)
    # Download file to temp location
    temp_file = Tempfile.new(['book', '.pdf'])
    temp_file.binmode
    temp_file.write(attachment.download)
    temp_file.rewind

    text = ""
    PDF::Reader.new(temp_file.path).pages.each do |page|
      text << page.text
    end
    
    temp_file.close
    temp_file.unlink
    
    text.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    clean_extracted_text(text)
  end
  
  def self.extract_from_epub(attachment)
    temp_file = Tempfile.new(['book', '.epub'])
    temp_file.binmode
    temp_file.write(attachment.download)
    temp_file.rewind
    
    epub = EPUB::Parser.parse(temp_file.path)
    text = ""
    
    epub.each_page_on_spine do |page|
      text << Nokogiri::HTML(page.content).text
    end
    
    temp_file.close
    temp_file.unlink
    
    text.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    clean_extracted_text(text)
  end

  def self.clean_extracted_text(text)
        # Basic cleanup that's safe for all books
        text = text.gsub(/\s+/, ' ')                # Normalize whitespace
        text = text.gsub(/^\s*\d+\s*$/, '')         # Remove standalone page numbers
        text = text.gsub(/\f/, "\n\n")              # Replace form feeds with paragraph breaks
        
        # Remove common PDF artifacts that would sound awkward
        text = text.gsub(/https?:\/\/[^\s]+/, '')   # Remove URLs
        text = text.gsub(/www\.[^\s]+/, '')         # Remove www references
        
        # Fix common OCR/extraction issues
        text = text.gsub(/([a-z])- ([a-z])/, '\1\2')  # Fix hyphenated words
        
        text.strip
  end
end
