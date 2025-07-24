from rest_framework.renderers import JSONRenderer
import json

class UnicodeJSONRenderer(JSONRenderer):
    """
    Custom JSON renderer that ensures proper UTF-8 encoding for Romanian diacritics
    """
    charset = 'utf-8'
    
    def render(self, data, accepted_media_type=None, renderer_context=None):
        """
        Render data into JSON with proper Unicode support
        """
        if data is None:
            return b''
        
        # Ensure Unicode characters are not escaped
        json_str = json.dumps(
            data, 
            ensure_ascii=False,  # This is key for diacritics
            separators=(',', ':'),
            indent=None
        )
        
        # Encode to UTF-8 bytes
        return json_str.encode('utf-8')
