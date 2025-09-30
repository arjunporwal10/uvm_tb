import os, sys, yaml

def sv_escape(s):
    return f'"{s}"' if isinstance(s, str) else str(s)

def emit_action(action, idx):
    """Convert one YAML action into SV code and variable name"""
    atype = action['action_type']
    data = action.get('action_data', {})
    name = f"a_{atype.lower()}_{idx}"
    lines = []

    prefix = "stimulus_auto_builder_pkg::stimulus_auto_builder::"

    if atype == 'RESET':
        lines.append(f"{name} = {prefix}build_reset();")
    elif atype == 'WAIT_VIRAL':
        state = sv_escape(data.get('expected_state', 'VIRAL_ACTIVE'))
        timeout = data.get('timeout', 1000)
        lines.append(f"{name} = {prefix}build_wait_viral({state}, {timeout});")
    elif atype == 'ERROR':
        lines.append(f"{name} = {prefix}build_error();")
    elif atype == 'SELF_CHECK':
        lines.append(f"{name} = {prefix}build_self_check();")
    elif atype == 'REG_WRITE':
        addr = hex(data['addr']); val = hex(data['data'])
        lines.append(f"{name} = {prefix}build_reg_write({addr}, {val});")
    elif atype == 'REG_READ':
        addr = hex(data['addr'])
        lines.append(f"{name} = {prefix}build_reg_read({addr});")
    elif atype == 'TRAFFIC':
        npkt = data.get('num_packets', 16)
        dirn = "DIR_WRITE" if data.get('direction', 'write').lower() == 'write' else "DIR_READ"
        lines.append(f"{name} = {prefix}build_traffic({dirn}, {npkt});")
    elif atype == 'LINK_DEGRADE':
        lines.append(f"{name} = {prefix}build_link_degrade();")
    else:
        raise ValueError(f"Unknown action_type: {atype}")

    return lines, name

def emit_scenario(name, content):
    # Predeclare all variables first
    predecls = []
    action_list = content.get('action_list', [])
    for idx, action in enumerate(action_list):
        atype = action['action_type']
        predecls.append(f"stimulus_action_t a_{atype.lower()}_{idx};")

    lines = [f'    else if (name == "{name}") begin',
             f'      cfg.scenario_name = "{name}";']

    for field in ['timeout_value']:
        if field in content:
            val = content[field]
            lines.append(f"      cfg.{field} = {val};")

    lines.extend([f"      {d}" for d in predecls])

    action_names = []
    for idx, action in enumerate(action_list):
        action_code, action_name = emit_action(action, idx)
        for line in action_code:
            lines.append(f"      {line}")
        action_names.append(action_name)

    lines.append(f"      cfg.action_list.delete();")
    for name in action_names:
        lines.append(f"      cfg.action_list.push_back({name});")
    lines.append("    end")
    return '\n'.join(lines)

def main(yaml_dir, output_sv):
    scenario_blocks = []
    for fname in os.listdir(yaml_dir):
        if fname.endswith('.yaml'):
            with open(os.path.join(yaml_dir, fname), 'r') as f:
                data = yaml.safe_load(f)
                name = data.get('scenario_name')
                if not name:
                    print(f"[SKIP] {fname}: No scenario_name")
                    continue
                print(f"[OK] Generating SV for scenario: {name}")
                block = emit_scenario(name, data)
                scenario_blocks.append(block)

    with open(output_sv, 'w') as f:
        f.write("// Auto-generated scenario_config_pkg.sv\n")
        f.write("package scenario_config_pkg;\n")
        f.write("  import avry_types_pkg::*;\n")
        f.write("  import stimulus_auto_builder_pkg::*;\n")
        f.write("  function automatic avry_scenario_cfg get_scenario_by_name(string name);\n")
        f.write("      avry_scenario_cfg cfg = avry_scenario_cfg::type_id::create(name);\n")
        f.write("      if (0) ;\n")
        for block in scenario_blocks:
            f.write(block + "\n")
        f.write("      return cfg;\n")
        f.write("    endfunction\n")
        f.write("endpackage\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 tools/yaml2sv.py <yaml_dir> <output_sv_file>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

