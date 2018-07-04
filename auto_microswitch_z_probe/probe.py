import cadquery as cq
import cqparts as cp
from cqparts.params import *
from cqparts.display import display


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
            offset=(
                right_edge_plane.plane.toLocalCoords(slot_wall.vertices(">X").first().val().Center()).x,
                right_edge_plane.plane.toLocalCoords(top_wall.vertices("<Y").first().val().Center()).y,
                right_edge_plane.plane.toLocalCoords(pin.vertices("<Z").first().val().Center()).z))
        right_edge = right_edge_plane.rect(
            right_edge_plane.plane.toLocalCoords(top_wall.vertices(">X").first().val().Center()).x,
            self.width,
            centered=False).\
            extrude(self.slot_height)

        pin = pin.edges("<Z and |Y").fillet(self.pin_width/2 - 0.0001)
        pin = pin.edges("<Y and |Z").chamfer(self.chamfer)
        pin = pin.edges("<Y and >Z").chamfer(self.chamfer)

        ret = slot_wall.union(top_wall)
        ret = ret.union(right_edge)
        ret = ret.union(right_edge.mirror(mirrorPlane="YZ"))

        ret = ret.edges().chamfer(self.chamfer)
        ret = ret.union(pin)
        return ret

toggle = Toggle(
    length=100,
    width=6,
    height = 7,
    pin_width=1.5,
    slot_width = 5,
    slot_height = 5,
    chamfer = 0.3
)

display(toggle)
