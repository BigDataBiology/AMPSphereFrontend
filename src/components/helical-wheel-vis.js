// URL: https://observablehq.com/@tinaswang/helical-wheel-visualization-wip-2019_05_16/2
// Title: Helical Wheel Visualization (WIP 2019_05_31)
// Author: Tina Wang (@tinaswang)
// Version: 2655
// Runtime version: 1
import {Runtime, Inspector} from "../components/observablehq-runtime";


function drawHelicalWheel(amp_seq){
    const m0 = {
        id: "0a758b4fa09748f2@2655",
        variables: [
          {
            name: "viewof inputAngle",
            inputs: ["select", "startingAngle"],
            value: function (select, startingAngle) {
              const inputAngle = select({
                title: "Angle of Separation between Amino Acids",
                options: [
                  { label: "Alpha Helix: 100", value: 100 },
                  { label: "Pi-Helix: 87", value: 87 },
                  // { label: "3-10 Helix: 120", value: 120 },
                ],
                value: startingAngle,
              });
              return inputAngle;
            },
          },
          {
            name: "inputAngle",
            inputs: ["Generators", "viewof inputAngle"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startingAngle",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return 100;
              }
              return allvars["d"][0]["inputAngle"];
            },
          },
          {
            name: "startingString",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return amp_seq;
              }
              return allvars["f"][0]["string"];
            },
          },
          {
            name: "viewof inputText",
            inputs: ["textarea", "startingString"],
            value: function (textarea, startingString) {
              return textarea({
                title: "Input String",
                value: startingString,
                placeholder: "ACDEFGH",
              });
            },
          },
          {
            name: "inputText",
            inputs: ["Generators", "viewof inputText"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof slider",
            inputs: ["slider_snap", "inputText"],
            value: function (slider_snap, inputText) {
              return slider_snap(inputText);
            },
          },
          {
            name: "slider",
            inputs: ["Generators", "viewof slider"],
            value: (G, _) => G.input(_),
          },
          {
            name: "helicalwheel",
            inputs: [
              "globals",
              "displayOptions",
              "strokeThickness",
              "color_schemes",
              "math",
              "inputAngle",
              "d3",
              "DOM",
              "fields",
              "circleDecrease",
              "labelOption",
              "numsOn",
              "residuesOn",
              "labelColor",
              "numColor",
              "hFace",
              "hMoment",
            ],
            value: function (
              globals,
              displayOptions,
              strokeThickness,
              color_schemes,
              math,
              inputAngle,
              d3,
              DOM,
              fields,
              circleDecrease,
              labelOption,
              numsOn,
              residuesOn,
              labelColor,
              numColor,
              hFace,
              hMoment
            ) {
              // Mess with globals?
              const gvar = globals[0];
              const gWidth = gvar["width"];
              const gHeight = gvar["height"];
              const gAngle = gvar["angle"];
              const gRadius = gvar["radius"];
      
              var gColors = displayOptions[0]["colors"];
      
              const termDist = gvar["termDist"];
              const gCircleSep = gvar["circleSep"];
              const maxDotRadius = gvar["maxDotRadius"];
              const minDotRadius = gvar["minDotRadius"];
              const startStroke = strokeThickness[1];
              const endStroke = strokeThickness[0];
              console.log(color_schemes[0]["custom"]);
              // Number of residues (i.e. circles) all the way around, i.e. 360 degrees
              // `math` is from math.js library
              const circlesPerRound = math.lcm(inputAngle, 360) / inputAngle;
              // Number of residues past the first, e.g. 4 for an alpha helix
              const circlesPerTurn = Math.ceil(360 / inputAngle);
      
              const svg = d3
                .select(DOM.svg(gWidth, gHeight))
                .attr("text-anchor", "middle")
                .style("display", "block")
                .style("font", "700 14px sans-serif")
                .style("width", "100%")
                .style("max-width", `${window.screen.height}px`)
                .style("height", "auto")
                .style("margin", "auto");
      
              var group = svg.append("g");
      
              const field = group
                .attr("transform", `translate(${gWidth / 2}, ${gHeight / 2})`) // Center in viewport
                .selectAll("g")
                .data(fields)
                .join("g");
      
              // create the points we're going to draw circles on
              const fieldTick = field
                .selectAll("g")
                .data((d) =>
                  d.string
                    .toUpperCase()
                    .split("")
                    .map((c, i) => ({ c: c, i: i, params: d }))
                )
                .join("g")
                .attr("transform", (d) => {
                  const angleRad = (((d.i * gAngle) % 360) * Math.PI) / 180;
                  const radiusAdj =
                    d.params.radius + gCircleSep * Math.floor(d.i / circlesPerRound);
                  d.x = Math.cos(angleRad) * radiusAdj;
                  d.y = Math.sin(angleRad) * radiusAdj;
                  return `translate(${d.x}, ${d.y})`; // Center for each circle to be drawn
                });
      
              // Size to decrease each turn
              var pctRadius =
                Math.abs(maxDotRadius - minDotRadius) /
                (circlesPerRound / circlesPerTurn);
              if (circleDecrease === "not_dec") {
                pctRadius = 0;
              }
              // Add circles around the wheel
              fieldTick
                .append("circle")
                .attr("r", (d, i) => {
                  if (i < circlesPerRound)
                    d.circleRadius =
                      maxDotRadius - Math.floor(i / circlesPerTurn) * pctRadius;
                  else d.circleRadius = minDotRadius;
                  return d.circleRadius;
                })
                .attr("fill", (d) => gColors[d.c])
                .attr("stroke", "black")
                .attr("stroke-width", 1);
      
              // Function to draw a path between pairs of x,y coords
              var lineFunction = d3
                .line()
                .x((d) => d.x)
                .y((d) => d.y)
                .curve(d3.curveLinear);
      
              // Accumulate pairs of x,y coordinates for drawing paths
              fieldTick.data().forEach(function (obj, i, arr) {
                const d = arr[i],
                  d_next = arr[i + 1];
                if (typeof d_next !== "undefined")
                  arr[i].linePoints = [
                    { x: d.x, y: d.y },
                    { x: d_next.x, y: d_next.y },
                  ];
              });
      
              // Stroke to decrease per segment
              var pctStroke = (endStroke - startStroke) / circlesPerRound;
      
              // Add the paths between each pair
              // stroke-width shrinks linearly as residue index increases
              field
                .selectAll("path")
                .data(fieldTick.data().slice(0, -1)) // Last element doesn't connect to a "next" circle
                .join("path")
                .attr("d", (d) => lineFunction(d.linePoints))
                .attr("stroke-width", function (d) {
                  if (endStroke >= startStroke) {
                    return Math.max(endStroke - pctStroke * d.i, startStroke);
                  }
      
                  return Math.min(endStroke + pctStroke * d.i, startStroke);
                })
                .attr("stroke", "black")
                .lower();
      
              // Add labels inside each circle
              fieldTick
                .append("text")
                .attr("text-anchor", "middle") // These 2 lines center
                .attr("dominant-baseline", "central") // text in the circle
                .text((d) => {
                  if (labelOption === "nums_inside" && numsOn === "on") {
                    // Add numbers inside the circle if the boolean is true
                    return d.i + 1;
                  } else if (labelOption !== "nums_inside" && residuesOn === "on") {
                    return d.c;
                  } else {
                    return "";
                  }
                })
                .attr("fill", (d) => {
                  if (labelOption !== "nums_inside") {
                    return labelColor;
                  } else {
                    return numColor;
                  }
                });
      
              // Add text outside
              fieldTick
                .append("text")
                .attr("dx", (d) => -d.circleRadius - termDist)
                .attr("dy", (d) => -d.circleRadius - termDist)
                .text((d) => {
                  // if we set nums to be inside
                  if (labelOption === "nums_inside" && residuesOn === "on") {
                    return d.c;
                  } else if (labelOption !== "nums_inside" && numsOn === "on") {
                    return d.i + 1;
                  } else {
                    return "";
                  }
                })
                .attr("fill", (d) => {
                  if (labelOption === "nums_inside" && numsOn === "on") {
                    return labelColor;
                  } else {
                    return numColor;
                  }
                });
      
              // Add labels for the N and C termini in red
              fieldTick
                .append("text")
                .attr("dx", (d) => d.circleRadius + termDist)
                .attr("dy", (d) => d.circleRadius + termDist)
                .text((d, i) => {
                  if (i == 0) return "N";
                  else if (i == fieldTick.data().length - 1) return "C";
                })
                .attr("fill", "red")
                .lower();
      
              // Draw arc for hydrophobic face
              if (hFace === "on") {
                var arc = d3
                  .arc()
                  .innerRadius(fields[0].radius * 1.3)
                  .outerRadius(fields[0].radius * 1.3)
                  .startAngle(Math.PI / 2 - (2 * Math.PI) / 9) // start 0-indexed
                  .endAngle(Math.PI / 2 - (4 * Math.PI) / 9); // end   0-indexed
      
                svg
                  .append("svg:defs")
                  .append("svg:marker")
                  .attr("id", "circlehead")
                  .attr("refX", 0)
                  .attr("refY", 0)
                  .attr("viewBox", "-6 -6 12 12")
                  .attr("markerWidth", 15)
                  .attr("markerHeight", 15)
                  .attr("markerUnits", "userSpaceOnUse")
                  .attr("orient", "auto")
                  .append("path") // ↓ from http://bl.ocks.org/dustinlarimer/5888271
                  .attr("d", "M 0, 0  m -5, 0  a 5,5 0 1,0 10,0  a 5,5 0 1,0 -10,0")
                  .style("fill", "#bbb");
      
                field
                  .append("path")
                  .attr("d", arc)
                  .style("fill", "none")
                  .attr("marker-start", "url(#circlehead)")
                  .attr("marker-end", "url(#circlehead)")
                  .style("stroke", "#bbb")
                  .style("stroke-width", 3)
                  .style("stroke-dasharray", "4,8");
              }
              // Draw arrow for hydrophobic moment
              if (hMoment === "on") {
                svg
                  .append("svg:defs")
                  .append("svg:marker")
                  .attr("id", "arrowhead")
                  .attr("refX", 3)
                  .attr("refY", 3)
                  .attr("markerWidth", 20)
                  .attr("markerHeight", 20)
                  .attr("orient", "auto")
                  .append("path")
                  // .attr("d", "M 0 0 12 6 0 12 3 6")
                  .attr("d", "M 0 0 6 3 0 6 1.5 3") // Dimensions of Arrowhead
                  .style("fill", "#bbb");
      
                field
                  .append("line")
                  .attr("x1", 0)
                  .attr("y1", 0)
                  .attr("x2", 50)
                  .attr("y2", 50)
                  .attr("stroke", "#bbb")
                  .attr("stroke-width", 3)
                  .attr("marker-end", "url(#arrowhead)")
                  .attr("transform", `rotate(100)`);
              }
      
              function dist(x1, y1, x0, y0) {
                return Math.sqrt((x1 - x0) ** 2 + (y1 - y0) ** 2);
              }
      
              function vertexAngle(a, b, v) {
                var a_dist = dist(b[0], b[1], v[0], v[1]);
                var b_dist = dist(a[0], a[1], v[0], v[1]);
                var c_dist = dist(a[0], a[1], b[0], b[1]);
      
                var numer = a_dist ** 2 + b_dist ** 2 - c_dist ** 2;
                var denom = 2 * a_dist * b_dist;
      
                console.log([numer, denom, Math.acos(numer / denom)]);
      
                return (Math.acos(numer / denom) * 180) / Math.PI;
              }
      
              // handle rotation drag
              group.call(
                d3.drag().on("drag", function (d) {
                  // Function that moves the helical wheel
                  // Calculations for angle from http://bl.ocks.org/tomgp/f39ccb9d4c17ced4e3d2
                  d3.select(this).classed("active", true);
                  var x = d3.event.x - gRadius;
                  var y = d3.event.y - gRadius;
                  var newAngle = (Math.atan2(y, x) * 180) / Math.PI;
                  if (newAngle < 0) newAngle = 360 + newAngle;
                  // Rotate everything using the newly calculated angle and centered on the center of the circle
                  group.attr(
                    "transform",
                    `translate(${gWidth / 2}, ${gHeight / 2}) rotate(${newAngle})`
                  );
                  // Rotate text back by the same angle
                  svg.selectAll("text").attr("transform", `rotate(${-newAngle})`);
                })
              );
      
              return svg.node();
            },
          },
          {
            name: "viewof currColors",
            inputs: ["select", "currColScheme"],
            value: function (select, currColScheme) {
              const currColors = select({
                title: "Color Scheme to Use",
                options: [
                  { label: "Shapely", value: "shapely" },
                  { label: "Lesk", value: "lesk" },
                  { label: "Clustal", value: "clustal" },
                  { label: "Cinema", value: "cinema" },
                  {
                    label: "MAEditor (Multiple Alignment Editor)",
                    value: "maeditor",
                  },
                  { label: "HeliQuest", value: "heliquest" },
                  // { label: "Custom", value: "custom" },
                ],
                description:
                  "See <a href=http://www.bioinformatics.nl/~berndb/aacolour.html>http://www.bioinformatics.nl/~berndb/aacolour.html</a> for more details.",
                value: currColScheme,
              });
              return currColors;
            },
          },
          {
            name: "currColors",
            inputs: ["Generators", "viewof currColors"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof labelOption",
            inputs: ["radio", "startOption"],
            value: function (radio, startOption) {
              return radio({
                title: "Residue Labels Inside/Outside Circles",
                options: [
                  { label: "Residue Labels Inside Circles", value: "nums_outside" },
                  { label: "Residue Labels Outside Circles", value: "nums_inside" },
                ],
                value: startOption,
              });
            },
          },
          {
            name: "labelOption",
            inputs: ["Generators", "viewof labelOption"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startOption",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "nums_outside";
              }
              return allvars["d"][0]["labelOption"];
            },
          },
          {
            name: "viewof strokeThickness",
            inputs: ["getStrokeWidth", "startingStroke"],
            value: function (getStrokeWidth, startingStroke) {
              return getStrokeWidth({
                title: "Stroke Width",
                description: "Control the min and max stroke widths.",
                value: startingStroke,
                submit: true,
              });
            },
          },
          {
            name: "strokeThickness",
            inputs: ["Generators", "viewof strokeThickness"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startingStroke",
            inputs: ["params", "globals", "allvars"],
            value: function (params, globals, allvars) {
              if (params.get("a") === null) {
                return [globals[0]["startStroke"], globals[0]["endStroke"]];
              }
              return allvars["d"][0]["strokeThickness"];
            },
          },
          {
            name: "viewof labelColor",
            inputs: ["color", "startlabelColor"],
            value: function (color, startlabelColor) {
              return color({
                value: startlabelColor,
                title: "Label Color",
                description: "This color picker starts out blue",
              });
            },
          },
          {
            name: "labelColor",
            inputs: ["Generators", "viewof labelColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startlabelColor",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "#000000";
              }
              return allvars["d"][0]["labelColor"];
            },
          },
          {
            name: "viewof numColor",
            inputs: ["color", "startNumColor"],
            value: function (color, startNumColor) {
              return color({
                value: startNumColor,
                title: "Number Color",
              });
            },
          },
          {
            name: "numColor",
            inputs: ["Generators", "viewof numColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startNumColor",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "#000000";
              }
              return allvars["d"][0]["numColor"];
            },
          },
          {
            inputs: ["labelColor"],
            value: function (labelColor) {
              return labelColor;
            },
          },
          {
            inputs: ["numColor"],
            value: function (numColor) {
              return numColor;
            },
          },
          {
            name: "viewof circleDecrease",
            inputs: ["radio", "startResSize"],
            value: function (radio, startResSize) {
              return radio({
                title: "Residue Size",
                options: [
                  { label: "Gradually Decrease", value: "dec" },
                  { label: "Uniform size", value: "not_dec" },
                ],
                value: startResSize,
              });
            },
          },
          {
            name: "circleDecrease",
            inputs: ["Generators", "viewof circleDecrease"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startResSize",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "dec";
              }
              return allvars["d"][0]["circleDecrease"];
            },
          },
          {
            name: "viewof hMoment",
            inputs: ["radio", "startHMoment"],
            value: function (radio, startHMoment) {
              return radio({
                title: "Hydrophobic Moment",
                options: [
                  { label: "On", value: "on" },
                  { label: "Off", value: "off" },
                ],
                value: startHMoment,
              });
            },
          },
          {
            name: "hMoment",
            inputs: ["Generators", "viewof hMoment"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startHMoment",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "on";
              }
              return allvars["d"][0]["hMoment"];
            },
          },
          {
            name: "viewof hFace",
            inputs: ["radio", "startHFace"],
            value: function (radio, startHFace) {
              return radio({
                title: "Hydrophobic Face",
                options: [
                  { label: "On", value: "on" },
                  { label: "Off", value: "off" },
                ],
                value: startHFace,
              });
            },
          },
          {
            name: "hFace",
            inputs: ["Generators", "viewof hFace"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startHFace",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "on";
              }
              return allvars["d"][0]["hFace"];
            },
          },
          {
            name: "viewof numsOn",
            inputs: ["radio", "startNums"],
            value: function (radio, startNums) {
              return radio({
                title: "Numbers On/Off",
                options: [
                  { label: "On", value: "on" },
                  { label: "Off", value: "off" },
                ],
                value: startNums,
              });
            },
          },
          {
            name: "numsOn",
            inputs: ["Generators", "viewof numsOn"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startNums",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "on";
              }
              return allvars["d"][0]["numsOn"];
            },
          },
          {
            name: "viewof residuesOn",
            inputs: ["radio", "startResidues"],
            value: function (radio, startResidues) {
              return radio({
                title: "Residue Labels On/Off",
                options: [
                  { label: "On", value: "on" },
                  { label: "Off", value: "off" },
                ],
                value: startResidues,
              });
            },
          },
          {
            name: "residuesOn",
            inputs: ["Generators", "viewof residuesOn"],
            value: (G, _) => G.input(_),
          },
          {
            name: "startResidues",
            inputs: ["params", "allvars"],
            value: function (params, allvars) {
              if (params.get("a") === null) {
                return "on";
              }
              return allvars["d"][0]["residuesOn"];
            },
          },
          {
            name: "currColScheme",
            inputs: ["allvars"],
            value: function (allvars) {
              if (allvars !== null) {
                return allvars["d"][0]["colScheme"];
              }
              return "shapely";
            },
          },
          {
            name: "displayOptions",
            inputs: [
              "residuesOn",
              "numsOn",
              "labelOption",
              "hFace",
              "hMoment",
              "circleDecrease",
              "labelColor",
              "numColor",
              "strokeThickness",
              "inputAngle",
              "currColors",
              "color_schemes",
            ],
            value: function (
              residuesOn,
              numsOn,
              labelOption,
              hFace,
              hMoment,
              circleDecrease,
              labelColor,
              numColor,
              strokeThickness,
              inputAngle,
              currColors,
              color_schemes
            ) {
              return [
                {
                  residuesOn: residuesOn,
                  numsOn: numsOn,
                  labelOption: labelOption,
                  hFace: hFace,
                  hMoment: hMoment,
                  circleDecrease: circleDecrease,
                  labelColor: labelColor,
                  numColor: numColor,
                  strokeThickness: strokeThickness,
                  inputAngle: inputAngle,
                  colScheme: currColors,
                  colors: color_schemes[0][currColors],
                },
              ];
            },
          },
          {
            name: "fields",
            inputs: ["globals", "inputText", "slider"],
            value: function (globals, inputText, slider) {
              return [
                {
                  radius: 0.7 * globals[0]["radius"],
                  string: inputText.trim().substring(slider[0], slider[1]),
                  dotRadius: globals[0]["radius"] / 15,
                },
              ];
            },
          },
          {
            name: "globals",
            inputs: ["inputAngle", "color_schemes", "currColors"],
            value: function (inputAngle, color_schemes, currColors) {
              return [
                {
                  width: 700,
                  height: 700,
                  radius: 300,
                  maxDotRadius: 300 / 15,
                  minDotRadius: 300 / 25,
                  termDist: 2,
                  circleSep: 50,
                  angle: inputAngle,
                  startStroke: 0.1,
                  endStroke: 2,
                  // Shapely colors (not colorblind friendly)
                  // http://life.nthu.edu.tw/~fmhsu/rasframe/SHAPELY.HTM
                  colors: color_schemes[0][currColors],
                },
              ];
            },
          },
          {
            name: "allvars",
            inputs: ["params", "Base64DecodeUrl"],
            value: function (params, Base64DecodeUrl) {
              if (params.get("a") !== null) {
                return JSON.parse(atob(Base64DecodeUrl(params.get("a"))));
              }
              return null;
            },
          },
          {
            name: "color_schemes",
            inputs: [
              "hColor",
              "kColor",
              "rColor",
              "dColor",
              "eColor",
              "sColor",
              "tColor",
              "nColor",
              "qColor",
              "aColor",
              "vColor",
              "lColor",
              "iColor",
              "mColor",
              "fColor",
              "wColor",
              "yColor",
              "pColor",
              "gColor",
              "cColor",
            ],
            value: function (
              hColor,
              kColor,
              rColor,
              dColor,
              eColor,
              sColor,
              tColor,
              nColor,
              qColor,
              aColor,
              vColor,
              lColor,
              iColor,
              mColor,
              fColor,
              wColor,
              yColor,
              pColor,
              gColor,
              cColor
            ) {
              return [
                {
                  shapely: {
                    D: "#E60A0A",
                    E: "#E60A0A",
                    C: "#E6E600",
                    M: "#E6E600",
                    K: "#145AFF",
                    R: "#145AFF",
                    S: "#FA9600",
                    T: "#FA9600",
                    F: "#3232AA",
                    Y: "#3232AA",
                    N: "#00DCDC",
                    Q: "#00DCDC",
                    G: "#EBEBEB",
                    L: "#0F820F",
                    V: "#0F820F",
                    I: "#0F820F",
                    A: "#C8C8C8",
                    W: "#B45AB4",
                    H: "#8282D2",
                    P: "#DC9682",
                  },
                  clustal: {
                    M: "#00FF00",
                    K: "#FF0000",
                    R: "#FF0000",
                    S: "#FFA500",
                    T: "#FFA500",
                    F: "#FF0000",
                    Y: "#0000FF",
                    G: "#FFA500",
                    L: "#0F820F",
                    V: "#00FF00",
                    I: "#0000FF",
                    W: "#0000FF",
                    H: "#FFA500",
                    P: "#FFA500",
                  },
      
                  lesk: {
                    G: "#FFA500",
                    A: "#FFA500",
                    S: "#FFA500",
                    T: "#FFA500",
                    C: "#00FF00",
                    V: "#00FF00",
                    I: "#00FF00",
                    L: "#00FF00",
                    P: "#00FF00",
                    F: "#00FF00",
                    Y: "#00FF00",
                    M: "#00FF00",
                    W: "#00FF00",
                    N: "#FF00FF",
                    Q: "#FF00FF",
                    H: "#FF00FF",
                    D: "#FF0000",
                    E: "#FF0000",
                    K: "#0000FF",
                    R: "#0000FF",
                  },
      
                  cinema: {
                    H: "#0000FF",
                    K: "#0000FF",
                    R: "#0000FF",
                    D: "#FF0000",
                    E: "#FF0000",
                    S: "#00FF00",
                    T: "#00FF00",
                    N: "#00FF00",
                    Q: "#00FF00",
                    A: "#FFFFFF",
                    V: "#FFFFFF",
                    L: "#FFFFFF",
                    I: "#FFFFFF",
                    M: "#FFFFFF",
                    F: "#FF00FF",
                    W: "#FF00FF",
                    Y: "#FF00FF",
                    P: "#A52A2A",
                    G: "#A52A2A",
                    C: "#FFFF00",
                  },
      
                  maeditor: {
                    A: "#90EE90",
                    G: "#90EE90",
                    C: "#00FF00",
                    D: "#006400",
                    E: "#006400",
                    N: "#006400",
                    Q: "#006400",
                    I: "#0000FF",
                    L: "#0000FF",
                    M: "#0000FF",
                    V: "#0000FF",
                    F: "#9999FF",
                    W: "#9999FF",
                    Y: "#9999FF",
                    H: "#00008B",
                    K: "#FFA500",
                    R: "#FFA500",
                    P: "#FFC0CB",
                    S: "#FF0000",
                    T: "#FF0000",
                  },
      
                  heliquest: {
                    A: "#BEBEBE",
                    C: "#FFFF00",
                    D: "#FFFF00",
                    E: "#FFFF00",
                    F: "#FFFF00",
                    G: "#BEBEBE",
                    H: "#ADD8E6",
                    I: "#FFFF00",
                    L: "#FFFF00",
                    M: "#FFFF00",
                    N: "#FFC0CB",
                    P: "#00FF00",
                    Q: "#FFC0CB",
                    R: "#0000FF",
                    S: "#A020F0",
                    T: "#A020F0",
                    V: "#FFFF00",
                    W: "#FFFF00",
                    Y: "#FFFF00",
                  },
      
                  // TODO: Custom colors
                  custom: {
                    H: hColor,
                    K: kColor,
                    R: rColor,
                    D: dColor,
                    E: eColor,
                    S: sColor,
                    T: tColor,
                    N: nColor,
                    Q: qColor,
                    A: aColor,
                    V: vColor,
                    L: lColor,
                    I: iColor,
                    M: mColor,
                    F: fColor,
                    W: wColor,
                    Y: yColor,
                    P: pColor,
                    G: gColor,
                    C: cColor,
                  },
                },
              ];
            },
          },
          {
            name: "svgSave",
            inputs: ["DOM", "serialize", "helicalwheel"],
            value: function (DOM, serialize, helicalwheel) {
              return DOM.download(() => serialize(helicalwheel), undefined, "Save as SVG");
            },
          },
          {
            name: "viewof aColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "A",
              });
            },
          },
          {
            name: "aColor",
            inputs: ["Generators", "viewof aColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof vColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "V",
              });
            },
          },
          {
            name: "vColor",
            inputs: ["Generators", "viewof vColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof lColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "L",
              });
            },
          },
          {
            name: "lColor",
            inputs: ["Generators", "viewof lColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof hColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "H",
              });
            },
          },
          {
            name: "hColor",
            inputs: ["Generators", "viewof hColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof kColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "K",
              });
            },
          },
          {
            name: "kColor",
            inputs: ["Generators", "viewof kColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof rColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "R",
              });
            },
          },
          {
            name: "rColor",
            inputs: ["Generators", "viewof rColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof dColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "D",
              });
            },
          },
          {
            name: "dColor",
            inputs: ["Generators", "viewof dColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof eColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "E",
              });
            },
          },
          {
            name: "eColor",
            inputs: ["Generators", "viewof eColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof sColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "S",
              });
            },
          },
          {
            name: "sColor",
            inputs: ["Generators", "viewof sColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof tColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "T",
              });
            },
          },
          {
            name: "tColor",
            inputs: ["Generators", "viewof tColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof nColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "N",
              });
            },
          },
          {
            name: "nColor",
            inputs: ["Generators", "viewof nColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof qColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "Q",
              });
            },
          },
          {
            name: "qColor",
            inputs: ["Generators", "viewof qColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof iColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "I",
              });
            },
          },
          {
            name: "iColor",
            inputs: ["Generators", "viewof iColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof mColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "M",
              });
            },
          },
          {
            name: "mColor",
            inputs: ["Generators", "viewof mColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof fColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "F",
              });
            },
          },
          {
            name: "fColor",
            inputs: ["Generators", "viewof fColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof wColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "W",
              });
            },
          },
          {
            name: "wColor",
            inputs: ["Generators", "viewof wColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof yColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "Y",
              });
            },
          },
          {
            name: "yColor",
            inputs: ["Generators", "viewof yColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof pColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "P",
              });
            },
          },
          {
            name: "pColor",
            inputs: ["Generators", "viewof pColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof gColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "G",
              });
            },
          },
          {
            name: "gColor",
            inputs: ["Generators", "viewof gColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof cColor",
            inputs: ["color"],
            value: function (color) {
              return color({
                value: "#000000",
                title: "C",
              });
            },
          },
          {
            name: "cColor",
            inputs: ["Generators", "viewof cColor"],
            value: (G, _) => G.input(_),
          },
          {
            name: "compressedURL",
            inputs: ["displayOptions", "fields", "Base64EncodeUrl"],
            value: function (displayOptions, fields, Base64EncodeUrl) {
              return function () {
                var url = document.baseURI;
                var urlGlobals = { d: displayOptions, f: fields };
                var allvars = Base64EncodeUrl(btoa(JSON.stringify(urlGlobals)));
                var genURL = url.split("?")[0] + "?a=" + allvars;
      
                // Call bit.ly API to get new URL?
                return genURL;
              };
            },
          },
          {
            name: "viewof copyButton",
            inputs: ["html", "copy", "compressedURL"],
            value: function (html, copy, compressedURL) {
              let count = 0;
              return Object.assign(
                html`<button>
                  Click to copy a sharable URL for this helical wheel to the clipboard
                </button>`,
                { onclick: () => copy(`${compressedURL()}`) }
              );
            },
          },
          {
            name: "copyButton",
            inputs: ["Generators", "viewof copyButton"],
            value: (G, _) => G.input(_),
          },
          {
            name: "viewof shareButtons",
            inputs: ["html", "compressedURL"],
            value: function (html, compressedURL) {
              return html`
        <a class="social-media-sharer" href="https://facebook.com/sharer/sharer.php?u=${compressedURL()}" target="_blank" rel="noopener noreferrer" aria-label="Share on Facebook">
          <div class="social-media-sharer__icon_wrapper social-media-sharer__icon_wrapper--facebook social-media-sharer__icon_wrapper--small"><div aria-hidden="true" class="social-media-sharer__icon social-media-sharer__icon--solid">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M18.77 7.46H14.5v-1.9c0-.9.6-1.1 1-1.1h3V.5h-4.33C10.24.5 9.5 3.44 9.5 5.32v2.15h-3v4h3v12h5v-12h3.85l.42-4z"></path></svg>
          </div>
          </div>
        </a>
      
        <a class="social-media-sharer" href="https://twitter.com/intent/tweet/?text=Check%20out%20my%20helical%20wheel%20diagram!\n&amp;url=${compressedURL()}" target="_blank" rel="noopener noreferrer" aria-label="Tweet a link to this page">
          <div class="social-media-sharer__icon_wrapper social-media-sharer__icon_wrapper--twitter social-media-sharer__icon_wrapper--small"><div aria-hidden="true" class="social-media-sharer__icon social-media-sharer__icon--solid">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M23.44 4.83c-.8.37-1.5.38-2.22.02.93-.56.98-.96 1.32-2.02-.88.52-1.86.9-2.9 1.1-.82-.88-2-1.43-3.3-1.43-2.5 0-4.55 2.04-4.55 4.54 0 .36.03.7.1 1.04-3.77-.2-7.12-2-9.36-4.75-.4.67-.6 1.45-.6 2.3 0 1.56.8 2.95 2 3.77-.74-.03-1.44-.23-2.05-.57v.06c0 2.2 1.56 4.03 3.64 4.44-.67.2-1.37.2-2.06.08.58 1.8 2.26 3.12 4.25 3.16C5.78 18.1 3.37 18.74 1 18.46c2 1.3 4.4 2.04 6.97 2.04 8.35 0 12.92-6.92 12.92-12.93 0-.2 0-.4-.02-.6.9-.63 1.96-1.22 2.56-2.14z"></path></svg>
          </div>
          </div>
        </a>
      
      
        <a class="social-media-sharer" href="mailto:?subject=My%20Helical%20Wheel%20Diagram&amp;body=${compressedURL()}" target="_self" aria-label="Email a link to this page (opens up email program, if configured on this system)">
          <div class="social-media-sharer__icon_wrapper social-media-sharer__icon_wrapper--email social-media-sharer__icon_wrapper--small"><div aria-hidden="true" class="social-media-sharer__icon social-media-sharer__icon--solid">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M22 4H2C.9 4 0 4.9 0 6v12c0 1.1.9 2 2 2h20c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zM7.25 14.43l-3.5 2c-.08.05-.17.07-.25.07-.17 0-.34-.1-.43-.25-.14-.24-.06-.55.18-.68l3.5-2c.24-.14.55-.06.68.18.14.24.06.55-.18.68zm4.75.07c-.1 0-.2-.03-.27-.08l-8.5-5.5c-.23-.15-.3-.46-.15-.7.15-.22.46-.3.7-.14L12 13.4l8.23-5.32c.23-.15.54-.08.7.15.14.23.07.54-.16.7l-8.5 5.5c-.08.04-.17.07-.27.07zm8.93 1.75c-.1.16-.26.25-.43.25-.08 0-.17-.02-.25-.07l-3.5-2c-.24-.13-.32-.44-.18-.68s.44-.32.68-.18l3.5 2c.24.13.32.44.18.68z"></path></svg>
          </div>
          </div>
        </a>
      
        <a class="social-media-sharer" href="https://old.reddit.com/submit/?title=Helical%20Wheel%20Diagram&amp&amp;url=${compressedURL()}" target="_blank" rel="noopener noreferrer" aria-label="Share this page on Reddit">
          <div class="social-media-sharer__icon_wrapper social-media-sharer__icon_wrapper--reddit social-media-sharer__icon_wrapper--small"><div aria-hidden="true" class="social-media-sharer__icon social-media-sharer__icon--solid">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M24 11.5c0-1.65-1.35-3-3-3-.96 0-1.86.48-2.42 1.24-1.64-1-3.75-1.64-6.07-1.72.08-1.1.4-3.05 1.52-3.7.72-.4 1.73-.24 3 .5C17.2 6.3 18.46 7.5 20 7.5c1.65 0 3-1.35 3-3s-1.35-3-3-3c-1.38 0-2.54.94-2.88 2.22-1.43-.72-2.64-.8-3.6-.25-1.64.94-1.95 3.47-2 4.55-2.33.08-4.45.7-6.1 1.72C4.86 8.98 3.96 8.5 3 8.5c-1.65 0-3 1.35-3 3 0 1.32.84 2.44 2.05 2.84-.03.22-.05.44-.05.66 0 3.86 4.5 7 10 7s10-3.14 10-7c0-.22-.02-.44-.05-.66 1.2-.4 2.05-1.54 2.05-2.84zM2.3 13.37C1.5 13.07 1 12.35 1 11.5c0-1.1.9-2 2-2 .64 0 1.22.32 1.6.82-1.1.85-1.92 1.9-2.3 3.05zm3.7.13c0-1.1.9-2 2-2s2 .9 2 2-.9 2-2 2-2-.9-2-2zm9.8 4.8c-1.08.63-2.42.96-3.8.96-1.4 0-2.74-.34-3.8-.95-.24-.13-.32-.44-.2-.68.15-.24.46-.32.7-.18 1.83 1.06 4.76 1.06 6.6 0 .23-.13.53-.05.67.2.14.23.06.54-.18.67zm.2-2.8c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm5.7-2.13c-.38-1.16-1.2-2.2-2.3-3.05.38-.5.97-.82 1.6-.82 1.1 0 2 .9 2 2 0 .84-.53 1.57-1.3 1.87z"></path></svg>
          </div>
          </div>
        </a>
      
      </div>
      
      `;
            },
          },
          {
            name: "shareButtons",
            inputs: ["Generators", "viewof shareButtons"],
            value: (G, _) => G.input(_),
          },
          {
            name: "Base64EncodeUrl",
            value: function () {
              return function Base64EncodeUrl(str) {
                return str
                  .replace(/\+/g, "-")
                  .replace(/\//g, "_")
                  .replace(/\=+$/, "");
              };
            },
          },
          {
            name: "Base64DecodeUrl",
            value: function () {
              return function Base64DecodeUrl(str) {
                str = (str + "===").slice(0, str.length + (str.length % 4));
                return str.replace(/-/g, "+").replace(/_/g, "/");
              };
            },
          },
          {
            name: "slider_snap",
            inputs: ["globals", "d3", "DOM"],
            value: function (globals, d3, DOM) {
              return function (myText) {
                var myText = myText.trim();
                var max = myText.length;
                var range = [0, max];
      
                var textArr = myText.split("");
      
                // set width and height of svg
                const gvar = globals[0];
                const gWidth = gvar["width"];
      
                var unitw = 25;
                var w = unitw * myText.length;
                // When the user has a really long string, the slider will no longer display text
                var longText = false;
                if (Math.min(gWidth, w) === gWidth) {
                  longText = true;
                  unitw = gWidth / myText.length;
                }
                var h = 300;
                var margin = { top: 130, bottom: 135, left: 20, right: 40 };
      
                // dimensions of slider bar
                var width = Math.min(w, gWidth) - margin.left - margin.right;
                var height = h - margin.top - margin.bottom;
      
                // create x scale
                var x = d3
                  .scaleLinear()
                  .domain(range) // data space
                  .range([0, width]); // display space
      
                // create svg and translated g
                var svg = d3.select(DOM.svg(Math.min(w, gWidth), h));
                const g = svg
                  .append("g")
                  .attr("transform", `translate(${margin.left}, ${margin.top})`);
      
                // draw background lines
                const lines = g
                  .append("g")
                  .selectAll("line")
                  .data(d3.range(range[0], range[1] + 1))
                  .enter()
                  .append("line")
                  .attr("x1", (d) => x(d))
                  .attr("x2", (d) => x(d))
                  .attr("y1", 0)
                  .attr("y2", height)
                  .style("stroke", "#ccc");
      
                // Add the individual letters onto the slider
                if (longText === false) {
                  g.append("g")
                    .selectAll("line")
                    .data(d3.range(range[0], range[1]))
                    .enter()
                    .append("text")
                    .attr("x", (d) => x(d) + unitw / 4)
                    .attr("y", 0.75 * height)
                    .style("stroke", "black")
                    .text((d) => textArr[d]);
                }
                // labels
                var labelL = g
                  .append("text")
                  .attr("id", "labelleft")
                  .attr("x", 0)
                  .attr("y", height + 5)
                  .text(textArr[range[0]]);
      
                var labelR = g
                  .append("text")
                  .attr("id", "labelright")
                  .attr("x", 0)
                  .attr("y", height + 5)
                  .text(textArr[range[1]]);
      
                // define brush
                var brush = d3
                  .brushX()
                  .extent([
                    [0, 0],
                    [width, height],
                  ])
                  .on("brush", function () {
                    var s = d3.event.selection;
                    // update and move labels
                    labelL.attr("x", s[0]).text(textArr[Math.round(x.invert(s[0]))]);
                    labelR
                      .attr("x", s[1])
                      .text(textArr[Math.round(x.invert(s[1])) - 1]);
                    // move brush handles
                    handle.attr("display", null).attr("transform", function (d, i) {
                      return "translate(" + [s[i], -height / 4] + ")";
                    });
                    // update view
                    // if the view should only be updated after brushing is over,
                    // move these two lines into the on('end') part below
                    svg.node().value = s.map((d) => Math.round(x.invert(d)));
                    svg.node().dispatchEvent(new CustomEvent("input"));
                  })
                  .on("end", function () {
                    if (!d3.event.sourceEvent) return;
                    var d0 = d3.event.selection.map(x.invert);
                    var d1 = d0.map(Math.round);
                    d3.select(this)
                      .transition()
                      .call(d3.event.target.move, d1.map(x));
                  });
      
                // append brush to g
                var gBrush = g.append("g").attr("class", "brush").call(brush);
      
                // add brush handles (from https://bl.ocks.org/Fil/2d43867ba1f36a05459c7113c7f6f98a)
                var brushResizePath = function (d) {
                  var e = +(d.type == "e"),
                    x = e ? 1 : -1,
                    y = height / 2;
                  return (
                    "M" +
                    0.5 * x +
                    "," +
                    y +
                    "A6,6 0 0 " +
                    e +
                    " " +
                    6.5 * x +
                    "," +
                    (y + 6) +
                    "V" +
                    (2 * y - 6) +
                    "A6,6 0 0 " +
                    e +
                    " " +
                    0.5 * x +
                    "," +
                    2 * y +
                    "Z" +
                    "M" +
                    2.5 * x +
                    "," +
                    (y + 8) +
                    "V" +
                    (2 * y - 8) +
                    "M" +
                    4.5 * x +
                    "," +
                    (y + 8) +
                    "V" +
                    (2 * y - 8)
                  );
                };
      
                var handle = gBrush
                  .selectAll(".handle--custom")
                  .data([{ type: "w" }, { type: "e" }])
                  .enter()
                  .append("path")
                  .attr("class", "handle--custom")
                  .attr("stroke", "#000")
                  .attr("fill", "#eee")
                  .attr("cursor", "ew-resize")
                  .attr("d", brushResizePath);
      
                // override default behaviour - clicking outside of the selected area
                // will select a small piece there rather than deselecting everything
                // https://bl.ocks.org/mbostock/6498000
                gBrush
                  .selectAll(".overlay")
                  .each(function (d) {
                    d.type = "selection";
                  })
                  .on("mousedown touchstart", brushcentered);
      
                function brushcentered() {
                  var dx = x(1) - x(0), // Use a fixed width when recentering.
                    cx = d3.mouse(this)[0],
                    x0 = cx - dx / 2,
                    x1 = cx + dx / 2;
                  d3.select(this.parentNode).call(
                    brush.move,
                    x1 > width ? [width - dx, width] : x0 < 0 ? [0, dx] : [x0, x1]
                  );
                }
      
                // select entire range
                gBrush.call(brush.move, range.map(x));
      
                return svg.node();
              };
            },
          },
          {
            name: "d3",
            inputs: ["require"],
            value: function (require) {
              return require("d3@5");
            },
          },
          {
            name: "textarea",
            inputs: ["input", "html"],
            value: function (input, html) {
              return function textarea(config = {}) {
                let {
                  value,
                  title,
                  description,
                  autocomplete,
                  cols = 45,
                  rows = 3,
                  width,
                  height,
                  maxlength,
                  placeholder,
                  spellcheck,
                  wrap,
                  submit,
                } = config;
                if (typeof config == "string") value = config;
                if (value == null) value = "";
                const form = input({
                  form: html`<form>
                    <textarea style="display: block; font-size: 0.8em;" name="input">
      ${value}</textarea
                    >
                  </form>`,
                  title,
                  description,
                  submit,
                  attributes: {
                    autocomplete,
                    cols,
                    rows,
                    maxlength,
                    placeholder,
                    spellcheck,
                    wrap,
                  },
                });
                form.output.remove();
                if (width != null) form.input.style.width = width;
                if (height != null) form.input.style.height = height;
                if (submit) form.submit.style.margin = "0";
                if (title || description) form.input.style.margin = "3px 0";
                return form;
              };
            },
          },
          {
            name: "d3format",
            inputs: ["require"],
            value: function (require) {
              return require("d3-format@1");
            },
          },
          {
            name: "input",
            inputs: ["html", "d3format"],
            value: function (html, d3format) {
              return function input(config) {
                let {
                  form,
                  type = "text",
                  attributes = {},
                  action,
                  getValue,
                  title,
                  description,
                  format,
                  display,
                  submit,
                  options,
                } = config;
                const wrapper = html`<div></div>`;
                if (!form)
                  form = html`<form>
                    <input name="input" type=${type} />
                  </form>`;
                Object.keys(attributes).forEach((key) => {
                  const val = attributes[key];
                  if (val != null) form.input.setAttribute(key, val);
                });
                if (submit)
                  form.append(
                    html`<input
                      name="submit"
                      type="submit"
                      style="margin: 0 0.75em"
                      value="${typeof submit == "string" ? submit : "Submit"}"
                    />`
                  );
                form.append(
                  html`<output
                    name="output"
                    style="font: 14px Menlo, Consolas, monospace; margin-left: 0.5em;"
                  ></output>`
                );
                if (title)
                  form.prepend(
                    html`<div style="font: 700 0.9rem sans-serif;">${title}</div>`
                  );
                if (description)
                  form.append(
                    html`<div style="font-size: 0.85rem; font-style: italic;">
                      ${description}
                    </div>`
                  );
                if (format)
                  format =
                    typeof format === "function" ? format : d3format.format(format);
                if (action) {
                  action(form);
                } else {
                  const verb = submit
                    ? "onsubmit"
                    : type == "button"
                    ? "onclick"
                    : type == "checkbox" || type == "radio"
                    ? "onchange"
                    : "oninput";
                  form[verb] = (e) => {
                    e && e.preventDefault();
                    const value = getValue ? getValue(form.input) : form.input.value;
                    if (form.output) {
                      const out = display
                        ? display(value)
                        : format
                        ? format(value)
                        : value;
                      if (out instanceof window.Element) {
                        while (form.output.hasChildNodes()) {
                          form.output.removeChild(form.output.lastChild);
                        }
                        form.output.append(out);
                      } else {
                        form.output.value = out;
                      }
                    }
                    form.value = value;
                    if (verb !== "oninput")
                      form.dispatchEvent(new CustomEvent("input", { bubbles: true }));
                  };
                  if (verb !== "oninput")
                    wrapper.oninput = (e) =>
                      e && e.stopPropagation() && e.preventDefault();
                  if (verb !== "onsubmit")
                    form.onsubmit = (e) => e && e.preventDefault();
                  form[verb]();
                }
                while (form.childNodes.length) {
                  wrapper.appendChild(form.childNodes[0]);
                }
                form.append(wrapper);
                return form;
              };
            },
          },
          {
            name: "getStrokeWidth",
            inputs: ["html", "input"],
            value: function (html, input) {
              return function getStrokeWidth(config = {}) {
                let { value = [], title, description, submit } = config;
                if (Array.isArray(config)) value = config;
                let [lon, lat] = value;
                lon = lon != null ? lon : "";
                lat = lat != null ? lat : "";
                const lonEl = html`<input
                  name="input"
                  type="number"
                  autocomplete="off"
                  min="0"
                  max="20"
                  style="width: 80px;"
                  step="0.1"
                  value="${lon}"
                />`;
                const latEl = html`<input
                  name="input"
                  type="number"
                  autocomplete="off"
                  min="0"
                  max="20"
                  style="width: 80px;"
                  step="0.1"
                  value="${lat}"
                />`;
                const form = input({
                  type: "coordinates",
                  title,
                  description,
                  submit,
                  getValue: () => {
                    const lon = lonEl.valueAsNumber;
                    const lat = latEl.valueAsNumber;
                    return [isNaN(lon) ? null : lat, isNaN(lat) ? null : lon];
                  },
                  form: html`
                    <form>
                      <label
                        style="display: inline-block; font: 600 0.75rem sans-serif; margin: 30px 0 0;"
                      >
                        <span style="display: inline-block; width: 100px;"
                          >Starting Width:</span
                        >
                        ${lonEl}
                      </label>
                      <br />
                      <label
                        style="display: inline-block; font: 600 0.75rem sans-serif; margin: 0 0 30px;"
                      >
                        <span style="display: inline-block; width: 100px;"
                          >Ending Width:</span
                        >
                        ${latEl}
                      </label>
                    </form>
                  `,
                });
                form.output.remove();
                return form;
              };
            },
          },
          {
            name: "select",
            inputs: ["input", "html"],
            value: function (input, html) {
              return function select(config = {}) {
                let {
                  value: formValue,
                  title,
                  description,
                  submit,
                  multiple,
                  size,
                  options,
                } = config;
                if (Array.isArray(config)) options = config;
                options = options.map((o) =>
                  typeof o === "object" ? o : { value: o, label: o }
                );
                const form = input({
                  type: "select",
                  title,
                  description,
                  submit,
                  getValue: (input) => {
                    const selected = Array.prototype.filter
                      .call(input.options, (i) => i.selected)
                      .map((i) => i.value);
                    return multiple ? selected : selected[0];
                  },
                  form: html`
                    <form>
                      <select
                        name="input"
                        ${multiple ? `multiple size="${size || options.length}"` : ""}
                      >
                        ${options.map(({ value, label }) =>
                          Object.assign(html`<option></option>`, {
                            value,
                            selected: Array.isArray(formValue)
                              ? formValue.includes(value)
                              : formValue === value,
                            textContent: label,
                          })
                        )}
                      </select>
                    </form>
                  `,
                });
                form.output.remove();
                return form;
              };
            },
          },
          {
            name: "color",
            inputs: ["input"],
            value: function (input) {
              return function color(config = {}) {
                let { value, title, description, submit, display } = config;
                if (typeof config == "string") value = config;
                if (value == null) value = "#000000";
                const form = input({
                  type: "color",
                  title,
                  description,
                  submit,
                  display,
                  attributes: { value },
                });
                if (title || description) form.input.style.margin = "5px 0";
                return form;
              };
            },
          },
          {
            name: "radio",
            inputs: ["input", "html"],
            value: function (input, html) {
              return function radio(config = {}) {
                let {
                  value: formValue,
                  title,
                  description,
                  submit,
                  options,
                } = config;
                if (Array.isArray(config)) options = config;
                options = options.map((o) =>
                  typeof o === "string" ? { value: o, label: o } : o
                );
                const form = input({
                  type: "radio",
                  title,
                  description,
                  submit,
                  getValue: (input) => {
                    const checked = Array.prototype.find.call(
                      input,
                      (radio) => radio.checked
                    );
                    return checked ? checked.value : undefined;
                  },
                  form: html`
                    <form>
                      ${options.map(({ value, label }) => {
                        const input = html`<input
                          type="radio"
                          name="input"
                          ${value === formValue ? "checked" : ""}
                          style="vertical-align: baseline;"
                        />`;
                        input.setAttribute("value", value);
                        const tag = html` <label
                          style="display: inline-block; margin: 5px 10px 3px 0; font-size: 0.85em;"
                        >
                          ${input} ${label}
                        </label>`;
                        return tag;
                      })}
                    </form>
                  `,
                });
                form.output.remove();
                return form;
              };
            },
          },
          {
            name: "number",
            inputs: ["input"],
            value: function (input) {
              return function number(config = {}) {
                const {
                  value,
                  title,
                  description,
                  placeholder,
                  submit,
                  step = "any",
                  min,
                  max,
                } = config;
                if (typeof config == "number") value = config;
                const form = input({
                  type: "number",
                  title,
                  description,
                  submit,
                  attributes: {
                    value,
                    placeholder,
                    step,
                    min,
                    max,
                    autocomplete: "off",
                  },
                  getValue: (input) => input.valueAsNumber,
                });
                form.output.remove();
                form.input.style.width = "auto";
                form.input.style.fontSize = "1em";
                return form;
              };
            },
          },
          {
            name: "serialize",
            inputs: ["NodeFilter"],
            value: function (NodeFilter) {
              const xmlns = "http://www.w3.org/2000/xmlns/";
              const xlinkns = "http://www.w3.org/1999/xlink";
              const svgns = "http://www.w3.org/2000/svg";
              return function serialize(svg) {
                svg = svg.cloneNode(true);
                const fragment = window.location.href + "#";
                const walker = document.createTreeWalker(
                  svg,
                  NodeFilter.SHOW_ELEMENT,
                  null,
                  false
                );
                while (walker.nextNode()) {
                  for (const attr of walker.currentNode.attributes) {
                    if (attr.value.includes(fragment)) {
                      attr.value = attr.value.replace(fragment, "#");
                    }
                  }
                }
                svg.setAttributeNS(xmlns, "xmlns", svgns);
                svg.setAttributeNS(xmlns, "xmlns:xlink", xlinkns);
                const serializer = new window.XMLSerializer();
                const string = serializer.serializeToString(svg);
                return new Blob([string], { type: "image/svg+xml" });
              };
            },
          },
          {
            name: "math",
            inputs: ["require"],
            value: function (require) {
              return require("https://cdnjs.cloudflare.com/ajax/libs/mathjs/5.4.0/math.js");
            },
          },
          {
            name: "text",
            inputs: ["input"],
            value: function (input) {
              return function text(config = {}) {
                const {
                  value,
                  title,
                  description,
                  autocomplete = "off",
                  maxlength,
                  minlength,
                  pattern,
                  placeholder,
                  size,
                  submit,
                } = config;
                if (typeof config == "string") value = config;
                const form = input({
                  type: "text",
                  title,
                  description,
                  submit,
                  attributes: {
                    value,
                    autocomplete,
                    maxlength,
                    minlength,
                    pattern,
                    placeholder,
                    size,
                  },
                });
                form.output.remove();
                form.input.style.fontSize = "1em";
                return form;
              };
            },
          },
          {
            name: "params",
            value: function () {
              return new URL(document.baseURI).searchParams;
            },
          },
          {
            name: "d3require",
            inputs: ["require"],
            value: function (require) {
              return require("d3-require");
            },
          },
          {
            name: "copy",
            value: function () {
              return function copy(text) {
                const fake = document.body.appendChild(
                  document.createElement("input")
                );
                fake.style.position = "absolute";
                fake.style.left = "-9999px";
                fake.setAttribute("readonly", "");
                fake.value = "" + text;
                fake.select();
                try {
                  return document.execCommand("copy");
                } catch (err) {
                  return false;
                } finally {
                  fake.parentNode.removeChild(fake);
                }
              };
            },
          },
        ],
      };
      
      const notebook = {
        id: "0a758b4fa09748f2@2655",
        modules: [m0],
      };
      
      const renders = {
        "viewof inputAngle": "#viewof-inputAngle",
        "viewof inputText": "#viewof-inputText",
        "viewof labelOption": "#viewof-labelOption",
        "viewof currColors": "#viewof-currColors",
        "viewof strokeThickness": "#viewof-strokeThickness",
        "viewof labelColor": "#viewof-labelColor",
        "viewof numColor": "#viewof-numColor",
        "viewof hMoment": "#viewof-hMoment",
        "viewof hFace": "#viewof-hFace",
        "viewof customColorInput" : "#viewof-customColorInput",
        "viewof customColor" : "#viewof-customColor",
        "svgSave": "#svgSave",
        "helicalwheel": "#helicalwheel",
        "viewof slider": "#viewof-slider",
        "viewof copyButton" : "#viewof-copyButton",
        "viewof shareButtons" : "#viewof-shareButtons",
        "viewof numsOn" : "#viewof-numsOn",
        "viewof residuesOn" : "#viewof-residuesOn",
    
        // We have many color pickers
        "viewof hColor": "#viewof-hColor",
        "viewof kColor": "#viewof-kColor",
        "viewof rColor": "#viewof-rColor",
        "viewof dColor": "#viewof-dColor",
        "viewof eColor": "#viewof-eColor",
        "viewof sColor": "#viewof-sColor",
        "viewof tColor": "#viewof-tColor",
        "viewof nColor": "#viewof-nColor",
        "viewof qColor": "#viewof-qColor",
        "viewof aColor": "#viewof-aColor",
        "viewof vColor": "#viewof-vColor",
        "viewof lColor": "#viewof-lColor",
        "viewof iColor": "#viewof-iColor",
        "viewof mColor": "#viewof-mColor",
        "viewof fColor": "#viewof-fColor",
        "viewof wColor": "#viewof-wColor",
        "viewof yColor": "#viewof-yColor",
        "viewof pColor": "#viewof-pColor",
        "viewof gColor": "#viewof-gColor",
        "viewof cColor": "#viewof-cColor",
      };
    
    for (let i in renders)
    renders[i] = document.querySelector(renders[i]);
    
    Runtime.load(notebook, (variable) => {
    if (renders[variable.name]){
      console.log(variable.name)
      return new Inspector(renders[variable.name]);
      }
    });
}


export default drawHelicalWheel;
  