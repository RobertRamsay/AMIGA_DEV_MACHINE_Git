"""Checks the type-along steps of the 68K course (datafiles/course/course_N.txt).

For every lesson with tests it applies the @step blocks to the @start code the
way TYPE IT FOR ME does (scr_course_step_apply) and checks that the result has
the same lines as @solution (comments, spaces and case ignored), that every
step has a title, an explanation and a line to type, and that no step is
already done in @start. -admcourse then assembles and tests the result too.

    python tools/course_steps_check.py            all five files
    python tools/course_steps_check.py 3          course_3.txt only
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IDENT = re.compile(r'^([A-Za-z_.][\w.]*)(:?)(.*)$')


def strip_comment(line):
    if line[:1] == "*":
        return ""
    quote = None
    for i, ch in enumerate(line):
        if quote:
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
        elif ch == ";":
            return line[:i]
    return line


def line_keys(line):
    """Mirror of scr_course_line_keys: label key and instruction key."""
    line = strip_comment(line.replace("\r", "").replace("\t", "    "))
    out = []
    if line.strip() == "":
        return out
    rest = line
    if line[:1] not in (" ", ""):
        m = IDENT.match(line)
        if m:
            out.append("label:" + m.group(1).lower())
            rest = m.group(3)
    else:
        m = IDENT.match(line.strip())
        if m and m.group(2) == ":":
            out.append("label:" + m.group(1).lower())
            rest = m.group(3)
    op = re.sub(r"\s+", "", rest).lower()
    if op:
        out.append(op)
    return out


def counts(lines):
    c = {}
    for l in lines:
        for k in line_keys(l):
            c[k] = c.get(k, 0) + 1
    return c


def find_line(lines, want):
    wk = line_keys(want)
    if not wk:
        return -1
    for i, l in enumerate(lines):
        k = line_keys(l)
        if all(w in k for w in wk):
            return i
    return -1


def apply_step(lines, step):
    out = list(lines)
    at = -1
    for r in step["remove"]:
        f = find_line(out, r)
        if f < 0:
            continue
        del out[f]
        if at < 0 or f < at:
            at = f
    if at < 0 and step["after"]:
        a = find_line(out, step["after"])
        if a >= 0:
            at = a + 1
    if at < 0:
        at = len(out)
        while at > 0 and out[at - 1].strip() == "":
            at -= 1
    out[at:at] = step["add"]
    return out


def trim(block):
    lines = block.split("\n")
    while lines and lines[0].strip() == "":
        lines.pop(0)
    while lines and lines[-1].strip() == "":
        lines.pop()
    return lines


def parse(text):
    items = []
    item = None
    section = ""
    step = None
    for line in text.replace("\r", "").split("\n"):
        if line.startswith("=== "):
            head = line[4:]
            kw = head.split(":")[0].split()
            if kw[0].upper() == "UNIT":
                continue
            item = {"kind": kw[0].upper(), "n": int(kw[1]), "start": "", "solution": "",
                    "tests": 0, "steps": []}
            items.append(item)
            section = ""
            continue
        if item is None:
            continue
        if line.startswith("@"):
            parts = line[1:].split(" ", 1)
            section = parts[0].lower()
            rest = parts[1].strip() if len(parts) > 1 else ""
            if section == "test":
                item["tests"] += 1
            if section == "step":
                step = {"title": rest, "text": "", "add": [], "remove": [], "after": ""}
                item["steps"].append(step)
            continue
        if section in ("start", "solution"):
            item[section] += ("\n" if item[section] else "") + line
        elif section == "step":
            m = line[:1]
            if m in (">", "<", "^"):
                body = line[1:]
                if body[:1] == " ":
                    body = body[1:]
                if m == ">":
                    step["add"].append(body)
                elif m == "<":
                    step["remove"].append(body)
                else:
                    step["after"] = body
            else:
                step["text"] += line + "\n"
    return items


def key_seq(lines):
    seq = []
    for l in lines:
        seq.extend(line_keys(l))
    return seq


def check(path):
    with open(path, encoding="utf-8") as f:
        items = parse(f.read())
    problems = []
    for it in items:
        if it["kind"] != "LESSON" or it["tests"] == 0:
            continue
        name = "LESSON %d" % it["n"]
        if not it["steps"]:
            problems.append(name + ": no @step")
            continue
        code = trim(it["start"])
        start_counts = counts(code)
        for s, st in enumerate(it["steps"], 1):
            sn = "%s step %d" % (name, s)
            has = bool(st["remove"]) or any(line_keys(a) for a in st["add"])
            if not has:
                problems.append(sn + ": no line to type")
            if not st["title"] or not st["text"].strip():
                problems.append(sn + ": needs a title and an explanation")
            for tl in st["text"].split("\n"):
                if tl.startswith("\t") or tl.startswith("    "):
                    problems.append(sn + ": indented code in the explanation (use > lines): " + tl.strip())
            if st["after"] and find_line(code, st["after"]) < 0:
                problems.append(sn + ": its ^ line is not in the code yet: " + st["after"].strip())
            for r in st["remove"]:
                if find_line(code, r) < 0:
                    problems.append(sn + ": its < line is not in the code: " + r.strip())
            code = apply_step(code, st)
            after = counts(code)
            need = {}
            for a in st["add"]:
                for k in line_keys(a):
                    need[k] = after.get(k, 1)
            most = {}
            for r in st["remove"]:
                rk = line_keys(r)
                if rk:
                    most[rk[-1]] = after.get(rk[-1], 0)
            done_in_start = has and all(start_counts.get(k, 0) >= v for k, v in need.items()) \
                and all(start_counts.get(k, 0) <= v for k, v in most.items())
            if done_in_start:
                problems.append(sn + ": already done in @start")
        got = key_seq(code)
        want = key_seq(trim(it["solution"]))
        if got != want:
            i = 0
            while i < min(len(got), len(want)) and got[i] == want[i]:
                i += 1
            problems.append("%s: start + steps differs from @solution at key %d: got %r, want %r"
                            % (name, i, got[i:i + 3], want[i:i + 3]))
    return problems


def main():
    files = sys.argv[1:] or ["1", "2", "3", "4", "5"]
    total = 0
    for n in files:
        path = os.path.join(ROOT, "datafiles", "course", "course_%s.txt" % n)
        probs = check(path)
        for p in probs:
            print("course_%s: %s" % (n, p))
        total += len(probs)
    print(total, "problems")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
