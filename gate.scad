// Gate hinge for Stephen's house
//
//  Rendered in two parts:
//      Hinge body
//      Hinge clamp
//

/* [Gate] ---------------------- */

// [Column Size]
_ColumnSize = 51;		// From testfit

/* [Hinge] */

// [Hinge Size]
_HingeSize = 80;

// [Hinge Thickness]
_HingeThickness = 20.0;

/* [Bearing] ---------------------- */

// [Bearing Diameter]
_BearingDiameter = 15.0;

// [Bearing Height]
_BearingHeight = 3.0;

/* [Shaft] ---------------------- */

// [Shaft Diameter]
_ShaftDiameter = 5.0;

/* [Screws] ---------------------- */

// [Screw Count]
_ScrewCount = 1;

// [Screw Shaft Diameter]
_ScrewShaftDiameter = 1.5;

// [Screw Head Diameter]
_ScrewHeadDiameter = 3.0;

// [Screw Hole Length]
_ScrewHoleLength = 8.0;

/* [Inserts] ---------------------- */

// [Insert Diameter]
_InsertDiameter = 6.0;

// [Insert Hole Length]
_InsertHoleLength = 2.5;

// Assertions
assert(_HingeSize > _ColumnSize, "Twilight zone!");

/* [Inserts] */

module RenderHinge(HingeSize, HingeThickness)
{
	union()
	{
		linear_extrude(HingeThickness)
		{
			square([HingeSize, HingeSize], center=false);
		}
	
		linear_extrude(HingeThickness / 2)
		{
			translate([HingeSize, 0, 0])
			{
				square([HingeSize / 2, HingeSize], center=false);
			}
			
			translate([HingeSize * 1.5, HingeSize / 2, 0])
			{
				circle(d=HingeSize, $fn=99);
			}
		}
	}
}

// 
// RenderScrewHole -
//
//  Render a hole for a screw with room for a recessed head.
//

module RenderScrewHole(HeadDiameter, ShaftDiameter, HeadLength, ShaftLength)
{
    union()
    {
        // Hole for head
    	cylinder(h=HeadLength, d=HeadDiameter, $fn=99);
     
        // Hole for shaft
        translate([0, 0, HeadLength])
        {
            cylinder(h=ShaftLength, d=ShaftDiameter, $fn=99);
        }
    }
}

//
// RenderInsertHole -
//
//  Render a hole for a threaded insert.
//

module RenderInsertHole(InsertDiameter, InsertHoleLength)
{
    cylinder(h=InsertHoleLength, d=InsertDiameter, $fn=99);
}

module RenderHingeHoles(HingeSize, ColumnSize, HingeThickness, BearingDiameter, BearingHeight, ShaftDiameter, ScrewCount, ScrewHeadDiameter, ScrewShaftDiameter, ScrewHoleLength, InsertDiameter, InsertHoleLength)
{
	// Hole for column
	translate([HingeSize / 2, HingeSize / 2, 0])
	{	
		linear_extrude(HingeThickness)
		square([ColumnSize, ColumnSize], center=true);
	}
	
	// Hole for bearing
	translate([HingeSize * 1.5, HingeSize / 2, HingeThickness / 2 - BearingHeight])
	{
		linear_extrude(BearingDiameter)
		{
			circle(d=BearingDiameter, $fn=99);
		}
	}
	
	// Hole for shaft
	translate([HingeSize * 1.5, HingeSize / 2, 0])
	{
		linear_extrude(HingeThickness - BearingHeight)
		{
			circle(d=ShaftDiameter, $fn=99);
		}
	}
	
	//
    // Holes for screws and inserts:
    //
    //  ScrewDeltaY         - Y spacing between screws
    //  ScrewInset          - X offset from near and far vertical edges
    //  ScrewHeadHoleLength - Length of hole for head of screw
    //
    //  InsertDeltaX        - X offset from left side to insert
    
