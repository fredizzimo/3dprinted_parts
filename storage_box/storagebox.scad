FILAMENT_FRONT_PLATE_THICKNESS = 2;
FILAMENT_BACK_PLATE_THICKNESS = 5;
FILAMENT_PLATE_SIZE = 30;
FILAMENT_HOLE_DISTANCE = 20;
CAP_HEIGHT = 8.5;
SCREW_RADIUS = (4 + 0.1) / 2;
NUT_RADIUS = (6.9 + 0.1) / 2;
NUT_THICKNESS = 3;
FILAMENT_HOLE_BOTTOM_RADIUS = 3;
FILAMENT_HOLE_TOP_RADIUS = 2;

SPOOL_PLATE_SIZE = 40;
SPOOL_HOLE_DISTANCE = 30;
SPOOL_BACK_PLATE_THICKNESS = FILAMENT_FRONT_PLATE_THICKNESS;
SPOOL_FRONT_PLATE_THICKNESS = FILAMENT_BACK_PLATE_THICKNESS;
SPOOL_ROD_RADIUS = 21 / 2;
SPOOL_ROD_MOUNT_RADIUS = 30 / 2;
SPOOL_ROD_MOUNT_LENGTH = 20;
SPOOL_EXTRA_STRENGTH_WIDTH = 15;
SPOOL_EXTRA_STRENGTH_THICKNESS = 5;
SPOOL_EXTRA_STRENGTH_LENGTH = 10;

module hole(h, r, center, fn=100)
{
   fudge = 1/cos(180/fn);
   cylinder(h=h,r=r*fudge,center=center,$fn=fn);
}

module ScrewHoles(radius, distance, fn=100)
{
	translate([distance / 2, distance / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
	translate([-distance / 2, distance / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
	translate([-distance / 2, -distance / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
	translate([distance / 2, -distance / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
}

module FilamentFrontPlate()
{
	rotate([180, 0, 0])
	{
		difference()
		{
			cube([FILAMENT_PLATE_SIZE, FILAMENT_PLATE_SIZE, FILAMENT_FRONT_PLATE_THICKNESS], center=true);
			hole(h=10, r=5, center=true);
			ScrewHoles(SCREW_RADIUS, FILAMENT_HOLE_DISTANCE);
		}
		translate([0, 0, -CAP_HEIGHT - FILAMENT_FRONT_PLATE_THICKNESS / 2])
		import("TFF_Female_Flat_v2.1.stl");
	}
}

module FilamentBackPlate()
{
	difference()
	{
		cube([FILAMENT_PLATE_SIZE, FILAMENT_PLATE_SIZE, FILAMENT_BACK_PLATE_THICKNESS], center=true);
		ScrewHoles(SCREW_RADIUS, FILAMENT_HOLE_DISTANCE);
		translate([0, 0, -NUT_THICKNESS + 10 / 2 + FILAMENT_BACK_PLATE_THICKNESS / 2])
		ScrewHoles(NUT_RADIUS, FILAMENT_HOLE_DISTANCE, fn=6);
		cylinder(
			h = FILAMENT_BACK_PLATE_THICKNESS + 0.01, 
			r1 = FILAMENT_HOLE_TOP_RADIUS,
			r2 = FILAMENT_HOLE_BOTTOM_RADIUS, 
			center = true,
			$fn=100
		);
	}
}

module SpoolHolderBackPlate()
{
	difference()
	{
		cube([SPOOL_PLATE_SIZE, SPOOL_PLATE_SIZE, SPOOL_BACK_PLATE_THICKNESS], center=true);
		ScrewHoles(SCREW_RADIUS, SPOOL_HOLE_DISTANCE);
	}
}

module SpoolHolderFrontPlate()
{
	difference()
	{
		cube([SPOOL_PLATE_SIZE, SPOOL_PLATE_SIZE, SPOOL_FRONT_PLATE_THICKNESS], center=true);
		ScrewHoles(SCREW_RADIUS, SPOOL_HOLE_DISTANCE);
		translate([0, 0, 10 / 2 + SPOOL_FRONT_PLATE_THICKNESS / 2 - NUT_THICKNESS])
		ScrewHoles(NUT_RADIUS, SPOOL_HOLE_DISTANCE, fn=6);
	}
	difference()
	{
		translate([0, 0, SPOOL_FRONT_PLATE_THICKNESS / 2])
		cylinder(h=SPOOL_ROD_MOUNT_LENGTH, r=SPOOL_ROD_MOUNT_RADIUS, $fn=100);
		translate([0.1, 0, SPOOL_FRONT_PLATE_THICKNESS / 2])
		cylinder(h=SPOOL_ROD_MOUNT_LENGTH + 0.1, r=SPOOL_ROD_RADIUS, $fn=100);
		translate([-SPOOL_ROD_MOUNT_RADIUS, 0, SPOOL_FRONT_PLATE_THICKNESS / 2])
		cube([SPOOL_ROD_MOUNT_RADIUS * 2, SPOOL_ROD_MOUNT_RADIUS, SPOOL_ROD_MOUNT_LENGTH + 0.1]);
	}
	
	translate([SPOOL_EXTRA_STRENGTH_WIDTH /2 - SPOOL_EXTRA_STRENGTH_THICKNESS / 2, -SPOOL_PLATE_SIZE / 2, SPOOL_FRONT_PLATE_THICKNESS / 2])
	cube([SPOOL_EXTRA_STRENGTH_THICKNESS, SPOOL_EXTRA_STRENGTH_LENGTH, SPOOL_ROD_MOUNT_LENGTH]);
	translate([-SPOOL_EXTRA_STRENGTH_WIDTH /2 - SPOOL_EXTRA_STRENGTH_THICKNESS / 2, -SPOOL_PLATE_SIZE / 2, SPOOL_FRONT_PLATE_THICKNESS / 2])
	cube([SPOOL_EXTRA_STRENGTH_THICKNESS, SPOOL_EXTRA_STRENGTH_LENGTH, SPOOL_ROD_MOUNT_LENGTH]);
}

module ClosedCap()
{
	translate([0, 0, 15.5])
	rotate([180, 0, 0])
	import("TFF_Male_Flat_v2.1.stl");

	CAP_WALL_HEIGHT = 3;
	translate([0, 0, CAP_WALL_HEIGHT / 2])
	cube([8, 8, CAP_WALL_HEIGHT], center=true);
}

// Enable one of these
//FilamentFrontPlate();
//FilamentBackPlate();
//ClosedCap();
//SpoolHolderBackPlate();
SpoolHolderFrontPlate();

