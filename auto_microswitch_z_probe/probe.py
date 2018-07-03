import cadquery as cq
import cqparts as cp
from cqparts.params import *
from cqparts.display import display

class Toggle(cp.Part):
   length = PositiveFloat(10)
   width = PositiveFloat(10)
   height = PositiveFloat(10)

   def make(self):
      return cq.Workplane("XY").box(self.length, self.width, self.height)


toggle = Toggle(length=100, width=20, height=10)
display(toggle)
