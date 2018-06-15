/*
 * xcarriage.scad
 * v1.0.1 24th May 2016
 * Written by landie @ Thingiverse (Dave White)
 *
 * This script is licensed under the Creative Commons - Attribution license.
 *
 * http://www.thingiverse.com/thing:1585254
 *
 * Original design based on the Prusa Rework .stl file thing # 119616
 *
 * The three parameters below determine the number of bearings per axle (1 or 2) and the
 * use or not of the "geetech cutout" which allows room for the X tensioner pulley on the
 * Geetech Prusa i3 and possibly others. Aimed at maximising the available x travel.
 * The final setting adds a square corner to the top left to aid in hitting the x-axis end stop
 * which was causing a problem on my Geetech Prusa i3
 */


//Number of bearings per axle (1 or 2)
axle_bearings = 2;

// Should we use the geetech prusa i3 x axis tensioner cutout ? (true or false)
geetech_cutout = false;

// Should the top left corner be square ? (Geetech Prusa i3 x end stop is a bit high and squaring the corner gives a better contact)
square_endstop = false;

// Define curve smoothing (50 is good, anywhere between 20 and 100 will work with 100 being the smoothest)
$fn = 50;

// You should only edit anything below here if you have an idea what you are doing ! :)

// Variables for the main block
carriage_width = 56;
carriage_height = 68;
carriage_corner_radius = 5;
carriage_block_depth = 5;

// Variables for the two bearing blocks
bearing_block_height = 25.75;
bearing_block_depth = 7;
bearing_block_corner_radius = 5;

// Variables for the two belt clamps
belt_clamp_height = 9.5;
belt_clamp_width = 23;
belt_clamp_chamfer = 2;
belt_clamp_depth = 9;
belt_tooth_diameter = 1.25;
belt_pitch = 2;

// Mounting hole diameters and spacing
bolt_hole_dia = 4.5;
bolt_y_centres = 23;
bolt_x_centres = 23;

// variables for the axis bearing cutouts
axis_bar_centres = 45;
axis_bearing_dia = 15.5;
axis_bearing_length = 45.5;
axis_bearing_collar_dia = 11;
axis_bearing_z = bearing_block_depth + carriage_block_depth - 1;
twin_bearing_length = 24.5;
twin_bearing_offset = 1;

// Variables for the tie wrap cutouts/slots
tiewrap_depth = 1.5;
tiewrap_inner_height = 17;
tiewrap_bottom_offset = 1;
tiewrap_radius = 2.5;
tiewrap_width = 4;

// Variables for use with the geetech tensioner pulley cutout
geetech_pulley_dia = 15;
geetech_pulley_offset = 8;

// Utility variable used to simplify some of the translations
total_depth = carriage_block_depth + bearing_block_depth;

x_carriage();

module x_carriage() {
    difference() {
        main_block();
        union() {
            bolt_holes();
            bearing_cutouts();
            if (geetech_cutout) {
                translate([-carriage_width/2 + geetech_pulley_offset - geetech_pulley_dia / 2, 0, 0])
                cylinder(d = geetech_pulley_dia, h = total_depth);
            }
        }
    }
}

module main_block()
{
    linear_extrude(carriage_block_depth)
    hull() {
        if (square_endstop) {
            translate([carriage_width / 2 - carriage_corner_radius, carriage_height / 2 - carriage_corner_radius, 0])
                square(size = [carriage_corner_radius, carriage_corner_radius]);
        } else {
            translate([carriage_width / 2 - carriage_corner_radius, carriage_height / 2 - carriage_corner_radius, 0])
                circle(r = carriage_corner_radius);
        }
        translate([-carriage_width / 2 + carriage_corner_radius, carriage_height / 2 - carriage_corner_radius, 0])
            circle(r = carriage_corner_radius);
        translate([carriage_width / 2 - carriage_corner_radius, -carriage_height / 2 + carriage_corner_radius, 0])
            circle(r = carriage_corner_radius);
        translate([-carriage_width / 2 + carriage_corner_radius, -carriage_height / 2 + carriage_corner_radius, 0])
            circle(r = carriage_corner_radius);
    }
    translate([0, -carriage_height / 2 + bearing_block_height / 2, carriage_block_depth])
        bearing_block();
    translate([0, carriage_height / 2 - bearing_block_height / 2, carriage_block_depth])
        bearing_block();
    translate([carriage_width / 2 - belt_clamp_width, -belt_clamp_height + 2.5, carriage_block_depth])
        belt_clamp();
    
    if (geetech_cutout) {
        translate([-carriage_width / 2 + geetech_pulley_offset, -belt_clamp_height + 2.5, carriage_block_depth])
        belt_clamp();
    }
    else {
        translate([-carriage_width / 2, -belt_clamp_height + 2.5, carriage_block_depth])
        belt_clamp();
    }
}

module bearing_block()
{
    linear_extrude(bearing_block_depth)
    hull() {
        translate([carriage_width / 2 - bearing_block_corner_radius, bearing_block_height / 2 - bearing_block_corner_radius, 0])
            circle(r = bearing_block_corner_radius);
        translate([-carriage_width / 2 + bearing_block_corner_radius, bearing_block_height / 2 - bearing_block_corner_radius, 0])
            circle(r = bearing_block_corner_radius);
        translate([carriage_width / 2 - bearing_block_corner_radius, -bearing_block_height / 2 + bearing_block_corner_radius, 0])
            circle(r = bearing_block_corner_radius);
        translate([-carriage_width / 2 + bearing_block_corner_radius, -bearing_block_height / 2 + bearing_block_corner_radius, 0])
            circle(r = bearing_block_corner_radius);
    }
}

