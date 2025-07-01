import 'package:flutter/material.dart';
import '../services/responsive_service.dart';
import '../services/api_service.dart';

class ResponsiveBookCard extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final String? thumbnailUrl;
  final String? bookClass;
  final String bookType;
  final String? description;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewPdf;
  final VoidCallback? onRequestBook;
  final bool showActions;
  final bool isLoading;
  final int? availableCopies;
  final int? totalCopies;

  const ResponsiveBookCard({
    Key? key,
    required this.title,
    required this.author,
    required this.category,
    this.thumbnailUrl,
    this.bookClass,
    required this.bookType,
    this.description,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onViewPdf,
    this.onRequestBook,
    this.showActions = false,
    this.isLoading = false,
    this.availableCopies,
    this.totalCopies,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Bigger sizes for better visibility and centering
    final cardPadding = ResponsiveService.getSpacing(20);
    final titleFontSize = ResponsiveService.getFontSize(22);
    final authorFontSize = ResponsiveService.getFontSize(17);
    final categoryFontSize = ResponsiveService.getFontSize(16);
    final classFontSize = ResponsiveService.getFontSize(14);
    final iconSize = ResponsiveService.getIconSize(22);
    final buttonSize = ResponsiveService.getSpacing(52);
    final borderRadius = ResponsiveService.getSpacing(18);
    final thumbnailWidth = ResponsiveService.getSpacing(60);
    final thumbnailHeight = ResponsiveService.getSpacing(80);
    final descriptionFontSize = ResponsiveService.getFontSize(13);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSpacing(14),
        vertical: ResponsiveService.getSpacing(10),
      ),
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onTap,
              child: _buildCardContent(context, borderRadius, thumbnailWidth, thumbnailHeight, titleFontSize, authorFontSize, categoryFontSize),
            )
          : _buildCardContent(context, borderRadius, thumbnailWidth, thumbnailHeight, titleFontSize, authorFontSize, categoryFontSize),
    );
  }

  Widget _buildCardContent(BuildContext context, double borderRadius, double thumbnailWidth, double thumbnailHeight, double titleFontSize, double authorFontSize, double categoryFontSize) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveService.getSpacing(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Builder(
                builder: (context) {
                  if (thumbnailUrl == null) {
                    return Container(
                      width: thumbnailWidth,
                      height: thumbnailHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      ),
                      child: Icon(
                        bookType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Image.network(
                      thumbnailUrl!,
                      width: thumbnailWidth,
                      height: thumbnailHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: thumbnailWidth,
                          height: thumbnailHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          ),
                          child: Icon(
                            bookType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(width: 8),
              // Book details with better spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: ResponsiveService.getSpacing(6)),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: authorFontSize,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (description != null && description!.trim().isNotEmpty) ...[
                      SizedBox(height: ResponsiveService.getSpacing(8)),
                      Text.rich(
                        TextSpan(text: description),
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(14),
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: ResponsiveService.getSpacing(10)),
                    Wrap(
                      spacing: ResponsiveService.getSpacing(8),
                      runSpacing: ResponsiveService.getSpacing(6),
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveService.getSpacing(12),
                            vertical: ResponsiveService.getSpacing(6),
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(10)),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: categoryFontSize,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        if (bookClass != null && bookClass!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveService.getSpacing(10),
                              vertical: ResponsiveService.getSpacing(5),
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(10)),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: ResponsiveService.getIconSize(14),
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                SizedBox(width: ResponsiveService.getSpacing(3)),
                                Text(
                                  'Clasa $bookClass',
                                  style: TextStyle(
                                    fontSize: ResponsiveService.getFontSize(14),
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Glowing availability indicator
              if (availableCopies != null)
                Padding(
                  padding: EdgeInsets.only(left: ResponsiveService.getSpacing(12)),
                  child: _buildAvailabilityIndicator(context),
                ),
              if (onEdit != null || onViewPdf != null || onDelete != null)
                Padding(
                  padding: EdgeInsets.only(left: ResponsiveService.getSpacing(8)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        Container(
                          width: ResponsiveService.getSpacing(52),
                          height: ResponsiveService.getSpacing(52),
                          margin: EdgeInsets.only(bottom: ResponsiveService.getSpacing(8)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: ResponsiveService.getSpacing(8),
                                offset: Offset(0, ResponsiveService.getSpacing(2)),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit_rounded, size: ResponsiveService.getIconSize(22), color: Colors.white),
                            tooltip: 'Editează',
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      if (onDelete != null)
                        Container(
                          width: ResponsiveService.getSpacing(52),
                          height: ResponsiveService.getSpacing(52),
                          margin: EdgeInsets.only(bottom: ResponsiveService.getSpacing(8)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.error,
                                Theme.of(context).colorScheme.error.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                                blurRadius: ResponsiveService.getSpacing(8),
                                offset: Offset(0, ResponsiveService.getSpacing(2)),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete_rounded, size: ResponsiveService.getIconSize(22), color: Colors.white),
                            tooltip: 'Șterge',
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      if (onViewPdf != null)
                        Container(
                          width: ResponsiveService.getSpacing(52),
                          height: ResponsiveService.getSpacing(52),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                blurRadius: ResponsiveService.getSpacing(8),
                                offset: Offset(0, ResponsiveService.getSpacing(2)),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.picture_as_pdf_rounded, size: ResponsiveService.getIconSize(22), color: Colors.white),
                            onPressed: onViewPdf,
                            tooltip: 'PDF',
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Glowing availability indicator widget
  Widget _buildAvailabilityIndicator(BuildContext context) {
    final isAvailable = (availableCopies ?? 0) > 0;
    final color = isAvailable ? Colors.green : Colors.red;
    return Container(
      width: ResponsiveService.getSpacing(28),
      height: ResponsiveService.getSpacing(28),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
} 