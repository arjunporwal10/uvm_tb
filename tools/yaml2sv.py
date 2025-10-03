#!/usr/bin/env python3
import os, sys, yaml

# ---------- Literal helpers ----------
def sv_dec(val:int) -> str:
    return str(int(val))

def sv_hex32(val:int) -> str:
    v = int(val)
    return f"32'h{v & 0xFFFFFFFF:08x}"

def sv_str(s:str) -> str:
    return f'"{s}"'

def parse_int_maybe_hex(v):
    if isinstance(v, int):
        return v
    if isinstance(v, str):
        try:
            return int(v, 0)  # "0x...", "1234"
        except:
            raise ValueError(f"Expected int/hex string, got: {v}")
    raise ValueError(f"Expected int/hex string, got type: {type(v)}")

# ---------- Emitter ----------
class Emitter:
    def __init__(self):
        self.decls   = []  # stimulus_action_t a_x;
        self.assigns = []  # a_x = builder(...);

    def declare(self, var):
        line = f"      stimulus_action_t {var};"
        if line not in self.decls:
            self.decls.append(line)

    def assign(self, line):
        self.assigns.append(f"      {line}")

# ---------- Action emission ----------
def emit_action(action, idx_path, em: Emitter):
    atype = action['action_type']
    data  = action.get('action_data', {}) or {}
    base_name = atype.lower().replace('-', '_')
    var = f"a_{base_name}_{idx_path}"
    em.declare(var)

    if atype == 'RESET':
        em.assign(f"{var} = stimulus_auto_builder::build_reset();")

    elif atype in ('VIRAL', 'VIRAL_CHECK'):
        em.assign(f"{var} = stimulus_auto_builder::build_viral();")

    elif atype == 'WAIT_VIRAL':
        state   = sv_str(data.get('expected_state', 'VIRAL_ACTIVE'))
        timeout = sv_dec(parse_int_maybe_hex(data.get('timeout', 1000)))
        em.assign(f"{var} = stimulus_auto_builder::build_wait_viral({state}, {timeout});")

    elif atype in ('ERROR', 'ERROR_INJECTION'):
        em.assign(f"{var} = stimulus_auto_builder::build_error();")

    elif atype == 'SELF_CHECK':
        em.assign(f"{var} = stimulus_auto_builder::build_self_check();")

    elif atype == 'REG_WRITE':
        addr = sv_hex32(parse_int_maybe_hex(data['addr']))
        val  = sv_hex32(parse_int_maybe_hex(data['data']))
        em.assign(f"{var} = stimulus_auto_builder::build_reg_write({addr}, {val});")

    elif atype == 'REG_READ':
        addr = sv_hex32(parse_int_maybe_hex(data['addr']))
        em.assign(f"{var} = stimulus_auto_builder::build_reg_read({addr});")

    elif atype == 'LINK_DEGRADE':
        dtype        = sv_str(data.get('degrade_type', "generic"))
        delay_cycles = sv_dec(parse_int_maybe_hex(data.get('delay_cycles', 100)))
        em.assign(f"{var} = stimulus_auto_builder::build_link_degrade({dtype}, {delay_cycles});")

    elif atype == 'TRAFFIC':
        npkt = sv_dec(parse_int_maybe_hex(data.get('num_packets', 16)))
        dstr = str(data.get('direction', 'write')).lower()
        dirn = "DIR_WRITE" if dstr == "write" else "DIR_READ"
        base = data.get('addr_base', None)
        pat  = data.get('data_pattern', None)
        if base is None and pat is None:
            em.assign(f"{var} = stimulus_auto_builder::build_traffic({dirn}, {npkt});")
        else:
            base_lit = sv_hex32(parse_int_maybe_hex(base)) if base is not None else "32'h00000000"
            pat_lit  = sv_hex32(parse_int_maybe_hex(pat))  if pat  is not None else "32'h00000000"
            em.assign(f"{var} = stimulus_auto_builder::build_traffic({dirn}, {npkt}, {base_lit}, {pat_lit});")

    elif atype == 'PARALLEL_GROUP':
        subs = data.get('parallel_actions', [])
        names = []
        for i, sa in enumerate(subs):
            names.append(emit_action(sa, f"{idx_path}_{i}", em))
        em.assign(f"{var} = stimulus_auto_builder::build_parallel({{{', '.join(names)}}});")

    elif atype == 'SERIAL_GROUP':
        subs = data.get('serial_actions', [])
        names = []
        for i, sa in enumerate(subs):
            names.append(emit_action(sa, f"{idx_path}_{i}", em))
        em.assign(f"{var} = stimulus_auto_builder::build_serial({{{', '.join(names)}}});")

    else:
        raise ValueError(f"Unknown action_type: {atype}")

    return var

