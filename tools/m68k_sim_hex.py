"""Fills in the machine code of the 68000 simulator self test.

Every case in scripts/scr_m68k_selftest/scr_m68k_selftest.gml is one line:
    ["name", "source | lines", "HEX", "setup", "expected"],
This assembles each source with the bundled vasm (-Fbin -no-opt, ORG $1000;
a source starting "020|" is assembled with -m68020 and run on a 68020)
and writes the bytes into the third field. Run it after editing a case:
    python tools/m68k_sim_hex.py
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GML = os.path.join(ROOT, "scripts", "scr_m68k_selftest", "scr_m68k_selftest.gml")
VASM = os.path.join(ROOT, "datafiles", "vasmm68k_mot_Win64", "vasmm68k_mot.exe")
CASE = re.compile(r'^(\s*\[\s*"[^"]*",\s*")([^"]*)(",\s*")([0-9A-Fa-f ]*)(".*)$')
LABEL = re.compile(r'^([A-Za-z_.][\w.]*):\s*(.*)$')


def assemble(source, workdir):
    cpu = "-m68000"
    if source.startswith("020|"):
        cpu = "-m68020"
        source = source[4:]
    lines = ["\torg $1000"]
    for part in source.split("|"):
        part = part.strip()
        m = LABEL.match(part)
        if m:
            lines.append(m.group(1) + ":")
            part = m.group(2)
        if part:
            lines.append("\t" + part)
    src = os.path.join(workdir, "case.s")
    out = os.path.join(workdir, "case.bin")
    with open(src, "w") as f:
        f.write("\n".join(lines) + "\n")
    if os.path.exists(out):
        os.remove(out)
    r = subprocess.run([VASM, "-Fbin", cpu, "-no-opt", "-quiet", "-o", out, src],
                       capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(out):
        raise RuntimeError(r.stdout + r.stderr)
    with open(out, "rb") as f:
        return f.read().hex().upper()


def main():
    with open(GML, encoding="utf-8") as f:
        text = f.read().split("\n")
    changed = 0
    errors = 0
    with tempfile.TemporaryDirectory() as work:
        for i, line in enumerate(text):
            m = CASE.match(line)
            if not m:
                continue
            try:
                code = assemble(m.group(2), work)
            except RuntimeError as e:
                print("FAILED:", m.group(2), "\n", e)
                errors += 1
                continue
            if code != m.group(4):
                text[i] = m.group(1) + m.group(2) + m.group(3) + code + m.group(5)
                changed += 1
    with open(GML, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(text))
    print(changed, "cases updated,", errors, "errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
