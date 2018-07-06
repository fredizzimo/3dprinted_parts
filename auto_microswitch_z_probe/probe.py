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


class Probe(cp.Part):
    active_flat_length = 5
    inactive_flat_length = 2
    height = 20
    bottom_width = 10
    radius = 8.5
    left_length = height - radius - 3
    thickness=5
    pin_area_width = 5
    probe_circle_radius = 1
    screw_radius = 3 / 2
    corner_radius = 1
    chamfer_radius = 0.3
    def make(self):

        probe_radius_45 = math.sin(math.pi / 4) * self.probe_circle_radius
        wp = cq.Workplane("XY")
        ret = (
            wp
            .hLine(self.active_flat_length)
            .vLine(-self.height)
            .hLine(-self.bottom_width)
            .vLine(self.left_length)
            .lineTo(-self.radius, -self.radius-self.inactive_flat_length)
            .vLine(self.inactive_flat_length)
            .radiusArc((0, 0), self.radius)
            .close()
            .extrude(self.thickness)
            .transformed(offset=(-self.radius + self.pin_area_width, 0))
            .vLine(-self.pin_area_width)
            .hLine(-self.pin_area_width)
            .hLine(-self.pin_area_width)
            .close()
            .cutThruAll(positive=True)
            .transformed(offset=(0, -self.pin_area_width))
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
            .circle(self.screw_radius)
            .cutThruAll(positive=True)
        )

        #ret = ret.edges(">X and >Y").fillet(self.corner_radius)
        #ret = ret.edges(">X and <Y").fillet(self.corner_radius)
        #ret = ret.edges("<X[1] and <Y[1]").fillet(self.corner_radius)

        ret = (
            cq.Workplane("XY")
            .transformed(origin=(0,0,0), offset=(0, 0, 0))
            .union(ret)
            #.moveTo(-self.radius + self.pin_area_width - self.probe_circle_radius,
            #    -self.pin_area_width - self.probe_circle_radius)
            #.rect(self.probe_circle_radius * 2,
            #     self.probe_circle_radius * 2, centered=False)
            #.extrude(10)
        )

        all_edges = ret.edges("|Z").vals()
        all_edges_selector = cq.Selector()
        screw_edges = cq.BoxSelector(
            (-self.screw_radius - 1 , -self.radius - self.screw_radius - 1, -100),
            (self.screw_radius + 1 , -self.radius + self.screw_radius + 1, 100),
        )
        if False:
            fillet_edges = cq.BoxSelector(
                (-self.radius + self.pin_area_width + self.probe_circle_radius, -self.pin_area_width - self.probe_circle_radius, -100),
                (-self.radius + self.pin_area_width - self.probe_circle_radius-1, -self.pin_area_width + self.probe_circle_radius, 100),
            )

        else:
            fillet_edges = cq.BoxSelector(
                (-100, -self.pin_area_width - self.probe_circle_radius, -100),
                (100, 100, 100),
            )
        if True:
            extra = 0.4
            chamfer_edges = cq.BoxSelector(
                (-self.radius + self.pin_area_width - self.probe_circle_radius - extra,
                 -self.pin_area_width - self.probe_circle_radius - extra,
                 -100),
                (-self.radius + self.pin_area_width - self.probe_circle_radius + self.probe_circle_radius * 2 + extra,
                 -self.pin_area_width - self.probe_circle_radius + self.probe_circle_radius * 2 + extra,
                 100),
                True
            )
        else:
            chamfer_edges = cq.BoxSelector(
                (-self.radius + self.pin_area_width + self.probe_circle_radius,
                 -self.pin_area_width - self.probe_circle_radius ,
                 -100),
                (-self.radius + self.pin_area_width - self.probe_circle_radius,
                 -self.pin_area_width + self.probe_circle_radius,
                 100),
                True
            )

        fillet_edges = cq.BoxSelector(
            (-self.radius + self.pin_area_width + self.probe_circle_radius, -self.pin_area_width - self.probe_circle_radius, -100),
            (-self.radius + self.pin_area_width - self.probe_circle_radius, -self.pin_area_width + self.probe_circle_radius, 100),
        )

        selector = (
            cq.SubtractSelector(
                all_edges_selector,
                fillet_edges)
        )
        fillet_selector = (
            cq.SubtractSelector(
                all_edges_selector,
                fillet_edges)
        )
        chamfer_selector = (
            cq.SubtractSelector(
                all_edges_selector,
                chamfer_edges)
        )
        #ret = ret.newObject(pin_edges.filter(ret.edges("|Z").vals())).fillet(self.corner_radius)

        # This
        ret = ret.newObject(fillet_selector.filter(ret.edges("|Z").vals())).fillet(self.corner_radius)

        #ret = ret.clean()
        #ret = ret.newObject(chamfer_selector.filter(ret.edges("|Z").vals())).fillet(self.corner_radius)

        #ret = ret.newObject(fillet_selector.filter(ret.edges("not |Z").vals())).chamfer(self.chamfer_radius)
        #ret = ret.newObject(chamfer_edges.filter(ret.edges("|Z").vals())).fillet(self.corner_radius)
        #ret = ret.newObject(chamfer_selector.filter(ret.edges("|Z").vals())).fillet(self.corner_radius)

        ret = ret.newObject(chamfer_edges.filter(ret.edges("not |Z").vals())).chamfer(self.chamfer_radius)
        ret=ret.clean()
        #ret = ret.newObject(chamfer_selector.filter(ret.edges("not |Z").vals())).chamfer(self.chamfer_radius)

        all_edges = ret.edges("not |Z").vals()
        curve_edges = chamfer_edges.filter(all_edges)
        edges = chamfer_selector.filter(all_edges)
        ret = ret.newObject(edges)

        ret = ret.chamfer(self.chamfer_radius)


        #return cq.Workplane("XY").box(10, 10, 10).edges(">Z").chamfer(self.chamfer_radius)


        return ret



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

#assembly = Assembly()
#display(assembly)
probe = Probe()
display(probe)
