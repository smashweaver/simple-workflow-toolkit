#!/usr/bin/env python3
import sys
import re
import os

def main():
    if len(sys.argv) < 3:
        print("Usage: archive_plan.py <task_file> <spec_file>")
        sys.exit(1)
        
    task_file = sys.argv[1]
    spec_file = sys.argv[2]
    
    if not os.path.exists(task_file):
        print(f"Error: Task file '{task_file}' does not exist.")
        sys.exit(1)
        
    if not os.path.exists(spec_file):
        # Spec file is optional/might not exist (Lite path)
        print(f"Spec file '{spec_file}' does not exist. Skipping plan archival.")
        sys.exit(0)
        
    with open(task_file, 'r', encoding='utf-8') as f:
        task_content = f.read()
        
    # Extract from ## Implementation Plan to the start of the next section
    # Valid next sections in task file: Tactical Roadmap, Commit Reference, Checklist
    match = re.search(
        r'##\s+Implementation Plan\s*\n(.*?)(?=\n##\s+(Tactical Roadmap Protocol|Commit Reference|Checklist|Notes|Ritual Logs)|\Z)',
        task_content,
        re.DOTALL | re.IGNORECASE
    )
    
    if not match:
        print("⚠️  Warning: No '## Implementation Plan' section found in task file. Skipping archival.")
        sys.exit(0)
        
    plan_body = match.group(1).strip()
    
    with open(spec_file, 'r', encoding='utf-8') as f:
        spec_content = f.read()
        
    # We want to replace from ## 6. Implementation Plan to ## 7. Risks & Mitigations
    # The header in spec might be numbered or unnumbered, e.g. "## 6. Implementation Plan" or "## Implementation Plan"
    pattern = r'(##\s+(?:6\.\s+)?Implementation Plan\s*\n).*?(?=\n##\s+(?:7\.\s+)?Risks\s*&\s*Mitigations|\n##\s+\d+\.|\Z)'
    
    spec_new, count = re.subn(
        pattern,
        r'\1' + plan_body + '\n',
        spec_content,
        flags=re.DOTALL | re.IGNORECASE
    )
    
    if count == 0:
        # Fallback if Risks & Mitigations header is different
        pattern_fallback = r'(##\s+(?:6\.\s+)?Implementation Plan\s*\n).*?(?=\n##\s+|\Z)'
        spec_new, count = re.subn(
            pattern_fallback,
            r'\1' + plan_body + '\n',
            spec_content,
            flags=re.DOTALL | re.IGNORECASE
        )
        
    if count > 0:
        with open(spec_file, 'w', encoding='utf-8') as f:
            f.write(spec_new)
        print(f"✅ Implementation Plan successfully archived into Spec: {spec_file}")
    else:
        print("⚠️  Warning: Could not find target Implementation Plan section in Spec file. Skipping archival.")

if __name__ == "__main__":
    main()
