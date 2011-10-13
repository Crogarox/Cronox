package Cronox::Util;
use strict;
use warnings;
use Carp ();
use POSIX ();
use File::Spec ();
use File::Basename ();
use Path::Class ();
use Cwd ();

use Exporter qw(import);
our @EXPORT      = qw(path_to script_name script_path parse_command parse_script_name now);
our @EXPORT_OK   = qw(home);
our %EXPORT_TAGS = (
    default => [ @EXPORT ],
    all     => [ @EXPORT, @EXPORT_OK ],
);

our $HOME;

BEGIN {
    my $class = __PACKAGE__;

    ( my $file = "$class.pm" ) =~ s{::}{/}g;
    if ( my $inc_entry = $INC{$file} ) {
        ( my $path = $inc_entry ) =~ s/$file$//;
        my $dir = Path::Class::dir($path)->absolute->cleanup;

        $dir = $dir->parent while $dir =~ /b?lib$/;
        if (-d $dir) {
            $HOME = $dir->stringify;
            return;
        }
    }
    Carp::croak( sprintf( "Can't create %s instance.", __PACKAGE__ ) );
};

sub home { $HOME }

sub path_to {
    my @path = (defined $_[0])
        ? ( ( index($_[0], '/') eq 0 ) ? @_ : ($HOME, @_) )
        : $HOME;
    my $file = File::Spec->catfile( @path );
    return -f $file ? $file : File::Spec->catdir( @path );
}

sub script_name {
    my $cmd = $_[0]->[0];
    my $abs_path = Cwd::abs_path($cmd);
    (-f $abs_path) ? File::Basename::basename($abs_path) : ""
}

sub script_path {
    my $cmd = $_[0]->[0];
    my $abs_path = Cwd::abs_path($cmd);
    (-f $abs_path) ? File::Basename::dirname($abs_path) : ""
}

sub parse_command {
    my $cmd = $_[0]->[0];
    (split(/\s+/, $cmd))[0];
}

sub parse_script_name {
    my $cmd = $_[0]->[0];
    $cmd = (split(/\s+/, $cmd))[0];
    my $abs_path = Cwd::abs_path($cmd);
    (-f $abs_path) ? File::Basename::basename($abs_path) : ""
}

sub now {
    ( $_[0] && $_[0] eq 'ymd' )
      ? POSIX::strftime( '%Y%m%d',      localtime )
      : POSIX::strftime( '%Y-%m-%d %T', localtime );
}

1;
