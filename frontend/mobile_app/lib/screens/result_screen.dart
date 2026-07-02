import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/disease_result.dart';
import 'camera_screen.dart';

class ResultScreen extends StatelessWidget {
  final DiseaseResult result;
  final Uint8List? imageBytes;

  const ResultScreen({
    super.key,
    required this.result,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          _ResultAppBar(result: result, imageBytes: imageBytes),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DiseaseCard(result: result),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Recommended Treatment',
                  icon: Icons.medical_services_outlined,
                  content: result.treatment,
                  color: kErrorRed,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Prevention',
                  icon: Icons.shield_outlined,
                  content: result.prevention,
                  color: kDeepGreen,
                ),
                const SizedBox(height: 24),
                _ActionButtons(result: result),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultAppBar extends StatelessWidget {
  final DiseaseResult result;
  final Uint8List? imageBytes;

  const _ResultAppBar({required this.result, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: imageBytes != null ? 260 : 120,
      pinned: true,
      backgroundColor: kDeepGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Detection Result',
          style: TextStyle(color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        background: imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeepGreen, Color(0xFF1B5E20)],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  final DiseaseResult result;
  const _DiseaseCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: result.color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: result.color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: result.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.isHealthy
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: result.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.disease,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kDeepGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: result.severityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Severity: ${result.severity}',
                        style: TextStyle(
                          color: result.severityColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _ConfidenceBar(confidence: result.confidence, color: result.color),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  final Color color;

  const _ConfidenceBar({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${confidence.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: confidence / 100,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final DiseaseResult result;
  const _ActionButtons({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CameraScreen()),
            );
          },
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Scan Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kDeepGreen,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showDADialog(context),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Report to DA Technician'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kDeepGreen,
            side: const BorderSide(color: kDeepGreen, width: 1.5),
          ),
        ),
      ],
    );
  }

  void _showDADialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report to DA'),
        content: Text(
          'Send detection result for "${result.disease}" (${result.confidence.toStringAsFixed(1)}% confidence) to your local Department of Agriculture technician in New Bataan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report sent to DA Technician!'),
                  backgroundColor: kDeepGreen,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
