from django.contrib import admin
from .models import Book, Student, BookBorrowing, ExamModel

@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ('name', 'author', 'inventory', 'stock', 'available_copies')
    search_fields = ('name', 'author', 'isbn')
    list_filter = ('category',)

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ('student_id', 'get_full_name', 'department', 'phone_number')
    search_fields = ('user__username', 'user__first_name', 'user__last_name', 'student_id')
    
    def get_full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username
    get_full_name.short_description = 'Name'

@admin.register(BookBorrowing)
class BookBorrowingAdmin(admin.ModelAdmin):
    list_display = ('get_student', 'get_book', 'status', 'request_date', 'due_date', 'return_date', 'fine_amount')
    list_filter = ('status',)
    search_fields = ('student__user__username', 'book__name')
    list_editable = ('status', 'due_date')
    date_hierarchy = 'request_date'
    
    def get_student(self, obj):
        return f"{obj.student.user.get_full_name() or obj.student.user.username} ({obj.student.student_id})"
    
    def get_book(self, obj):
        return obj.book.name
    
    get_student.short_description = 'Student'
    get_book.short_description = 'Book'

admin.site.register(ExamModel)
