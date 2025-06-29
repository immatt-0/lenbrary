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
    final titleFontSize = ResponsiveService.getFontSize(18);
    final authorFontSize = ResponsiveService.getFontSize(15);
    final categoryFontSize = ResponsiveService.getFontSize(13);
    final classFontSize = ResponsiveService.getFontSize(13);
    final iconSize = ResponsiveService.getIconSize(22);
    final buttonSize = ResponsiveService.getSpacing(52);
    final borderRadius = ResponsiveService.getSpacing(18);
    final thumbnailWidth = ResponsiveService.getSpacing(60);
    final thumbnailHeight = ResponsiveService.getSpacing(80);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSpacing(14),
        vertical: ResponsiveService.getSpacing(10),
      ),
      child: Card(
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
            padding: EdgeInsets.all(cardPadding),
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
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      SizedBox(height: ResponsiveService.getSpacing(4)),
                      Text(
                        author,
                        style: TextStyle(
                          fontSize: authorFontSize,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: ResponsiveService.getSpacing(8)),
                      Wrap(
                        spacing: ResponsiveService.getSpacing(6),
                        runSpacing: ResponsiveService.getSpacing(4),
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveService.getSpacing(8),
                              vertical: ResponsiveService.getSpacing(4),
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: categoryFontSize,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          if (bookClass != null && bookClass!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveService.getSpacing(8),
                                vertical: ResponsiveService.getSpacing(4),
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: ResponsiveService.getIconSize(12),
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  SizedBox(width: ResponsiveService.getSpacing(2)),
                                  Text(
                                    'Clasa $bookClass',
                                    style: TextStyle(
                                      fontSize: classFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (availableCopies != null && totalCopies != null) ...[
                        SizedBox(height: ResponsiveService.getSpacing(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveService.getSpacing(8),
                            vertical: ResponsiveService.getSpacing(4),
                          ),
                          decoration: BoxDecoration(
                            color: (availableCopies ?? 0) > 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                            border: Border.all(
                              color: (availableCopies ?? 0) > 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                size: ResponsiveService.getIconSize(12),
                                color: (availableCopies ?? 0) > 0 ? Colors.green : Colors.red,
                              ),
                              SizedBox(width: ResponsiveService.getSpacing(4)),
                              Text(
                                '${availableCopies ?? 0}/${totalCopies ?? 0}',
                                style: TextStyle(
                                  fontSize: categoryFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: (availableCopies ?? 0) > 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action buttons with better styling
                if (onRequestBook != null)
                  Padding(
                    padding: EdgeInsets.only(left: ResponsiveService.getSpacing(8)),
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
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
                        icon: Icon(Icons.bookmark_add_rounded, size: iconSize, color: Colors.white),
                        onPressed: onRequestBook,
                        tooltip: 'Solicită',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                if (onViewPdf != null)
                  Padding(
                    padding: EdgeInsets.only(left: ResponsiveService.getSpacing(8)),
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
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
                        icon: Icon(Icons.picture_as_pdf_rounded, size: iconSize, color: Colors.white),
                        onPressed: onViewPdf,
                        tooltip: 'PDF',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 