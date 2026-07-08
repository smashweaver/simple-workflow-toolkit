#!/usr/bin/env python3
import sys
import re
import os

def parse_markdown_sections(file_path):
    if not os.path.exists(file_path):
        return {}
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    sections = {}
    current_section = None
    section_lines = []
    
    for line in content.splitlines():
        if line.startswith('## ') or line.startswith('### '):
            if current_section:
                sections[current_section] = '\n'.join(section_lines).strip()
            current_section = line.lstrip('#').strip()
            section_lines = []
        elif current_section is not None:
            section_lines.append(line)
            
    if current_section:
        sections[current_section] = '\n'.join(section_lines).strip()
        
    return sections

def find_section(sections, name_lower):
    for k, v in sections.items():
        if name_lower in k.lower():
            return v
    return None

def has_substance(text):
    if not text:
        return False
    # Strip whitespace, asterisks, list bullet dashes, blockquotes, and brackets/alerts
    val = re.sub(r'[\s*>\-\[\]!:]', '', text)
    # Remove standard template indicators/placeholders
    val = val.replace('IMPORTANT', '').replace('NOTE', '').replace('WARNING', '').replace('CAUTION', '')
    return len(val) > 0

def main():
    if len(sys.argv) < 3:
        print("Usage: validate_substance.py <task_file> <phase>")
        sys.exit(1)
        
    task_file = sys.argv[1]
    try:
        phase = int(sys.argv[2])
    except ValueError:
        print(f"Error: Invalid phase '{sys.argv[2]}'")
        sys.exit(1)
        
    if not os.path.exists(task_file):
        print(f"Error: Task file '{task_file}' does not exist.")
        sys.exit(1)
        
    sections = parse_markdown_sections(task_file)
    
    # Validation for Phase 1+ (Implementation Plan)
    if phase >= 1 and phase < 8:
        # Check if the internal header even exists
        if not any("implementation plan" in k.lower() for k in sections.keys()):
            # If there is no internal plan, check for legacy external plan file
            task_dir = os.path.dirname(task_file)
            ts = os.path.basename(task_file).split('_')[0]
            legacy_plan = os.path.join(task_dir, f"{ts}.plan.md")
            if os.path.exists(legacy_plan):
                # Validate external plan
                sections = parse_markdown_sections(legacy_plan)
            elif os.path.exists("implementation_plan.md"):
                sections = parse_markdown_sections("implementation_plan.md")
            else:
                # If neither internal nor external exists, let task.sh validate_artifacts handle it
                return
                
        proposed_changes = find_section(sections, 'proposed changes')
        automated_tests = find_section(sections, 'automated tests')
        manual_verification = find_section(sections, 'manual verification')
        
        if proposed_changes is not None and not has_substance(proposed_changes):
            print("🛑 PROTOCOL VIOLATION: Implementation Plan section 'Proposed Changes' is empty or bare.")
            sys.exit(1)
            
        # At least one verification path must have substance
        has_auto = automated_tests is not None and has_substance(automated_tests)
        has_manual = manual_verification is not None and has_substance(manual_verification)
        
        if (automated_tests is not None or manual_verification is not None) and not (has_auto or has_manual):
            print("🛑 PROTOCOL VIOLATION: Verification Plan ('Automated Tests' or 'Manual Verification') has no substance.")
            sys.exit(1)
            
    # Validation for Phase 5+ (Tactical Roadmap Protocol)
    if phase >= 5:
        if not any("tactical roadmap protocol" in k.lower() for k in sections.keys()):
            # Check legacy external tr file
            task_dir = os.path.dirname(task_file)
            ts = os.path.basename(task_file).split('_')[0]
            legacy_tr = os.path.join(task_dir, f"{ts}.tr.md")
            if os.path.exists(legacy_tr):
                sections = parse_markdown_sections(legacy_tr)
            elif os.path.exists("protocol.md"):
                sections = parse_markdown_sections("protocol.md")
            else:
                return
                
        mission_briefing = find_section(sections, 'mission briefing')
        execution_loop = find_section(sections, 'execution loop')
        
        if mission_briefing is not None and not has_substance(mission_briefing):
            print("🛑 PROTOCOL VIOLATION: Tactical Roadmap Protocol section 'Mission Briefing' is empty or bare.")
            sys.exit(1)
            
        if execution_loop is not None and not has_substance(execution_loop):
            print("🛑 PROTOCOL VIOLATION: Tactical Roadmap Protocol section 'Execution Loop' is empty or bare.")
            sys.exit(1)

if __name__ == "__main__":
    main()
