import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/server.dart' as model;
import 'scaffold_body/message_composer.dart';
import 'scaffold_body/message_list.dart';
import 'scaffold_body_subject.dart';

class ScaffoldBody extends StatelessWidget {
  static Widget inSubject() {
    return Provider<ScaffoldBodySubject>(
      create: (context) => ScaffoldBodySubject(
        Provider.of<model.Server>(context, listen: false),
      ),
      child: const ScaffoldBody._(),
    );
  }

  const ScaffoldBody._();

  @override
  Widget build(BuildContext context) {
    final subject = Provider.of<ScaffoldBodySubject>(context);

    return StreamBuilder<model.Channel>(
      stream: subject.currentChannel,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final channel = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MessageList.inSubject(
                key: subject.messageListKey(channel),
                channel: channel,
              ),
              MessageComposer.inSubject(
                key: subject.messageComposerKey(channel),
                channel: channel,
              ),
            ],
          ),
        );
      },
    );
  }
}
