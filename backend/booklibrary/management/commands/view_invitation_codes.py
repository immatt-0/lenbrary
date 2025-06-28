from django.core.management.base import BaseCommand
from booklibrary.models import InvitationCode
from datetime import datetime


class Command(BaseCommand):
    help = 'Display all invitation codes with their status (active, expired, used)'

    def handle(self, *args, **options):
        """Display all invitation codes with their details."""
        self.stdout.write("=" * 80)
        self.stdout.write("INVITATION CODES")
        self.stdout.write("=" * 80)
        
        # Get all invitation codes
        invitation_codes = InvitationCode.objects.all().order_by('created_at')
        
        if not invitation_codes.exists():
            self.stdout.write("No invitation codes found in the system.")
            return
        
        active_count = 0
        expired_count = 0
        
        for code in invitation_codes:
            self.stdout.write(f"\nCode ID: {code.id}")
            self.stdout.write(f"Code: {code.code}")
            self.stdout.write(f"Created By: {code.created_by.username if code.created_by else 'Unknown'}")
            self.stdout.write(f"Created At: {code.created_at.strftime('%Y-%m-%d %H:%M:%S')}")
            self.stdout.write(f"Expires At: {code.expires_at.strftime('%Y-%m-%d %H:%M:%S')}")
            
            # Check status
            now = datetime.now()
            if code.is_expired():
                self.stdout.write("Status: ❌ EXPIRED")
                expired_count += 1
            else:
                self.stdout.write("Status: 🟢 ACTIVE")
                active_count += 1
            
            self.stdout.write("-" * 80)
        
        self.stdout.write(f"\nSUMMARY:")
        self.stdout.write(f"Total Invitation Codes: {invitation_codes.count()}")
        self.stdout.write(f"Active Codes: {active_count}")
        self.stdout.write(f"Expired Codes: {expired_count}")
        self.stdout.write("=" * 80) 