	ScrewDeltaY         = HingeThickness / (ScrewCount + 1);
	ScrewInset          = (HingeSize - ColumnSize) / 4;
    ScrewHeadHoleLength = HingeSize / 2 - ScrewHoleLength;
    InsertDeltaX        = HingeSize / 2;
                
	for (Screw = [1 : ScrewCount])
	{
		// Close edge
		translate([0, ScrewInset, Screw * ScrewDeltaY])
		{
			rotate([0, 90, 0])
			{
                RenderScrewHole(ScrewHeadDiameter, ScrewShaftDiameter, ScrewHeadHoleLength, ScrewHoleLength);
			}
		}
		
		// Far edge
		translate([0, HingeSize - ScrewInset, Screw * ScrewDeltaY])
		{
			rotate([0, 90, 0])
			{
                RenderScrewHole(ScrewHeadDiameter, ScrewShaftDiameter, ScrewHeadHoleLength, ScrewHoleLength);
            }
		}
	}
    
    // Holes for inserts (spacing matches screws)
    for (Insert = [1 : ScrewCount])
    {
    	// Close edge
		translate([InsertDeltaX, ScrewInset, Insert * ScrewDeltaY])
		{
			rotate([0, 90, 0])
			{
                RenderInsertHole(InsertDiameter, InsertHoleLength);
			}
		}
		
		// Far edge
		translate([InsertDeltaX, HingeSize - ScrewInset, Insert * ScrewDeltaY])
		{
			rotate([0, 90, 0])
			{
                RenderInsertHole(InsertDiameter, InsertHoleLength);
            }
		}
    }
}

module RenderWholeHinge(HingeSize, ColumnSize, HingeThickness, BearingDiameter, BearingHeight, ShaftDiameter, ScrewCount, ScrewHeadDiameter, ScrewShaftDiameter, ScrewHoleLength, InsertDiameter, InsertHoleLength)
{
	difference()
	{
        // Matter
		RenderHinge(HingeSize, HingeThickness);
        
        // Anti-matter
		RenderHingeHoles(HingeSize, ColumnSize, HingeThickness, BearingDiameter, BearingHeight, ShaftDiameter, ScrewCount, ScrewHeadDiameter, ScrewShaftDiameter, ScrewHoleLength, InsertDiameter, InsertHoleLength);
	}
}

module main(ColumnSize, HingeSize, HingeThickness, BearingDiameter, BearingHeight, ShaftDiameter, ScrewCount, ScrewHeadDiameter, ScrewShaftDiameter, ScrewHoleLength, InsertDiameter, InsertHoleLength)
{
	// Render twice, with different clipping, to get assemblable parts
	
	// Clamp - Back part
	intersection()
	{
		RenderWholeHinge(HingeSize, ColumnSize, HingeThickness, BearingDiameter, BearingHeight, ShaftDiameter, ScrewCount, ScrewHeadDiameter, ScrewShaftDiameter, ScrewHoleLength, InsertDiameter, InsertHoleLength);
	
		cube([HingeSize / 2, HingeSize, HingeThickness]);
	}
	
	// Hinge - Front part
	translate([HingeSize / 2, 0, 0])
	{
		intersection()
		{
			RenderWholeHinge(HingeSize, ColumnSize, HingeThickness, BearingDiameter, BearingHeight, ShaftDiameter, ScrewCount, ScrewHeadDiameter, ScrewShaftDiameter, ScrewHoleLength, InsertDiameter, InsertHoleLength);
	
			translate([HingeSize /2, 0, 0])
			{
				cube([HingeSize * 1.5, HingeSize, HingeThickness]);
			}
		}
	}
}

main(_ColumnSize, _HingeSize, _HingeThickness, _BearingDiameter, _BearingHeight, _ShaftDiameter, _ScrewCount, _ScrewHeadDiameter, _ScrewShaftDiameter, _ScrewHoleLength, _InsertDiameter, _InsertHoleLength);

//RenderScrewHole(20, 10, 30, 50);
