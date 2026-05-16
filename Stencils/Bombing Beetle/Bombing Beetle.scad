/*#################################################################################*\
	   _____ _______ _______      ______ _______ __  __ _______ _______
	 _|     |    ___|_     _|    |   __ \   _   |  |/  |    ___|_     _|
	|       |    ___| |   |      |      <       |     <|    ___| |   |
	|_______|_______| |___|      |___|__|___|___|__|\__|_______| |___|

	-----------------------------------------------------------------------------

	Developed by:           Jerry van Heerikhuize
	Modified by:            Jerry van Heerikhuize

	-----------------------------------------------------------------------------

	Version:                1.7.0
	Creation Date:          25/01/25
	Modification Date:      07/04/26
	Email:                  jvanheerikhuize@gmail.com
	Description:            Customizable stencil generator for OpenSCAD
	Dependencies:           none

\*#################################################################################*/


/*#################################################################################*\

    QUALITY

\*#################################################################################*/

/* [Quality:] */
// Use lower resolution for faster preview; disable for final high-quality render
preview_mode = true; //[true:false]
// Slice the model in half to inspect the plate profile and cutout depth
show_cross_section = false; //[true:false]


/*#################################################################################*\

    CONFIGURATION

\*#################################################################################*/

/* [SVG File:] */
// Filename of the SVG to import — must be in the same folder as this .scad file
svg_file = "bee_stencil.svg";
// Native width of the SVG artwork as imported by OpenSCAD, in mm.
// To find this value: import your SVG with design_scale=1 and measure it in the OpenSCAD viewport,
// or check Document Properties in Inkscape (divide pixel value by 3.7795 to convert to mm).
svg_native_width = 100; //[1:999]
// Native height of the SVG artwork as imported by OpenSCAD, in mm
svg_native_height = 100; //[1:999]

/* [Design:] */
// Scale factor for the SVG cutout only — the plate auto-sizes around the scaled artwork
design_scale = 1; //[0.1:0.1:10]
// How much wider the top (spray-side) opening is than the bottom per side, in mm.
// Creates a knife-edge at the surface contact side to reduce paint bleed. 0 = vertical walls.
bevel_width = 0; //[0:0.1:5]
// Height of the beveled portion measured down from the top face, in mm
bevel_depth = 1; //[0.2:0.1:10]

/* [Plate:] */
// Distance between the SVG cutout and the plate edge, in mm.
// The plate automatically grows by 2 × plate_border around the scaled SVG.
plate_border = 10; //[0:50]
// Thickness of the stencil plate along the Z-axis, in mm
plate_depth = 3; //[1:20]
// Radius of the rounded corners on the plate. 0 = sharp corners.
plate_corner_radius = 2; //[0:0.5:20]

/* [Model Scale:] */
// Uniform scale applied to the entire assembled model (plate, cutout, handles, marks).
// Use this to resize the whole stencil proportionally — e.g. 0.5 = half size.
model_scale = 1; //[0.1:0.1:10]

/* [Handles:] */
// Enable handle 1 (positive-Y side of the stencil)
show_handle_1 = true; //[true:false]
// Enable handle 2 (negative-Y side of the stencil, opposite handle 1)
show_handle_2 = true; //[true:false]
// Width of the handle tab along the X-axis, in mm
handle_width = 30; //[5:100]
// Length the handle tab protrudes beyond the plate edge, in mm
handle_length = 40; //[5:200]
// How far the handle overlaps into the plate edge to ensure a watertight union
handle_overlap = 1; //[0:10]
// Cut a circular finger hole through each enabled handle
show_handle_grip = false; //[true:false]
// Diameter of the circular grip hole, in mm
handle_grip_diameter = 15; //[5:50]

/* [Registration Marks:] */
// Cut crosshair alignment marks into all four corners of the plate
show_registration_marks = true; //[true:false]
// Total length of each crosshair arm, in mm
reg_mark_size = 10; //[3:30]
// Width of each crosshair arm, in mm
reg_mark_width = 1; //[0.5:0.1:5]
// Distance from the plate corner to the centre of the crosshair, in mm
reg_mark_inset = 8; //[3:30]


/*#################################################################################*\

    HIDDEN

\*#################################################################################*/

