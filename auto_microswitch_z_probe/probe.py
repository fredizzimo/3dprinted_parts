import cadquery as cq
import cqparts as cp
from cqparts.params import *
from cqparts.display import display
import cqparts.constraint
from cqparts.utils.geometry import CoordSystem
import math


#cadquery bugs
# there's no solid when you create a new workplane, or want to transform for example

def toLocalVector(self, x=0.0, y=0.0, z=0.0):
    if type(x) is cq.Workplane:
        x = x.first().val().Center().x
    if type(y) is cq.Workplane:
        y = y.first().val().Center().y
    if type(z) is cq.Workplane:
        z = z.first().val().Center().z

    return self.plane.toLocalCoords(cq.Vector( x, y, z))

original_transformed = cq.Workplane.transformed


def transformed(self, rotate=(0, 0, 0), offset=(0, 0, 0), origin=None):
    if origin is not None:
        x, y, z = origin

        if x is None:
            x = self.plane.origin.x
        if y is None:
            y = self.plane.origin.y
        if z is None:
            z = self.plane.origin.z

        local = self.toLocalVector(x, y, z)
        xo, yo, zo = offset
        offset = (xo + local.x, yo + local.y, zo + local.z)

    return original_transformed(self, rotate, offset)

cq.Workplane.toLocalVector = toLocalVector
cq.Workplane.transformed = transformed


class Toggle(cp.Part):
    length = PositiveFloat()
    width = PositiveFloat()
    height = PositiveFloat()
    pin_width = PositiveFloat()
    slot_height = PositiveFloat()
    slot_width = PositiveFloat()
    chamfer = PositiveFloat()

    def make(self):
        pin = cq.Workplane("XY").box(self.pin_width, self.slot_height, self.slot_height)

        top_wall = pin.edges(">Z and <Y").workplane().box(
            self.length,
            self.width,
            self.height - self.slot_height,
            centered=(True, False, False), combine=False)

        slot_wall = pin.faces(">Y").workplane(). \
            rect(self.pin_width + self.slot_width * 2, self.slot_height). \
            extrude(self.width - self.slot_height, combine=False)

        right_edge_plane = cq.Workplane("XY")
        right_edge_plane = right_edge_plane.transformed(
            offset=right_edge_plane.toLocalVector(
                slot_wall.vertices(">X"),
                top_wall.vertices("<Y"),
                pin.vertices("<Z")))
        right_edge = right_edge_plane.rect(
            right_edge_plane.toLocalVector(top_wall.vertices(">X")).x,
            self.width,
            centered=False).\
            extrude(self.slot_height)

        pin_plane = (
            pin.faces("<Z").workplane(invert=True)
            .transformed(origin=(None, right_edge.faces("<Z"), None))
            .plane
        )
        self._mate=cp.constraint.Mate(
            self,
            CoordSystem.from_plane(pin_plane))

        pin = pin.edges("<Z and |Y").fillet(self.pin_width/2 - 0.0001)
        pin = pin.edges("<Y and |Z").chamfer(self.chamfer)
        pin = pin.edges("<Y and >Z").chamfer(self.chamfer)


        ret = slot_wall.union(top_wall)
        ret = ret.union(right_edge)
        ret = ret.union(right_edge.mirror(mirrorPlane="YZ"))

        ret = ret.edges().chamfer(self.chamfer)
        ret = ret.union(pin)

        return ret

    @property
    def mate(self):
        local = self.local_obj
        return self._mate


