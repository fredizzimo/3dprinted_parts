import cadquery as cq
import cqparts as cp
from cqparts.params import *
from cqparts.display import display
import cqparts.constraint
from cqparts.utils.geometry import CoordSystem

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
        pin = cq.Workplane("XY").box(self.pin_width, self.slot_width, self.slot_height)

        top_wall = pin.edges(">Z and <Y").workplane().box(
            self.length,
            self.width,
            self.height - self.slot_height,
            centered=(True, False, False), combine=False)

        slot_wall = pin.faces(">Y").workplane(). \
            rect(self.pin_width + self.slot_width * 2, self.slot_height). \
            extrude(self.width - self.slot_width, combine=False)

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
                self.slot_width,
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
        return (
            top.union(back).
            union(front).
            union(left_bottom).
            union(right_bottom).
            union(front_mount_bracket).
            union(rear_mount_bracket)
        )

    @property
    def toggle_mate(self):
        local = self.local_obj
        return self._toggle_mate


class Assembly(cp.Assembly):
    def make_components(self):
        toggle = Toggle(
            length=80,
            width=6,
            height=7,
            pin_width=1.5,
            slot_width=5,
            slot_height=5,
            chamfer=0.3
        )

        mount = Mount(
            width=60,
            wall_thickness=1,
            toggle_width=toggle.width,
            toggle_height=toggle.height,
            extra_space=0.1,
            slot_width=2 * toggle.slot_width + toggle.pin_width,
            bracket_width=10,
            bracket_height=10,
            mount_hole_diameter=3,
            probe_hole_distance = 12,
        )
        return {
            "toggle": toggle,
            "mount": mount,
        }

    def make_constraints(self):
        toggle = self.components["toggle"]
        mount = self.components["mount"]
        return [
            cp.constraint.Fixed(
                mate=mount.mate_origin,
                world_coords=CoordSystem()
            ),
            cp.constraint.Coincident(toggle.mate, mount.toggle_mate)
        ]

assembly = Assembly()
display(assembly)
