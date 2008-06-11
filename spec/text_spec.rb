require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper")   

class TextObserver                         
  
  attr_accessor :font_settings, :size, :string
            
  def initialize     
    @font_settings = []
    @fonts = {}
  end
  
  def resource_font(*params)
    @fonts[params[0]] = params[1].basefont
  end

  def set_text_font_and_size(*params)     
    @font_settings << { :name => @fonts[params[0]], :size => params[1] }
  end     
  
  def show_text(*params)
    @string = params[0]
  end
end

class FontObserver

  attr_accessor :page_fonts

  def initialize
    @page_fonts = []
  end

  def resource_font(*params)
    @page_fonts.last << params[1].basefont
  end

  def begin_page(*params)
    @page_fonts << []
  end
end

describe "when drawing text" do
   
   before(:each) { create_pdf } 
   
   it "should default to 12 point helvetica" do
      @pdf.text "Blah", :at => [100,100]              
      text = observer(TextObserver)
      text.font_settings[0][:name].should == :Helvetica
      text.font_settings[0][:size].should == 12   
      text.string.should == "Blah"
   end   
   
   it "should allow setting font size" do
     @pdf.text "Blah", :at => [100,100], :size => 16
     text = observer(TextObserver)
     text.font_settings[0][:size].should == 16
   end
   
   it "should allow setting a default font size" do
     @pdf.font_size! 16
     @pdf.text "Blah"
     text = observer(TextObserver)
     text.font_settings[0][:size].should == 16
   end
   
   it "should allow overriding default font for a single instance" do
     @pdf.font_size! 16

     @pdf.text "Blah", :size => 11
     @pdf.text "Blaz"
     text = observer(TextObserver)
     text.font_settings[0][:size].should == 11
     text.font_settings[1][:size].should == 16
   end
   
   
   it "should allow setting a font size transaction with a block" do
     @pdf.font_size 16 do
       @pdf.text 'Blah'
     end

     @pdf.text 'blah'

     text = observer(TextObserver)
     text.font_settings[0][:size].should == 16
     text.font_settings[1][:size].should == 12
   end
   
   it "should allow manual setting the font size " +
       "when in a font size block" do
     @pdf.font_size 16 do
        @pdf.text 'Foo'
        @pdf.text 'Blah', :size => 11
        @pdf.text 'Blaz'
      end
      text = observer(TextObserver)
      text.font_settings[0][:size].should == 16
      text.font_settings[1][:size].should == 11
      text.font_settings[2][:size].should == 16
   end
      
   it "should allow registering of built-in font_settings on the fly" do
     @pdf.font "Courier"
     @pdf.text "Blah", :at => [100,100]
     @pdf.font "Times-Roman"                    
     @pdf.text "Blaz", :at => [150,150]
     text = observer(TextObserver) 
            
     text.font_settings[0][:name].should == :Courier
     text.font_settings[1][:name].should == :"Times-Roman"
   end   

   it "should utilise the same default font across multiple pages" do
     @pdf.text "Blah", :at => [100,100]
     @pdf.start_new_page
     @pdf.text "Blaz", :at => [150,150]
     text = observer(FontObserver)

     text.page_fonts.size.should eql(2)
     text.page_fonts[0][0].should eql(:Helvetica)
     text.page_fonts[1][0].should eql(:Helvetica)
   end
   
   it "should raise an exception when an unknown font is used" do
     lambda { @pdf.font "Pao bu" }.should raise_error(Prawn::Errors::UnknownFont)
   end

end
