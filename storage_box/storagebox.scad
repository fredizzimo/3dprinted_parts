FRONT_PLATE_THICKNESS = 2;
BACK_PLATE_THICKNESS = 5;
PLATE_SIZE = 30;
HOLE_DISTANCE = 20;
CAP_HEIGHT = 8.5;
SCREW_RADIUS = 4.1 / 2;
NUT_RADIUS = 6.9 / 2;
NUT_THICKNESS = 3;
FILAMENT_HOLE_BOTTOM_RADIUS = 3;
FILAMENT_HOLE_TOP_RADIUS = 2;


module hole(h, r, center, fn=100)
{
   fudge = 1/cos(180/fn);
   cylinder(h=h,r=r*fudge,center=center,$fn=fn);
}

module ScrewHoles(radius, fn=100)
{
	translate([HOLE_DISTANCE / 2, HOLE_DISTANCE / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
	translate([-HOLE_DISTANCE / 2, HOLE_DISTANCE / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
	translate([-HOLE_DISTANCE / 2, -HOLE_DISTANCE / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
	translate([HOLE_DISTANCE / 2, -HOLE_DISTANCE / 2, 0])
	hole(h=10, r=radius, center=true, fn=fn);
}

module FrontPlate()
{
	difference()
	{
		cube([PLATE_SIZE, PLATE_SIZE, FRONT_PLATE_THICKNESS], center=true);
		hole(h=10, r=5, center=true);
		ScrewHoles(SCREW_RADIUS);
	}
	translate([0, 0, -CAP_HEIGHT - FRONT_PLATE_THICKNESS / 2])
	import("TFF_Female_Flat_v2.1.stl");
}

module BackPlate()
{
	difference()
	{
		cube([PLATE_SIZE, PLATE_SIZE, BACK_PLATE_THICKNESS], center=true);
		ScrewHoles(SCREW_RADIUS);
		translate([0, 0, NUT_THICKNESS -10 / 2 - BACK_PLATE_THICKNESS / 2])
		ScrewHoles(NUT_RADIUS, fn=6);
		cylinder(
			h = BACK_PLATE_THICKNESS + 0.01, 
			r1 = FILAMENT_HOLE_BOTTOM_RADIUS,
			r2 = FILAMENT_HOLE_TOP_RADIUS, 
			center = true,
			$fn=100
		);
	}
}

//FrontPlate();
BackPlate();