/* [Hidden] */
// $fa — Minimum angle (degrees) between polygon vertices on curved surfaces.
// Lower values produce smoother curves at the cost of more triangles.
// 5° gives a usable preview; 1° is suitable for final render.
$fa = preview_mode ? 5   : 1;

// $fs — Minimum segment length (mm) on curved surfaces.
// Acts as a second constraint alongside $fa — whichever produces fewer segments wins.
// 0.5mm is adequate for preview; 0.1mm ensures smooth edges on small features.
$fs = preview_mode ? 0.5 : 0.1;

// ── Derived values ────────────────────────────────────────────────────────────
// Scaled SVG dimensions
scaled_svg_width  = svg_native_width  * design_scale;
scaled_svg_height = svg_native_height * design_scale;
// Plate dimensions are computed from the scaled SVG plus the border on each side
plate_width  = scaled_svg_width  + 2 * plate_border;
plate_length = scaled_svg_height + 2 * plate_border;

// ── Assertions ────────────────────────────────────────────────────────────────
assert(len(svg_file)      > 0,  "svg_file must not be empty");
assert(svg_native_width   > 0,  "svg_native_width must be positive");
assert(svg_native_height  > 0,  "svg_native_height must be positive");
assert(design_scale       > 0,  "design_scale must be positive");
assert(bevel_width        >= 0, "bevel_width must be zero or positive");
assert(bevel_depth        > 0,  "bevel_depth must be positive");
assert(bevel_depth        < plate_depth, "bevel_depth must be less than plate_depth");
assert(model_scale        > 0,  "model_scale must be positive");
assert(plate_border       >= 0, "plate_border must be zero or positive");
assert(plate_depth        > 0,  "plate_depth must be positive");
assert(plate_corner_radius >= 0, "plate_corner_radius must be zero or positive");
assert(
    plate_corner_radius <= min(plate_width, plate_length) / 2,
    "plate_corner_radius must not exceed half the smallest plate dimension"
);
assert(handle_width       > 0,  "handle_width must be positive");
assert(handle_length      > 0,  "handle_length must be positive");
assert(handle_overlap     >= 0, "handle_overlap must be zero or positive");
assert(handle_grip_diameter > 0,  "handle_grip_diameter must be positive");
assert(
    !show_handle_grip || handle_grip_diameter < handle_width,
    "handle_grip_diameter must be less than handle_width"
);
assert(
    !show_handle_grip || handle_grip_diameter < handle_length,
    "handle_grip_diameter must be less than handle_length"
);
assert(reg_mark_size      > 0,  "reg_mark_size must be positive");
assert(reg_mark_width     > 0,  "reg_mark_width must be positive");
assert(reg_mark_inset     > 0,  "reg_mark_inset must be positive");
assert(
    !show_registration_marks || reg_mark_inset > plate_corner_radius,
    "reg_mark_inset must be greater than plate_corner_radius to avoid marks landing outside rounded corners"
);
assert(
    !show_registration_marks || reg_mark_inset + reg_mark_size / 2 < plate_width  / 2,
    "registration mark extends beyond plate width — reduce reg_mark_size or reg_mark_inset"
);
assert(
    !show_registration_marks || reg_mark_inset + reg_mark_size / 2 < plate_length / 2,
    "registration mark extends beyond plate length — reduce reg_mark_size or reg_mark_inset"
);


/*#################################################################################*\

    MAIN

\*#################################################################################*/

scale([model_scale, model_scale, model_scale])
    assemble();

// Entry point: optionally clips a cross-section, then delegates to build()
module assemble() {
    if (show_cross_section) {
        // Intersect with a half-space on the negative-X side to expose the
        // plate profile and cutout depth when viewed from the front.
        // The clip volume is tall enough to include both handle tabs.
        intersection() {
            build();
            translate([
                -(plate_width / 2 + 1),
                -(plate_length / 2 + handle_length + 1),
                -(plate_depth / 2 + 1)
            ])
                cube([plate_width / 2 + 1, plate_length + 2 * handle_length + 2, plate_depth + 2]);
        }
    } else {
        build();
    }
}

