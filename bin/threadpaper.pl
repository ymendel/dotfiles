#!/usr/bin/env perl -wT
#
#  threadpaper -- make wallpaper from a Threadless sample image
#
#  by Rich Lafferty <rich@lafferty.ca> -- released into the public
#  domain on December 21, 2005.
#
#  default filename changed to shirt-title - joshua@cpan.org 23 Oct 2006
#

use strict;
use LWP::Simple qw(getstore);
use Image::Magick;
use Getopt::Long;
use File::Basename;
# use Smart::Comments;

my $logo = "./threadless-logo.png";
my $tmp = "/tmp";

# Image::Magick::Histogram's returned color values are the true color
# multiplied by this magic number:
my $hist_magic = 257;

$ENV{PATH} = '/usr/bin:/bin:/usr/local/bin';
$ENV{BASH_ENV} = '';


#------------------------------------------------------------------------
# get and verify arguments

my $width = 1920;
my $height = 1200;
my $center;
my $do_logo;
my $scale = 100;
my $outfile;
my $histfile = "$ENV{HOME}/.threadpaper_history";

($histfile) = $histfile =~ m{^([/\w+.]+)$}; # detaint
write_history();

GetOptions ("width=i"   => \$width,
            "height=i"  => \$height,
            "center"    => \$center,
            "centre"    => \$center,
            "logo"      => \$do_logo,
            "scale=i"   => \$scale,
            "file=s"    => \$outfile ) or die usage();

my $type = $center ? 'center' : 'southeast';

usage() unless @ARGV;
my $url = $ARGV[0];

usage() unless $url =~ m|^http://.*threadless.*/(\d+)/([^/]+)|;

my $num = $1;
my $title = $2;

$outfile = "\L$title.png" unless $outfile;

usage() unless $width =~ /^(\d+)$/; 
$width = $1;
usage() unless $height =~ /^(\d+)$/;
$height = $1;
my $geometry = "${width}!x${height}!";

#------------------------------------------------------------------------
# retrieve image from Threadless

my $file = "$tmp/th_orig_$$.gif";
my $realurl = "http://media.threadless.com/product/$num/zoom.gif";
getstore($realurl, $file) or die "Can't get $url\n"; ### Downloading

my $orig = Image::Magick->new;
$orig->Read($file);
unlink($file);

$orig->Resize( geometry => "${scale}%" ) if $scale != 100; ### Resizing

#------------------------------------------------------------------------
# prepare background

### Building new background

my $bg = $orig->Clone();
$bg->Crop(   geometry => '1x1+0+0' );
$bg->Resize( geometry => $geometry );
$bg->Composite( image => $orig, gravity => $type );

#------------------------------------------------------------------------
# add logo

if ($do_logo)
{
	
	### Adding logo
	
    my $lo = Image::Magick->new;
    $lo->read($logo);

    my @bghist   = gethist($bg);
    my $bgcolor = hist2rgb($bghist[0]);

    my @orighist = gethist($orig);
    my $color0 = hist2rgb($orighist[0]);
    my $color1 = hist2rgb($orighist[1]);

    my $logocolor = $bgcolor eq $color0 ? $color1 : $color0;

    $lo->Opaque( color => "rgb(0,0,0)", fill => $logocolor );
    $lo->Resize( geometry => "100x" );
    $bg->Composite( image => $lo, gravity => "southeast");
}

#------------------------------------------------------------------------
# finish

$bg->Write($outfile); ### Writing file
exit 0;

#------------------------------------------------------------------------
# Subs

sub gethist
{
    my $im = shift;
    my @h = $im->Histogram();
    
    # The returned values are an array of red, green, blue, opacity, and
    # count values [all shoved into one long array].
    my @hist;

    push @hist, [splice(@h, 0, 5)] while @h;
    
    return reverse sort { $a->[4] <=> $b->[4] } @hist;    
}

sub hist2rgb
{
    my $hist = shift;
    return sprintf("rgb(%d,%d,%d)", $hist->[0] / $hist_magic,
                                    $hist->[1] / $hist_magic,
                                    $hist->[2] / $hist_magic);
}

sub usage
{
    warn "Usage: $0 [options] [threadless-url]\n";
    warn "\n";
    warn "\t--width WIDTH    width of wallpaper (default: $width)\n";
    warn "\t--height HEIGHT  height of wallpaper (default: $height)\n";
    warn "\t--center         center image instead of lower corner\n";
    warn "\t--logo           include color-matched Threadless logo\n";
    warn "\t--scale PERCENT  scale image by PERCENT\n";
    warn "\t--file FILENAME  output filename\n";
    die "\t                      (default: <shirt-title in lowercase>.png)\n";
}

sub write_history
{
	my $binary = basename $0;
	
	open  LOG, ">> $histfile" or die "Can't open $histfile: $!";
	print LOG "$binary @ARGV\n";
	close LOG;
}
