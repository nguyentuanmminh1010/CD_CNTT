import 'package:flutter/material.dart';

import '../application/vocabulary_providers.dart';
import 'topic_list_screen.dart';

class VocabularyTopicsScreen extends StatelessWidget {
  const VocabularyTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TopicListScreen(
      title: 'Vocabulary',
      topicsProvider: vocabularyTopicsProvider,
      basePath: '/vocabulary',
      itemUnitLabel: 'từ vựng',
    );
  }
}
