TOGGLE_LENGTH = 50;
TOGGLE_HEIGHT = 7;
TOGGLE_WIDTH = 6;
PROBE_WIDTH = 5;
TOGGLE_SLOT_HEIGHT = 5;
TOGGLE_SLOT_WIDTH = 14;
TOGGLE_SLOT_DISTANCE = 1.5;

MOUNT_HEIGHT = 15;
MOUNT_WIDTH = TOGGLE_SLOT_WIDTH * 2 + TOGGLE_SLOT_DISTANCE + 2 * 10;
MOUNT_WALL_THICKNESS = 1;
MOUNT_MIDDLE_THICKNESS = 10;
MOUNT_EXTRA_SPACE=0.1;
MOUNT_HOLE_RADIUS = 3.1 / 2;

PROBE_SMALL_RADIUS = 7;
PROBE_BIG_RADIUS = 8.5;
PROBE_LENGTH = 33.5;
PROBE_HOLDER_LENGTH = 12;
PROBE_BOTTOM_WIDTH = 20;

//TODO: Solve the wavy short line
//Front and top can have the same long straight line
//no rounded corner angles matters, so the model can be simplified
//The housing needs to come out so that the probe can actually touch it
//
//

module hole(h, r, center, fn=100)
{
   fudge = 1/cos(180/fn);
   cylinder(h=h,r=r*fudge,center=center,$fn=fn);
}

module toggle()
{
	difference()
	{
		cube([TOGGLE_WIDTH, TOGGLE_LENGTH, TOGGLE_HEIGHT]);
		translate([-0.1, TOGGLE_LENGTH / 2 - TOGGLE_SLOT_WIDTH - TOGGLE_SLOT_DISTANCE / 2, -0.001])
		cube([PROBE_WIDTH + 0.1, TOGGLE_SLOT_WIDTH, TOGGLE_SLOT_HEIGHT]);
		translate([-0.1, TOGGLE_LENGTH / 2 + TOGGLE_SLOT_DISTANCE / 2, -0.001])
		cube([PROBE_WIDTH + 0.1, TOGGLE_SLOT_WIDTH, TOGGLE_SLOT_HEIGHT]);
	}
}

