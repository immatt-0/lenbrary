#!/usr/bin/env python3
"""
Fix Compilation Errors from Localization Conversion
"""
import os
import re
from pathlib import Path

SCREEN_FILES = [
    "lib/screens/active_loans_screen.dart",
    "lib/screens/add_book_screen.dart", 
    "lib/screens/book_details_screen.dart",
    "lib/screens/edit_book_screen.dart",
    "lib/screens/extension_requests_screen.dart",
    "lib/screens/loan_history_screen.dart",
    "lib/screens/manage_books_screen.dart",
    "lib/screens/my_requests_screen.dart",
    "lib/screens/notifications_screen.dart",
    "lib/screens/pending_requests_screen.dart",
    "lib/screens/search_books_screen.dart",
    "lib/screens/teacher_code_generation_screen.dart",
]

def fix_const_issues(content):
    """Remove const keywords that cause issues with AppLocalizations"""
    # Fix const Text with AppLocalizations
    content = re.sub(r'const Text\(AppLocalizations\.of\(context\)![^)]+\)', 
                    lambda m: m.group(0).replace('const ', ''), content)
    
    # Fix other const issues with AppLocalizations
    content = re.sub(r'const\s+([^,\)]*AppLocalizations\.of\(context\)![^,\)]*)', 
                    r'\1', content)
    
    return content

def fix_missing_applocalization_refs(content):
    """Fix missing AppLocalizations references where just 'AppLocalizations' is used"""
    # This pattern looks for standalone 'AppLocalizations' that should be full references
    content = re.sub(r'(?<!\.)AppLocalizations\.of\(context\)!', 
                    'AppLocalizations.of(context)!', content)
    
    return content

def ensure_import(content):
    """Add AppLocalizations import if not present"""
    import_line = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
    
    if import_line not in content:
        lines = content.split('\n')
        import_added = False
        
        for i, line in enumerate(lines):
            if line.startswith('import ') and 'flutter/' in line:
                lines.insert(i + 1, import_line)
                import_added = True
                break
        
        if not import_added:
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i + 1, import_line)
                    break
        
        return '\n'.join(lines)
    return content

def fix_file(file_path):
    """Fix compilation errors in a single file"""
    if not os.path.exists(file_path):
        print(f"⚠️  File not found: {file_path}")
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Add import if needed
        content = ensure_import(content)
        
        # Fix const issues
        content = fix_const_issues(content)
        
        # Fix missing AppLocalizations references
        content = fix_missing_applocalization_refs(content)
        
        # Write back if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Fixed compilation issues in {file_path}")
            return True
        else:
            print(f"⏭️  No fixes needed for {file_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error fixing {file_path}: {e}")
        return False

def main():
    """Main fixing process"""
    print("🔧 Fixing Lenbrary Localization Compilation Errors...")
    print(f"📝 Processing {len(SCREEN_FILES)} screen files...")
    
    files_fixed = 0
    
    for screen_file in SCREEN_FILES:
        if fix_file(screen_file):
            files_fixed += 1
    
    print(f"\n📊 Fix Complete:")
    print(f"   Files processed: {len(SCREEN_FILES)}")
    print(f"   Files fixed: {files_fixed}")

if __name__ == "__main__":
    main()
