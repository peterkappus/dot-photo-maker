#version 1.0

# revision history
# 1.0 added stroke opacity
# 1.1 Added Polygon & draw_border methods
# 1.2 Added "read_image" and "image" methods

#include this file (include './lib.rb') and use the functions below...
#add SVG to the @yield variable then call "output" when you're done

#NOTE: set the @height & @width as desired

  @height = 800
  @width = @height * 2 #@height * 1.618 # golden ratio, yo!
  @margin = @width/20
  @priority = 6 
  @background = "222"

  @yield = ""
  @myconvert = `which convert`.chomp

#shouldn't need this...
#as long as nice is found, we don't care which one we're using
#@mynice = `which nice`

#generate a random hex color value
def rand_color
  "%06x" % (rand * 0xffffff)
end

def read_image(infile)
  image = MiniMagick::Image.open infile

  width = image[:width]
  height = image[:height]
  return [width,height]
  
end

def image(infile)
  width, height = read_image(infile)
  @yield += %Q^ <image width="#{width}px" height="#{height}px" xlink:href="#{infile}"/>^
end

def curve(x,y,x2,y2,x3,y3,stroke_color=rand_color,thickness=3)
  @yield += %Q^<path d="M #{x} #{y} q #{x2} #{y2} #{x3} #{y3}" fill="none" stroke="##{stroke_color}" stroke-width="#{thickness}" />\n^
end

def polygon(points,color="000",stroke_width=0,stroke_color="000",opacity = 1)
  point_str = ""
  points.each_slice(2).to_a.map{|point| point_str += "#{point[0]},#{point[1]} "}
  stroke = "stroke:##{stroke_color};stroke-width:#{stroke_width}" if stroke_width > 0
  @yield += %Q^<polygon points="#{point_str}" style="fill:##{color};#{stroke}; " fill-opacity="#{opacity}"/>\n^
end

#make an SVG circle
def circle(x,y,radius,color=rand_color,stroke_width=0,stroke_color="000") 
  #break out the stroke because imagemagick doesn't correctly ignore a stroke with width of "0"
  #so it's best to leave out all mention of stroke unless we actually want one
  stroke = %Q^stroke-width="#{stroke_width}" stroke="##{stroke_color}"^ if(stroke_width > 0)
  @yield += %Q^<circle fill="##{color}" #{stroke} cx="#{x}" cy="#{y}" r="#{radius}"/>\n^
end

#make a rectangle
def rect(x,y,w,h,color,stroke_width=0,stroke_color="000",opacity=1,stroke_opacity=1)
  #specify opacity AFTER stroke color... see: http://www.imagemagick.org/discourse-server/viewtopic.php?f=3&t=10594
  if(stroke_width > 0)
    stroke = %Q^stroke-width="#{stroke_width}"  stroke="##{stroke_color}" stroke-opacity="#{stroke_opacity}"^ 
  else
    stroke = %Q^ stroke="none" ^
  end
  opacity_str = " opacity=\"#{opacity}\" " if opacity < 1
  @yield += %Q^<rect x="#{x}" y="#{y}" fill="##{color}" #{opacity_str} #{stroke} width="#{w}" height="#{h}"/>\n^
end

#wrap our @yield in an SVG doc
def build
  #originally had this in an ERB file but refactored so I can put everything in one file
    out = %Q^<?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
      <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
      	 width="#{@width}px" height="#{@height}px" viewBox="0 0 #{@width} #{@height}" enable-background="new 0 0  #{@width} #{@height}" xml:space="preserve">
      <desc>Awesomeness by Peter</desc>
      <rect x="0" y="0" fill="##{@background}" width="#{@width}" height="#{@height}"/>
      ^

      out += %Q^#{@yield}</svg>^
end

#save the file (remember to include the SVG extension)
def save_file(name)
  #first save SVG
  name += ".svg" unless name.match(/svg$/)
  File.open(name, "w") do |file|
    file.write build
  end
  
  #convert to JPG and delete the SVG doc
  if(name.match(/jpg|png/))
    #puts "converting..."
    system("nice -n #{@priority} #{@myconvert} -quality 95 #{name} #{name.sub('.svg','')}")
    #system("rm #{name}")    
  end
end

def draw_border
  #black out around margin
  rect 0,0,@width,@margin, @background
  rect 0,0,@margin,@height, @background
  rect @width-@margin,0,@margin,@height, @background
  rect 0,@height-@margin,@width,@margin, @background
end

#alias for 'puts' but could be customised later
def debug(msg)
  puts msg if @debug
end

def alert
  `echo -ne '\007'` #terminal bell
end

#add text to the image
def label(words, x,y,size=12, color="fff", font_family="Helvetica", font_style="normal")
    @yield += %Q!<text x="#{x}" y="#{y}" font-family="#{font_family}" font-style="#{font_style}" font-size="#{size}px" fill="##{color}">#{words}</text>\n!
end

def signature(color="fff")
  label "PETER KAPPUS", @margin, @height-(@margin*0.8),@margin/4,color
end
