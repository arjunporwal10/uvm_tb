#!/usr/bin/env python3
import os, sys, re, glob

def parse_yaml_subset(path):
    """
    Extremely small 'key: value' parser:
      - Booleans: true/false
      - Integers: decimal (e.g. 123)
      - Strings: everything else (strip quotes if present)
    One key per line, no nesting (sufficient for our scenario_cfg).
    """
    d = {}
    with open(path, "r") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if ":" not in line:
                continue
            key, val = line.split(":", 1)
            key = key.strip()
            val = val.strip()

            # strip optional surrounding quotes
            if (len(val) >= 2) and ((val[0] == '"' and val[-1] == '"') or (val[0] == "'" and val[-1] == "'")):
                val = val[1:-1]

            low = val.lower()
            if low in ("true", "false"):
                d[key] = 1 if low == "true" else 0
            elif re.fullmatch(r"-?\d+", val):
                d[key] = int(val)
            else:
                d[key] = val
    return d

def emit_pkg(cfgs, out_path):
    with open(out_path, "w") as f:
        f.write("package scenario_config_pkg;\n  import uvm_pkg::*;\n  import avry_types_pkg::*;\n\n")
        f.write("  function avry_scenario_cfg get_scenario_by_name(string name);\n")
        f.write("    avry_scenario_cfg cfg = new();\n")
        f.write("    if (0) ;\n")
        for c in cfgs:
            nm = c.get("scenario_name", "unknown")
            f.write(f"    else if (name == \"{nm}\") begin\n")
            for k, v in c.items():
                if isinstance(v, int):
                    f.write(f"      cfg.{k} = {v};\n")
                else:
                    f.write(f"      cfg.{k} = \"{v}\";\n")
            f.write("    end\n")
        f.write("    else begin `uvm_warning(\"SCEN\", $sformatf(\"Unknown scenario %s\", name)) end\n")
        f.write("    return cfg;\n  endfunction\nendpackage\n")

def main():
    if len(sys.argv) < 3:
        print("Usage: yaml2sv.py <yaml_dir> <out_pkg_path>")
        sys.exit(2)

    yaml_dir = os.path.abspath(sys.argv[1])
    out_pkg   = sys.argv[2]
    if not os.path.isdir(yaml_dir):
        print(f"[ERROR] YAML directory not found: {yaml_dir}")
        sys.exit(3)

    # Find YAML files recursively
    files = sorted(glob.glob(os.path.join(yaml_dir, "**", "*.yaml"), recursive=True) +
                   glob.glob(os.path.join(yaml_dir, "**", "*.yml"),  recursive=True))

    if not files:
        print(f"[ERROR] No YAML files found under: {yaml_dir}")
        print("        Ensure you run from repo root or pass the correct path, e.g.:")
        print("        python3 tools/yaml2sv.py ./yaml src/tb/pkgs/scenario_config_pkg.sv")
        sys.exit(4)

    print("[INFO] Parsing YAML files:")
    cfgs = []
    for p in files:
        d = parse_yaml_subset(p)
        if "scenario_name" in d:
            print(f"  - {p}  -> scenario_name={d['scenario_name']}")
            cfgs.append(d)
        else:
            print(f"  - {p}  (skipped: no 'scenario_name')")

    if not cfgs:
        print("[ERROR] Parsed YAML files, but none contained 'scenario_name'.")
        sys.exit(5)

    os.makedirs(os.path.dirname(out_pkg), exist_ok=True)
    emit_pkg(cfgs, out_pkg)
    print(f"[OK] Wrote {out_pkg} with {len(cfgs)} scenarios.")

if __name__ == "__main__":
    main()

