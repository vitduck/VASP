#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use VASP::TBdyn::Gradient; 
use VASP::TBdyn::Report; 

my ( $cc, $z_12, $z_12xlGkT, $z_12xEpot );
my ( $gradient, $avg_gradient ); 

read_report       ( \$cc, \$z_12, \$z_12xlGkT, \$z_12xEpot ); 
get_gradient      ( \$z_12, \$z_12xlGkT, \$gradient ); 
get_avg_gradient  ( \$z_12, \$z_12xlGkT, \$avg_gradient ); 
write_avg_gradient( \$gradient, \$avg_gradient => 'gradient.dat' ); 
plot_avg_gradient ( \$cc, \$gradient, \$avg_gradient ); 
