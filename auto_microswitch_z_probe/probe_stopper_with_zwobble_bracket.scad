BRACKET_WIDTH = 26;
BRACKET_LENGTH = 41;
FLOOR_HEIGHT = 5.5;
TOP_HEIGHT = 11;
CUTOUT_DEPTH = 15.15;
CUTOUT_WIDTH = 8.30;
TOP_RADIUS = 20;
MOUNT_CURVE_WIDTH = 20;
CENTER_HOLE_RADIUS = 10.4 / 2;
SCREW_HOLE_RADIUS = 3.5 / 2;
SCREW_HOLE_BIG_RADIUS = 6.0 / 2;
SCREW_HOLE_DIST_RADIUS = 11.50 / 2;
SCREW_HOLE_DEPTH = 4.5;
END_STOPPER_WIDTH = 35;
END_STOPPER_WALL_WIDTH = 15;
END_STOPPER_WALL_HEIGHT = 80;
END_STOPPER_WALL_THICKNESS = 1.5;

module hole(h, r, center, fn=100)
{
   fudge = 1/cos(180/fn);
   cylinder(h=h,r=r*fudge,center=center,$fn=fn);
}

module mount_curve()
{
	$fn = 300;
	translate([0, -BRACKET_LENGTH / 2 + MOUNT_CURVE_WIDTH / 2, -FLOOR_HEIGHT /2])
	intersection()
	{
		translate([0, 0, -TOP_RADIUS + TOP_HEIGHT])
		rotate([0, 90, 0])
		cylinder(h=BRACKET_WIDTH, r=TOP_RADIUS, center=true);
		translate([0, 0, TOP_HEIGHT / 2])
		cube([BRACKET_WIDTH, MOUNT_CURVE_WIDTH, TOP_HEIGHT], center=true);
	}
}

module screw_hole()
{
	big_screw_z = -SCREW_HOLE_DEPTH / 2 + TOP_HEIGHT - FLOOR_HEIGHT / 2;
	hole(h=TOP_HEIGHT * 2, r = SCREW_HOLE_RADIUS, center=true);
	translate([0, 0, big_screw_z])
	hole(h=SCREW_HOLE_DEPTH, r = SCREW_HOLE_BIG_RADIUS, center=true);
}

difference()
{
	union()
	{
		translate([END_STOPPER_WIDTH / 2, 0, 0])
		cube([BRACKET_WIDTH + END_STOPPER_WIDTH, BRACKET_LENGTH, FLOOR_HEIGHT], center=true);
		mount_curve();
		
		translate([END_STOPPER_WIDTH + BRACKET_WIDTH / 2 - END_STOPPER_WALL_WIDTH, -BRACKET_LENGTH / 2, FLOOR_HEIGHT / 2])
		cube([END_STOPPER_WALL_WIDTH, END_STOPPER_WALL_THICKNESS, END_STOPPER_WALL_HEIGHT]);

		translate([BRACKET_WIDTH / 2 + END_STOPPER_WIDTH - END_STOPPER_WALL_THICKNESS, -BRACKET_LENGTH / 2 + END_STOPPER_WALL_THICKNESS, FLOOR_HEIGHT / 2])
		rotate([90, 0, 90])
		linear_extrude(height = END_STOPPER_WALL_THICKNESS)
		polygon([[0, 0], [BRACKET_LENGTH - END_STOPPER_WALL_THICKNESS, 0], [0, END_STOPPER_WALL_HEIGHT]]);

		translate([BRACKET_WIDTH / 2 + END_STOPPER_WIDTH - END_STOPPER_WALL_WIDTH, -BRACKET_LENGTH / 2 + END_STOPPER_WALL_THICKNESS, FLOOR_HEIGHT / 2])
		rotate([90, 0, 90])
		linear_extrude(height = END_STOPPER_WALL_THICKNESS)
		polygon([[0, 0], [BRACKET_LENGTH - END_STOPPER_WALL_THICKNESS, 0], [0, END_STOPPER_WALL_HEIGHT]]);
	}
	cutout_square_depth = CUTOUT_DEPTH - CUTOUT_WIDTH / 2;
	translate([0, BRACKET_LENGTH / 2 - cutout_square_depth / 2 + 0.1 / 2, 0])
	cube([CUTOUT_WIDTH, cutout_square_depth + 0.1, FLOOR_HEIGHT + 0.1], center=true);
	translate([0, BRACKET_LENGTH / 2 - cutout_square_depth, 0])
	hole(h=FLOOR_HEIGHT + 0.1, r = CUTOUT_WIDTH / 2, center=true);
	curve_center = -BRACKET_LENGTH / 2 + MOUNT_CURVE_WIDTH / 2;
	translate([0, curve_center, 0])
	hole(h=TOP_HEIGHT * 2, r = CENTER_HOLE_RADIUS, center=true);

	big_screw_z = TOP_HEIGHT + FLOOR_HEIGHT / 2 - SCREW_HOLE_DEPTH;

	translate([SCREW_HOLE_DIST_RADIUS, curve_center - SCREW_HOLE_DIST_RADIUS, 0])
	screw_hole();
	translate([-SCREW_HOLE_DIST_RADIUS, curve_center - SCREW_HOLE_DIST_RADIUS, 0])
	screw_hole();
	translate([SCREW_HOLE_DIST_RADIUS, curve_center + SCREW_HOLE_DIST_RADIUS, 0])
	screw_hole();
	translate([-SCREW_HOLE_DIST_RADIUS, curve_center + SCREW_HOLE_DIST_RADIUS, 0])
	screw_hole();
}

