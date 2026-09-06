#!/usr/bin/env python3
import os
import sys
import re
import json
from datetime import datetime

def main():
    # 1. Parse CLI arguments
    # We support positional violation, detail, and an optional --agent/-a flag.
    # To be extremely developer friendly and robust, we will handle them manually or via argparse.
    import argparse
    parser = argparse.ArgumentParser(
        description="Log an AI agent protocol violation directly to the central SWT JAILBREAKS.md ledger."
    )
    parser.add_argument("violation", type=str, help="Name of the protocol violation")
    parser.add_argument("detail", type=str, help="Detailed description of what occurred")
    parser.add_argument("-a", "--agent", type=str, default="Agent", help="Name of the offending agent")

    # If too few arguments, show a friendly help message
    if len(sys.argv) < 3:
        print("❌ Error: Missing required arguments.")
        print("👉 Usage: /swt:flow jailbreak \"<violation_name>\" \"<details_explanation>\" [--agent <agent_name>]")
        sys.exit(1)

    args = parser.parse_args()

    # 2. Resolve ROOT_DIR (active project root)
    root_dir = os.path.abspath(os.getcwd())
    while root_dir != "/" and not os.path.exists(os.path.join(root_dir, "AGENTS.md")) and not os.path.isdir(os.path.join(root_dir, ".git")):
        root_dir = os.path.dirname(root_dir)

    # 3. Determine SWT_HOME and check strict configuration rules
    # Check if we are in the central SWT repository itself
    is_central = (
        os.path.exists(os.path.join(root_dir, "JAILBREAKS.md")) and
        os.path.exists(os.path.join(root_dir, "AGENTS.md")) and
        os.path.isdir(os.path.join(root_dir, "skills/swt-task"))
    )

    if is_central:
        swt_home = root_dir
        print("🎯 Executing in central toolkit repository. Central log targeted.")
    else:
        # Downstream project repository check: MUST have swt.json and contain swt_home
        swt_json_path = os.path.join(root_dir, "swt.json")
        if not os.path.exists(swt_json_path):
            print("❌ Error: swt.json not found in project root.")
            print("👉 Downstream projects must be initialized with '/swt:flow setup' before logging jailbreaks.")
            sys.exit(1)

        try:
            with open(swt_json_path, 'r') as f:
                config = json.load(f)
        except Exception as e:
            print(f"❌ Error parsing swt.json: {e}")
            sys.exit(1)

        swt_home = config.get("swt_home", "").strip()
        if not swt_home:
            print("❌ Error: 'swt_home' reference is missing or empty in swt.json.")
            print("👉 Downstream projects must configure 'swt_home' in swt.json pointing to the central SWT repository.")
            sys.exit(1)

        if not os.path.isdir(swt_home) or not os.path.exists(os.path.join(swt_home, "JAILBREAKS.md")):
            print(f"❌ Error: The 'swt_home' path '{swt_home}' configured in swt.json is invalid or does not contain JAILBREAKS.md.")
            sys.exit(1)

        print(f"🔗 Downstream project detected. SWT_HOME resolved to central ledger: {swt_home}")

    jailbreaks_path = os.path.join(swt_home, "JAILBREAKS.md")

    # 4. Harvest Downstream Context (Active Task & Phase)
    task_link = "N/A"
    phase = "N/A"

    task_ctx_path = os.path.join(root_dir, "task.ctx")
    if os.path.exists(task_ctx_path):
        try:
            with open(task_ctx_path, 'r') as f:
                relative_task_path = f.read().strip()
            
            if relative_task_path:
                absolute_task_path = os.path.abspath(os.path.join(root_dir, relative_task_path))
                if os.path.exists(absolute_task_path):
                    # Extract slug from task filename
                    filename = os.path.basename(absolute_task_path)
                    match = re.match(r"^\d+_(.+)\.md$", filename)
                    slug = match.group(1) if match else os.path.splitext(filename)[0]
                    
                    # Create clickable file:// URI
                    task_link = f"[{slug}](file://{absolute_task_path})"
                    
                    # Extract phase from metadata
                    with open(absolute_task_path, 'r') as tf:
                        task_content = tf.read()
                    phase_match = re.search(r"^\*\*?Phase\*\*?:\s*(\d+)", task_content, re.MULTILINE | re.IGNORECASE)
                    if phase_match:
                        phase = phase_match.group(1)
        except Exception as e:
            print(f"⚠️ Context harvest warning: {e}")

    # 5. Format the Markdown row
    current_date = datetime.now().strftime("%Y-%m-%d")
    new_row = f"| {current_date} | {task_link} | {args.agent} | {phase} | {args.violation} | {args.detail} |"

    # 6. Surgically append to JAILBREAKS.md
    try:
        with open(jailbreaks_path, 'r') as f:
            content = f.read()

        # Clean trailing whitespace and add the new row
        content_stripped = content.rstrip()
        updated_content = f"{content_stripped}\n{new_row}\n"

        with open(jailbreaks_path, 'w') as f:
            f.write(updated_content)

        print(f"✅ Jailbreak successfully logged directly to central ledger!")
        print(f"👉 Entry: {new_row}")
    except Exception as e:
        print(f"❌ Error writing to JAILBREAKS.md: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