// Assembles the full stencil: plate and handles as a union, with the SVG cutout
// and registration marks subtracted in a single difference operation
module build() {
    difference() {
        union() {
            stencil_plate();
            if (show_handle_1) handle(1);
            if (show_handle_2) handle(-1);
        }
        svg_cutout();
        if (show_registration_marks) registration_marks();
        if (show_handle_grip && show_handle_1) handle_grip(1);
        if (show_handle_grip && show_handle_2) handle_grip(-1);
    }
}


/*#################################################################################*\

    PLATE

\*#################################################################################*/

// Flat plate that forms the stencil body, with optional rounded corners
module stencil_plate() {
    if (plate_corner_radius > 0) {
        r = plate_corner_radius;
        hull() {
            for (x = [-plate_width/2 + r, plate_width/2 - r])
                for (y = [-plate_length/2 + r, plate_length/2 - r])
                    translate([x, y, -plate_depth/2])
                        cylinder(h = plate_depth, r = r);
        }
    } else {
        cube([plate_width, plate_length, plate_depth], center = true);
    }
}


/*#################################################################################*\

    HANDLES

\*#################################################################################*/

// A flat tab extending outward from the plate edge.
// side = +1 for positive-Y, -1 for negative-Y.
// Overlaps the plate by `handle_overlap` mm to ensure a watertight union.
module handle(side) {
    y_offset = side == 1
        ? plate_length / 2 - handle_overlap
        : -(plate_length / 2 + handle_length);
    translate([
        -handle_width / 2,
        y_offset,
        -plate_depth / 2
    ])
        cube([handle_width, handle_length + handle_overlap, plate_depth]);
}

// Circular grip hole centred on a handle tab.
// side = +1 for positive-Y handle, -1 for negative-Y handle.
module handle_grip(side) {
    cy = side == 1
        ? plate_length / 2 + handle_length / 2
        : -(plate_length / 2 + handle_length / 2);
    translate([0, cy, 0])
        cylinder(h = plate_depth + 2, d = handle_grip_diameter, center = true);
}


/*#################################################################################*\

    REGISTRATION MARKS

\*#################################################################################*/

// Cuts crosshair alignment marks into all four corners of the plate.
// Each crosshair centre is inset `reg_mark_inset` mm from both edges at that corner.
module registration_marks() {
    corners = [
        [ plate_width / 2 - reg_mark_inset,  plate_length / 2 - reg_mark_inset],
        [-plate_width / 2 + reg_mark_inset,  plate_length / 2 - reg_mark_inset],
        [ plate_width / 2 - reg_mark_inset, -plate_length / 2 + reg_mark_inset],
        [-plate_width / 2 + reg_mark_inset, -plate_length / 2 + reg_mark_inset],
    ];
    for (c = corners) {
        translate([c[0], c[1], 0]) {
            // Horizontal arm
            cube([reg_mark_size, reg_mark_width, plate_depth + 2], center = true);
            // Vertical arm
            cube([reg_mark_width, reg_mark_size, plate_depth + 2], center = true);
        }
    }
}


/*#################################################################################*\

    SVG CUTOUT

\*#################################################################################*/

// Extrudes the SVG artwork through the full plate thickness to create the cutout.
// Scale is applied to the 2D profile only, keeping the extrusion height exact.
// The cutout is clipped to the scaled SVG bounding box (expanded by bevel_width),
// so any SVG geometry that overflows its natural canvas boundary cannot cut through
// the plate border.
// When bevel_width > 0, a stepped bevel widens the top (spray-side) opening,
// creating a knife-edge at the bottom (surface-contact) side to reduce paint bleed.
module svg_cutout() {
    intersection() {
        cube([
            scaled_svg_width + 2 * bevel_width,
            scaled_svg_height + 2 * bevel_width,
            plate_depth + 2
        ], center = true);

        union() {
            // Full-depth cut at exact SVG size (knife-edge at bottom)
            linear_extrude(height = plate_depth + 2, center = true, convexity = 100)
                scale([design_scale, design_scale])
                    import(svg_file, center = true);

            // Top-side bevel: wider cut, partial depth
            if (bevel_width > 0) {
                translate([0, 0, (plate_depth / 2) - bevel_depth])
                    linear_extrude(height = bevel_depth + 1, convexity = 100)
                        offset(delta = bevel_width)
                            scale([design_scale, design_scale])
                                import(svg_file, center = true);
            }
        }
    }
}
