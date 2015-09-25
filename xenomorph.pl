#!/usr/bin/env perl 

use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use List::Util; 
use Pod::Usage; 

use Gaussian qw( read_gaussian print_gaussian ); 
use GenUtil  qw( read_line file_format eps2png zenburnize set_boundary ); 
use Math     qw( mat_mul ); 
use VASP     qw( read_cell read_geometry print_poscar ); 
use XYZ      qw( read_xyz direct_to_cart set_pbc print_xyz ); 

my @usages = qw(NAME SYSNOPSIS OPTIONS NOTE); 

# POD 
=head1 NAME 
 
xenomorph.pl: file conversion

=head1 SYNOPSIS

xenomorph.pl [-h] [-i] <input> [-o] <output> [-r] CONTCAR -c 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

Source input file 

=item B<-o> 

Converted output file

=item B<-r> 

use POSCAR/CONTCAR for reference

=item B<-c> 

Center the geometry (default: no) 

=item B<-d> 

PBC shifting (default [1.0, 1.0. 1.0])

=item B<-b> 

Fix boundaries of eps (generated by gnuplot)

=item B<-q> 

Quality of JPEG/MIFF/PNG compression

=item B<-z> 

With sufficient thrust, pig fly just fine

=back

=head1 NOTE 

File conversion 

POSCAR => xyz, com (g03) 

xyz    => POSCAR, com (g03) 

com    => POSCAR, xyz 

eps    => png 

=cut

# default optional arguments 
my $help     = 0;
my $input    = ''; 
my $output   = ''; 
my $boundary = 0;  
my $zenburn  = 0; 
my $quality  = 150; 
my @dxyz     = (1.0, 1.0, 1.0); 

# available operation 
my @eps_transform = (); 

# converision table 
my %conversion = ( 
    POSCAR => [ qw( xyz com gif ) ], 
    xyz    => [ qw( POSCAR com gif ) ], 
    com    => [ qw( POSCAR xyz ) ], 
    gif    => [ qw( POSCAR xyz ) ], 
    eps    => [ qw( png ) ], 
), 

# -------------------------#
# default POSCAR parametes #
# -------------------------#
my $lat      = [ 
    [ 20.0, 0.00, 0.00 ], 
    [ 0.00, 20.0, 0.00 ], 
    [ 0.00, 0.00, 20.0 ], 
]; 
my $scaling  = 1.0; 
my $dynamics = 0; 
my $type     = 'Direct'; 

# ----------------------------#
# gaussian default parameters #
# ----------------------------#
my $option   = ['%chk=file.chk']; 
my $theory   = '# hf/3-21g'; 
my $title    = 'Structure'; 
my $charge   = 0; 
my $spin     = 1; 

#----------------#
# xyz parameters #
#----------------#
my $comment = ''; 

#----------#
# geometry #
#----------# 
my ($atom, $natom, $geometry); 

# defaul behavior
if ( @ARGV == 0 ) { pod2usage(-verbose => 99) }; 

# parse optional arguments 
GetOptions(
    'h'    => \$help, 
    'i=s'  => \$input, 
    'o=s'  => \$output,
    'q=i'  => \$quality, 
    'r=s'  => sub { 
        # use reference cell parameters
        my ($opt, $arg) = @_; 
        my $line = read_line($arg); 
        ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($line); 
    }, 
    'c'    => sub { 
        @dxyz = (0.5, 0.5, 0.5); 
    },
    'd=f{3}'    => sub { 
        my ($opt, $arg) = @_; 
        shift @dxyz; 
        push @dxyz, $arg;  
    }, 
    'b'    => sub { push @eps_transform, \&set_boundary },  
    'z'    => sub { push @eps_transform, \&zenburnizz }, 
) or pod2usage(-verbose => 1); 

# default output 
if ( $help ) { pod2usage(-verbose => 99) }; 

# check legitimate conversion 
my $iformat = file_format($input); 
my $oformat = file_format($output); 
unless ( grep { $oformat =~ /$_/ } @{$conversion{$iformat}} ) { 
    die "=> What are you doing ???\n"; 
}

# parse input
my $line = ( $iformat =~ /com|gif/ ) ? read_line($input, 'slurp') : read_line($input);  

# quite messy wait to emulate C-style switch
INPUT: { 
    $iformat =~ /POSCAR/ && do { 
        ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($line); 
        $geometry = read_geometry($line); 
        # dealing with direct coordinate (quick fix)
        if ( $type =~ /direct/i ) { 
            # set PBC 
            set_pbc($geometry, \@dxyz); 
            # direct to cart 
            $geometry = mat_mul($geometry, $lat); 
        }
    }; 

    $iformat =~ /com|gif/ && do { 
        ($option, $theory, $title, $charge, $spin, $atom, $natom, $geometry) = read_gaussian($line); 
    }; 

    $iformat =~ /xyz/ && do { 
        ($comment, $atom, $natom, $geometry) = read_xyz($line); 
    }; 

    $iformat =~ /eps/ && do { 
        # performs eps transformation
        for ( @eps_transform ) {  $_->($input) }
    }
}

# output fh 
my $fh = IO::File->new($output, 'w'); 

OUTPUT: { 
    $oformat =~ /POSCAR/ && do { 
        # force scaling, dynamics and type
        print_poscar($fh, $title, 1.0, $lat, $atom, $natom, 0, 'Cartesian', $geometry); 
    }; 

    $oformat =~ /com|gif/ && do { 
        print_gaussian($fh, $option, $theory, $title, 0, 1, $atom, $natom, $geometry);  
    }; 

    $oformat =~ /xyz/ && do { 
        print_xyz($fh, $comment, $atom, $natom, $geometry); 
    }; 

    $oformat =~ /png/ && do { 
        eps2png($input, $output, $quality); 
    }; 
}

# flush 
$fh->close; 
