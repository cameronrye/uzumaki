#!/bin/bash
# Extract screenshots from xcresult bundles with proper names
# Usage: ./extract_screenshots.sh <xcresult_path> <output_dir>

set -e

XCRESULT="$1"
OUTPUT_DIR="$2"

if [ -z "$XCRESULT" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <xcresult_path> <output_dir>"
    echo "Example: $0 /tmp/ios_screenshots.xcresult screenshots/raw/iPhone"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

python3 << PYEOF
import json
import subprocess
import os

xcresult = "$XCRESULT"
output_dir = "$OUTPUT_DIR"

def get_json(ref_id=None):
    cmd = ["xcrun", "xcresulttool", "get", "--path", xcresult, "--format", "json", "--legacy"]
    if ref_id:
        cmd.extend(["--id", ref_id])
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)

def find_summary_refs(node, refs=None):
    if refs is None:
        refs = []
    if isinstance(node, dict):
        if 'summaryRef' in node:
            ref_id = node['summaryRef'].get('id', {}).get('_value', '')
            if ref_id:
                refs.append(ref_id)
        for value in node.values():
            find_summary_refs(value, refs)
    elif isinstance(node, list):
        for item in node:
            find_summary_refs(item, refs)
    return refs

def find_attachments(node, attachments=None):
    if attachments is None:
        attachments = []
    if isinstance(node, dict):
        if 'attachments' in node and '_values' in node['attachments']:
            for att in node['attachments']['_values']:
                name = att.get('name', {}).get('_value', 'unknown')
                payload_ref = att.get('payloadRef', {}).get('id', {}).get('_value', '')
                uti = att.get('uniformTypeIdentifier', {}).get('_value', '')
                if payload_ref and 'png' in uti.lower():
                    attachments.append((name, payload_ref))
        for value in node.values():
            find_attachments(value, attachments)
    elif isinstance(node, list):
        for item in node:
            find_attachments(item, attachments)
    return attachments

# Get root data
root_data = get_json()
tests_ref_id = root_data["actions"]["_values"][0]["actionResult"]["testsRef"]["id"]["_value"]

# Get test plan summaries
tests_data = get_json(tests_ref_id)

# Find all summary refs
summary_refs = find_summary_refs(tests_data)

# Get attachments from each summary
all_attachments = []
for ref_id in summary_refs:
    summary_data = get_json(ref_id)
    attachments = find_attachments(summary_data)
    all_attachments.extend(attachments)

print(f"Found {len(all_attachments)} PNG attachments")

# Extract each attachment
for name, ref_id in all_attachments:
    safe_name = name if name.endswith('.png') else f"{name}.png"
    output_path = os.path.join(output_dir, safe_name)

    cmd = ["xcrun", "xcresulttool", "get", "--path", xcresult, "--id", ref_id, "--legacy"]
    with open(output_path, 'wb') as f:
        result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE)

    if result.returncode == 0 and os.path.exists(output_path) and os.path.getsize(output_path) > 0:
        size = os.path.getsize(output_path)
        print(f"Extracted: {safe_name} ({size} bytes)")
    else:
        print(f"Failed: {name}")
        if os.path.exists(output_path):
            os.remove(output_path)

print(f"\nScreenshots saved to {output_dir}")
PYEOF

