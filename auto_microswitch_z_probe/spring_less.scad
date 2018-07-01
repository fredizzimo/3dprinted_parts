TOGGLE_LENGTH = 50;
TOGGLE_HEIGHT = 7;
TOGGLE_WIDTH = 6;
TOGGLE_SLOT_HEIGHT = 5;
TOGGLE_SLOT_WIDTH = 14;
TOGGLE_SLOT_DISTANCE = 1.5;

MOUNT_EXTRA_SPACE=3;
MOUNT_HEIGHT = 15 + MOUNT_EXTRA_SPACE;
MOUNT_WIDTH = TOGGLE_SLOT_WIDTH * 2 + TOGGLE_SLOT_DISTANCE + 2 * 10;
MOUNT_WALL_THICKNESS = 1;
MOUNT_MIDDLE_THICKNESS = 10;
MOUNT_HOLE_RADIUS = 3.1 / 2;

PROBE_WIDTH = 5;
PROBE_ACTIVATION_AREA_RADIUS = 8.5;
PROBE_ACTIVE_FLAT_AREA_WIDTH = PROBE_ACTIVATION_AREA_RADIUS;
PROBE_INACTIVE_FLAT_AREA_WIDTH = 3;
PROBE_HEIGHT = 33;
//PROBE_SLOT_WIDTH = PROBE_ACTIVATION_AREA_RADIUS * 2 + 1;
PROBE_SLOT_WIDTH= TOGGLE_SLOT_WIDTH * 2 + TOGGLE_SLOT_DISTANCE;
PROBE_ACTIVATION_CIRCLE_RADIUS = 2;

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
		cube([PROBE_WIDTH + 0.1, TOGGLE_SLOT_WIDTH * 2 + TOGGLE_SLOT_DISTANCE, TOGGLE_SLOT_HEIGHT]);
		
	}
	translate([0, TOGGLE_LENGTH / 2 - TOGGLE_SLOT_DISTANCE / 2, TOGGLE_SLOT_HEIGHT / 2])
	cube([PROBE_WIDTH, TOGGLE_SLOT_DISTANCE, TOGGLE_SLOT_HEIGHT / 2]);
	intersection()
	{
		translate([0, TOGGLE_LENGTH / 2 - TOGGLE_SLOT_DISTANCE / 2, 0])
		cube([PROBE_WIDTH, TOGGLE_SLOT_DISTANCE, TOGGLE_SLOT_HEIGHT]);
		translate([0, TOGGLE_LENGTH / 2, PROBE_ACTIVATION_CIRCLE_RADIUS])
		rotate([0, 90, 0])
		cylinder(h = TOGGLE_SLOT_HEIGHT, r = PROBE_ACTIVATION_CIRCLE_RADIUS, $fn=100);
	}
}

module probe()
{
	$fn = 100;
	difference()
	{
		union()
		{
			difference()
			{
				cylinder(h = PROBE_WIDTH, r = PROBE_ACTIVATION_AREA_RADIUS, center=true);
				translate([(PROBE_ACTIVATION_AREA_RADIUS + 0.1) / 2, 0, 0])
				cube([PROBE_ACTIVATION_AREA_RADIUS + 0.1, 2 * PROBE_ACTIVATION_AREA_RADIUS + 0.1, PROBE_WIDTH + 0.1], center=true);
			}
			translate([-PROBE_ACTIVATION_AREA_RADIUS / 2, -PROBE_ACTIVE_FLAT_AREA_WIDTH / 2, 0])
			cube([PROBE_ACTIVATION_AREA_RADIUS, PROBE_ACTIVE_FLAT_AREA_WIDTH, PROBE_WIDTH], center=true);

			translate([PROBE_INACTIVE_FLAT_AREA_WIDTH / 2, PROBE_ACTIVATION_AREA_RADIUS / 2, 0])
			cube([PROBE_INACTIVE_FLAT_AREA_WIDTH, PROBE_ACTIVATION_AREA_RADIUS, PROBE_WIDTH], center=true);
			probe_top_width = PROBE_ACTIVE_FLAT_AREA_WIDTH + (PROBE_ACTIVATION_AREA_RADIUS - TOGGLE_SLOT_HEIGHT);
			translate([
				(PROBE_HEIGHT - PROBE_ACTIVATION_AREA_RADIUS) / 2,
				-probe_top_width / 2 + PROBE_ACTIVATION_AREA_RADIUS - TOGGLE_SLOT_HEIGHT - MOUNT_WALL_THICKNESS / 2,
				0])
			cube([PROBE_HEIGHT - PROBE_ACTIVATION_AREA_RADIUS, probe_top_width - MOUNT_WALL_THICKNESS, PROBE_WIDTH], center=true);

		}
		translate([-PROBE_ACTIVATION_AREA_RADIUS + TOGGLE_SLOT_HEIGHT / 2, PROBE_ACTIVATION_AREA_RADIUS - TOGGLE_SLOT_HEIGHT / 2, 0])
		cube([TOGGLE_SLOT_HEIGHT, TOGGLE_SLOT_HEIGHT, PROBE_WIDTH + 0.1], center=true);
		hole(r = MOUNT_HOLE_RADIUS, h=PROBE_WIDTH + 0.1, center=true);

		dist = sin(45) * (PROBE_ACTIVATION_AREA_RADIUS - TOGGLE_SLOT_HEIGHT + PROBE_ACTIVATION_CIRCLE_RADIUS);
		translate([-dist, dist, 0])
		hole(r = PROBE_ACTIVATION_CIRCLE_RADIUS, h = PROBE_WIDTH + 0.1, center=true);
	}
}

