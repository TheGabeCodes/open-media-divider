// Open Media Divider: shelf divider with flush two-colour lettering, printed face-down.
// The visible face is printed on the build plate. The first layers hold the letters, set flush into the face.
// Optionally a backing in the letter colour sits behind the face, so the letters can't show through from the back.
// Export the "white" (body) and "black" (letters + backing) parts separately and load them together in the
// slicer as one object with two parts. The colour names are just names: assign any filaments in the slicer.
//
// Copyright (C) 2026 TheGabeCodes. https://github.com/TheGabeCodes/open-media-divider
// Licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later); see LICENSE.

/* [Label] */
// The text on the label
label_text = "Gilliam, Terry";
// Font. Roboto Condensed Bold is the default: narrow enough for long names, open and easy to read. Barlow Semi Condensed is similarly narrow but squarer; Inter is wider. Liberation Sans is metrically matched to Arial / Helvetica and ships with OpenSCAD. In desktop OpenSCAD, the other fonts must be installed on your computer
font = "Roboto Condensed:style=Bold"; // ["Barlow Semi Condensed:style=Bold", "Inter:style=Bold", "Inter:style=SemiBold", "Liberation Sans:style=Bold", "Liberation Sans:style=Regular", "Roboto Condensed:style=Bold"]
// Text size: about the height of the capital letters, in mm (not points)
text_size = 10; // [4:0.5:20]
// Letter spacing (1 = the font's normal spacing)
letter_spacing = 1.0; // [0.8:0.01:1.5]
// Where the text sits along the strip, as the divider stands on the shelf
text_align = "bottom"; // [bottom, center, top]
// Gap from the bottom (or top) end of the strip to the text, for bottom and top alignment (mm)
text_end_inset = 10; // [0:0.5:60]
// Distance from the strip's outer (front) edge to the text baseline (mm)
baseline_inset = 10; // [2:0.5:40]

/* [Panel] */
// Panel width, front to back (mm)
panel_width = 165; // [60:0.5:300]
// Panel height (mm)
panel_height = 170; // [60:0.5:300]
// Total thickness (mm)
thickness = 1.6; // [0.8:0.1:5]
// Outer corner radius (mm); the inside corners of the L and U use it too
corner_radius = 5; // [0:0.5:20]
// Width of the solid strip that carries the text, and of the L and U bars (mm)
strip_width = 45.5; // [20:0.5:120]

/* [Type] */
// Shape. full: frame with a window (least material). L: text strip plus a bar along the shelf; two fit on one plate. U: the L plus a back leg, open at the top; meets the back of the shelf at any height; two fit on one plate
type = "full"; // [full, L, U]

/* [Window] */
// Cut a window to save material (full type only)
window = true;
// Width of the frame on the other three sides (mm)
window_margin = 15.5; // [5:0.5:60]
// Window corner radius (mm)
window_radius = 5; // [0:0.5:20]

/* [Print] */
// The layer height you print at (mm). Letter, face and backing depths are counted in layers, so set this to match your slicer
layer_height = 0.2; // [0.08:0.02:0.32]
// How many layers deep the letters go (depth = letter layers × layer height)
letter_layers = 2; // [1:1:8]
// Optional layer of letter colour behind the face. It stops the letters showing through faintly from the back, but the face may look slightly greyer. Meant for dark letters on a light body. Adds one filament change
backing = "none"; // [none:None, letters:Letter colour]
// Layers of body colour in front of the backing (depth = face layers × layer height). The backing fills the rest of the thickness
face_layers = 5; // [2:1:20]
// Which part to output
part = "both"; // [both, white, black]

/* [Hidden] */
$fn = 64;
letter_depth = letter_layers * layer_height;
face_depth = face_layers * layer_height;
backed = backing == "letters";
assert(type == "full" || strip_width < panel_height - 20, "strip_width too large for the panel height");
assert(type != "U" || 2 * strip_width + 2 * corner_radius < panel_width, "strip_width too large for the panel width (U)");
assert(!backed || face_layers > letter_layers, str("face layers (", face_layers, ") must be more than the letter layers (", letter_layers, ")"));
assert(!backed || face_depth < thickness - layer_height / 2, str("no room for the backing: the face (", face_depth, " mm) must be thinner than the thickness (", thickness, " mm)"));
assert(letter_depth < thickness, str("letter depth (", letter_depth, " mm) must be less than the thickness (", thickness, " mm)"));
assert(type != "full" || !window || strip_width + window_margin + 2 * window_radius < panel_width, "window does not fit: reduce strip_width or window_margin");
assert(type != "full" || !window || 2 * window_margin + 2 * window_radius < panel_height, "window does not fit: reduce window_margin");

module rrect(w, h, r) if (r > 0) translate([r, r]) offset(r = r) square([w - 2 * r, h - 2 * r]); else square([w, h]);

// --- layout: the face as it stands on the shelf (x right, y up, y = 0 is the edge on the shelf) ---
// text strip along the right (front) edge; the back edge is on the left
module panel2d() if (type == "L" || type == "U") {
    // text strip + bar (+ back leg for U), every corner (outside and inside) rounded to corner_radius
    offset(r = -corner_radius) offset(delta = corner_radius) union() {
        translate([panel_width - strip_width, 0]) rrect(strip_width, panel_height, corner_radius);
        // bar along the bottom edge, which sits on the shelf
        rrect(panel_width, strip_width, corner_radius);
        // U: back leg along the back edge, full height, so the divider meets the shelf back at any height
        if (type == "U") rrect(strip_width, panel_height, corner_radius);
    }
} else difference() {
    rrect(panel_width, panel_height, corner_radius);
    if (window) translate([window_margin, window_margin])
        rrect(panel_width - strip_width - window_margin, panel_height - 2 * window_margin, window_radius);
}
// text runs up the front strip like a book spine: reads bottom to top, letter tops toward the back
module text2d() {
    y = text_align == "bottom" ? text_end_inset : text_align == "top" ? panel_height - text_end_inset : panel_height / 2;
    h = text_align == "bottom" ? "left" : text_align == "top" ? "right" : "center";
    translate([panel_width - baseline_inset, y]) rotate(90)
        text(label_text, size = text_size, font = font, spacing = letter_spacing, halign = h, valign = "baseline");
}
module letters2d() intersection() { panel2d(); text2d(); }

// --- bodies, in print orientation: the face is on the plate (z = 0), flipped so it reads correctly from the front ---
module print_orient() translate([0, panel_height, 0]) mirror([0, 1, 0]) children();
module white_part() print_orient() difference() {
    linear_extrude(backed ? face_depth : thickness) panel2d();
    translate([0, 0, -1]) linear_extrude(letter_depth + 1) letters2d();
}
module black_part() print_orient() {
    linear_extrude(letter_depth) letters2d();
    // letter-colour backing behind the face
    if (backed) translate([0, 0, face_depth]) linear_extrude(thickness - face_depth) panel2d();
}

if (part != "black") color("white") white_part();
if (part != "white") color([0.15, 0.15, 0.15]) black_part();
