M3_RADIUS_TIGHT = 2.9 / 2;
M3_DIAMETER = 3.1;
M3_RADIUS = M3_DIAMETER / 2;
M4_DIAMETER = 4.1;
M4_RADIUS = M4_DIAMETER / 2;
WIDTH = 21;
LENGTH = 55;
INNER_WIDTH = 10.5;
SPRING_WIDTH = 25;
WALL_THICKNESS = WIDTH / 2 - INNER_WIDTH / 2; 
SPRING_CONE_THICKNESS = (SPRING_WIDTH - WIDTH) / 2;
CONE_INNER = M3_RADIUS + 1;
CONE_OUTER = CONE_INNER + 2;
CONE_HOLE_DEPTH = WALL_THICKNESS + SPRING_CONE_THICKNESS - 2;
SPRING_Y = 15;
SPRING_Z = 10 - CONE_OUTER;
SPRING_HOLDER_HEIGHT = 7.5;
PROBE_HOLE = 20 + SPRING_HOLDER_HEIGHT - 5.0;
BOTTOM_WALL_THICKNESS = 1;
RACK_HOLE_THICKNESS = 9;
TOP_WALL_THICKNESS = 1.6;
MAIN_THICKNESS = BOTTOM_WALL_THICKNESS + RACK_HOLE_THICKNESS + TOP_WALL_THICKNESS;
MOUNT_Z_FROM_RACK_TOP=10.7;
MOUNT_Z = MAIN_THICKNESS - TOP_WALL_THICKNESS - MOUNT_Z_FROM_RACK_TOP - M3_RADIUS;
TOP_MOUNT_BORDER = 4;
TOP_MOUNT_HOLE_SPACING = 74;
TOP_MOUNT_WIDTH = TOP_MOUNT_HOLE_SPACING + 2 * (TOP_MOUNT_BORDER + M4_RADIUS);
WIRE_BRACKET_THICKNESS = 1;
WIRE_BRACKET_OUTER_RADIUS = 8;
WIRE_BRACKET_INNER_RADIUS = 5;


module hole(h, r, center, fn=100)
{
   fudge = 1/cos(180/fn);
   cylinder(h=h,r=r*fudge,center=center,$fn=fn);
}

radius = 5;
module rounded_corner()
{
	difference()
	{
		cylinder(r=radius, h=WALL_THICKNESS / 2);
		x = radius * 2;	
		translate([-radius, -x, 0])
		cube([x, x, WALL_THICKNESS]);
		translate([-x, 0, 0])
		cube([x, x, WALL_THICKNESS]);
	}
}

module spring_holder()
{
	difference()
	{
		translate([0, 20, 0])
		{
			rotate([-90, 0, -90])
			linear_extrude(WALL_THICKNESS)
			polygon([[0, 0], [20, 0], [0, SPRING_HOLDER_HEIGHT]]);

			rotate([0, 90, 0])
			minkowski($fn=100)
			{
				cube([SPRING_HOLDER_HEIGHT - radius, SPRING_HOLDER_HEIGHT - radius, WALL_THICKNESS / 2]);
				rounded_corner();
			}
		}

		translate([-WALL_THICKNESS / 4, PROBE_HOLE, MOUNT_Z])
		{
			rotate([0, 90, 0])
			hole(r=M3_RADIUS, h = WALL_THICKNESS * 2);
		}
	}
}

module spring_cone()
{
	translate([0, SPRING_Y, SPRING_Z])
	rotate([0, -90, 0])
	cylinder(h=SPRING_CONE_THICKNESS, r1=CONE_OUTER, r2=CONE_INNER, $fn=100);
}

module top_mounting_plate()
{
	difference()
	{
		screw_head_extra = 2;
		x = WIDTH - WALL_THICKNESS + screw_head_extra + M4_DIAMETER + TOP_MOUNT_BORDER;
		hole_pos = TOP_MOUNT_WIDTH / 2 - TOP_MOUNT_BORDER - M4_RADIUS;
		y_trans = -(TOP_MOUNT_WIDTH - LENGTH) / 2;
		translate([-x + WIDTH, -(TOP_MOUNT_WIDTH - LENGTH) / 2, MAIN_THICKNESS - TOP_WALL_THICKNESS])
		cube([x, TOP_MOUNT_WIDTH, TOP_WALL_THICKNESS]);
		translate([WALL_THICKNESS - M4_RADIUS - screw_head_extra, y_trans + TOP_MOUNT_BORDER + M4_RADIUS, MAIN_THICKNESS - 0.1])
		hole(r=M4_RADIUS, h=TOP_WALL_THICKNESS * 2, center=true);
		translate([WALL_THICKNESS - M4_RADIUS - screw_head_extra, y_trans + TOP_MOUNT_BORDER + M4_RADIUS + TOP_MOUNT_HOLE_SPACING, MAIN_THICKNESS - 0.1])
		hole(r=M4_RADIUS, h=TOP_WALL_THICKNESS * 2, center=true);
	}
}

module rack_holder()
{
	difference()
	{
		cube([WIDTH, LENGTH, MAIN_THICKNESS]);
		translate([WALL_THICKNESS, -1, BOTTOM_WALL_THICKNESS])
		cube([INNER_WIDTH, 60, RACK_HOLE_THICKNESS]); 
		translate([WALL_THICKNESS, 6.5, -BOTTOM_WALL_THICKNESS])
		cube([INNER_WIDTH, LENGTH - 2 * 6.5 , BOTTOM_WALL_THICKNESS * 3]);
	}
}

module holes()
{
	translate([-WALL_THICKNESS + 3, PROBE_HOLE, MOUNT_Z])
	{
		rotate([0, 90, 0])
		hole(r=2.85, h = WALL_THICKNESS, center=false, fn=6);
	}

	translate([WIDTH - 4, PROBE_HOLE, MOUNT_Z])
	{
		rotate([0, 90, 0])
		hole(r=2.6, h = WALL_THICKNESS, center=false);
	}

	translate([-SPRING_CONE_THICKNESS + CONE_HOLE_DEPTH, SPRING_Y, SPRING_Z])
	rotate([0, -90, 0])
	hole(r=M3_RADIUS_TIGHT, h = 30, center=false);

	translate([30 + WIDTH + SPRING_CONE_THICKNESS - CONE_HOLE_DEPTH, SPRING_Y, SPRING_Z])
	rotate([0, -90, 0])
	hole(r=M3_RADIUS_TIGHT, h = 30, center=false);
}

module wire_bracket()
{
	$fn=100;
	rotate([0, 90, 0])
	translate([0, WIRE_BRACKET_OUTER_RADIUS, 0])
	difference()
	{
		cylinder(r=WIRE_BRACKET_OUTER_RADIUS, h=WIRE_BRACKET_THICKNESS);
		translate([0, 0, -0.1])
		cylinder(r=WIRE_BRACKET_INNER_RADIUS, h=WIRE_BRACKET_THICKNESS + 0.2);
	}
}

module body()
{
	rack_holder();
	spring_holder();
	spring_cone();
	translate([WIDTH, 0, 0])
	mirror([1, 0, 0])
	{
		spring_holder();
		spring_cone();
	}
	wire_bracket();

	top_mounting_plate();
}


module probe_holder()
{
	difference()
	{
		body();		
		holes();
	}

}

rotate([180, 0, 0])
probe_holder();

