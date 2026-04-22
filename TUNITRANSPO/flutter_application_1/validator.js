const fs = require("fs");
const files = [
  "scripts/data/banlieue_sud_line_a_timetable.json",
  "scripts/data/line_d_timetable.json",
  "scripts/data/banlieue_nabeul_timetable.json",
  "scripts/data/grandes_lignes_timetable.json",
  "scripts/data/sncft_kef_timetable.json"
];

const results = {};
files.forEach(file => {
  try {
    if (fs.existsSync(file)) {
      results[file] = JSON.parse(fs.readFileSync(file, "utf8"));
    } else {
      results[file] = null;
    }
  } catch (e) {
    results[file] = { error: e.message };
  }
});

function checkBanlieueSud(data) {
  if (!data || data.error) return data;
  const out = [];
  const south = data.trips.filter(t => t.routeId === "route_bs_south");
  const north = data.trips.filter(t => t.routeId === "route_bs_north");
  out.push({ rule: "South trip count 60-67", pass: south.length >= 60 && south.length <= 67, val: south.length });
  out.push({ rule: "North trip count 48-55", pass: north.length >= 48 && north.length <= 55, val: north.length });
  const badSouth = south.filter(t => JSON.stringify(t.operatingDays) === "[0,1,2,3,4,5,6]" && parseInt(t.tripNumber) >= 113 && parseInt(t.tripNumber) <= 213);
  out.push({ rule: "No matching daily trips 113-213", pass: badSouth.length === 0, count: badSouth.length });
  const required = ["129", "145", "169", "173"];
  const missing = required.filter(n => !south.some(t => t.tripNumber === n));
  out.push({ rule: "Trains 129, 145, 169, 173 exist", pass: missing.length === 0, missing });
  const times = data.trips.flatMap(t => t.stopTimes.map(st => st.departureTime).filter(Boolean));
  const badTimes = times.filter(t => t < "04:00" || t > "23:00");
  out.push({ rule: "Departure times 04:00-23:00", pass: badTimes.length === 0, count: badTimes.length });
  return out;
}

function checkLineD(data) {
  if (!data || data.error) return data;
  const out = [];
  const forward = data.trips.filter(t => t.routeId === "route_sncft_line_d_forward");
  const reverse = data.trips.filter(t => t.routeId === "route_sncft_line_d_reverse");
  out.push({ rule: "Forward count = 21", pass: forward.length === 21, val: forward.length });
  out.push({ rule: "Reverse count = 22", pass: reverse.length === 22, val: reverse.length });
  const nonDaily = data.trips.filter(t => t.operatingDays && JSON.stringify(t.operatingDays) !== "[0,1,2,3,4,5,6]");
  out.push({ rule: "At least 5 non-daily trains", pass: nonDaily.length >= 5, val: nonDaily.length });
  return out;
}

function checkNabeul(data) {
  if (!data || data.error) return data;
  const out = [];
  const allowed = ["bn_foundouk_jedid", "bn_khanguet", "bn_turki", "bn_belli", "bn_hammamet", "bn_omar_khayem", "bn_mrazga", "bn_nabeul"];
  const badId = [];
  data.routeStops.forEach(rs => {
    if (rs.stationId.startsWith("bn_") && !allowed.includes(rs.stationId)) badId.push(rs.stationId);
  });
  out.push({ rule: "Station ID bn_ whitelist", pass: badId.length === 0, badId });
  const required = ["bs_tunis_ville", "bs_borj_cedria", "sncft_grombalia", "sncft_bir_bou_regba"];
  const missing = required.filter(id => {
    const s = data.routeStops.find(rs => rs.stationId === id);
    return !s || s.shared !== true;
  });
  out.push({ rule: "Required shared stations exist", pass: missing.length === 0, missing });
  return out;
}

function checkGL(data) {
  if (!data || data.error) return data;
  const out = [];
  const t14 = data.trips.find(t => t.tripNumber === "14" && t.routeId === "route_sncft_gl_annaba_reverse");
  out.push({ rule: "Train 14 operatingDays [1..6]", pass: t14 && JSON.stringify(t14.operatingDays) === "[1,2,3,4,5,6]", val: t14 ? t14.operatingDays : "not found" });
  return out;
}

function checkKef(data) {
  if (!data || data.error) return data;
  const out = [];
  const t650A = data.trips.find(t => t.tripNumber === "6/50(A)");
  out.push({ rule: "Train 6/50(A) operatingDays [1..6]", pass: t650A && JSON.stringify(t650A.operatingDays) === "[1,2,3,4,5,6]", val: t650A ? t650A.operatingDays : "not found" });
  const stations = data.routeStops.map(rs => rs.stationName);
  out.push({ rule: "El Akhouat exists", pass: stations.includes("El Akhouat") });
  out.push({ rule: "El Akeba does not exist", pass: !stations.includes("El Akeba") });
  out.push({ rule: "Bir MCherga exists", pass: stations.includes("Bir M'Cherga") });
  out.push({ rule: "Bir Mcherga does not exist", pass: !stations.includes("Bir Mcherga") });
  out.push({ rule: "Gouraïa exists", pass: stations.includes("Gouraïa") });
  out.push({ rule: "Gouraia does not exist", pass: !stations.includes("Gouraia") });
  return out;
}

console.log("BANLIEUE SUD:", JSON.stringify(checkBanlieueSud(results[files[0]]), null, 2));
console.log("LINE D:", JSON.stringify(checkLineD(results[files[1]]), null, 2));
console.log("NABEUL:", JSON.stringify(checkNabeul(results[files[2]]), null, 2));
console.log("GRANDES LIGNES:", JSON.stringify(checkGL(results[files[3]]), null, 2));
console.log("KEF:", JSON.stringify(checkKef(results[files[4]]), null, 2));
