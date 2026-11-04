import 'package:flutter/material.dart';

import '../../vocabulary/presentation/topic_list_screen.dart';
import '../application/grammar_providers.dart';

class GrammarTopicsScreen extends StatelessWidget {
  const GrammarTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TopicListScreen(
      title: 'Grammar',
      topicsProvider: grammarTopicsProvider,
      basePath: '/grammar',
      itemUnitLabel: 'điểm ngữ pháp',
    );
  }
}
