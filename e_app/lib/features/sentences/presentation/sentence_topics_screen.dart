import 'package:flutter/material.dart';

import '../../vocabulary/presentation/topic_list_screen.dart';
import '../application/sentence_providers.dart';

class SentenceTopicsScreen extends StatelessWidget {
  const SentenceTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TopicListScreen(
      title: 'Sentences',
      topicsProvider: sentenceTopicsProvider,
      basePath: '/sentences',
      itemUnitLabel: 'câu mẫu',
    );
  }
}
