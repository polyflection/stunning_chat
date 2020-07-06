import 'package:flutter/material.dart';

import '../../model/server.dart' as model;
import 'channel_creating_page_subject.dart';

class ChannelCreatingPage extends StatefulWidget {
  final model.Server server;

  ChannelCreatingPage(this.server);

  @override
  _ChannelCreatingPageState createState() => _ChannelCreatingPageState();
}

class _ChannelCreatingPageState extends State<ChannelCreatingPage> {
  ChannelCreatingSubject subject;

  @override
  void initState() {
    super.initState();
    subject = ChannelCreatingSubject(widget.server);
  }

  @override
  void dispose() {
    subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<ChannelForm>(
        future: subject.channelForm.future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final channelForm = snapshot.data;

          return Scaffold(
            key: subject.scaffoldKey,
            appBar: AppBar(
              title: const Text('Creating Channel'),
              actions: [
                StreamBuilder<bool>(
                  stream: channelForm.canSubmit,
                  initialData: false,
                  builder: (context, snapshot) {
                    return IconButton(
                      key: const Key('submitButton'),
                      icon: const Icon(Icons.done),
                      onPressed: snapshot.data
                          ? () => channelForm.submit.add(null)
                          : null,
                    );
                  },
                ),
              ],
            ),
            body: StreamBuilder<bool>(
              stream: channelForm.isSubmitting,
              initialData: false,
              builder: (context, snapshot) {
                final isSubmitting = snapshot.data;
                const progressIndicatorHeight = 4.0;
                final padding = isSubmitting
                    ? const EdgeInsets.fromLTRB(
                        16, (16 - progressIndicatorHeight), 16, 16)
                    : const EdgeInsets.all(16);
                final form = Padding(
                  padding: padding,
                  child: Form(
                    child: StreamBuilder<NameField>(
                      stream: channelForm.nameField,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final field = snapshot.data;
                        return TextFormField(
                          enabled: !isSubmitting,
                          maxLines: 1,
                          controller: field.controller,
                          decoration: InputDecoration(
                              hintText: field.hintText,
                              errorText: field.errorText),
                        );
                      },
                    ),
                  ),
                );

                if (snapshot.data) {
                  return Column(children: [
                    const LinearProgressIndicator(
                      minHeight: progressIndicatorHeight,
                    ),
                    form
                  ]);
                } else {
                  return form;
                }
              },
            ),
          );
        },
      ),
    );
  }
}
