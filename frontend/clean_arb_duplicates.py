#!/usr/bin/env python3
"""
Script to clean duplicate keys from ARB (Application Resource Bundle) files.
This script will remove duplicate translation keys while preserving the first occurrence
and maintaining the JSON structure including metadata.
"""

import json
import os
import sys
from collections import OrderedDict

def clean_arb_file(file_path):
    """
    Clean duplicate keys from an ARB file.
    
    Args:
        file_path (str): Path to the ARB file
        
    Returns:
        tuple: (success, message, duplicates_found)
    """
    try:
        # Read the file
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Parse JSON while preserving order
        data = json.loads(content, object_pairs_hook=OrderedDict)
        
        # Track seen keys and duplicates
        seen_keys = set()
        duplicates = []
        cleaned_data = OrderedDict()
        
        # Process each key-value pair
        for key, value in data.items():
            if key in seen_keys:
                duplicates.append(key)
                print(f"  Removing duplicate: {key}")
            else:
                seen_keys.add(key)
                cleaned_data[key] = value
        
        if duplicates:
            # Create backup
            backup_path = file_path + '.backup'
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  Created backup: {backup_path}")
            
            # Write cleaned file
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(cleaned_data, f, ensure_ascii=False, indent=2)
            
            return True, f"Cleaned {len(duplicates)} duplicates", duplicates
        else:
            return True, "No duplicates found", []
            
    except json.JSONDecodeError as e:
        return False, f"JSON parsing error: {e}", []
    except Exception as e:
        return False, f"Error processing file: {e}", []

def main():
    """Main function to clean all ARB files."""
    # Define ARB files to clean
    arb_files = [
        'lib/l10n/app_ro.arb',
        'lib/l10n/app_en.arb',
        'lib/l10n/app_de.arb'
    ]
    
    print("🧹 Cleaning duplicate keys from ARB files...")
    print("=" * 50)
    
    total_duplicates = 0
    processed_files = 0
    
    for arb_file in arb_files:
        if os.path.exists(arb_file):
            print(f"\n📄 Processing: {arb_file}")
            success, message, duplicates = clean_arb_file(arb_file)
            
            if success:
                processed_files += 1
                total_duplicates += len(duplicates)
                print(f"  ✅ {message}")
                
                if duplicates:
                    print(f"  📋 Duplicates removed: {', '.join(duplicates)}")
            else:
                print(f"  ❌ {message}")
        else:
            print(f"\n⚠️  File not found: {arb_file}")
    
    print("\n" + "=" * 50)
    print(f"🎉 Cleanup complete!")
    print(f"📊 Files processed: {processed_files}/{len(arb_files)}")
    print(f"🔧 Total duplicates removed: {total_duplicates}")
    
    if total_duplicates > 0:
        print("\n💡 Backups created with .backup extension")
        print("   You can delete them after verifying the cleaned files work correctly.")

if __name__ == "__main__":
    main()
