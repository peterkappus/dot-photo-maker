#setup
load './lib.rb'
require 'optparse'
options = {}

@target_width = 1800
@cols = 10
@colors = 4 #max colors per dot
@max_rad = (@target_width-(@margin  * 2))/@cols
@percent_of_box = 0.90
@debug = false
@rand_size = 0
@rand_pos = 0
@background="fff"

def get_dimensions(file)
  `#{my_identify} -format "%w %h" \"#{file}\"`.split(" ").map{|i| i.to_i}  
end

#find local binaries...
def my_convert 
  `which convert`.chomp
end
def my_identify 
  `which identify`.chomp
end


def orbify(in_file,col,row,box_width,box_height,margin,max_rad,max_colors=4,shape='circle',min_threshold=0.03)
    colors = Hash.new
    total = 0
    current_scale = 1
    last_scale = 0
    the_end = false

    #debug "orbifying #{col} x #{row}"
    result = `#{my_convert} \"#{in_file}[#{box_width}x#{box_height}+#{col*box_width}+#{row*box_height}]\" -colors #{max_colors} -depth 8 -format %c histogram:info: | sort -r`

    #split the result to make a hash of colors and amounts.
    result.split("\n").each do |line|
      #parse the output via regexp...  
      (blah,amount,color) = line.match(/(\d+): .+? #(\w{6})/).to_a
      colors[color] = amount.to_i  
      total += amount.to_i #add up the total pixels
    end

   # debug "Colors in #{in_file}: #{colors.count}"
    
    max_width = max_height = max_rad  * 2
  
    #randomize the total width & height of these
    if(@rand_size > 0)
      max_width *= 0.4 + rand(3)
      max_height *= 0.4 + rand(3)
    end
    
    #make a circle for each color in the hash (which should already be orderd by largest to smallest)
    last_scale = 0
    current_scale = 1   * @percent_of_box
    colors.each do |color,amount|
      #determine the size
      scale = amount/total.to_f
      #debug "color:#{color} amount: #{amount}"
      if scale > min_threshold #ignore the super tiny stuff... this is usually anti-aliased pixels counted in our histogram

      #scale up our small items so they're more visible
      #  if(scale < min_threshold*1.2)
       #   scale = 0.15 
          #debug "making #{color} bigger! #{scale}"
        #  the_end = true #bail out after this one...
        #end

        #measure the radius by subtracting how big the previous radius was
        r = max_rad * (current_scale - last_scale) 
        w = max_rad * ((current_scale - last_scale).to_i  * 2) #rects only
        h = max_rad * ((current_scale - last_scale).to_i  * 2) #rects only
        
        current_scale -= last_scale
        
        #randomize!!!!!!
        r += -(@rand_size / 2) + (rand * @rand_size)
        h += -(@rand_size / 2) + (rand * @rand_size)
        w += -(@rand_size / 2) + (rand * @rand_size)
        #randomise poisition
        rand_x = -(@rand_pos / 2) + (rand * @rand_pos)
        rand_y = -(@rand_pos / 2) + (rand * @rand_pos)
        
        case shape
        when "rect"
          rect x-w / 2,y-h / 2,w,h,color, max_rad/30, '000'
        when "rand"
          rand_burst x,y,r,color
        else      
          circle margin + (col*max_rad  * 2)+max_rad + rand_x, margin + (row*max_rad  * 2)+max_rad + rand_y, r, color  
        end
        last_scale = scale
      end
    end
end


#
#read args/options from user
#possible options:
#  colors, cols, final_size, shape, dot_fill_percent, margin?
def parse_opts
  
  OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"
  
  #a way to build options that directly read into the global variable named after the command line switch  
  
    opt_builder=[
      ['cols','Number of Columns'],      
      #not yet... ['stroke_width','Stroke Width'],
      ['colors','Number of colors per dot'],
      ['margin','The margin...'],      
      ['verbose','Verbose mode','bool'],
      ['rand_size','Multiplier by which to randomize the size'],
      ['rand_pos','Multiplier by which to randomize the position'],      
      ['status_file','File to fill with status messages while rendering','String'],            
      ['background','Background color (hex)','String'],
      ['max_rad','Max radius for dots'],
      ['target_width','Target width of new image']
    ]
      
    opt_builder.each do |opt|
      var_name = opt[0]
      description = opt[1]
      case opt[2]
      when "bool"    
        opts.on("--#{var_name}",description) do 
          eval("@#{var_name} = true")
          debug "setting @#{var_name} to #{eval "@#{var_name}"}\n"
        end   
      when nil #assume integer when empty
         opts.on("--#{var_name} x",Integer,description) do |x|
            eval "@#{var_name} = x"
            debug "setting @#{var_name} to #{eval "@#{var_name}"}\n"
         end
      else #otherwise, use the type provided
        opts.on("--#{var_name} x",opt[2],description) do |x|
          eval "@#{var_name} = x"
          debug "setting @#{var_name} to #{eval "@#{var_name}"}\n"
        end
      end
    end
        
    #as a nicety...see: http://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces.html
    opts.on("-o","--output") do |o|
      out_file = o
    end

  end.parse!
end


start = Time.now
parse_opts
#convenience...cuz our lib uses "debug"
@debug = @verbose = true

file = ARGV[0]
abort "No input file specified" unless file
abort "Input file #{file} not found" unless File.exists?(file)
out_file = ARGV[1]

@margin = 0 if(@margin > @target_width / 2)
@max_rad = ((@target_width-(@margin  * 2))/@cols.ceil) / 2

#read image dimensions
(width,height) = get_dimensions(file)

#determine number of rows 
@rows = (@cols/width.to_f*height.to_f).ceil# * (height.to_f/width.to_f).ceil
#debug @rows
#read squares from image and generate SVG
box_width = (width/@cols.to_f).round(2)
box_height = (height/@rows.to_f).round(2)

#debug "#{width} x #{height}"
#debug "#{box_width} x #{box_height}"

@width = @target_width
@height = (@rows * @max_rad  * 2) + (@margin  * 2)
#exit

i=0
@cols.times do |c|
  @rows.times do |r|  
    i +=1
    #def orbify(in_file,col,row,box_width,box_height,margin,max_rad,max_colors=4,shape='circle',min_threshold=0.03)
    orbify file, c, r, box_width, box_height, @margin, @max_rad, @colors
    #if(@status_file && (i%((@cols*@rows/5).floor) == 0))
    if(@status_file)
      status = (i*100/(@cols*@rows)).to_i
      File.open(@status_file, 'w') {|f| f.write(status.to_s) } if(status % 10 == 0); #update every 10%
    end
  end
end

#Save SVG 
if(out_file)
  save_file out_file
else
  print build
end

debug "Rendered in: #{(Time.now.to_f - start.to_f).to_s} seconds."
#render to JPG if desired