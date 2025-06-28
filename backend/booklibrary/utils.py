def capitalize_name(name):
    """
    Properly capitalize a name for display.
    Handles multiple words, hyphens, and special cases.
    """
    if not name:
        return ""
    
    # Split by spaces and hyphens, capitalize each part
    parts = name.replace('-', ' - ').split()
    capitalized_parts = []
    
    for part in parts:
        if part == '-':
            capitalized_parts.append('-')
        else:
            # Handle special cases like "de", "van", "von", etc.
            if part.lower() in ['de', 'van', 'von', 'del', 'della', 'di', 'da', 'du', 'le', 'la']:
                capitalized_parts.append(part.lower())
            else:
                # Capitalize first letter, lowercase the rest
                capitalized_parts.append(part.capitalize())
    
    return ' '.join(capitalized_parts)

def get_display_name(user):
    """
    Get a properly capitalized display name for a user.
    Returns first_name + last_name if available, otherwise username.
    """
    if user.first_name and user.last_name:
        first_name = capitalize_name(user.first_name)
        last_name = capitalize_name(user.last_name)
        return f"{first_name} {last_name}"
    elif user.first_name:
        return capitalize_name(user.first_name)
    elif user.last_name:
        return capitalize_name(user.last_name)
    else:
        return user.username 