class Mount(cp.Part):
    width = PositiveFloat()
    wall_thickness = PositiveFloat()
    toggle_width = PositiveFloat()
    toggle_height = PositiveFloat()
    slot_width = PositiveFloat()
    extra_space = PositiveFloat()
    bracket_width = PositiveFloat()
    bracket_height = PositiveFloat()
    mount_hole_diameter = PositiveFloat()
    probe_hole_distance = PositiveFloat()
    hide_front = Boolean(False)

    def make(self):
        top = cq.Workplane("XY").box(
            self.width,
            self.toggle_width + self.extra_space,
            self.wall_thickness)
        back = (
            top.faces(">Z").workplane(invert=True).
            transformed(
                origin=( None, top.vertices(">Y"), None ),
                offset=(0, -self.wall_thickness, 0)
            ).
            box(
                self.width,
                self.wall_thickness,
                self.toggle_height + self.extra_space + 2*self.wall_thickness,
                centered=[True, False, False],
                combine=False)
        )
        front = back.mirror(mirrorPlane="XZ").translate((0,0,0))
        left_bottom = (
            back.faces("<Z").workplane(invert=True).
            transformed(
                origin=(front.vertices("<X"), front.vertices(">Y"), None),
            ).
            box(
                (self.width - self.slot_width) / 2,
                self.toggle_width + self.extra_space,
                self.wall_thickness,
                combine=False,
                centered=(False, False, False)
            )
        )
        right_bottom = left_bottom.mirror(mirrorPlane="YZ")

        front_mount_bracket = (
            front.faces("<Z").workplane().
            box(
                self.bracket_width,
                self.wall_thickness,
                self.bracket_height,
                combine=False,
                centered=(True, True, False)
            ).
            faces(">Y").
            workplane().
            transformed(
                origin=(None, None, top.faces("<Z")),
                offset=(0, -self.extra_space - self.probe_hole_distance, 0)
            ).
            hole(self.mount_hole_diameter)
        )

        rear_mount_bracket = front_mount_bracket.mirror(mirrorPlane="XZ")

        toggle_plane = (
            right_bottom.faces(">Z").workplane()
                .transformed(
                origin=(
                    0,
                    None,
                    None
                )
            )
            .plane
        )
        self._toggle_mate = cp.constraint.Mate(
            self,
            CoordSystem.from_plane(toggle_plane))

        probe_plane = (
            front_mount_bracket.faces(">Y").workplane()
                .transformed(
                    origin=(None, None, top.faces("<Z")),
                    offset=(0, -self.extra_space - self.probe_hole_distance, 0)
            )
            .plane
        )
        self._probe_mate = cp.constraint.Mate(
            self,
            CoordSystem.from_plane(probe_plane))

        ret = (
            top.union(back).
            union(left_bottom).
            union(right_bottom).
            union(rear_mount_bracket)
        )

        if not self.hide_front:
            ret = ret.union(front).union(front_mount_bracket)
        return ret

    @property
    def toggle_mate(self):
        local = self.local_obj
        return self._toggle_mate

    @property
    def screw_hole(self):
        local = self.local_obj
        return self._probe_mate


