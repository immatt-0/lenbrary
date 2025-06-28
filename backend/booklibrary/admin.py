from django.contrib import admin
from .models import Book, Student, BookBorrowing, ExamModel, EmailVerification, InvitationCode

@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ('name', 'author', 'inventory', 'stock', 'available_copies')
    search_fields = ('name', 'author', 'isbn')
    list_filter = ('category',)

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ('user', 'student_id', 'school_type', 'department', 'student_class')
    search_fields = ('user__email', 'user__first_name', 'user__last_name', 'student_id')
    list_filter = ('school_type', 'department', 'student_class')

@admin.register(BookBorrowing)
class BookBorrowingAdmin(admin.ModelAdmin):
    list_display = ('student', 'book', 'status', 'request_date', 'due_date')
    list_filter = ('status', 'request_date')
    search_fields = ('student__user__email', 'book__name')

admin.site.register(ExamModel)

@admin.register(EmailVerification)
class EmailVerificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'is_verified', 'created_at')
    search_fields = ('user__email',)

@admin.register(InvitationCode)
class InvitationCodeAdmin(admin.ModelAdmin):
    list_display = ('code', 'created_by', 'created_at', 'expires_at', 'is_valid')
    list_filter = ('created_at', 'expires_at')
    search_fields = ('code', 'created_by__username')
    readonly_fields = ('code', 'created_at')
    
    def is_valid(self, obj):
        return obj.is_valid()
    is_valid.boolean = True
    is_valid.short_description = 'Valid'
