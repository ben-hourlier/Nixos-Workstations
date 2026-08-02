{ pkgs, ... } :

pkgs.writers.writePython3Bin "comp-inventory" ''
    import csv
    import os
    import subprocess
    import sys
    from pathlib import Path

    DB_FILE = Path.home() / "Sync/02-AREAS/components.tsv"
    HEADER = ["DRAWER", "NAME", "QTY", "TAGS"]


    def ensure_db():
        DB_FILE.parent.mkdir(parents=True, exist_ok=True)
        if not DB_FILE.exists():
            with open(DB_FILE, "w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f, delimiter="\t")
                writer.writerow(HEADER)


    def read_db():
        ensure_db()
        with open(DB_FILE, "r", encoding="utf-8") as f:
            reader = csv.reader(f, delimiter="\t")
            rows = list(reader)
        if not rows:
            return HEADER, []
        return rows[0], rows[1:]


    def write_db(header, rows):
        with open(DB_FILE, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f, delimiter="\t")
            writer.writerow(header)
            writer.writerows(rows)


    def add_item():
        print("\n--- Add New Component ---")
        drawer = input("Drawer ID (e.g. A01) : ").strip()
        name = input("Component Name (without space) : ").strip()

        print("Quantity status : 1) available  2) low  3) none")
        q_choice = input("Select (1-3) [1]   : ").strip()
        qty_map = {"1": "available", "2": "low", "3": "none"}
        qty = qty_map.get(q_choice, "available")

        tags = input("Tags (comma separated): ").strip()

        header, rows = read_db()
        rows.append([drawer, name, qty, tags])
        write_db(header, rows)
        print(f"✅ '{name}' successfully added to drawer {drawer}!")


    def cycle_qty(row):
        if not row or len(row) < 3:
            return
        drawer, name = row[0], row[1]
        header, rows = read_db()

        cycle_map = {"available": "low", "low": "none", "none": "available"}

        for r in rows:
            if len(r) >= 3 and r[0] == drawer and r[1] == name:
                r[2] = cycle_map.get(r[2].strip(), "available")
                break

        write_db(header, rows)


    def delete_item(row):
        if not row or len(row) < 2:
            return
        drawer, name = row[0], row[1]
        confirm = input(f"Delete '{name}' from {drawer}? (y/N) : ").strip().lower()
        if confirm == "y":
            header, rows = read_db()
            rows = [r for r in rows if not (r[0] == drawer and r[1] == name)]
            write_db(header, rows)
            print("Deleted!")


    def build_fzf_input(rows, padding=5):
        """Calculates column widths for clean alignment with custom spacing."""
        if not rows:
            return []

        col_widths = [0] * 4
        for r in rows:
            for i in range(min(4, len(r))):
                col_widths[i] = max(col_widths[i], len(r[i]))

        lines = []
        for r in rows:
            padded = [r[i].ljust(col_widths[i]) for i in range(min(4, len(r)))]
            lines.append((" " * padding).join(padded))
        return lines


    def interactive_mode():
        while True:
            header, rows = read_db()
            if not rows:
                print("No components found. Opening creation prompt...")
                add_item()
                continue

            lines = build_fzf_input(rows, padding=5)

            preview_cmd = (
                "python3 -c '"
                "import sys; "
                "line=sys.argv[1].split(); "
                "qty=line[2] if len(line)>2 else \"\"; "
                "icon=\"🟢\" if qty==\"available\" else (\"🟡\" if qty==\"low\" else \"🔴\"); "
                "print(f\"\\033[1;32m📍 DRAWER : {line[0]}\\033[0m\\n"
                "📦 Name   : {line[1]}\\n"
                "📊 Stock  : {icon} {qty}\\n"
                "🏷️  Tags   : {\" \".join(line[3:])}\")'"
                " {}"
            )

            fzf_proc = subprocess.Popen(
                [
                    "fzf",
                    "--prompt=🔍 Search > ",
                    "--layout=reverse",
                    "--header=[Ctrl-A] Add | [Ctrl-D] Delete | [Ctrl-Q] Cycle Qty | [Ctrl-E] Nvim",
                    "--preview", preview_cmd,
                    "--preview-window=bottom:5:wrap",
                    "--expect=ctrl-a,ctrl-d,ctrl-q,ctrl-e",
                ],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                text=True,
            )

            stdout, _ = fzf_proc.communicate(input="\n".join(lines))
            out_lines = stdout.splitlines()

            if not out_lines:
                break  # ESC key pressed

            key = out_lines[0]
            selected_text = out_lines[1] if len(out_lines) > 1 else ""

            selected_row = None
            if selected_text:
                idx = lines.index(selected_text)
                selected_row = rows[idx]

            if key == "ctrl-a":
                add_item()
            elif key == "ctrl-d" and selected_row:
                delete_item(selected_row)
            elif key == "ctrl-q" and selected_row:
                cycle_qty(selected_row)
            elif key == "ctrl-e":
                editor = os.environ.get("EDITOR", "nvim")
                subprocess.run([editor, str(DB_FILE)])
            else:
                break


    if __name__ == "__main__":
        if len(sys.argv) > 1:
            cmd = sys.argv[1]
            if cmd == "add":
                add_item()
            elif cmd == "edit":
                editor = os.environ.get("EDITOR", "nvim")
                subprocess.run([editor, str(DB_FILE)])
        else:
            interactive_mode()
''