part of '../hiring_applicant_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CV viewer for HiringApplicantDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showCvDialog(BuildContext context, String url) =>
    CvViewer.open(context, url);
