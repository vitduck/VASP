package VASP::KPOINTS; 

use Try::Tiny; 
use List::Util qw( product );  

use Moose;  
use MooseX::Types::Moose qw( Str Int ArrayRef );  
use IO::KISS; 

use namespace::autoclean; 
use feature qw( switch );  
use experimental qw( signatures smartmatch );  

with qw/IO::Reader IO::Cache/;  

has 'file', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 
    init_arg => undef, 
    default  => 'KPOINTS' 
); 

has 'comment', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_comment' 
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_mode' 
);  

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_scheme' 
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef[ Int ], 
    traits   => [ 'Array' ], 
    lazy     => 1, 
    builder  => '_build_grid', 
    handles  => { 
        get_grids => 'elements' 
    } 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => ArrayRef[ Str ], 
    traits   => [ 'Array' ], 
    lazy     => 1, 
    builder  => '_build_shift', 
    handles  => { 
        get_shifts => 'elements' 
    } 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_nkpt', 
); 

sub BUILD ( $self, @ ) { 
    try { $self->cache } 
} 

# from IO::Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( input => $self->file, mode  => 'r', chomp => 1 ) 
}

# from IO::Cache
sub _build_cache ( $self ) { 
    my %kp = ();  
    
    $kp{comment} = $self->get_line;   
    $kp{mode}    = $self->get_line;   
    $kp{scheme}  = ( $self->get_line ) =~ /^M/ ? 'Monkhorst-Pack' : 'Gamma-centered';
    
    given ( $kp{mode } ) {   
        when ( 0 )      { $kp{grid} = [ map int, map split, $self->get_line ] }
        when ( $_ > 0 ) { push $kp{grid}->@*, [ ( split )[0,1,2] ] for $self->get_lines } 
    }
    
    $kp{shift} = [ map split, $self->get_line ] if $kp{mode} == 0; 

    $self->close_reader;  

    return \%kp; 
} 

# parse cached KPOINTS 
sub _build_comment ( $self ) { return $self->read( 'comment ') } 
sub _build_mode    ( $self ) { return $self->read( 'mode' )    }
sub _build_scheme  ( $self ) { return $self->read( 'scheme' )  }
sub _build_grid    ( $self ) { return $self->read( 'grid' )    }   
sub _build_shift   ( $self ) { return $self->read( 'shift' )   }

# total number of kpoints 
sub _build_nkpt ( $self ) { 
    return 
        $self->mode == 0 ? 
        product($self->get_grids) : 
        $self->mode 
}

__PACKAGE__->meta->make_immutable;

1 
