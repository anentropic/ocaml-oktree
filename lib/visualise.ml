open Oplot.Plt
open Oplot.Points

type cube_vertices = {
  nwu : Point3.t;
  nwd : Point3.t;
  neu : Point3.t;
  ned : Point3.t;
  swu : Point3.t;
  swd : Point3.t;
  seu : Point3.t;
  sed : Point3.t;
}

let cube_wire_point_lists xa xb ya yb za zb =
  let vert =
    {
      nwu = { x = xa; y = yb; z = za };
      nwd = { x = xa; y = ya; z = za };
      neu = { x = xb; y = yb; z = za };
      ned = { x = xb; y = ya; z = za };
      swu = { x = xa; y = yb; z = zb };
      swd = { x = xa; y = ya; z = zb };
      seu = { x = xb; y = yb; z = zb };
      sed = { x = xb; y = ya; z = zb };
    }
  in
  (*
    oplot Curve3d takes a list of points and renders a line
    so this is a list of lines to draw a wireframe cube
    imagine each of these draws an unbroken line and then we lift the pen
  *)
  [
    [ vert.nwd; vert.ned; vert.neu; vert.nwu; vert.nwd ];
    [ vert.ned; vert.sed; vert.seu; vert.neu ];
    [ vert.nwu; vert.swu; vert.seu ];
    [ vert.nwd; vert.swd; vert.swu ];
    [ vert.swd; vert.sed ];
  ]

let cube_wires origin size va vb =
  let open Point3 in
  let l = size /. 2. in
  let xa = origin.x -. l
  and xb = origin.x +. l
  and ya = origin.y -. l
  and yb = origin.y +. l
  and za = origin.z -. l
  and zb = origin.z +. l in
  let view = ({ x = va; y = va; z = va }, { x = vb; y = vb; z = vb }) in
  Sheet
    (List.map
       (fun pts -> Curve3d ((pts, view), Internal.gllist_empty ()))
       (cube_wire_point_lists xa xb ya yb za zb))
