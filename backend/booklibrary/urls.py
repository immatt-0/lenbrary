from django.urls import path
from . import views
from .views import list_exam_models, create_exam_model, delete_exam_model

urlpatterns = [
    path('books', views.books, name='books'),
    path('book', views.book, name='book'),
    path('thumbnails', views.upload_thumbnail, name='upload_thumbnail'),
    path('request-book', views.request_book, name='request_book'),
    path('my-books', views.my_books, name='my_books'),
    path('return-book/<int:borrowing_id>', views.return_book, name='return_book'),
    path('register', views.register_user, name='register_user'),
    path('user-info', views.user_info, name='user_info'),
    path('pending-requests', views.pending_requests, name='pending_requests'),
    path('active-loans', views.active_loans, name='active_loans'),
    path('loan-history', views.loan_history, name='loan_history'),
    path('all-book-requests', views.all_book_requests, name='all_book_requests'),
    path('approve-request/<int:borrowing_id>', views.approve_request, name='approve_request'),
    path('reject-request/<int:borrowing_id>', views.reject_request, name='reject_request'),
    path('mark-pickup/<int:borrowing_id>', views.mark_pickup, name='mark_pickup'),
    path('librarian-return/<int:borrowing_id>', views.librarian_return_book, name='librarian_return_book'),
    path('update-book-stock/<int:book_id>', views.update_book_stock, name='update_book_stock'),
    
    # New messaging endpoints
    path('request-extension/<int:borrowing_id>', views.request_loan_extension, name='request_extension'),
    path('approve-extension/<int:borrowing_id>', views.approve_extension, name='approve_extension'),
    path('decline-extension/<int:borrowing_id>', views.decline_extension, name='decline_extension'),
    path('send-message', views.send_message, name='send_message'),
    path('messages', views.get_messages, name='get_messages'),
    path('mark-message-read/<int:message_id>', views.mark_message_read, name='mark_message_read'),
    path('users', views.get_all_users, name='get_all_users'),
    path('search-users', views.search_users, name='search_users'),
    
    # Notification endpoints
    path('notifications', views.get_notifications, name='get_notifications'),
    path('mark-notification-read/<int:notification_id>', views.mark_notification_read, name='mark_notification_read'),

    # Exam model API endpoints
    path('exam-models/', list_exam_models, name='list_exam_models'),
    path('exam-models/create/', create_exam_model, name='create_exam_model'),
    path('exam-models/<int:pk>/delete/', delete_exam_model, name='delete_exam_model'),

    # Email verification endpoints
    path('send-verification-email', views.send_verification_email, name='send_verification_email'),
    path('verify-email', views.verify_email, name='verify_email'),
    
    # Invitation code endpoints
    path('invitation-codes/create', views.create_invitation_code, name='create_invitation_code'),
    path('invitation-codes', views.list_invitation_codes, name='list_invitation_codes'),
    path('invitation-codes/<int:code_id>/delete', views.delete_invitation_code, name='delete_invitation_code'),
    path('invitation-codes/cleanup', views.cleanup_expired_invitations, name='cleanup_expired_invitations'),
]
