import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Simple page indicator that reads the current page from a
/// [PdfViewerController] and updates itself on page change.
///
/// Wrap inside the PDF viewer's `onPageChanged` callback to refresh:
/// ```dart
/// SfPdfViewer.file(
///   ...,
///   onPageChanged: (_) => setState(() {}),
/// )
/// ```
/// Then place [PageIndicator] anywhere in the widget tree — it will update
/// on each setState call from its parent.
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.controller,
  });

  final PdfViewerController controller;

  @override
  Widget build(BuildContext context) {
    final currentPage = controller.pageCount > 0 ? controller.pageNumber : 0;
    final totalPages = controller.pageCount;

    return Text(
      'Pag. $currentPage / $totalPages',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
