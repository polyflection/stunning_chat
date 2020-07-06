import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../resource_provider.dart';
import '../../../model/server.dart' as model;
import 'message_composer_subject.dart';

class MessageComposer extends StatelessWidget {
  static Widget inSubject({Key key, @required model.Channel channel}) {
    return ResourceProvider<MessageComposerSubject>(
      key: key,
      create: (_) => MessageComposerSubject(channel),
      child: const MessageComposer._(),
    );
  }

  const MessageComposer._();

  @override
  Widget build(BuildContext context) {
    final subject = Provider.of<MessageComposerSubject>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 144),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.all(Radius.circular(25.0)),
      ),
      child: StreamBuilder<model.MessageComposer>(
        stream: subject.messageCreator,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final creator = snapshot.data;

          return Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    key: ObjectKey(creator),
                    maxLines: null,
                    decoration: const InputDecoration.collapsed(
                        hintText: 'Type your message...'),
                    onChanged: creator.updateBody.add,
                    focusNode: subject.focusNode,
                  ),
                ),
              ),
              StreamBuilder<bool>(
                stream: creator.canSend,
                initialData: false,
                builder: (context, snapshot) {
                  return IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: snapshot.data
                        ? () => subject.onSendButtonPressed(creator)
                        : null,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