module probe()
{
	$fn=300;
	difference()
	{
		union()
		{
			cylinder(r=PROBE_SMALL_RADIUS, h=PROBE_WIDTH, center=true);
			translate([4, -0.9, -PROBE_WIDTH / 2])
			cube([3.6, 3, PROBE_WIDTH]);
			translate([6.95, 1.45, 0])
			cylinder(r=1.4, h=PROBE_WIDTH, center=true);
			translate([-PROBE_SMALL_RADIUS, PROBE_BIG_RADIUS - PROBE_SMALL_RADIUS, -PROBE_WIDTH / 2])
			cube([PROBE_SMALL_RADIUS, PROBE_SMALL_RADIUS, PROBE_WIDTH]);
			probe_bottom_length = PROBE_LENGTH - PROBE_SMALL_RADIUS;
			probe_left_edge = -17;
			translate([0, 0, -PROBE_WIDTH / 2])
			linear_extrude(PROBE_WIDTH)
			#polygon([
				[-PROBE_SMALL_RADIUS,0], 
				[probe_left_edge, -(probe_bottom_length - PROBE_HOLDER_LENGTH)],
				[probe_left_edge, -probe_bottom_length], 
				[probe_left_edge + PROBE_BOTTOM_WIDTH, -probe_bottom_length],
				[probe_left_edge + PROBE_BOTTOM_WIDTH, 0],
			]);
			difference()
			{
				cylinder(r=PROBE_BIG_RADIUS, h=PROBE_WIDTH, center=true);
				translate([-50, -100 + 1.8, -0.1 - PROBE_WIDTH / 2])
				cube([100, 100, PROBE_WIDTH + 0.2]);
				translate([-100, -50, -0.1 - PROBE_WIDTH / 2])
				cube([100, 100, PROBE_WIDTH + 0.2]);
					
			}
		}
		cutout=3.5;
		translate([cutout, cutout, -PROBE_WIDTH / 2 - 0.1])
		cube([10, 10, PROBE_WIDTH + 0.2]);

		translate([cutout + 0.1, cutout + 0.1, 0])
		cylinder(r=1.25, h=PROBE_WIDTH + 0.2, center=true);
		
		r = 1.5;
		translate([8.35, -1.0])
		cylinder(r=1.4, h=PROBE_WIDTH + 0.2, center=true);

		//Rounded corner remove
		translate([7.1, 2.9, -0.1 - PROBE_WIDTH / 2])
		cube([1, 1, PROBE_WIDTH + 0.2]);
		translate([4.3, 3.2, -0.1 - PROBE_WIDTH / 2])
		cube([1, 1, PROBE_WIDTH + 0.2]);
		translate([3.1, 4.2, -0.1 - PROBE_WIDTH / 2])
		cube([1, 1, PROBE_WIDTH + 0.2]);
		translate([2.9, 7.2, -0.1 - PROBE_WIDTH / 2])
		cube([1, 1, PROBE_WIDTH + 0.2]);
	}
	
	//Rounded corners
	translate([7.0, 2.4, 0])
	cylinder(r=1.10, h=PROBE_WIDTH, center=true);
	
	translate([5.3, 2.9, 0])
	cylinder(r=0.6, h=PROBE_WIDTH, center=true);
	translate([3.15, 5.2, 0])
	cylinder(r=0.35, h=PROBE_WIDTH, center=true);

	translate([2.6, 4.4, -PROBE_WIDTH / 2])
	rotate([0, 0, 34])
	cube([0.9, 0.9, PROBE_WIDTH]);

	translate([2.4, 7, 0])
	cylinder(r=1.10, h=PROBE_WIDTH, center=true);
}

module mount()
{
	difference()
	{
		translate([0, 0, -MOUNT_WALL_THICKNESS])
		cube([TOGGLE_WIDTH + MOUNT_WALL_THICKNESS + MOUNT_EXTRA_SPACE, MOUNT_WIDTH, TOGGLE_HEIGHT + 2*MOUNT_WALL_THICKNESS + MOUNT_EXTRA_SPACE]);
		translate([-0.1 - MOUNT_EXTRA_SPACE, -0.1, 0])
		cube([TOGGLE_WIDTH+MOUNT_EXTRA_SPACE + 0.1, MOUNT_WIDTH + 0.2, TOGGLE_HEIGHT + MOUNT_EXTRA_SPACE]);
		
	}
	difference()
	{
		pole_height = MOUNT_HEIGHT - (TOGGLE_HEIGHT + 2*MOUNT_WALL_THICKNESS + MOUNT_EXTRA_SPACE);
		translate([0, MOUNT_WIDTH / 2 - MOUNT_MIDDLE_THICKNESS / 2, -pole_height - MOUNT_WALL_THICKNESS])
		cube([TOGGLE_WIDTH + MOUNT_WALL_THICKNESS, MOUNT_MIDDLE_THICKNESS, pole_height]);
		
		translate([-0.1, MOUNT_WIDTH / 2, TOGGLE_SLOT_HEIGHT - PROBE_BIG_RADIUS])
		rotate([0, 90, 0])
		hole(r=MOUNT_HOLE_RADIUS, h = TOGGLE_WIDTH + MOUNT_WALL_THICKNESS + MOUNT_EXTRA_SPACE + 0.2);
	}
}

//translate([0, 0, -5])
//import("Probe_1013_Toggle.stl");

toggle();
//mount();
//translate([-7/2, TOGGLE_LENGTH / 2 + TOGGLE_SLOT_WIDTH / 2, 0])
//rotate([180, 0, 0])
//probe();