# ---------- Scenario emission ----------
def emit_scenario_block(name, content):
    """
    Emits an else-if block that declares a_* variables FIRST,
    then cfg.* assignments, then action assignments, then push_backs.
    """
    em = Emitter()

    # Pre-walk actions to populate decls/assigns and final var order
    built = []
    for idx, act in enumerate(content.get('action_list', [])):
        built.append(emit_action(act, str(idx), em))

    lines = [f'    else if (name == "{name}") begin']

    # ---- Declarations FIRST
    lines.extend(em.decls)

    # ---- cfg.* assignments (including scenario_name) AFTER declarations
    lines.append(f'      cfg.scenario_name = "{name}";')
    if 'timeout_value' in content:
        lines.append(f"      cfg.timeout_value = {sv_dec(parse_int_maybe_hex(content['timeout_value']))};")
    if 'addr_base' in content:
        lines.append(f"      cfg.addr_base = {sv_hex32(parse_int_maybe_hex(content['addr_base']))};")
    if 'data_pattern' in content:
        lines.append(f"      cfg.data_pattern = {sv_hex32(parse_int_maybe_hex(content['data_pattern']))};")
    if 'num_packets' in content:
        lines.append(f"      cfg.num_packets = {sv_dec(parse_int_maybe_hex(content['num_packets']))};")
    if 'do_self_check' in content:
        lines.append(f"      cfg.do_self_check = {1 if content['do_self_check'] else 0};")
    if 'expected_interrupts' in content:
        ints = ', '.join([sv_str(x) for x in content['expected_interrupts']])
        lines.append(f"      cfg.expected_interrupts = '{{{ints}}};")

    # ---- Action assignments AFTER cfg fields
    lines.extend(em.assigns)

    # ---- Push into cfg
    lines.append("      cfg.action_list.delete();")
    for v in built:
        lines.append(f"      cfg.action_list.push_back({v});")

    lines.append("    end")
    return "\n".join(lines)

# ---------- Main ----------
def main(yaml_dir, output_sv):
    blocks = []
    for fname in sorted(os.listdir(yaml_dir)):
        if not fname.endswith(".yaml"):
            continue
        with open(os.path.join(yaml_dir, fname), 'r') as f:
            data = yaml.safe_load(f) or {}
        name = data.get("scenario_name")
        if not name:
            print(f"[SKIP] {fname}: no scenario_name")
            continue
        print(f"[OK] Generating SV for scenario: {name}")
        blocks.append(emit_scenario_block(name, data))

    with open(output_sv, "w") as f:
        f.write("// Auto-generated scenario_config_pkg.sv\n")
        f.write("package scenario_config_pkg;\n")
        f.write("  import avry_types_pkg::*;\n")
        f.write("  import stimulus_auto_builder_pkg::*;\n")
        f.write("  function automatic avry_scenario_cfg get_scenario_by_name(string name);\n")
        f.write("    avry_scenario_cfg cfg = avry_scenario_cfg::type_id::create(name);\n")
        f.write("    if (0) ;\n")
        for b in blocks:
            f.write(b + "\n")
        f.write("    return cfg;\n")
        f.write("  endfunction\n")
        f.write("endpackage\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 tools/yaml2sv.py <yaml_dir> <output_sv>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