module belt_clamp()
{
    points = [
        [0, 0, 0],
        [0, belt_clamp_height - belt_clamp_chamfer, 0],
        [0, belt_clamp_height - belt_clamp_chamfer, belt_clamp_depth],
        [0, belt_clamp_chamfer, belt_clamp_depth],
        [0, 0, belt_clamp_depth - belt_clamp_chamfer],
        [belt_clamp_chamfer, belt_clamp_height, belt_clamp_depth],
        [belt_clamp_chamfer, belt_clamp_height, 0],
        
        [belt_clamp_width, 0, 0],
        [belt_clamp_width, belt_clamp_height - belt_clamp_chamfer, 0],
        [belt_clamp_width, belt_clamp_height - belt_clamp_chamfer, belt_clamp_depth],
        [belt_clamp_width, belt_clamp_chamfer, belt_clamp_depth],
        [belt_clamp_width, 0, belt_clamp_depth - belt_clamp_chamfer],
        [belt_clamp_width - belt_clamp_chamfer, belt_clamp_height, belt_clamp_depth],
        [belt_clamp_width - belt_clamp_chamfer, belt_clamp_height, 0],
        
    ];
    
    faces = [
        [0,1,2,3,4],
        [1,6,5,2],
        [7,11,10,9,8],
        [8,9,12,13],
        [6,13,12,5],
        [5,12,9,10,3,2],
        [3,10,11,4],
        [0,4,11,7],
        [0,7,8,13,6,1],
    ];
    
    difference() {
        polyhedron(points = points, faces = faces);
        belt_teeth();
    }
}

module belt_teeth()
{
    for (i = [belt_tooth_diameter:belt_pitch:belt_clamp_width + belt_tooth_diameter]) {
        translate([i, 0, 0])
            cylinder(d = belt_tooth_diameter, h = belt_clamp_depth);
    }
}

module bolt_holes()
{
    translate([-bolt_x_centres / 2, -bolt_y_centres / 2, 0])
        cylinder(d = bolt_hole_dia, h = carriage_block_depth + bearing_block_depth);
    translate([-bolt_x_centres / 2, bolt_y_centres / 2, 0])
        cylinder(d = bolt_hole_dia, h = carriage_block_depth + bearing_block_depth);
    translate([bolt_x_centres / 2, -bolt_y_centres / 2, 0])
        cylinder(d = bolt_hole_dia, h = carriage_block_depth + bearing_block_depth);
    translate([bolt_x_centres / 2, bolt_y_centres / 2, 0])
        cylinder(d = bolt_hole_dia, h = carriage_block_depth + bearing_block_depth);
}

module bearing_cutouts()
{
    if (axle_bearings == 2) twin_bearing_cutouts();
    else single_bearing_cutouts();
}

module single_bearing_cutouts()
{
    translate([-axis_bearing_length / 2, axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_dia, h = axis_bearing_length);
    
    translate([-axis_bearing_length / 2, -axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_dia, h = axis_bearing_length);
    
    translate([-carriage_width / 2, axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_collar_dia, h = carriage_width);
    
    translate([-carriage_width / 2, -axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_collar_dia, h = carriage_width);
    
    translate([-axis_bearing_length / 2 + tiewrap_width, -axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([axis_bearing_length / 2 - tiewrap_width, -axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([0, -axis_bar_centres/2, 0])
    tiewrap_cutout();
    
    translate([-axis_bearing_length / 2 + tiewrap_width, axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([axis_bearing_length / 2 - tiewrap_width, axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([0, axis_bar_centres/2, 0])
    tiewrap_cutout();
}

module twin_bearing_cutouts()
{
    translate([-twin_bearing_length - twin_bearing_offset, axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_dia, h = twin_bearing_length);
    translate([twin_bearing_offset, axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_dia, h = twin_bearing_length);
    
    translate([-twin_bearing_length - twin_bearing_offset, -axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_dia, h = twin_bearing_length);
    translate([twin_bearing_offset, -axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_dia, h = twin_bearing_length);
    
    translate([-carriage_width / 2, axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_collar_dia, h = carriage_width);
    translate([-carriage_width / 2, -axis_bar_centres/2, axis_bearing_z])
    rotate([0,90,0])
    cylinder(d = axis_bearing_collar_dia, h = carriage_width);
    
    translate([-twin_bearing_length - twin_bearing_offset + tiewrap_width, -axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([-twin_bearing_offset - tiewrap_width, -axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([twin_bearing_length + twin_bearing_offset - tiewrap_width, -axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([twin_bearing_offset + tiewrap_width, -axis_bar_centres/2, 0])
    tiewrap_cutout();
    
    translate([-twin_bearing_length - twin_bearing_offset + tiewrap_width, axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([-twin_bearing_offset - tiewrap_width, axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([twin_bearing_length + twin_bearing_offset - tiewrap_width, axis_bar_centres/2, 0])
    tiewrap_cutout();
    translate([twin_bearing_offset + tiewrap_width, axis_bar_centres/2, 0])
    tiewrap_cutout();
}

module tiewrap_cutout()
{
    difference() {
        translate([0,0,total_depth / 2])
            cube(size = [tiewrap_width, tiewrap_inner_height + tiewrap_depth * 2,total_depth], center = true);
        
        translate([0,0,tiewrap_bottom_offset])
            rotate([0, -90, 0])
            minkowski()
            {
                translate([total_depth / 2 + tiewrap_radius, 0, -1])
                cube([total_depth, tiewrap_inner_height - tiewrap_radius * 2, tiewrap_width - 2], center = true);
                cylinder(r=tiewrap_radius,h=2);
            }
    }
}