class Probe(cp.Part):
    height = PositiveFloat()
    thickness = PositiveFloat()
    bottom_width = PositiveFloat()
    active_flat_length = PositiveFloat()
    inactive_flat_length = PositiveFloat()
    radius = PositiveFloat()
    left_slope_height = PositiveFloat()
    pin_height = PositiveFloat()
    probe_circle_radius = PositiveFloat()
    corner_radius = PositiveFloat()
    chamfer = PositiveFloat()
    screw_diameter = PositiveFloat()

    def make(self):

        probe_radius_45 = math.sin(math.pi / 4) * self.probe_circle_radius
        wp = cq.Workplane("XY")
        ret = (
            wp
            .hLine(self.active_flat_length)
            .vLine(-self.height)
            .hLine(-self.bottom_width)
            .vLine(self.height - self.radius - self.left_slope_height)
            .lineTo(-self.radius, -self.radius-self.inactive_flat_length)
            .vLine(self.inactive_flat_length)
            .radiusArc((0, 0), self.radius)
            .close()
            .extrude(self.thickness)
            .transformed(offset=(-self.radius + self.pin_height, 0))
            .vLine(-self.pin_height)
            .hLine(-self.pin_height)
            .hLine(-self.pin_height)
            .close()
            .cutThruAll(positive=True)
            .transformed(offset=(0, -self.pin_height))
            .circle(self.probe_circle_radius)
            .cutThruAll(positive=True)
            .transformed(offset=(
                0,
                self.probe_circle_radius + probe_radius_45))
            .radiusArc((probe_radius_45, -self.probe_circle_radius), -self.probe_circle_radius)
            .hLine(-self.probe_circle_radius)
            .close()
            .cutThruAll(positive=True)
            .transformed(offset=(
                -self.probe_circle_radius - probe_radius_45,
                -self.probe_circle_radius - probe_radius_45))
            .radiusArc((self.probe_circle_radius, -probe_radius_45), self.probe_circle_radius)
            .vLine(self.probe_circle_radius)
            .close()
            .cutThruAll(positive=True)
            .workplane()
            .transformed(
                origin=(0, 0, 0),
                offset=(0, -self.radius, 0)
            )
            .circle(self.screw_diameter / 2)
            .cutThruAll(positive=True)
        )

        ret = (
            cq.Workplane("XY")
            .transformed(origin=(0,0,0), offset=(0, 0, 0))
            .union(ret)
        )

        extra_probe_circle_radius = self.chamfer + 0.01
        probe_circle_left = (
            -self.radius + self.pin_height - self.probe_circle_radius)
        probe_circle_bottom = (
            -self.pin_height - self.probe_circle_radius)
        probe_circle_edges = cq.BoxSelector(
            (probe_circle_left - extra_probe_circle_radius,
             probe_circle_bottom - extra_probe_circle_radius,
             -100),
            (probe_circle_left + self.probe_circle_radius * 2 + extra_probe_circle_radius,
             probe_circle_bottom + self.probe_circle_radius * 2 + extra_probe_circle_radius,
             100),
            True
        )

        other_edges = (
            cq.SubtractSelector(
                cq.Selector(),
                probe_circle_edges)
        )
        ret = ret.newObject(
            other_edges.filter(
                ret.edges("|Z").vals())).fillet(self.corner_radius)

        ret = ret.newObject(
            probe_circle_edges.filter(
                ret.edges("not |Z").vals())).chamfer(self.chamfer)
        ret = ret.newObject(
            other_edges.filter(
                ret.edges("not |Z").vals())).chamfer(self.chamfer)

        return ret

    @property
    def screw_hole(self):
        return cp.constraint.Mate(
            self,
            CoordSystem(
                origin=(0, -self.radius, 0),
                xDir=(1, 0, 0),
                normal=(0, 0, 1)
            )
        )


class Assembly(cp.Assembly):
    def make_components(self):
        chamfer = 0.3
        screw_diameter = 3
        probe = Probe(
            height=20,
            thickness=5,
            bottom_width=10,
            active_flat_length=8.5,
            inactive_flat_length=2,
            radius=8.5,
            left_slope_height=3,
            pin_height=5,
            probe_circle_radius=1,
            corner_radius=1,
            chamfer=chamfer,
            screw_diameter=screw_diameter,
        )

        toggle = Toggle(
            length=80,
            width=6,
            height=7,
            pin_width=1.5, # TODO match the radius with the hole
            slot_width=probe.active_flat_length + probe.radius,
            slot_height=probe.pin_height,
            chamfer=chamfer
        )

        mount = Mount(
            width=60,
            wall_thickness=1,
            toggle_width=toggle.width,
            toggle_height=toggle.height,
            extra_space=0.1,
            slot_width=2 * toggle.slot_width + toggle.pin_width,
            bracket_width=10,
            bracket_height=7,
            mount_hole_diameter=screw_diameter,
            probe_hole_distance = probe.radius + (toggle.height - toggle.slot_height),
            hide_front=False,
        )
        return {
            "toggle": toggle,
            "mount": mount,
            "probe": probe
        }

    def make_constraints(self):
        toggle = self.components["toggle"]
        mount = self.components["mount"]
        probe = self.components["probe"]
        return [
            cp.constraint.Fixed(
                mate=mount.mate_origin,
                world_coords=CoordSystem()
            ),
            cp.constraint.Coincident(toggle.mate, mount.toggle_mate),
            cp.constraint.Coincident(probe.screw_hole, mount.screw_hole)
        ]

assembly = Assembly()
display(assembly)