module mount(invisible_front=false)
{
	difference()
	{
		front_wall = invisible_front ? 0 : MOUNT_WALL_THICKNESS;
		translate([-front_wall, 0, -MOUNT_WALL_THICKNESS])
		cube([TOGGLE_WIDTH + MOUNT_WALL_THICKNESS + MOUNT_EXTRA_SPACE + front_wall, MOUNT_WIDTH, TOGGLE_HEIGHT + 2*MOUNT_WALL_THICKNESS + MOUNT_EXTRA_SPACE]);
		translate([-0.1, -0.1, 0])
		cube([TOGGLE_WIDTH+MOUNT_EXTRA_SPACE + 0.1, MOUNT_WIDTH + 0.2, TOGGLE_HEIGHT + MOUNT_EXTRA_SPACE]);

		translate([-0.1, MOUNT_WIDTH / 2 - PROBE_SLOT_WIDTH / 2, -MOUNT_WALL_THICKNESS-0.1])
		cube([TOGGLE_WIDTH + MOUNT_EXTRA_SPACE + 0.1, PROBE_SLOT_WIDTH, MOUNT_WALL_THICKNESS + 0.2]);
		
	}
	difference()
	{
		pole_height = MOUNT_HEIGHT - (TOGGLE_HEIGHT + MOUNT_WALL_THICKNESS * 2 + MOUNT_EXTRA_SPACE);
		translate([-MOUNT_WALL_THICKNESS, MOUNT_WIDTH / 2 - MOUNT_MIDDLE_THICKNESS / 2, -pole_height - MOUNT_WALL_THICKNESS])
		cube([MOUNT_WALL_THICKNESS, MOUNT_MIDDLE_THICKNESS, pole_height]);
		
		translate([-0.1 - MOUNT_WALL_THICKNESS, MOUNT_WIDTH / 2, TOGGLE_SLOT_HEIGHT - PROBE_ACTIVATION_AREA_RADIUS])
		rotate([0, 90, 0])
		hole(r=MOUNT_HOLE_RADIUS, h = TOGGLE_WIDTH + MOUNT_WALL_THICKNESS + MOUNT_EXTRA_SPACE + 0.2);
	}
}

module original_probe()
{
	rotate([0, 0, 90])
	import("Probe_1013_Toggle.stl");
}

module assembly(angle, toggle_pos, invisible_front)
{
	translate([0, -MOUNT_WIDTH / 2, TOGGLE_SLOT_HEIGHT - MOUNT_HOLE_RADIUS])
	{
		translate([0, toggle_pos, 0])
		toggle();
		mount(invisible_front);
	}

	rotate([angle, 0, 0])
	translate([PROBE_WIDTH / 2, 0, 0])
	rotate([0, 90, 0])
	{
		//original_probe();
		color("red")
		probe();
	}
}

assembly(25, 1, false);
