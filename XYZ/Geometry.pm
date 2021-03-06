package XYZ::Geometry;  

use Moose::Role; 
use MooseX::Types::Moose 'Int';

use namespace::autoclean; 
use experimental qw( signatures );  

with 'General::Geometry'; 

has 'total_natom', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    reader   => 'get_total_natom', 
    builder  => '_build_total_natom'
); 

sub _build_comment ( $self ) { 
    return $self->_get_cached( 'comment' ) 
}

sub _build_atom ( $self ) { 
    return $self->_get_cached( 'atom' ) 
} 

sub _build_coordinate ( $self ) { 
    return $self->_get_cached( 'coordinate' ) 
} 

sub _build_lattice ( $self ) { 
    return [ 
        [ 15.0, 0.00, 0.00 ], 
        [ 0.00, 15.0, 0.00 ], 
        [ 0.00, 0.00, 15.0 ]
    ]
}

sub _build_total_natom ( $self ) { 
    return $self->_get_cached( 'total_natom' )
} 

1
