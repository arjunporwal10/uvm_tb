import os
import sys
import yaml

def sv_escape(s):
    return f'"{s}"' if isinstance(s, str) else str(s)

def emit_action(action, idx):
    """Convert a single action to SystemVerilog assignment"""
    atype = action['action_type']
    data = action.get('action_data', {})
    name = f"a_{atype.lower()}_{idx}"
    lines = []

    # Handle each action type
    if atype == 'RESET':
        lines.append(f"{name} = stimulus_auto_builder::build_reset();")
    elif atype == 'VIRAL':
        lines.append(f"{name} = stimulus_auto_builder::build_viral();")
    elif atype == 'WAIT_VIRAL':
        state = sv_escape(data.get('expected_state', 'VIRAL_ACTIVE'))
        timeout = data.get('timeout', 1000)
        lines.append(f"{name} = stimulus_auto_builder::build_wait_viral({state}, {timeout});")
    elif atype == 'ERROR':
        lines.append(f"{name} = stimulus_auto_builder::build_error();")
    elif atype == 'SELF_CHECK':
        lines.append(f"{name} = stimulus_auto_builder::build_self_check();")
    elif atype == 'REG_WRITE':
        addr = hex(data['addr'])
        val = hex(data['data'])
        lines.append(f"{name} = stimulus_auto_builder::build_reg_write({addr}, {val});")
    elif atype == 'REG_READ':
        addr = hex(data['addr'])
        lines.append(f"{name} = stimulus_auto_builder::build_reg_read({addr});")
    elif atype == 'TRAFFIC':
        npkt = data.get('num_packets', 16)
        dirn = "DIR_WRITE" if data.get('direction', 'write').lower() == 'write' else "DIR_READ"
        lines.append(f"{name} = stimulus_auto_builder::build_traffic({dirn}, {npkt});")
    elif atype == 'LINK_DEGRADE':
        lines.append(f"{name} = stimulus_auto_builder::build_link_degrade();")
    elif atype == 'PARALLEL_GROUP':
        sub_actions = data['parallel_actions']
        sub_lines = []
        sub_names = []
        for i, sa in enumerate(sub_actions):
            sub_code, sub_name = emit_action(sa, f"{idx}_{i}")
            sub_lines.extend(sub_code)
            sub_names.append(sub_name)
        lines.extend(sub_lines)
        lines.append(f"{name} = stimulus_auto_builder::build_parallel('{{{', '.join(sub_names)}}}');")
    elif atype == 'SERIAL_GROUP':
        sub_actions = data['serial_actions']
        sub_lines = []
        sub_names = []
        for i, sa in enumerate(sub_actions):
            sub_code, sub_name = emit_action(sa, f"{idx}_{i}")
            sub_lines.extend(sub_code)
            sub_names.append(sub_name)
        lines.extend(sub_lines)
        lines.append(f"{name} = stimulus_auto_builder::build_serial('{{{', '.join(sub_names)}}}');")
    else:
        raise ValueError(f"Unknown action_type: {atype}")
    return lines, name

def emit_scenario(name, content):
    lines = [f'    else if (name == "{name}") begin']
    lines.append(f'      cfg.scenario_name = "{name}";')

    for field in ['timeout_value', 'addr_base', 'data_pattern', 'num_packets']:
        if field in content:
            val = content[field]
            if isinstance(val, str):
                val = sv_escape(val)
            elif isinstance(val, bool):
                val = 1 if val else 0
            elif isinstance(val, int):
                if 'addr' in field or 'pattern' in field:
                    val = hex(val)
            lines.append(f"      cfg.{field} = {val};")

    if 'do_self_check' in content:
        lines.append(f"      cfg.do_self_check = {1 if content['do_self_check'] else 0};")
    if 'expected_interrupts' in content:
        intlist = ', '.join([f'"{i}"' for i in content['expected_interrupts']])
        lines.append(f"      cfg.expected_interrupts = '{{{intlist}}};")

    action_list = content.get('action_list', [])
    action_sv = []
    action_names = []
    action_decls = []

    for idx, action in enumerate(action_list):
        action_code, action_name = emit_action(action, idx)
        action_decls.append(f"    stimulus_action_t {action_name};")
        action_sv.extend([f"      {line}" for line in action_code])
        action_names.append(action_name)

    return '\n'.join(action_decls), '\n'.join(lines + action_sv + [f"      cfg.action_list.delete();"] + 
                                              [f"      cfg.action_list.push_back({name});" for name in action_names] + 
                                              ["    end"])

def main(yaml_dir, output_sv):
    scenario_blocks = []
    declarations = []

    for fname in os.listdir(yaml_dir):
        if fname.endswith('.yaml'):
            with open(os.path.join(yaml_dir, fname), 'r') as f:
                data = yaml.safe_load(f)
                name = data.get('scenario_name')
                if not name:
                    print(f"[SKIP] {fname}: No scenario_name")
                    continue
                print(f"[OK] Generating SV for scenario: {name}")
                decls, block = emit_scenario(name, data)
                declarations.append(decls)
                scenario_blocks.append(block)

    with open(output_sv, 'w') as f:
        f.write("// Auto-generated scenario_config_pkg.sv\n")
        f.write("package scenario_config_pkg;\n")
        f.write("  import uvm_pkg::*;\n")
        f.write("  import avry_types_pkg::*;\n")
        f.write("  import stimulus_auto_builder_pkg::*;\n")
        f.write("  `include \"uvm_macros.svh\"\n\n")
        f.write("  function automatic avry_scenario_cfg get_scenario_by_name(string name);\n")
        f.write("    avry_scenario_cfg cfg = avry_scenario_cfg::type_id::create(name);\n\n")

        # All declarations at top
        for decl in declarations:
            f.write(decl + "\n")
        f.write("    if (0);\n")
        for block in scenario_blocks:
            f.write(block + "\n")
        f.write("    return cfg;\n")
        f.write("  endfunction\n")
        f.write("endpackage\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 tools/yaml2sv.py <yaml_dir> <output_sv_file>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

