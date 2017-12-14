require 'sinatra'
require 'haml' #now in gemfile?
require 'sass'

enable :logging, :dump_errors, :raise_errors, :sessions

set :fields , [
  [:cols,"Columns", 8],
  [:rand_pos,"Pixels by which to randomize position",0],
  [:rand_size,"Pixels by which to randomize size"],
  #[:stroke,"Stroke width"] ,
  [:colors,"Colors per disc",4] ]

 
log = File.new("sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

#find local convert binary
def my_convert
  `which convert`.chomp
end

TARGET_WIDTH = 1500
THUMB_WIDTH = 600
TEMP_DIR = "tmp"

configure do
  #nah... set :public_folder, Proc.new { File.join(root, "static") }
  enable :sessions
end


#intent: show the status file to indicate the progress of the analysis
#Don't bother with this yet...our "THIN" webserver isn't multithreaded. :(
#might work in production... but I'm too lazy to try right now
get '/status' do
  'hello'
  #
  IO.read('tmp/status*') if (File.exists?('tmp/status*'));
end

get '/' do
  @fields = settings.fields
  #@fields = @fields
  haml :index
end

get '/style.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :style
end


#wipeout!
#nuke all our pix... use with care.
get '/clean' do
  `rm public/built/*`
end

post '/build' do
  
  start_time = Time.now
  #http://distilleryimage6.instagram.com/5a788d287a8811e1989612313815112c_7.jpg
  #http://s3.amazonaws.com/data.tumblr.com/tumblr_m157xeJQtL1qawpa6o1_1280.jpg?AWSAccessKeyId=AKIAI6WLSGT7Y3ET7ADQ&Expires=1333241957&Signature=lYJrtnEmWAx8xsLMfjLsSuRATc8%3D
  session[:url] = params[:url]
  
  temp_file = random_filename(5)

  upload(temp_file) unless(params[:file].to_s.empty?)
  #otherwise, download from the provided URL
  download(params[:url], temp_file) unless (params[:url].to_s.empty?)
  
  #make sure we're dealing w a jpg
  #my_ident = `which identify`
  
  #(w,h) = `#{my_ident}`.split(" ")[2].split("x")
  
  @new_w = params[:cols].to_i * params[:colors].to_i
  resize = "-resize #{@new_w}x"
  `convert #{temp_file} #{resize} -auto-orient #{temp_file}.jpg` #unless (params[:file].to_s.match(/.jpg$/i) or params[:url].to_s.match(/.jpg$/i))
  
  
  #NOTE!!!! NEED TO TWEAK SO RANDOM FILENAMES ARE GUARANTEED TO _NOT_ ALREADY EXIST
  #name = random_filename(10)    
  #just use timestamps...
  name = Time.now.to_i.to_s
  
  status_file = "public/status_#{name}.txt"
  
  
  svg = "public/built/#{name}.svg"
  jpg = "public/built/#{name}.jpg"
  thumb = svg.sub(".svg","_thumb.jpg")
  
  arg_string = ''
  settings.fields.each do |f|
    field_name = f[0]
    #TODO (make the below work)
    session[field_name] = params[field_name]
    arg_string += " --#{field_name} #{session[field_name]} "
    #--cols #{settings.fields[} --rand_size #{rand_size} --rand_pos #{rand_pos}  --colors '#{colors}' 
    #params += " --#{f[0]} #{session[f}
  end
  
  #session[:url] = params[:url]
  #cols = session[:cols] = params[:cols].to_i || 5
  #colors = session[:colors] = params[:colors].to_i || 3
  #rand_pos = session[:rand_pos] = params[:rand_pos].to_i || 0  
  #rand_size = session[:rand_size] = params[:rand_size].to_i || 0

  #orbify uploaded file to SVG
  #--resize 10 for preview...
  
  puts arg_string
  
  puts `ruby gen.rb --verbose --target_width #{TARGET_WIDTH} #{arg_string} --status_file #{status_file} --margin #{TARGET_WIDTH * 5 / 100} '#{temp_file}.jpg' '#{svg}'`
  
  #remove uploaded file
  `rm #{temp_file}`
  `rm #{temp_file}.jpg` #remove jpg file if we made one...
  
  #remove status file
  `rm #{status_file}`
  
  #convert SVG to JPG... keep both copies
  #{}`#{my_convert} #{svg} #{jpg}`
  
  #make a thumbnail
  `#{my_convert} -resize #{THUMB_WIDTH}x #{svg} #{thumb}`
  
  #now show us the new JPG
  @img = thumb.sub!('public','')
  
  @duration = (Time.now - start_time).to_i
  haml :show
end

get '/style.css' do
  sass :style
end

#not_found do
#  redirect "/"
#end


def upload(out_file)
  unless params[:file] &&
         (tmpfile = params[:file][:tempfile]) &&
         (name = params[:file][:filename])
         
    @error = "Bugger! No file selected"
    return haml(:index)
  end

  #write to it in chunks
  while blk = tmpfile.read(65536)
     File.open(out_file, "ab") { |f| f.write(blk) }
    STDERR.puts blk.inspect
  end
  out_file
end


def download url, out_file
  require 'open-uri'
  writeOut = open(out_file, "wb")
  writeOut.write(open(url).read)
  writeOut.close
end


def random_filename(size)
  name = rand(36**size).to_s(36)
  while(File.exists? "#{TEMP_DIR}/#{name}") do
    name = rand(36**size).to_s(36)
  end
  #return name
  "#{TEMP_DIR}/#{name}"
end


#mix-in to convert an array to a hash
class Array
  def to_h(keys)
    Hash[*keys.flatten]
  end
end

helpers do
#helpers go here.
end