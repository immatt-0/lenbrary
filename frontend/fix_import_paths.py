#!/usr/bin/env python3
"""
Fix AppLocalizations Import Paths
"""
import os
import re
from pathlib import Path

SCREEN_FILES = [
    "lib/screens/active_loans_screen.dart",
    "lib/screens/add_book_screen.dart", 
    "lib/screens/add_exam_model_screen.dart",
    "lib/screens/book_details_screen.dart",
    "lib/screens/edit_book_screen.dart",
    "lib/screens/exam_models_admin_screen.dart",
    "lib/screens/exam_models_screen.dart",
    "lib/screens/extension_requests_screen.dart",
    "lib/screens/loan_history_screen.dart",
    "lib/screens/login_screen.dart",
    "lib/screens/manage_books_screen.dart",
    "lib/screens/my_requests_screen.dart",
    "lib/screens/notifications_screen.dart",
    "lib/screens/pdf_viewer_screen.dart",
    "lib/screens/pending_requests_screen.dart",
    "lib/screens/pickup_and_loans_screen.dart",
    "lib/screens/register_screen.dart",
    "lib/screens/search_books_screen.dart",
    "lib/screens/settings_screen.dart",
    "lib/screens/success_screen.dart",
    "lib/screens/teacher_code_generation_screen.dart",
]

def fix_import_path(content):
    """Fix the AppLocalizations import path"""
    old_import = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
    new_import = "import '../l10n/app_localizations.dart';"
    
    return content.replace(old_import, new_import)

def fix_file(file_path):
    """Fix import path in a single file"""
    if not os.path.exists(file_path):
        print(f"⚠️  File not found: {file_path}")
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        content = fix_import_path(content)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Fixed import path in {file_path}")
            return True
        else:
            print(f"⏭️  No import fix needed for {file_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error fixing {file_path}: {e}")
        return False

def main():
    """Main fixing process"""
    print("🔧 Fixing AppLocalizations Import Paths...")
    print(f"📝 Processing {len(SCREEN_FILES)} screen files...")
    
    files_fixed = 0
    
    for screen_file in SCREEN_FILES:
        if fix_file(screen_file):
            files_fixed += 1
    
    print(f"\n📊 Import Fix Complete:")
    print(f"   Files processed: {len(SCREEN_FILES)}")
    print(f"   Files fixed: {files_fixed}")

if __name__ == "__main__":
    main()
