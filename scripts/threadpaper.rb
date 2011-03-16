#!/usr/bin/env ruby
#
#  threadpaper -- make wallpaper from a Threadless sample image
#
#  by Rich Lafferty <rich@lafferty.ca> -- released into the public
#  domain on December 21, 2005.
#
#  default filename changed to shirt-title - joshua@cpan.org 23 Oct 2006
#
#  ported to ruby - ymendel@pobox.com 13 Jul 2009

require 'rubygems'
require 'rmagick'
require 'optparse'
require 'net/http'

# use strict;
# use LWP::Simple qw(getstore);
# use Image::Magick;
# use Getopt::Long;
# use File::Basename;
# # use Smart::Comments;

logo = "./threadless-logo.png";
tmp = "/tmp";

# Image::Magick::Histogram's returned color values are the true color
# multiplied by this magic number:
hist_magic = 257;

ENV['PATH'] = '/usr/bin:/bin:/usr/local/bin';
ENV['BASH_ENV'] = '';


#------------------------------------------------------------------------
# get and verify arguments

OPTIONS = { :width => 1440, :height => 900, :scale => 100, :place => 'SouthEast' }

parser = OptionParser.new do |opts|
  opts.banner = <<BANNER
Usage: #{File.basename($0)} [options] [threadless-url]

Options are:
BANNER

  opts.separator ''
  opts.on('-w', '--width=WIDTH',
          "width of wallpaper (default: #{OPTIONS[:width]})")   { |width|   OPTIONS[:width] = width }
  opts.on('-h', '--height=HEIGHT',
          "height of wallpaper (default: #{OPTIONS[:height]})") { |height|  OPTIONS[:height] = height }
  opts.on('-c', '--center',
          'center image instead of lower corner') { |center|  OPTIONS[:place] = 'Center' }
  opts.on('-l', '--logo',
          'include color-matched Threadless logo') { |logo|  OPTIONS[:logo] = true }
  opts.on('-s', '--scale=PERCENT',
          'scale image by PERCENT') { |pct|  OPTIONS[:scale] = pct }
  opts.on('-f', '--file=FILENAME',
          'output filename', '(default: <shirt-title in lowercase>.png)') { |file|  OPTIONS[:file] = file }
  opts.on('--help',
          'Show this help message.') { puts opts; exit }

  opts.parse!(ARGV)
end

histfile = File.join(ENV['HOME'], '.threadpaper_history')
# write_history();

url = ARGV[0]
md = url.to_s.match(Regexp.new('^http://.*threadless.*/(\d+)/([^/]+)'))

unless md
  puts parser
  exit
end

num   = md[1]
title = md[2]

OPTIONS[:file] ||= "#{title}.png".downcase

[:width, :height].each do |dim|
  begin
    OPTIONS[dim] = Integer(OPTIONS[dim])
  rescue
    puts parser
    exit
  end
end
geometry = OPTIONS.values_at(:width, :height).collect { |x|  "#{x}!" }.join('x')

tmpfile = File.join(tmp, "th_orig_#{$$}.gif")
realurl = "http://media.threadless.com/product/#{num}/zoom.gif";

File.open(tmpfile, 'w') do |f|
  f.print Net::HTTP.get(URI.parse(realurl))
end

orig = Magick::Image.read(tmpfile).first
File.unlink(tmpfile)
orig.resize!(OPTIONS[:scale]/100.0) unless OPTIONS[:scale] == 100

bg = orig.clone
bg.crop!(0,0,1,1)
bg.resize!(OPTIONS[:width], OPTIONS[:height])
bg.composite!(orig, Magick.const_get("#{OPTIONS[:place]}Gravity"), Magick::CopyCompositeOp)

bg.write(OPTIONS[:file])

exit

# # add logo
# 
# if ($do_logo)
# {
#   
#   ### Adding logo
#   
#     my $lo = Image::Magick->new;
#     $lo->read($logo);
# 
#     my @bghist   = gethist($bg);
#     my $bgcolor = hist2rgb($bghist[0]);
# 
#     my @orighist = gethist($orig);
#     my $color0 = hist2rgb($orighist[0]);
#     my $color1 = hist2rgb($orighist[1]);
# 
#     my $logocolor = $bgcolor eq $color0 ? $color1 : $color0;
# 
#     $lo->Opaque( color => "rgb(0,0,0)", fill => $logocolor );
#     $lo->Resize( geometry => "100x" );
#     $bg->Composite( image => $lo, gravity => "southeast");
# }
# 
# sub gethist
# {
#     my $im = shift;
#     my @h = $im->Histogram();
#     
#     # The returned values are an array of red, green, blue, opacity, and
#     # count values [all shoved into one long array].
#     my @hist;
# 
#     push @hist, [splice(@h, 0, 5)] while @h;
#     
#     return reverse sort { $a->[4] <=> $b->[4] } @hist;    
# }
# 
# sub hist2rgb
# {
#     my $hist = shift;
#     return sprintf("rgb(%d,%d,%d)", $hist->[0] / $hist_magic,
#                                     $hist->[1] / $hist_magic,
#                                     $hist->[2] / $hist_magic);
# }
#
# sub write_history
# {
#   my $binary = basename $0;
#   
#   open  LOG, ">> $histfile" or die "Can't open $histfile: $!";
#   print LOG "$binary @ARGV\n";
#   close LOG;
# }
