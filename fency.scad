$fn= 32;

function mm(x) = x;
function cm(x) = mm(x) * 10;

NOZZLE = mm(0.4);
X_AXIS = [1,0,0];
Y_AXIS = [0,1,0];
Z_AXIS = [0,0,1];

fence_height               = mm(12.0);
fence_length               = cm(30.0);
fence_top_bar_height       = 3 * NOZZLE;
fence_top_bar_thickness    = mm(1.0);
fence_spoke_width          = 2 * NOZZLE;
fence_spoke_thickness      = mm(0.6);
fence_spoke_distance       = mm(3.0);
fence_bottom_bar_height    = 5 * NOZZLE;
fence_bottom_bar_thickness = mm(1.0);

plug_diameter              = mm(3.1);
plug_clearance             = mm(0.1);
plug_rim_pos               = mm(1.0);
plug_length                = mm(6.0);
plug_cross_thickness       = 2 * NOZZLE;
plug_bevel_r               = mm(0.5);
plug_bevel_l               = mm(1.5);
number_of_plugs            = 5;

baring_diameter            = mm(7.9);
baring_height              = mm(4.0);

needle_diameter            = mm(0.6);
needle_wall                = 4 * NOZZLE;

number_of_spokes  = floor((fence_length - fence_spoke_width) / fence_spoke_distance) + 1;
left_most_spoke_x = -(number_of_spokes - 1) / 2 * fence_spoke_distance;
plug_off_center =  sin(30) * (plug_diameter / 2) + cos(30) * (plug_cross_thickness/2);

help = undef;
part = "FenceWithPlugs";

if(help != undef) {
    echo("Parts:");
}
Part("FenceWithPlugs")   FenceWithPlugs();
Part("PlugDrillFixture") PlugDrillFixture();

module Part(name) {
    if(help != undef) {
        echo(str("- ", name));
    } else {
        if(part == name) {
            children();
        }
    }
}

module PlugDrillFixture() {
    linear_extrude(baring_height) {
        difference() {
            Outer();
            Barings();
        }
    }

    module Barings() {
        distribute_plugs() Baring();
        module Baring() {
            translate([0, plug_off_center]) {
                circle(d = baring_diameter);
            }
            copy_mirror(X_AXIS) {
                translate([
                    baring_diameter/2 + needle_diameter / 2 + needle_wall, 
                    fence_bottom_bar_thickness/2
                ]) {
                    circle(d=needle_diameter);
                }
            }
        }
    }
}

module Outer() {
    distribute_plugs() OuterEye();
    Fence();
    
    module Fence() {
        translate([-fence_length/2, 0]) {
            square([fence_length, fence_bottom_bar_thickness]);
        }
    }
    module OuterEye() {
        k1 = baring_diameter / 120;
        points = concat(
            [for(a=[-180:15:180]) [
                a * k1, 
                (cos(a) * .5 + .5) * (baring_diameter / 2 + plug_off_center) + fence_bottom_bar_thickness]
            ], [for(a=[180:-15:-180]) [
                a * k1, 
                -((cos(a) + 1) / 2 * baring_diameter / 2)]
            ]

        );
        polygon(points);
    }
}

module FenceWithPlugs() {
    Fence();
    Plugs();
}

module Fence() {
    BottomBar();
    TopBar();
    Spokes();

    module BottomBar() {
        linear_extrude(fence_bottom_bar_thickness) {
            translate([-fence_length / 2, 0]) {
                square([fence_length, fence_bottom_bar_height]);
            }
        }
    }
    module TopBar() {
        linear_extrude(fence_top_bar_thickness) {
            translate([-fence_length / 2, fence_height - fence_top_bar_height]) {
                square([fence_length, fence_top_bar_height]);
            }
        }
    }
    module Spokes() {
        distribute_spokes() Spoke();
        
        module Spoke() {
            linear_extrude(fence_spoke_thickness) {
                translate([-fence_spoke_width/2, 0]) {
                    square([fence_spoke_width, fence_height]);
                }
            }
        }
    }
}

module Plugs() {
    distribute_plugs() render() Plug();

    module Plug() {

        translate([0,0,plug_off_center]) {
            PlugBottom();
        }
        Pole();

        module Pole() {
            linear_extrude(fence_top_bar_thickness) {
                translate([-fence_top_bar_height / 2, 0]) {
                    square([fence_top_bar_height, fence_height]);
                }
            }
            rotate(-90, Y_AXIS) {
                linear_extrude(fence_top_bar_height, center=true) {
                    polygon([
                        [0,0],
                        [0, fence_bottom_bar_height],
                        [fence_bottom_bar_thickness, fence_bottom_bar_height],
                        [fence_bottom_bar_thickness + fence_bottom_bar_height/3*2, 0],
                    ]);
                }
                linear_extrude(plug_diameter, center=true) {
                    polygon([
                        [0,0],
                        [0, fence_bottom_bar_height],
                        [fence_bottom_bar_thickness, fence_bottom_bar_height/3],
                        [fence_bottom_bar_thickness + fence_bottom_bar_height/9*2, 0],
                    ]);
                }
            }
        }

        module PlugBottom() {
            rotate(90, X_AXIS) {
                intersection() {
                    TrianglePlug();
                    BeveledPlug();
                }
            }
            Cap();
            
            module Cap() {
                rotate(90, X_AXIS) {
                    intersection() {
                        union() {
                            translate([0,0, plug_rim_pos]) copy_mirror(Z_AXIS) {                            
                                cylinder(
                                    d1=plug_diameter - 2 * plug_clearance,
                                    d2= plug_diameter/2,
                                    h = plug_length - plug_rim_pos);
                            }
                        }
                        translate([0,plug_diameter/2-plug_off_center,plug_length/2]) {
                            cube([plug_diameter, plug_diameter, plug_length], true);
                        }
                    }
                }
            }
            module TrianglePlug() {
                linear_extrude(plug_length) {
                    hull() {
                        for (a=[0:120:359]) rotate(a) {
                            intersection() {
                                translate([-plug_cross_thickness/2,0]) {
                                    square([plug_cross_thickness, plug_diameter / 2]);
                                }
                                circle(d=plug_diameter);
                            }
                        }
                    }
                }
            }
            module BeveledPlug() {
                rotate_extrude() {
                    hull() {
                        square([plug_diameter / 2, plug_length - plug_bevel_l]);
                        square([plug_diameter / 2 - plug_bevel_r    , plug_length]);
                    }
                }
            }
        }
    }
}

module distribute_plugs() {
    spokes_per_plug = round(number_of_spokes / number_of_plugs);
    for (i=[floor(spokes_per_plug/2):spokes_per_plug:number_of_spokes-1]) {
        x = left_most_spoke_x + i * fence_spoke_distance;
        translate([x, 0]) children();
    }
}

module distribute_spokes() {
    for (i=[0:number_of_spokes-1]) {
        x = left_most_spoke_x + i * fence_spoke_distance;
        translate([x, 0]) children();
    }
}

module copy_rotate(a, vec=undef) {
    children();
    rotate(a, vec) children();
}

module copy_mirror(a, vec=undef) {
    children();
    mirror(a, vec) children();
}
